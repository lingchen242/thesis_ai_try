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
import com.example.thesis.entity.FinalSubmission;
import com.example.thesis.entity.Review;
import com.example.thesis.entity.Student;
import com.example.thesis.entity.Teacher;
import com.example.thesis.entity.Thesis;
import com.example.thesis.entity.ThesisScore;
import com.example.thesis.mapper.ReviewMapper;
import com.example.thesis.mapper.FinalSubmissionMapper;
import com.example.thesis.mapper.ThesisMapper;
import com.example.thesis.security.LoginUser;
import com.example.thesis.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

/**
 * 论文评阅：管理员指派 → 评阅教师打分。
 * <p>全部评阅提交后自动推进状态：平均分 &lt; 60 退回定稿重交，否则进入「评阅已通过」。
 */
@Service
@RequiredArgsConstructor
public class ReviewService {

    public static final BigDecimal PASS_LINE = new BigDecimal("60");

    private final ReviewMapper reviewMapper;
    private final ThesisMapper thesisMapper;
    private final FinalSubmissionMapper finalSubmissionMapper;
    private final ThesisService thesisService;
    private final UserService userService;
    private final ScoreService scoreService;
    private final AuditService auditService;

    // ======================================================= 查询
    public PageResult<Review> page(PageQuery query, String status, Long thesisId, Long reviewerId, String grade) {
        LambdaQueryWrapper<Review> wrapper = new LambdaQueryWrapper<Review>()
                .eq(StringUtils.hasText(status), Review::getStatus, status)
                .eq(thesisId != null, Review::getThesisId, thesisId)
                .eq(reviewerId != null, Review::getReviewerId, reviewerId)
                .orderByDesc(Review::getAssignTime)
                .orderByDesc(Review::getId);

        LoginUser user = SecurityUtils.current();
        if (Constants.ROLE_REVIEWER.equals(user.getRole())) {
            Teacher self = userService.findTeacherByUser(user.getId());
            wrapper.eq(Review::getReviewerId, self == null ? -1L : self.getId());
        } else if (Constants.ROLE_STUDENT.equals(user.getRole())) {
            Student self = userService.findStudentByUser(user.getId());
            List<Long> mine = thesisMapper.selectList(new LambdaQueryWrapper<Thesis>()
                            .eq(Thesis::getStudentId, self == null ? -1L : self.getId())
                            .select(Thesis::getId)).stream().map(Thesis::getId).toList();
            wrapper.in(Review::getThesisId, mine.isEmpty() ? List.of(-1L) : mine);
        } else if (Constants.ROLE_ADVISOR.equals(user.getRole())) {
            Teacher self = userService.findTeacherByUser(user.getId());
            List<Long> mine = thesisMapper.selectList(new LambdaQueryWrapper<Thesis>()
                            .eq(Thesis::getAdvisorId, self == null ? -1L : self.getId())
                            .select(Thesis::getId)).stream().map(Thesis::getId).toList();
            wrapper.in(Review::getThesisId, mine.isEmpty() ? List.of(-1L) : mine);
        }
        if (StringUtils.hasText(grade)) {
            List<Long> gradeThesisIds = thesisMapper.selectList(new LambdaQueryWrapper<Thesis>()
                            .eq(Thesis::getGrade, grade).select(Thesis::getId)).stream()
                    .map(Thesis::getId).toList();
            wrapper.in(Review::getThesisId, gradeThesisIds.isEmpty() ? List.of(-1L) : gradeThesisIds);
        }

        Page<Review> page = reviewMapper.selectPage(query.toPage(), wrapper);
        decorate(page.getRecords());
        return PageResult.of(page);
    }

    /** 待我评阅的清单 */
    public List<Review> mine(Boolean onlyPending) {
        Teacher self = currentTeacher();
        LambdaQueryWrapper<Review> wrapper = new LambdaQueryWrapper<Review>()
                .eq(Review::getReviewerId, self == null ? -1L : self.getId())
                .eq(Boolean.TRUE.equals(onlyPending), Review::getStatus, "PENDING")
                .orderByAsc(Review::getStatus)
                .orderByDesc(Review::getAssignTime);
        List<Review> list = reviewMapper.selectList(wrapper);
        decorate(list);
        return list;
    }

    // ======================================================= 指派
    @Transactional
    public Review assign(Requests.AssignReview req) {
        Thesis thesis = thesisService.requireVisible(req.thesisId());
        LoginUser user = SecurityUtils.current();
        if (!Constants.ROLE_ADMIN.equals(user.getRole())) {
            throw new BizException(ErrorCode.FORBIDDEN, "只有管理员可以指派评阅");
        }

        Long reviewerId = req.reviewerId();
        if (reviewerId == null) {
            reviewerId = pickReviewer();
        }
        if (reviewerId == null) {
            throw BizException.param("没有可指派的评阅教师，请先维护评阅教师数据");
        }
        Long exists = reviewMapper.selectCount(new LambdaQueryWrapper<Review>()
                .eq(Review::getThesisId, thesis.getId())
                .eq(Review::getReviewerId, reviewerId));
        if (exists != null && exists > 0) {
            throw BizException.param("该评阅教师已在此论文的评阅名单中");
        }

        boolean firstAssign = ThesisStatus.FINAL_SUBMITTED.name().equals(thesis.getStatus());
        if (!firstAssign && !ThesisStatus.REVIEWING.name().equals(thesis.getStatus())) {
            throw BizException.flow("当前状态「" + ThesisStatus.labelOf(thesis.getStatus())
                    + "」不能指派评阅，需先提交定稿");
        }

        Review review = new Review();
        review.setThesisId(thesis.getId());
        review.setReviewerId(reviewerId);
        review.setAssignedBy(user.getId());
        review.setStatus("PENDING");
        review.setBlind(Boolean.TRUE.equals(req.blind()) ? 1 : 0);
        review.setAssignTime(LocalDateTime.now());
        reviewMapper.insert(review);

        if (firstAssign) {
            FlowGuard.ensure(thesis.getStatus(), ThesisStatus.REVIEWING.name(), user.getRole());
            thesis.setStatus(ThesisStatus.REVIEWING.name());
            thesis.setCurrentStage(ThesisStatus.REVIEWING.getLabel());
            thesisMapper.updateById(thesis);
        }

        Teacher reviewer = userService.teacherMap(List.of(reviewerId)).get(reviewerId);
        auditService.log(Constants.ACT_ASSIGN_REVIEW, "THESIS", thesis.getId(),
                "指派 " + (reviewer == null ? "" : reviewer.getRealName()) + " 评阅论文");
        if (reviewer != null) {
            auditService.notify(reviewer.getUserId(), "待评阅任务",
                    "有一篇论文待你评阅：《" + thesis.getTitle() + "》", "/review/mine", Constants.NOTE_FLOW);
        }
        decorate(List.of(review));
        return review;
    }

    // ======================================================= 提交评阅
    @Transactional
    public Review submit(Long id, Requests.ReviewSubmit req) {
        Review review = reviewMapper.selectById(id);
        if (review == null) {
            throw BizException.notFound("评阅记录不存在");
        }
        if (!"PENDING".equals(review.getStatus())) {
            throw BizException.param("该评阅任务已提交");
        }
        Teacher self = currentTeacher();
        LoginUser user = SecurityUtils.current();
        boolean isAdmin = Constants.ROLE_ADMIN.equals(user.getRole());
        if (!isAdmin && (self == null || !self.getId().equals(review.getReviewerId()))) {
            throw new BizException(ErrorCode.FORBIDDEN, "只能提交指派给自己的评阅任务");
        }
        if (req.score() != null
                && (req.score().compareTo(BigDecimal.ZERO) < 0 || req.score().compareTo(new BigDecimal("100")) > 0)) {
            throw BizException.param("评阅成绩需在 0 ~ 100 之间");
        }
        if (req.score() == null && !StringUtils.hasText(req.comment())) {
            throw BizException.param("请至少填写评阅成绩或评阅意见");
        }

        review.setScore(req.score());
        review.setComment(req.comment());
        review.setStatus("SUBMITTED");
        review.setSubmitTime(LocalDateTime.now());
        reviewMapper.updateById(review);

        Thesis thesis = thesisMapper.selectById(review.getThesisId());
        auditService.log(Constants.ACT_SUBMIT_REVIEW, "THESIS", review.getThesisId(),
                "提交评阅意见" + (req.score() == null ? "" : "，成绩 " + req.score()));

        // 是否还有未提交的评阅
        Long pending = reviewMapper.selectCount(new LambdaQueryWrapper<Review>()
                .eq(Review::getThesisId, review.getThesisId())
                .eq(Review::getStatus, "PENDING"));
        if (pending == null || pending == 0) {
            finalizeReview(thesis, review);
        }
        return review;
    }

    /** 全部评阅提交后推进论文状态 */
    private void finalizeReview(Thesis thesis, Review lastReview) {
        if (thesis == null) {
            return;
        }
        ThesisScore score = scoreService.recompute(thesis.getId());
        BigDecimal reviewScore = score == null ? null : score.getReviewScore();
        boolean failed = reviewScore != null && reviewScore.compareTo(PASS_LINE) < 0;

        ThesisStatus target = failed ? ThesisStatus.FINAL_SUBMITTED : ThesisStatus.REVIEW_PASSED;
        if (thesis.getStatus().equals(ThesisStatus.REVIEWING.name())) {
            thesis.setStatus(target.name());
            thesis.setCurrentStage(target.getLabel());
            thesisMapper.updateById(thesis);
        }

        Student student = userService.studentMap(List.of(thesis.getStudentId())).get(thesis.getStudentId());
        if (student != null) {
            if (failed) {
                auditService.notify(student.getUserId(), "评阅未通过",
                        "评阅平均分 " + reviewScore + " 分，未达到 60 分，请修改后重新提交定稿。",
                        "/thesis/mine", Constants.NOTE_SCORE);
            } else {
                auditService.notify(student.getUserId(), "评阅已完成",
                        "评阅平均分 " + reviewScore + " 分，论文已进入「" + target.getLabel() + "」阶段。",
                        "/thesis/mine", Constants.NOTE_SCORE);
            }
        }
        auditService.log(lastReview.getReviewerId(), "评阅教师", "REVIEW_FINISHED", "THESIS", thesis.getId(),
                "评阅环节结束，评阅成绩 " + reviewScore + "，论文流转至「" + target.getLabel() + "」");
    }

    /** 自动挑选在评任务最少的评阅教师 */
    private Long pickReviewer() {
        List<Teacher> reviewers = userService.reviewerOptions();
        if (reviewers.isEmpty()) {
            return null;
        }
        Map<Long, Long> pendingCounts = reviewMapper.selectList(new LambdaQueryWrapper<Review>()
                        .eq(Review::getStatus, "PENDING")).stream()
                .collect(Collectors.groupingBy(Review::getReviewerId, Collectors.counting()));
        return reviewers.stream()
                .min(Comparator.comparingLong(t -> pendingCounts.getOrDefault(t.getId(), 0L)))
                .map(Teacher::getId)
                .orElse(null);
    }

    private Teacher currentTeacher() {
        return userService.findTeacherByUser(SecurityUtils.userId());
    }

    private void decorate(List<Review> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        List<Long> thesisIds = records.stream().map(Review::getThesisId)
                .filter(Objects::nonNull).distinct().toList();
        Map<Long, Thesis> theses = thesisIds.isEmpty() ? Map.of()
                : thesisMapper.selectBatchIds(thesisIds).stream()
                .collect(Collectors.toMap(Thesis::getId, t -> t, (a, b) -> a));
        List<Long> studentIds = theses.values().stream().map(Thesis::getStudentId)
                .filter(Objects::nonNull).distinct().toList();
        Map<Long, Student> students = userService.studentMap(studentIds);
        List<Long> reviewerIds = records.stream().map(Review::getReviewerId)
                .filter(Objects::nonNull).distinct().toList();
        Map<Long, Teacher> reviewers = userService.teacherMap(reviewerIds);

        // 评阅教师需要能打开定稿文件
        Map<Long, String> fileUrls = new java.util.HashMap<>();
        if (!thesisIds.isEmpty()) {
            finalSubmissionMapper.selectList(new LambdaQueryWrapper<FinalSubmission>()
                            .in(FinalSubmission::getThesisId, thesisIds)
                            .orderByDesc(FinalSubmission::getVersion))
                    .forEach(f -> fileUrls.putIfAbsent(f.getThesisId(), f.getFileUrl()));
        }

        for (Review r : records) {
            Thesis thesis = theses.get(r.getThesisId());
            if (thesis != null) {
                r.setThesisTitle(thesis.getTitle());
                r.setGrade(thesis.getGrade());
                Student student = students.get(thesis.getStudentId());
                if (student != null) {
                    r.setStudentName(student.getRealName());
                    r.setStudentNo(student.getStudentNo());
                }
            }
            Teacher reviewer = reviewers.get(r.getReviewerId());
            r.setReviewerName(reviewer == null ? null : reviewer.getRealName());
            r.setFileUrl(fileUrls.get(r.getThesisId()));
        }
    }
}
