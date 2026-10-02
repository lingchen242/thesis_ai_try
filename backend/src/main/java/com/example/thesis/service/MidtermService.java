package com.example.thesis.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.example.thesis.common.BizException;
import com.example.thesis.common.Constants;
import com.example.thesis.common.PageResult;
import com.example.thesis.domain.FlowGuard;
import com.example.thesis.domain.ThesisStatus;
import com.example.thesis.dto.PageQuery;
import com.example.thesis.dto.Requests;
import com.example.thesis.entity.MidtermReport;
import com.example.thesis.entity.Student;
import com.example.thesis.entity.Teacher;
import com.example.thesis.entity.Thesis;
import com.example.thesis.mapper.MidtermReportMapper;
import com.example.thesis.mapper.ThesisMapper;
import com.example.thesis.security.LoginUser;
import com.example.thesis.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

/**
 * 中期检查：学生提交 → 指导教师检查；并提供超期未提交预警。
 */
@Service
@RequiredArgsConstructor
public class MidtermService {

    private final MidtermReportMapper midtermMapper;
    private final ThesisMapper thesisMapper;
    private final ThesisService thesisService;
    private final UserService userService;
    private final AuditService auditService;
    private final SystemService systemService;

    public PageResult<MidtermReport> page(PageQuery query, Long thesisId, String reviewStatus) {
        LambdaQueryWrapper<MidtermReport> wrapper = new LambdaQueryWrapper<MidtermReport>()
                .eq(thesisId != null, MidtermReport::getThesisId, thesisId)
                .eq(StringUtils.hasText(reviewStatus), MidtermReport::getReviewStatus, reviewStatus)
                .orderByDesc(MidtermReport::getSubmitTime)
                .orderByDesc(MidtermReport::getId);
        LoginUser user = SecurityUtils.current();
        List<Long> visible = visibleThesisIds(user);
        if (visible != null) {
            wrapper.in(MidtermReport::getThesisId, visible.isEmpty() ? List.of(-1L) : visible);
        }
        Page<MidtermReport> page = midtermMapper.selectPage(query.toPage(), wrapper);
        decorate(page.getRecords());
        return PageResult.of(page);
    }

    public MidtermReport myReport() {
        Student student = thesisService.requireStudent();
        Thesis thesis = thesisMapper.selectOne(new LambdaQueryWrapper<Thesis>()
                .eq(Thesis::getStudentId, student.getId()).last("LIMIT 1"));
        if (thesis == null) {
            return null;
        }
        return midtermMapper.selectOne(new LambdaQueryWrapper<MidtermReport>()
                .eq(MidtermReport::getThesisId, thesis.getId())
                .orderByDesc(MidtermReport::getId).last("LIMIT 1"));
    }

    @Transactional
    public MidtermReport submit(MidtermReport request) {
        Student student = thesisService.requireStudent();
        Thesis thesis = thesisMapper.selectOne(new LambdaQueryWrapper<Thesis>()
                .eq(Thesis::getStudentId, student.getId()).last("LIMIT 1"));
        if (thesis == null) {
            throw BizException.param("你还没有论文记录，请先完成选题");
        }
        if (!StringUtils.hasText(request.getContent())) {
            throw BizException.param("中期报告正文不能为空");
        }
        if (request.getProgressPercent() != null
                && (request.getProgressPercent() < 0 || request.getProgressPercent() > 100)) {
            throw BizException.param("进度百分比需在 0 ~ 100 之间");
        }
        FlowGuard.ensure(thesis.getStatus(), ThesisStatus.MIDTERM_SUBMITTED.name(), Constants.ROLE_STUDENT);

        MidtermReport entity = new MidtermReport();
        entity.setThesisId(thesis.getId());
        entity.setContent(request.getContent());
        entity.setProgressPercent(request.getProgressPercent());
        entity.setAttachmentIds(request.getAttachmentIds());
        entity.setReviewStatus(Constants.REVIEW_PENDING);
        entity.setSubmitTime(LocalDateTime.now());
        midtermMapper.insert(entity);

        advance(thesis, ThesisStatus.MIDTERM_SUBMITTED);
        auditService.log(Constants.ACT_SUBMIT_MIDTERM, "THESIS", thesis.getId(),
                "提交中期报告，进度 " + (request.getProgressPercent() == null ? "-" : request.getProgressPercent() + "%"));
        notifyAdvisor(thesis, "待检查：中期报告",
                student.getRealName() + " 提交了中期报告，请及时检查。");
        return entity;
    }

    @Transactional
    public MidtermReport review(Long id, Requests.StageReview req) {
        MidtermReport report = midtermMapper.selectById(id);
        if (report == null) {
            throw BizException.notFound("中期报告不存在");
        }
        if (!Constants.REVIEW_PENDING.equals(report.getReviewStatus())) {
            throw BizException.param("该中期报告已检查，结论：" + report.getReviewStatus());
        }
        Thesis thesis = thesisService.requireAdvisorThesis(report.getThesisId());
        boolean approved = "APPROVED".equalsIgnoreCase(req.decision());
        ThesisStatus target = approved ? ThesisStatus.MIDTERM_PASSED : ThesisStatus.PROPOSAL_APPROVED;
        FlowGuard.ensure(thesis.getStatus(), target.name(), SecurityUtils.role());

        report.setReviewStatus(approved ? Constants.REVIEW_APPROVED : Constants.REVIEW_REJECTED);
        report.setReviewComment(req.comment());
        report.setScore(req.score());
        report.setReviewerId(currentTeacherId());
        report.setReviewTime(LocalDateTime.now());
        midtermMapper.updateById(report);

        advance(thesis, target);
        auditService.log(approved ? Constants.ACT_APPROVE_MIDTERM : Constants.ACT_REJECT_MIDTERM,
                "THESIS", thesis.getId(),
                approved ? "中期检查通过" : "中期检查退回：" + (req.comment() == null ? "" : req.comment()));
        notifyStudent(thesis, approved ? "中期检查通过" : "中期报告需要修改",
                approved ? "你的中期检查已通过，请继续完成定稿。"
                        : "中期报告未通过：" + (req.comment() == null ? "请修改后重新提交" : req.comment()));
        return report;
    }

    /**
     * 超期预警：列出处于「等待学生提交」状态且已过截止日期的论文。
     */
    public List<Map<String, Object>> alerts(String grade) {
        LocalDateTime deadlineProposal = parseDeadline(systemService.getConfig("deadline.proposal", null));
        LocalDateTime deadlineMidterm = parseDeadline(systemService.getConfig("deadline.midterm", null));
        LocalDateTime deadlineFinal = parseDeadline(systemService.getConfig("deadline.final", null));

        LambdaQueryWrapper<Thesis> wrapper = new LambdaQueryWrapper<Thesis>()
                .in(Thesis::getStatus, ThesisStatus.DRAFT.name(), ThesisStatus.PROPOSAL_APPROVED.name(),
                        ThesisStatus.MIDTERM_PASSED.name())
                .eq(StringUtils.hasText(grade), Thesis::getGrade, grade);
        thesisService.applyScope(wrapper);
        List<Thesis> theses = thesisMapper.selectList(wrapper);
        if (theses.isEmpty()) {
            return List.of();
        }

        List<Long> studentIds = theses.stream().map(Thesis::getStudentId)
                .filter(Objects::nonNull).distinct().toList();
        Map<Long, Student> students = userService.studentMap(studentIds);
        List<Long> advisorIds = theses.stream().map(Thesis::getAdvisorId)
                .filter(Objects::nonNull).distinct().toList();
        Map<Long, Teacher> teachers = userService.teacherMap(advisorIds);

        LocalDateTime now = LocalDateTime.now();
        List<Map<String, Object>> result = new ArrayList<>();
        for (Thesis thesis : theses) {
            LocalDateTime deadline;
            String task;
            if (ThesisStatus.DRAFT.name().equals(thesis.getStatus())) {
                deadline = deadlineProposal;
                task = "开题报告";
            } else if (ThesisStatus.PROPOSAL_APPROVED.name().equals(thesis.getStatus())) {
                deadline = deadlineMidterm;
                task = "中期报告";
            } else {
                deadline = deadlineFinal;
                task = "论文定稿";
            }
            if (deadline == null || now.isBefore(deadline)) {
                continue;
            }
            Student student = students.get(thesis.getStudentId());
            Teacher teacher = thesis.getAdvisorId() == null ? null : teachers.get(thesis.getAdvisorId());
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("thesisId", thesis.getId());
            item.put("title", thesis.getTitle());
            item.put("grade", thesis.getGrade());
            item.put("status", thesis.getStatus());
            item.put("statusLabel", ThesisStatus.labelOf(thesis.getStatus()));
            item.put("task", task);
            item.put("deadline", deadline);
            item.put("overdueDays", ChronoUnit.DAYS.between(deadline, now));
            item.put("studentName", student == null ? null : student.getRealName());
            item.put("studentNo", student == null ? null : student.getStudentNo());
            item.put("advisorName", teacher == null ? null : teacher.getRealName());
            result.add(item);
        }
        result.sort((a, b) -> Long.compare((Long) b.get("overdueDays"), (Long) a.get("overdueDays")));
        return result;
    }

    private LocalDateTime parseDeadline(String text) {
        if (!StringUtils.hasText(text)) {
            return null;
        }
        try {
            String value = text.trim();
            if (value.length() == 10) {
                return LocalDate.parse(value).atTime(23, 59, 59);
            }
            return LocalDateTime.parse(value);
        } catch (DateTimeParseException e) {
            return null;
        }
    }

    private void advance(Thesis thesis, ThesisStatus target) {
        thesis.setStatus(target.name());
        thesis.setCurrentStage(target.getLabel());
        thesisMapper.updateById(thesis);
    }

    private List<Long> visibleThesisIds(LoginUser user) {
        LambdaQueryWrapper<Thesis> wrapper = new LambdaQueryWrapper<>();
        if (Constants.ROLE_STUDENT.equals(user.getRole())) {
            Student student = userService.findStudentByUser(user.getId());
            wrapper.eq(Thesis::getStudentId, student == null ? -1L : student.getId());
        } else if (Constants.ROLE_ADVISOR.equals(user.getRole())) {
            Teacher teacher = userService.findTeacherByUser(user.getId());
            wrapper.eq(Thesis::getAdvisorId, teacher == null ? -1L : teacher.getId());
        } else {
            return null;
        }
        return thesisMapper.selectList(wrapper.select(Thesis::getId)).stream()
                .map(Thesis::getId).filter(Objects::nonNull).toList();
    }

    private void decorate(List<MidtermReport> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        List<Long> thesisIds = records.stream().map(MidtermReport::getThesisId)
                .filter(Objects::nonNull).distinct().toList();
        Map<Long, Thesis> theses = thesisIds.isEmpty() ? Map.of()
                : thesisMapper.selectBatchIds(thesisIds).stream()
                .collect(Collectors.toMap(Thesis::getId, t -> t, (a, b) -> a));
        List<Long> studentIds = theses.values().stream().map(Thesis::getStudentId)
                .filter(Objects::nonNull).distinct().toList();
        Map<Long, Student> students = userService.studentMap(studentIds);
        List<Long> advisorIds = theses.values().stream().map(Thesis::getAdvisorId)
                .filter(Objects::nonNull).distinct().toList();
        Map<Long, Teacher> teachers = userService.teacherMap(advisorIds);
        for (MidtermReport m : records) {
            Thesis thesis = theses.get(m.getThesisId());
            if (thesis == null) {
                continue;
            }
            m.setThesisTitle(thesis.getTitle());
            Student student = students.get(thesis.getStudentId());
            if (student != null) {
                m.setStudentName(student.getRealName());
                m.setStudentNo(student.getStudentNo());
            }
            Teacher teacher = thesis.getAdvisorId() == null ? null : teachers.get(thesis.getAdvisorId());
            m.setAdvisorName(teacher == null ? null : teacher.getRealName());
        }
    }

    private Long currentTeacherId() {
        Teacher teacher = userService.findTeacherByUser(SecurityUtils.userId());
        return teacher == null ? null : teacher.getId();
    }

    private void notifyAdvisor(Thesis thesis, String title, String content) {
        if (thesis.getAdvisorId() == null) {
            return;
        }
        Teacher teacher = userService.teacherMap(List.of(thesis.getAdvisorId())).get(thesis.getAdvisorId());
        if (teacher != null) {
            auditService.notify(teacher.getUserId(), title, content, "/midterm/review", Constants.NOTE_FLOW);
        }
    }

    private void notifyStudent(Thesis thesis, String title, String content) {
        Student student = userService.studentMap(List.of(thesis.getStudentId())).get(thesis.getStudentId());
        if (student != null) {
            auditService.notify(student.getUserId(), title, content, "/midterm/mine", Constants.NOTE_FLOW);
        }
    }
}
