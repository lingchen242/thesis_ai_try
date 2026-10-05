package com.example.thesis.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.example.thesis.common.BizException;
import com.example.thesis.common.Constants;
import com.example.thesis.security.SecurityUtils;
import com.example.thesis.common.PageResult;
import com.example.thesis.dto.PageQuery;
import com.example.thesis.entity.Student;
import com.example.thesis.entity.SysUser;
import com.example.thesis.entity.Teacher;
import com.example.thesis.entity.Thesis;
import com.example.thesis.mapper.StudentMapper;
import com.example.thesis.mapper.SysUserMapper;
import com.example.thesis.mapper.TeacherMapper;
import com.example.thesis.mapper.ThesisMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * 基础数据：账号 / 教师 / 学生。
 * <p>学生与教师都是「账号 + 档案」两张表，保存时在同一事务内一并处理。
 */
@Service
@RequiredArgsConstructor
public class UserService {

    private final SysUserMapper sysUserMapper;
    private final TeacherMapper teacherMapper;
    private final StudentMapper studentMapper;
    private final ThesisMapper thesisMapper;
    private final PasswordEncoder passwordEncoder;
    private final SystemService systemService;

    @Value("${thesis.import.default-password:123456}")
    private String defaultPassword;

    // =========================================================== 账号
    public PageResult<SysUser> pageUsers(PageQuery query, String role) {
        LambdaQueryWrapper<SysUser> wrapper = new LambdaQueryWrapper<SysUser>()
                .eq(StringUtils.hasText(role), SysUser::getRole, role)
                .and(StringUtils.hasText(query.getKeyword()), w -> w
                        .like(SysUser::getUsername, query.getKeyword())
                        .or().like(SysUser::getRealName, query.getKeyword()))
                .orderByAsc(SysUser::getRole).orderByAsc(SysUser::getId);
        Page<SysUser> page = sysUserMapper.selectPage(query.toPage(), wrapper);
        return PageResult.of(page);
    }

    @Transactional
    public SysUser createUser(SysUser user, String rawPassword) {
        requireUsername(user.getUsername(), null);
        requireText(user.getRealName(), "姓名不能为空");
        requireText(user.getRole(), "角色不能为空");
        user.setPassword(passwordEncoder.encode(
                StringUtils.hasText(rawPassword) ? rawPassword : defaultPassword));
        if (user.getStatus() == null) {
            user.setStatus(1);
        }
        sysUserMapper.insert(user);
        return user;
    }

    public SysUser updateUser(SysUser user) {
        SysUser exist = sysUserMapper.selectById(user.getId());
        if (exist == null) {
            throw BizException.notFound("账号不存在");
        }
        requireUsername(user.getUsername(), user.getId());
        // 密码不允许通过该接口修改，避免误把密文写坏
        user.setPassword(null);
        sysUserMapper.updateById(user);
        return sysUserMapper.selectById(user.getId());
    }

    @Transactional
    public void deleteUser(Long id) {
        SysUser user = sysUserMapper.selectById(id);
        if (user == null) {
            throw BizException.notFound("账号不存在");
        }
        // 自我保护：避免误删当前登录账号
        if (id.equals(SecurityUtils.userId())) {
            throw BizException.param("不能删除当前登录的账号");
        }
        // 保留至少一个管理员，避免系统失去管理入口后只能改库恢复
        if (Constants.ROLE_ADMIN.equals(user.getRole())) {
            Long adminCount = sysUserMapper.selectCount(new LambdaQueryWrapper<SysUser>()
                    .eq(SysUser::getRole, Constants.ROLE_ADMIN));
            if (adminCount != null && adminCount <= 1) {
                throw BizException.param("系统至少需要保留一个管理员账号");
            }
        }
        if (Constants.ROLE_STUDENT.equals(user.getRole())) {
            studentMapper.delete(new LambdaQueryWrapper<Student>().eq(Student::getUserId, id));
        } else if (!Constants.ROLE_ADMIN.equals(user.getRole())) {
            teacherMapper.delete(new LambdaQueryWrapper<Teacher>().eq(Teacher::getUserId, id));
        }
        sysUserMapper.deleteById(id);
    }

    public void resetPassword(Long id, String newPassword) {
        SysUser user = sysUserMapper.selectById(id);
        if (user == null) {
            throw BizException.notFound("账号不存在");
        }
        SysUser update = new SysUser();
        update.setId(id);
        update.setPassword(passwordEncoder.encode(
                StringUtils.hasText(newPassword) ? newPassword : defaultPassword));
        sysUserMapper.updateById(update);
    }

    // =========================================================== 教师
    public PageResult<Teacher> pageTeachers(PageQuery query, String college, String teacherType, Integer canReview) {
        LambdaQueryWrapper<Teacher> wrapper = new LambdaQueryWrapper<Teacher>()
                .eq(StringUtils.hasText(college), Teacher::getCollege, college)
                .eq(StringUtils.hasText(teacherType), Teacher::getTeacherType, teacherType)
                .eq(canReview != null, Teacher::getCanReview, canReview)
                .and(StringUtils.hasText(query.getKeyword()), w -> w
                        .like(Teacher::getRealName, query.getKeyword())
                        .or().like(Teacher::getTeacherNo, query.getKeyword()))
                .orderByAsc(Teacher::getTeacherNo);
        Page<Teacher> page = teacherMapper.selectPage(query.toPage(), wrapper);
        decorateTeachers(page.getRecords());
        return PageResult.of(page);
    }

    public List<Teacher> advisorOptions() {
        List<Teacher> list = teacherMapper.selectList(new LambdaQueryWrapper<Teacher>()
                .ne(Teacher::getTeacherType, "REVIEWER")
                .orderByAsc(Teacher::getTeacherNo));
        decorateTeachers(list);
        return list;
    }

    public List<Teacher> reviewerOptions() {
        return teacherMapper.selectReviewers();
    }

    @Transactional
    public Teacher saveTeacher(Teacher teacher, String rawPassword) {
        requireText(teacher.getTeacherNo(), "工号不能为空");
        requireText(teacher.getRealName(), "姓名不能为空");
        if (teacher.getId() == null) {
            SysUser user = new SysUser();
            user.setUsername(teacher.getTeacherNo().trim());
            user.setRealName(teacher.getRealName());
            user.setRole("REVIEWER".equals(teacher.getTeacherType())
                    ? Constants.ROLE_REVIEWER : Constants.ROLE_ADVISOR);
            user.setGender(teacher.getGender());
            user.setPhone(teacher.getPhone());
            user.setEmail(teacher.getEmail());
            SysUser created = createUser(user, rawPassword);
            teacher.setUserId(created.getId());
            if (teacher.getCanReview() == null) {
                teacher.setCanReview("REVIEWER".equals(teacher.getTeacherType()) ? 1 : 0);
            }
            if (teacher.getMaxQuota() == null) {
                teacher.setMaxQuota(8);
            }
            teacherMapper.insert(teacher);
        } else {
            Teacher exist = teacherMapper.selectById(teacher.getId());
            if (exist == null) {
                throw BizException.notFound("教师不存在");
            }
            // 方案 A：工号是身份标识，与登录账号绑定，不允许修改
            if (StringUtils.hasText(teacher.getTeacherNo())
                    && !exist.getTeacherNo().equals(teacher.getTeacherNo().trim())) {
                throw BizException.param("工号不允许修改，如需调整请新建档案并迁移数据");
            }
            teacher.setTeacherNo(exist.getTeacherNo());
            teacherMapper.updateById(teacher);
            syncUser(teacher.getUserId(), teacher.getRealName(), teacher.getPhone(),
                    teacher.getEmail(), teacher.getGender());
        }
        return teacherMapper.selectById(teacher.getId());
    }

    @Transactional
    public void deleteTeacher(Long id) {
        Teacher teacher = teacherMapper.selectById(id);
        if (teacher == null) {
            throw BizException.notFound("教师不存在");
        }
        Long students = studentMapper.selectCount(new LambdaQueryWrapper<Student>()
                .eq(Student::getAdvisorId, id));
        if (students != null && students > 0) {
            throw BizException.param("该教师名下还有 " + students + " 名学生，无法删除");
        }
        teacherMapper.deleteById(id);
        if (teacher.getUserId() != null) {
            sysUserMapper.deleteById(teacher.getUserId());
        }
    }

    // =========================================================== 学生
    public PageResult<Student> pageStudents(PageQuery query, String grade, String college,
                                            String major, Long advisorId) {
        LambdaQueryWrapper<Student> wrapper = new LambdaQueryWrapper<Student>()
                .eq(StringUtils.hasText(grade), Student::getGrade, grade)
                .eq(StringUtils.hasText(college), Student::getCollege, college)
                .eq(StringUtils.hasText(major), Student::getMajor, major)
                .eq(advisorId != null, Student::getAdvisorId, advisorId)
                .and(StringUtils.hasText(query.getKeyword()), w -> w
                        .like(Student::getRealName, query.getKeyword())
                        .or().like(Student::getStudentNo, query.getKeyword()))
                .orderByAsc(Student::getStudentNo);
        Page<Student> page = studentMapper.selectPage(query.toPage(), wrapper);
        decorateStudents(page.getRecords());
        return PageResult.of(page);
    }

    @Transactional
    public Student saveStudent(Student student, String rawPassword) {
        requireText(student.getStudentNo(), "学号不能为空");
        requireText(student.getRealName(), "姓名不能为空");
        checkDict(Constants.DICT_COLLEGE, student.getCollege(), "学院");
        checkDict(Constants.DICT_MAJOR, student.getMajor(), "专业");
        checkDict(Constants.DICT_CLASS, student.getClassName(), "班级");
        checkDict(Constants.DICT_GRADE, student.getGrade(), "届别");

        if (student.getId() == null) {
            SysUser user = new SysUser();
            user.setUsername(student.getStudentNo().trim());
            user.setRealName(student.getRealName());
            user.setRole(Constants.ROLE_STUDENT);
            user.setGender(student.getGender());
            user.setPhone(student.getPhone());
            user.setEmail(student.getEmail());
            SysUser created = createUser(user, rawPassword);
            student.setUserId(created.getId());
            studentMapper.insert(student);
        } else {
            Student exist = studentMapper.selectById(student.getId());
            if (exist == null) {
                throw BizException.notFound("学生不存在");
            }
            // 方案 A：学号是身份标识，与登录账号绑定，不允许修改
            if (StringUtils.hasText(student.getStudentNo())
                    && !exist.getStudentNo().equals(student.getStudentNo().trim())) {
                throw BizException.param("学号不允许修改，如需调整请新建档案并迁移数据");
            }
            student.setStudentNo(exist.getStudentNo());
            studentMapper.updateById(student);
            syncUser(student.getUserId(), student.getRealName(), student.getPhone(),
                    student.getEmail(), student.getGender());
        }
        return studentMapper.selectById(student.getId());
    }

    @Transactional
    public void deleteStudent(Long id) {
        Student student = studentMapper.selectById(id);
        if (student == null) {
            throw BizException.notFound("学生不存在");
        }
        Long theses = thesisMapper.selectCount(new LambdaQueryWrapper<Thesis>()
                .eq(Thesis::getStudentId, id));
        if (theses != null && theses > 0) {
            throw BizException.param("该学生已建立论文记录，无法删除");
        }
        studentMapper.deleteById(id);
        if (student.getUserId() != null) {
            sysUserMapper.deleteById(student.getUserId());
        }
    }

    // =========================================================== 内部工具
    /** 供其它服务按 user_id 反查学生 / 教师 */
    public Student findStudentByUser(Long userId) {
        return studentMapper.selectOne(new LambdaQueryWrapper<Student>()
                .eq(Student::getUserId, userId).last("LIMIT 1"));
    }

    public Teacher findTeacherByUser(Long userId) {
        return teacherMapper.selectOne(new LambdaQueryWrapper<Teacher>()
                .eq(Teacher::getUserId, userId).last("LIMIT 1"));
    }

    public Map<Long, Teacher> teacherMap(List<Long> ids) {
        if (ids == null || ids.isEmpty()) {
            return Collections.emptyMap();
        }
        return teacherMapper.selectBatchIds(ids).stream()
                .collect(Collectors.toMap(Teacher::getId, Function.identity(), (a, b) -> a));
    }

    public Map<Long, Student> studentMap(List<Long> ids) {
        if (ids == null || ids.isEmpty()) {
            return Collections.emptyMap();
        }
        return studentMapper.selectBatchIds(ids).stream()
                .collect(Collectors.toMap(Student::getId, Function.identity(), (a, b) -> a));
    }

    private void decorateTeachers(List<Teacher> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        Map<Long, Long> counts = studentMapper.countByAdvisor().stream()
                .collect(Collectors.toMap(m -> Long.parseLong(String.valueOf(m.get("advisorId"))),
                        m -> Long.parseLong(String.valueOf(m.get("cnt"))), (a, b) -> a));
        List<Long> userIds = records.stream().map(Teacher::getUserId).filter(java.util.Objects::nonNull).toList();
        Map<Long, SysUser> users = userIds.isEmpty() ? Collections.emptyMap()
                : sysUserMapper.selectBatchIds(userIds).stream()
                .collect(Collectors.toMap(SysUser::getId, Function.identity(), (a, b) -> a));
        for (Teacher t : records) {
            t.setStudentCount(counts.getOrDefault(t.getId(), 0L));
            SysUser u = users.get(t.getUserId());
            if (u != null) {
                t.setUsername(u.getUsername());
            }
        }
    }

    private void decorateStudents(List<Student> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        List<Long> advisorIds = records.stream().map(Student::getAdvisorId)
                .filter(java.util.Objects::nonNull).distinct().toList();
        Map<Long, Teacher> teachers = teacherMap(advisorIds);
        List<Long> studentIds = records.stream().map(Student::getId).toList();
        Map<Long, Thesis> theses = thesisMapper.selectList(new LambdaQueryWrapper<Thesis>()
                        .in(Thesis::getStudentId, studentIds)).stream()
                .collect(Collectors.toMap(Thesis::getStudentId, Function.identity(), (a, b) -> a));
        List<Long> userIds = records.stream().map(Student::getUserId)
                .filter(java.util.Objects::nonNull).toList();
        Map<Long, SysUser> users = userIds.isEmpty() ? Collections.emptyMap()
                : sysUserMapper.selectBatchIds(userIds).stream()
                .collect(Collectors.toMap(SysUser::getId, Function.identity(), (a, b) -> a));
        for (Student s : records) {
            Teacher t = s.getAdvisorId() == null ? null : teachers.get(s.getAdvisorId());
            s.setAdvisorName(t == null ? null : t.getRealName());
            Thesis thesis = theses.get(s.getId());
            s.setThesisStatus(thesis == null ? null : thesis.getStatus());
            SysUser u = users.get(s.getUserId());
            if (u != null) {
                s.setUsername(u.getUsername());
            }
        }
    }

    private void syncUser(Long userId, String realName, String phone, String email, Integer gender) {
        if (userId == null) {
            return;
        }
        SysUser update = new SysUser();
        update.setId(userId);
        update.setRealName(realName);
        update.setPhone(phone);
        update.setEmail(email);
        update.setGender(gender);
        sysUserMapper.updateById(update);
    }

    private void checkDict(String typeCode, String value, String label) {
        if (!StringUtils.hasText(value)) {
            throw BizException.param(label + "不能为空");
        }
        if (!systemService.nameExists(typeCode, value)) {
            throw BizException.param("字典中没有该" + label + "：" + value + "，请先在「系统管理 → 字典管理」中维护");
        }
    }

    private void requireUsername(String username, Long excludeId) {
        if (!StringUtils.hasText(username)) {
            throw BizException.param("账号不能为空");
        }
        LambdaQueryWrapper<SysUser> wrapper = new LambdaQueryWrapper<SysUser>()
                .eq(SysUser::getUsername, username.trim());
        if (excludeId != null) {
            wrapper.ne(SysUser::getId, excludeId);
        }
        if (sysUserMapper.selectCount(wrapper) > 0) {
            throw BizException.param("账号已存在：" + username);
        }
    }

    private void requireText(String value, String message) {
        if (!StringUtils.hasText(value)) {
            throw BizException.param(message);
        }
    }
}
