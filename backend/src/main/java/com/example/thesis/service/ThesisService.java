package com.example.thesis.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.example.thesis.common.BizException;
import com.example.thesis.common.Constants;
import com.example.thesis.common.ErrorCode;
import com.example.thesis.common.PageResult;
import com.example.thesis.domain.FlowGuard;
import com.example.thesis.domain.ThesisStatus;
import com.example.thesis.dto.PageQuery;
import com.example.thesis.dto.Requests;
import com.example.thesis.entity.AuditLog;
import com.example.thesis.entity.DefenseRecord;
import com.example.thesis.entity.FinalSubmission;
import com.example.thesis.entity.MidtermReport;
import com.example.thesis.entity.Proposal;
import com.example.thesis.entity.Review;
import com.example.thesis.entity.Student;
import com.example.thesis.entity.Teacher;
import com.example.thesis.entity.Thesis;
import com.example.thesis.entity.ThesisScore;
import com.example.thesis.mapper.DefenseRecordMapper;
import com.example.thesis.mapper.FinalSubmissionMapper;
import com.example.thesis.mapper.MidtermReportMapper;
import com.example.thesis.mapper.ProposalMapper;
import com.example.thesis.mapper.ReviewMapper;
import com.example.thesis.mapper.ThesisMapper;
import com.example.thesis.mapper.ThesisScoreMapper;
import com.example.thesis.security.LoginUser;
import com.example.thesis.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

/**
 * 论文主流程：列表 / 详情 / 时间轴 / 状态流转 / 定稿提交。
 * <p>状态校验统一由 {@link FlowGuard} 与 {@link ThesisStatus} 负责，本类不重复定义规则。
 */
@Service
@RequiredArgsConstructor
public class ThesisService {

    private final ThesisMapper thesisMapper;
    private final ProposalMapper proposalMapper;
    private final MidtermReportMapper midtermMapper;
    private final FinalSubmissionMapper finalMapper;
    private final ReviewMapper reviewMapper;
    private final DefenseRecordMapper defenseRecordMapper;
    private final ThesisScoreMapper thesisScoreMapper;
    private final UserService userService;
    private final AuditService auditService;

    // ======================================================= 查询
    public PageResult<Thesis> page(PageQuery query, String status, String grade, String college,
                                   Long advisorId, Long studentId) {
        LambdaQueryWrapper<Thesis> wrapper = new LambdaQueryWrapper<Thesis>()
                .eq(StringUtils.hasText(status), Thesis::getStatus, status)
                .eq(StringUtils.hasText(grade), Thesis::getGrade, grade)
                .eq(StringUtils.hasText(college), Thesis::getCollege, college)
                .eq(advisorId != null, Thesis::getAdvisorId, advisorId)
                .eq(studentId != null, Thesis::getStudentId, studentId)
                .like(StringUtils.hasText(query.getKeyword()), Thesis::getTitle, query.getKeyword())
                .orderByDesc(Thesis::getId);
        applyScope(wrapper);

        Page<Thesis> result = thesisMapper.selectPage(query.toPage(), wrapper);
        decorate(result.getRecords());
        return PageResult.of(result);
    }

    public Thesis detail(Long id) {
        Thesis thesis = thesisMapper.selectById(id);
        if (thesis == null) {
            throw BizException.notFound("论文不存在");
        }
        decorate(List.of(thesis));
        return thesis;
    }

    /** 当前学生的论文（学生端首页/我的论文） */
    public Thesis myThesis() {
        Student student = requireStudent();
        return thesisMapper.selectOne(new LambdaQueryWrapper<Thesis>()
                .eq(Thesis::getStudentId, student.getId()).last("LIMIT 1"));
    }

    public List<AuditLog> timeline(Long id) {
        requireVisible(id);
        return auditService.timeline("THESIS", id);
    }

    /** 论文详情聚合：一次返回详情页需要的全部数据 */
    public Map<String, Object> detailBundle(Long id) {
        Thesis thesis = requireVisible(id);
        Map<String, Object> bundle = new LinkedHashMap<>();
        bundle.put("thesis", thesis);
        bundle.put("timeline", auditService.timeline("THESIS", id));
        bundle.put("proposal", proposalMapper.selectOne(new LambdaQueryWrapper<Proposal>()
                .eq(Proposal::getThesisId, id).orderByDesc(Proposal::getId).last("LIMIT 1")));
        bundle.put("midterm", midtermMapper.selectOne(new LambdaQueryWrapper<MidtermReport>()
                .eq(MidtermReport::getThesisId, id).orderByDesc(MidtermReport::getId).last("LIMIT 1")));
        bundle.put("finals", finalMapper.selectList(new LambdaQueryWrapper<FinalSubmission>()
                .eq(FinalSubmission::getThesisId, id).orderByDesc(FinalSubmission::getVersion)));
        bundle.put("reviews", reviewMapper.selectList(new LambdaQueryWrapper<Review>()
                .eq(Review::getThesisId, id)));
        bundle.put("defenseRecord", defenseRecordMapper.selectOne(new LambdaQueryWrapper<DefenseRecord>()
                .eq(DefenseRecord::getThesisId, id).last("LIMIT 1")));
        bundle.put("score", thesisScoreMapper.selectOne(new LambdaQueryWrapper<ThesisScore>()
                .eq(ThesisScore::getThesisId, id).last("LIMIT 1")));
        return bundle;
    }

    // ======================================================= 流转
    @Transactional
    public Thesis transition(Long id, Requests.Transition req) {
        Thesis thesis = requireVisible(id);
        String role = SecurityUtils.role();
        FlowGuard.ensure(thesis.getStatus(), req.target(), role);

        ThesisStatus target = ThesisStatus.of(req.target());
        thesis.setStatus(target.name());
        thesis.setCurrentStage(target.getLabel());
        if (target == ThesisStatus.ARCHIVED) {
            thesis.setArchiveTime(LocalDateTime.now());
        }
        thesisMapper.updateById(thesis);

        String detail = StringUtils.hasText(req.comment())
                ? req.comment() : ("论文流转至「" + target.getLabel() + "」");
        auditService.log("TRANSITION_" + target.name(), "THESIS", id, detail);
        notifyStudent(thesis, "论文进度更新",
                "你的论文已进入「" + target.getLabel() + "」阶段。", "/thesis/mine");
        return thesis;
    }

    @Transactional
    public FinalSubmission submitFinal(FinalSubmission request) {
        Student student = requireStudent();
        Thesis thesis = thesisMapper.selectOne(new LambdaQueryWrapper<Thesis>()
                .eq(Thesis::getStudentId, student.getId()).last("LIMIT 1"));
        if (thesis == null) {
            throw BizException.param("你还没有论文记录，请先完成选题");
        }
        // 走状态机校验，只有 中期已通过 / 评阅退回 才能提交定稿
        FlowGuard.ensure(thesis.getStatus(), ThesisStatus.FINAL_SUBMITTED.name(), Constants.ROLE_STUDENT);

        Long count = finalMapper.selectCount(new LambdaQueryWrapper<FinalSubmission>()
                .eq(FinalSubmission::getThesisId, thesis.getId()));
        FinalSubmission entity = new FinalSubmission();
        entity.setThesisId(thesis.getId());
        entity.setFileUrl(request.getFileUrl());
        entity.setFileName(request.getFileName());
        entity.setFileSize(request.getFileSize());
        entity.setNote(request.getNote());
        entity.setVersion((count == null ? 0 : count.intValue()) + 1);
        entity.setSubmitTime(LocalDateTime.now());
        finalMapper.insert(entity);

        ThesisStatus target = ThesisStatus.FINAL_SUBMITTED;
        thesis.setStatus(target.name());
        thesis.setCurrentStage(target.getLabel());
        thesis.setSubmitTime(entity.getSubmitTime());
        thesisMapper.updateById(thesis);

        auditService.log(Constants.ACT_SUBMIT_FINAL, "THESIS", thesis.getId(),
                "提交论文定稿（第 " + entity.getVersion() + " 版）");
        notifyAdvisor(thesis, "学生已提交定稿",
                student.getRealName() + " 提交了论文定稿，请关注评阅安排。");
        return entity;
    }

    public PageResult<FinalSubmission> pageFinals(PageQuery query, String grade) {
        LambdaQueryWrapper<Thesis> thesisWrapper = new LambdaQueryWrapper<>();
        if (StringUtils.hasText(grade)) {
            thesisWrapper.eq(Thesis::getGrade, grade);
        }
        List<Long> thesisIds = thesisMapper.selectList(thesisWrapper.select(Thesis::getId)).stream()
                .map(Thesis::getId).toList();
        if (thesisIds.isEmpty()) {
            return PageResult.of(List.of(), 0, query.getPageNum(), query.getPageSize());
        }
        Page<FinalSubmission> page = finalMapper.selectPage(query.toPage(),
                new LambdaQueryWrapper<FinalSubmission>()
                        .in(FinalSubmission::getThesisId, thesisIds)
                        .orderByDesc(FinalSubmission::getSubmitTime));
        decorateFinals(page.getRecords());
        return PageResult.of(page);
    }

    // ======================================================= 内部
    /** 数据范围过滤：学生只看自己，导师只看自己带的，评阅教师只看分派给自己的 */
    public void applyScope(LambdaQueryWrapper<Thesis> wrapper) {
        LoginUser user = SecurityUtils.current();
        switch (user.getRole()) {
            case Constants.ROLE_STUDENT -> {
                Student student = userService.findStudentByUser(user.getId());
                wrapper.eq(Thesis::getStudentId, student == null ? -1L : student.getId());
            }
            case Constants.ROLE_ADVISOR -> {
                Teacher teacher = userService.findTeacherByUser(user.getId());
                wrapper.eq(Thesis::getAdvisorId, teacher == null ? -1L : teacher.getId());
            }
            case Constants.ROLE_REVIEWER -> {
                Teacher teacher = userService.findTeacherByUser(user.getId());
                List<Long> ids = reviewMapper.selectList(new LambdaQueryWrapper<Review>()
                                .eq(Review::getReviewerId, teacher == null ? -1L : teacher.getId())
                                .select(Review::getThesisId)).stream()
                        .map(Review::getThesisId).filter(Objects::nonNull).toList();
                wrapper.in(Thesis::getId, ids.isEmpty() ? List.of(-1L) : ids);
            }
            default -> {
                // 管理员：不加限制
            }
        }
    }

    /** 校验可见性并返回论文 */
    public Thesis requireVisible(Long id) {
        Thesis thesis = thesisMapper.selectById(id);
        if (thesis == null) {
            throw BizException.notFound("论文不存在");
        }
        LoginUser user = SecurityUtils.current();
        if (Constants.ROLE_ADMIN.equals(user.getRole())) {
            return thesis;
        }
        if (Constants.ROLE_STUDENT.equals(user.getRole())) {
            Student student = userService.findStudentByUser(user.getId());
            if (student == null || !student.getId().equals(thesis.getStudentId())) {
                throw new BizException(ErrorCode.FORBIDDEN, "只能查看自己的论文");
            }
        } else if (Constants.ROLE_ADVISOR.equals(user.getRole())) {
            Teacher teacher = userService.findTeacherByUser(user.getId());
            if (teacher == null || !teacher.getId().equals(thesis.getAdvisorId())) {
                throw new BizException(ErrorCode.FORBIDDEN, "只能查看自己指导的论文");
            }
        } else if (Constants.ROLE_REVIEWER.equals(user.getRole())) {
            Teacher teacher = userService.findTeacherByUser(user.getId());
            Long count = reviewMapper.selectCount(new LambdaQueryWrapper<Review>()
                    .eq(Review::getThesisId, id)
                    .eq(Review::getReviewerId, teacher == null ? -1L : teacher.getId()));
            if (count == null || count == 0) {
                throw new BizException(ErrorCode.FORBIDDEN, "该论文未指派给你评阅");
            }
        }
        return thesis;
    }

    public Student requireStudent() {
        LoginUser user = SecurityUtils.current();
        if (!Constants.ROLE_STUDENT.equals(user.getRole())) {
            throw new BizException(ErrorCode.FORBIDDEN, "仅学生可执行该操作");
        }
        Student student = userService.findStudentByUser(user.getId());
        if (student == null) {
            throw BizException.param("当前账号没有关联学生档案");
        }
        return student;
    }

    public Thesis requireAdvisorThesis(Long thesisId) {
        Thesis thesis = requireVisible(thesisId);
        LoginUser user = SecurityUtils.current();
        if (Constants.ROLE_ADVISOR.equals(user.getRole())) {
            Teacher teacher = userService.findTeacherByUser(user.getId());
            if (teacher == null || !teacher.getId().equals(thesis.getAdvisorId())) {
                throw new BizException(ErrorCode.FORBIDDEN, "只能操作自己指导的论文");
            }
        } else if (!Constants.ROLE_ADMIN.equals(user.getRole())) {
            throw new BizException(ErrorCode.FORBIDDEN, "无权操作该论文");
        }
        return thesis;
    }

    private void decorate(List<Thesis> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        List<Long> studentIds = records.stream().map(Thesis::getStudentId)
                .filter(Objects::nonNull).distinct().toList();
        Map<Long, Student> students = userService.studentMap(studentIds);
        List<Long> advisorIds = records.stream().map(Thesis::getAdvisorId)
                .filter(Objects::nonNull).distinct().toList();
        Map<Long, Teacher> teachers = userService.teacherMap(advisorIds);
        for (Thesis t : records) {
            Student student = students.get(t.getStudentId());
            if (student != null) {
                t.setStudentName(student.getRealName());
                t.setStudentNo(student.getStudentNo());
                t.setClassName(student.getClassName());
            }
            Teacher teacher = t.getAdvisorId() == null ? null : teachers.get(t.getAdvisorId());
            t.setAdvisorName(teacher == null ? null : teacher.getRealName());
            t.setStatusLabel(ThesisStatus.labelOf(t.getStatus()));
        }
    }

    private void decorateFinals(List<FinalSubmission> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        List<Long> thesisIds = records.stream().map(FinalSubmission::getThesisId)
                .filter(Objects::nonNull).distinct().toList();
        Map<Long, Thesis> theses = thesisIds.isEmpty() ? Collections.emptyMap()
                : thesisMapper.selectBatchIds(thesisIds).stream()
                .collect(Collectors.toMap(Thesis::getId, t -> t, (a, b) -> a));
        List<Long> studentIds = theses.values().stream().map(Thesis::getStudentId)
                .filter(Objects::nonNull).distinct().toList();
        Map<Long, Student> students = userService.studentMap(studentIds);
        for (FinalSubmission f : records) {
            Thesis thesis = theses.get(f.getThesisId());
            if (thesis != null) {
                f.setThesisTitle(thesis.getTitle());
                Student student = students.get(thesis.getStudentId());
                if (student != null) {
                    f.setStudentName(student.getRealName());
                    f.setStudentNo(student.getStudentNo());
                }
                f.setStatusLabel(ThesisStatus.labelOf(thesis.getStatus()));
            }
        }
    }

    private void notifyStudent(Thesis thesis, String title, String content, String link) {
        Student student = userService.studentMap(List.of(thesis.getStudentId()))
                .get(thesis.getStudentId());
        if (student != null) {
            auditService.notify(student.getUserId(), title, content, link, Constants.NOTE_FLOW);
        }
    }

    private void notifyAdvisor(Thesis thesis, String title, String content) {
        if (thesis.getAdvisorId() == null) {
            return;
        }
        Teacher teacher = userService.teacherMap(List.of(thesis.getAdvisorId())).get(thesis.getAdvisorId());
        if (teacher != null) {
            auditService.notify(teacher.getUserId(), title, content, "/thesis/list", Constants.NOTE_FLOW);
        }
    }
}
