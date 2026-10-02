package com.example.thesis.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.thesis.common.Constants;
import com.example.thesis.entity.Student;
import com.example.thesis.entity.SysUser;
import com.example.thesis.entity.Teacher;
import com.example.thesis.mapper.SysUserMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.CellType;
import org.apache.poi.ss.usermodel.DataFormatter;
import org.apache.poi.ss.usermodel.FillPatternType;
import org.apache.poi.ss.usermodel.Font;
import org.apache.poi.ss.usermodel.IndexedColors;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * 账号批量导入。
 * <p>策略：先全量校验（必填、重复、字典命中），全部通过才落库；任一行有问题则整批不导入，
 * 并返回逐行错误报告，避免出现「导了一半」的中间状态。
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ImportService {

    /** 模板列顺序，导入解析与模板生成共用，避免两边不一致 */
    private static final String[] HEADERS = {
            "角色*", "姓名*", "性别", "学号/工号*", "届别", "学院", "专业", "班级",
            "职称", "联系电话", "邮箱", "初始密码"
    };
    private static final String[] EXAMPLE = {
            "学生", "张三", "男", "20271234", "2027", "计算机与人工智能学院",
            "计算机科学与技术", "计科23-1班", "", "13700000000", "zhangsan@stu.edu.cn", "123456"
    };
    private static final String[] EXAMPLE_TEACHER = {
            "指导教师", "李四", "女", "T2025", "", "软件学院", "软件工程", "",
            "副教授", "13800000000", "lisi@edu.cn", "123456"
    };

    private static final Map<String, String> ROLE_ALIAS = Map.of(
            "学生", Constants.ROLE_STUDENT,
            "STUDENT", Constants.ROLE_STUDENT,
            "指导教师", Constants.ROLE_ADVISOR,
            "ADVISOR", Constants.ROLE_ADVISOR,
            "评阅教师", Constants.ROLE_REVIEWER,
            "REVIEWER", Constants.ROLE_REVIEWER
    );

    private final SysUserMapper sysUserMapper;
    private final SystemService systemService;
    private final UserService userService;

    // ===================================================== 模板
    public byte[] buildTemplate() {
        try (Workbook workbook = new XSSFWorkbook()) {
            Sheet sheet = workbook.createSheet("账号导入");

            CellStyle headStyle = workbook.createCellStyle();
            Font headFont = workbook.createFont();
            headFont.setBold(true);
            headStyle.setFont(headFont);
            headStyle.setFillForegroundColor(IndexedColors.GREY_25_PERCENT.getIndex());
            headStyle.setFillPattern(FillPatternType.SOLID_FOREGROUND);

            Row header = sheet.createRow(0);
            for (int i = 0; i < HEADERS.length; i++) {
                Cell cell = header.createCell(i);
                cell.setCellValue(HEADERS[i]);
                cell.setCellStyle(headStyle);
            }
            Row demo1 = sheet.createRow(1);
            Row demo2 = sheet.createRow(2);
            for (int i = 0; i < HEADERS.length; i++) {
                demo1.createCell(i).setCellValue(EXAMPLE[i]);
                demo2.createCell(i).setCellValue(EXAMPLE_TEACHER[i]);
            }
            for (int i = 0; i < HEADERS.length; i++) {
                sheet.setColumnWidth(i, 20 * 256);
            }

            Sheet help = workbook.createSheet("填写说明");
            String[] lines = {
                    "角色*：填写 学生 / 指导教师 / 评阅教师（或 STUDENT / ADVISOR / REVIEWER）",
                    "姓名*：真实姓名，必填",
                    "性别：男 / 女，可留空",
                    "学号/工号*：必填，同时作为登录账号，全库唯一",
                    "届别：学生必填，如 2027，取值需在字典 GRADE 中",
                    "学院 / 专业 / 班级：学生必填，取值需在字典 COLLEGE / MAJOR / CLASS 中；",
                    "                  班级需属于所选专业，专业需属于所选学院",
                    "职称：教师填写，取值需在字典 TITLE 中",
                    "初始密码：可留空，留空时使用系统默认密码",
                    "注意：示例行（第 2、3 行）请在正式导入前删除；任一行校验失败则整批不导入"
            };
            for (int i = 0; i < lines.length; i++) {
                help.createRow(i).createCell(0).setCellValue(lines[i]);
            }
            help.setColumnWidth(0, 80 * 256);

            ByteArrayOutputStream out = new ByteArrayOutputStream();
            workbook.write(out);
            return out.toByteArray();
        } catch (IOException e) {
            throw new IllegalStateException("生成导入模板失败", e);
        }
    }

    // ===================================================== 导入
    @Transactional
    public Map<String, Object> importUsers(MultipartFile file) {
        List<Map<String, Object>> errors = new ArrayList<>();
        List<ParsedRow> rows = parse(file, errors);

        // 第二遍：业务校验
        Set<String> seenInFile = new HashSet<>();
        for (ParsedRow row : rows) {
            StringBuilder msg = new StringBuilder();
            if (!seenInFile.add(row.account)) {
                msg.append("文件内学号/工号重复；");
            }
            if (sysUserMapper.selectCount(new LambdaQueryWrapper<SysUser>()
                    .eq(SysUser::getUsername, row.account)) > 0) {
                msg.append("账号已存在；");
            }
            if (Constants.ROLE_STUDENT.equals(row.role)) {
                if (!StringUtils.hasText(row.grade)) {
                    msg.append("学生届别不能为空；");
                } else if (!systemService.nameExists(Constants.DICT_GRADE, row.grade)) {
                    msg.append("届别不在字典中；");
                }
                if (!StringUtils.hasText(row.college) || !systemService.nameExists(Constants.DICT_COLLEGE, row.college)) {
                    msg.append("学院不在字典中；");
                }
                if (!StringUtils.hasText(row.major) || !systemService.nameExists(Constants.DICT_MAJOR, row.major)) {
                    msg.append("专业不在字典中；");
                }
                if (!StringUtils.hasText(row.className) || !systemService.nameExists(Constants.DICT_CLASS, row.className)) {
                    msg.append("班级不在字典中；");
                }
            } else if (StringUtils.hasText(row.title) && !systemService.nameExists(Constants.DICT_TITLE, row.title)) {
                msg.append("职称不在字典中；");
            }
            if (msg.length() > 0) {
                errors.add(errorItem(row.rowNum, msg.toString()));
            }
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("total", rows.size());
        if (!errors.isEmpty()) {
            result.put("successCount", 0);
            result.put("failCount", errors.size());
            result.put("errors", errors);
            result.put("imported", false);
            result.put("message", "校验未通过，本次未导入任何数据");
            return result;
        }

        for (ParsedRow row : rows) {
            if (Constants.ROLE_STUDENT.equals(row.role)) {
                Student student = new Student();
                student.setStudentNo(row.account);
                student.setRealName(row.name);
                student.setGender(row.gender);
                student.setGrade(row.grade);
                student.setCollege(row.college);
                student.setMajor(row.major);
                student.setClassName(row.className);
                student.setPhone(row.phone);
                student.setEmail(row.email);
                userService.saveStudent(student, row.password);
            } else {
                Teacher teacher = new Teacher();
                teacher.setTeacherNo(row.account);
                teacher.setRealName(row.name);
                teacher.setGender(row.gender);
                teacher.setTitle(row.title);
                teacher.setCollege(row.college);
                teacher.setMajor(row.major);
                teacher.setTeacherType(Constants.ROLE_REVIEWER.equals(row.role) ? "REVIEWER" : "ADVISOR");
                teacher.setCanReview(Constants.ROLE_REVIEWER.equals(row.role) ? 1 : 0);
                teacher.setPhone(row.phone);
                teacher.setEmail(row.email);
                userService.saveTeacher(teacher, row.password);
            }
        }

        result.put("successCount", rows.size());
        result.put("failCount", 0);
        result.put("errors", List.of());
        result.put("imported", true);
        result.put("message", "导入成功 " + rows.size() + " 条");
        return result;
    }

    // ===================================================== 解析
    private List<ParsedRow> parse(MultipartFile file, List<Map<String, Object>> errors) {
        List<ParsedRow> rows = new ArrayList<>();
        if (file == null || file.isEmpty()) {
            errors.add(errorItem(0, "上传文件为空"));
            return rows;
        }
        DataFormatter formatter = new DataFormatter();
        try (InputStream in = file.getInputStream(); Workbook workbook = new XSSFWorkbook(in)) {
            Sheet sheet = workbook.getSheetAt(0);
            for (int i = 1; i <= sheet.getLastRowNum(); i++) {
                Row row = sheet.getRow(i);
                if (row == null || isBlankRow(row, formatter)) {
                    continue;
                }
                int rowNum = i + 1;
                ParsedRow parsed = new ParsedRow();
                parsed.rowNum = rowNum;
                String roleText = cell(row, 0, formatter);
                String account = cell(row, 3, formatter);
                String name = cell(row, 1, formatter);

                StringBuilder msg = new StringBuilder();
                parsed.role = ROLE_ALIAS.get(roleText.trim().toUpperCase());
                if (parsed.role == null) {
                    parsed.role = ROLE_ALIAS.get(roleText.trim());
                }
                if (parsed.role == null) {
                    msg.append("角色无法识别；");
                }
                if (!StringUtils.hasText(name)) {
                    msg.append("姓名不能为空；");
                }
                if (!StringUtils.hasText(account)) {
                    msg.append("学号/工号不能为空；");
                }
                if (msg.length() > 0) {
                    errors.add(errorItem(rowNum, msg.toString()));
                    continue;
                }

                parsed.account = account.trim();
                parsed.name = name.trim();
                parsed.gender = parseGender(cell(row, 2, formatter));
                parsed.grade = cell(row, 4, formatter);
                parsed.college = cell(row, 5, formatter);
                parsed.major = cell(row, 6, formatter);
                parsed.className = cell(row, 7, formatter);
                parsed.title = cell(row, 8, formatter);
                parsed.phone = cell(row, 9, formatter);
                parsed.email = cell(row, 10, formatter);
                parsed.password = cell(row, 11, formatter);
                rows.add(parsed);
            }
        } catch (IOException e) {
            log.error("解析 Excel 失败", e);
            errors.add(errorItem(0, "文件解析失败，请使用模板格式的 .xlsx 文件"));
        }
        return rows;
    }

    private boolean isBlankRow(Row row, DataFormatter formatter) {
        for (int i = 0; i < HEADERS.length; i++) {
            if (StringUtils.hasText(cell(row, i, formatter))) {
                return false;
            }
        }
        return true;
    }

    private String cell(Row row, int index, DataFormatter formatter) {
        Cell cell = row.getCell(index);
        if (cell == null) {
            return "";
        }
        cell.setCellType(CellType.STRING);
        return formatter.formatCellValue(cell).trim();
    }

    private Integer parseGender(String text) {
        if ("男".equals(text) || "1".equals(text)) {
            return 1;
        }
        if ("女".equals(text) || "2".equals(text)) {
            return 2;
        }
        return 0;
    }

    private Map<String, Object> errorItem(int rowNum, String message) {
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("row", rowNum);
        item.put("message", message);
        return item;
    }

    /** 解析后的单行 */
    private static class ParsedRow {
        int rowNum;
        String role;
        String account;
        String name;
        Integer gender = 0;
        String grade;
        String college;
        String major;
        String className;
        String title;
        String phone;
        String email;
        String password;
    }
}
