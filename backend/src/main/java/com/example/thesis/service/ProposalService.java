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
import com.example.thesis.entity.Proposal;
import com.example.thesis.entity.Student;
import com.example.thesis.entity.Teacher;
import com.example.thesis.entity.Thesis;
import com.example.thesis.mapper.ProposalMapper;
import com.example.thesis.mapper.ThesisMapper;
import com.example.thesis.security.LoginUser;
import com.example.thesis.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Objects;

/**
 * 开题报告：学生提交 → 指导教师审核。
 */
@Service
@RequiredArgsConstructor
public class ProposalService {

    private final ProposalMapper proposalMapper;
    private final ThesisMapper thesisMapper;
    private final ThesisService thesisService;
    private final UserService userService;
    private final AuditService auditService;

    public PageResult<Proposal> page(PageQuery query, Long thesisId, String reviewStatus) {
        LambdaQueryWrapper<Proposal> wrapper = new LambdaQueryWrapper<Proposal>()
                .eq(thesisId != null, Proposal::getThesisId, thesisId)
                .eq(StringUtils.hasText(reviewStatus), Proposal::getReviewStatus, reviewStatus)
                .orderByDesc(Proposal::getSubmitTime)
                .orderByDesc(Proposal::getId);
        applyScope(wrapper);
        Page<Proposal> page = proposalMapper.selectPage(query.toPage(), wrapper);
        decorate(page.getRecords());
        return PageResult.of(page);
    }

    /** 学生查看自己的开题报告 */
    public Proposal myProposal() {
        Student student = thesisService.requireStudent();
        Thesis thesis = thesisMapper.selectOne(new LambdaQueryWrapper<Thesis>()
                .eq(Thesis::getStudentId, student.getId()).last("LIMIT 1"));
        if (thesis == null) {
            return null;
        }
        return proposalMapper.selectOne(new LambdaQueryWrapper<Proposal>()
                .eq(Proposal::getThesisId, thesis.getId())
                .orderByDesc(Proposal::getId).last("LIMIT 1"));
    }

    @Transactional
    public Proposal submit(Proposal request) {
        Student student = thesisService.requireStudent();
        Thesis thesis = thesisMapper.selectOne(new LambdaQueryWrapper<Thesis>()
                .eq(Thesis::getStudentId, student.getId()).last("LIMIT 1"));
        if (thesis == null) {
            throw BizException.param("你还没有论文记录，请先完成选题");
        }
        if (!StringUtils.hasText(request.getContent())) {
            throw BizException.param("开题报告正文不能为空");
        }
        FlowGuard.ensure(thesis.getStatus(), ThesisStatus.PROPOSAL_SUBMITTED.name(), Constants.ROLE_STUDENT);

        Proposal entity = new Proposal();
        entity.setThesisId(thesis.getId());
        entity.setContent(request.getContent());
        entity.setAttachmentIds(request.getAttachmentIds());
        entity.setReviewStatus(Constants.REVIEW_PENDING);
        entity.setSubmitTime(LocalDateTime.now());
        proposalMapper.insert(entity);

        advance(thesis, ThesisStatus.PROPOSAL_SUBMITTED);
        auditService.log(Constants.ACT_SUBMIT_PROPOSAL, "THESIS", thesis.getId(), "提交开题报告");
        notifyAdvisor(thesis, "待审核：开题报告",
                student.getRealName() + " 提交了开题报告，请及时审核。");
        return entity;
    }

    @Transactional
    public Proposal review(Long id, Requests.StageReview req) {
        Proposal proposal = proposalMapper.selectById(id);
        if (proposal == null) {
            throw BizException.notFound("开题报告不存在");
        }
        if (!Constants.REVIEW_PENDING.equals(proposal.getReviewStatus())) {
            throw BizException.param("该开题报告已审核，结论：" + proposal.getReviewStatus());
        }
        Thesis thesis = thesisService.requireAdvisorThesis(proposal.getThesisId());
        boolean approved = "APPROVED".equalsIgnoreCase(req.decision());
        ThesisStatus target = approved ? ThesisStatus.PROPOSAL_APPROVED : ThesisStatus.DRAFT;
        FlowGuard.ensure(thesis.getStatus(), target.name(), SecurityUtils.role());

        proposal.setReviewStatus(approved ? Constants.REVIEW_APPROVED : Constants.REVIEW_REJECTED);
        proposal.setReviewComment(req.comment());
        proposal.setScore(req.score());
        proposal.setReviewerId(currentTeacherId());
        proposal.setReviewTime(LocalDateTime.now());
        proposalMapper.updateById(proposal);

        advance(thesis, target);
        auditService.log(approved ? Constants.ACT_APPROVE_PROPOSAL : Constants.ACT_REJECT_PROPOSAL,
                "THESIS", thesis.getId(),
                approved ? "开题审核通过" : "开题被退回修改：" + (req.comment() == null ? "" : req.comment()));
        notifyStudent(thesis, approved ? "开题审核通过" : "开题需要修改",
                approved ? "你的开题报告已通过，请按计划开展研究并准备中期检查。"
                        : "开题报告未通过：" + (req.comment() == null ? "请修改后重新提交" : req.comment()));
        return proposal;
    }

    private void advance(Thesis thesis, ThesisStatus target) {
        thesis.setStatus(target.name());
        thesis.setCurrentStage(target.getLabel());
        thesisMapper.updateById(thesis);
    }

    private void applyScope(LambdaQueryWrapper<Proposal> wrapper) {
        LoginUser user = SecurityUtils.current();
        List<Long> visible = visibleThesisIds(user);
        if (visible != null) {
            wrapper.in(Proposal::getThesisId, visible.isEmpty() ? List.of(-1L) : visible);
        }
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

    private void decorate(List<Proposal> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        List<Long> thesisIds = records.stream().map(Proposal::getThesisId)
                .filter(Objects::nonNull).distinct().toList();
        Map<Long, Thesis> theses = thesisIds.isEmpty() ? Map.of()
                : thesisMapper.selectBatchIds(thesisIds).stream()
                .collect(java.util.stream.Collectors.toMap(Thesis::getId, t -> t, (a, b) -> a));
        List<Long> studentIds = theses.values().stream().map(Thesis::getStudentId)
                .filter(Objects::nonNull).distinct().toList();
        Map<Long, Student> students = userService.studentMap(studentIds);
        List<Long> teacherIds = new java.util.ArrayList<>();
        theses.values().stream().map(Thesis::getAdvisorId).filter(Objects::nonNull).forEach(teacherIds::add);
        records.stream().map(Proposal::getReviewerId).filter(Objects::nonNull).forEach(teacherIds::add);
        Map<Long, Teacher> teachers = userService.teacherMap(teacherIds);

        for (Proposal p : records) {
            Thesis thesis = theses.get(p.getThesisId());
            if (thesis != null) {
                p.setThesisTitle(thesis.getTitle());
                Student student = students.get(thesis.getStudentId());
                if (student != null) {
                    p.setStudentName(student.getRealName());
                    p.setStudentNo(student.getStudentNo());
                }
                Teacher advisor = thesis.getAdvisorId() == null ? null : teachers.get(thesis.getAdvisorId());
                p.setAdvisorName(advisor == null ? null : advisor.getRealName());
            }
            Teacher reviewer = p.getReviewerId() == null ? null : teachers.get(p.getReviewerId());
            p.setReviewerName(reviewer == null ? null : reviewer.getRealName());
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
            auditService.notify(teacher.getUserId(), title, content, "/proposal/review", Constants.NOTE_FLOW);
        }
    }

    private void notifyStudent(Thesis thesis, String title, String content) {
        Student student = userService.studentMap(List.of(thesis.getStudentId())).get(thesis.getStudentId());
        if (student != null) {
            auditService.notify(student.getUserId(), title, content, "/proposal/mine", Constants.NOTE_FLOW);
        }
    }
}
