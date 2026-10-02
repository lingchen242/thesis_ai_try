package com.example.thesis.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.thesis.common.Constants;
import com.example.thesis.domain.ThesisStatus;
import com.example.thesis.entity.Review;
import com.example.thesis.entity.Selection;
import com.example.thesis.entity.Student;
import com.example.thesis.entity.Teacher;
import com.example.thesis.entity.Thesis;
import com.example.thesis.entity.Topic;
import com.example.thesis.mapper.ReviewMapper;
import com.example.thesis.mapper.SelectionMapper;
import com.example.thesis.mapper.StudentMapper;
import com.example.thesis.mapper.TeacherMapper;
import com.example.thesis.mapper.ThesisMapper;
import com.example.thesis.mapper.TopicMapper;
import com.example.thesis.security.LoginUser;
import com.example.thesis.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 数据看板：按角色返回不同的统计口径与待办清单。
 */
@Service
@RequiredArgsConstructor
public class DashboardService {

    /** 各状态在整体流程中的大致进度，用于学生端进度条 */
    private static final Map<String, Integer> PROGRESS = Map.ofEntries(
            Map.entry(ThesisStatus.DRAFT.name(), 10),
            Map.entry(ThesisStatus.PROPOSAL_SUBMITTED.name(), 25),
            Map.entry(ThesisStatus.PROPOSAL_APPROVED.name(), 35),
            Map.entry(ThesisStatus.MIDTERM_SUBMITTED.name(), 50),
            Map.entry(ThesisStatus.MIDTERM_PASSED.name(), 60),
            Map.entry(ThesisStatus.FINAL_SUBMITTED.name(), 70),
            Map.entry(ThesisStatus.REVIEWING.name(), 80),
            Map.entry(ThesisStatus.REVIEW_PASSED.name(), 85),
            Map.entry(ThesisStatus.DEFENSE_SCHEDULED.name(), 92),
            Map.entry(ThesisStatus.DEFENSE_DONE.name(), 98),
            Map.entry(ThesisStatus.ARCHIVED.name(), 100)
    );

    private final ThesisMapper thesisMapper;
    private final StudentMapper studentMapper;
    private final TeacherMapper teacherMapper;
    private final TopicMapper topicMapper;
    private final SelectionMapper selectionMapper;
    private final ReviewMapper reviewMapper;
    private final ScoreService scoreService;
    private final MidtermService midtermService;
    private final UserService userService;

    /** 角色化总览 */
    public Map<String, Object> overview() {
        LoginUser user = SecurityUtils.current();
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("role", user.getRole());
        result.put("realName", user.getRealName());
        result.put("stageDistribution", stageDistribution());
        result.put("scoreDistribution", scoreService.scoreBuckets());
        result.put("todos", todos());

        switch (user.getRole()) {
            case Constants.ROLE_ADMIN -> {
                long thesisCount = thesisMapper.selectCount(null);
                long finished = thesisMapper.selectCount(new LambdaQueryWrapper<Thesis>()
                        .in(Thesis::getStatus, ThesisStatus.DEFENSE_DONE.name(), ThesisStatus.ARCHIVED.name()));
                result.put("studentCount", studentMapper.selectCount(null));
                result.put("teacherCount", teacherMapper.selectCount(null));
                result.put("thesisCount", thesisCount);
                result.put("finishedCount", finished);
                result.put("completionRate", thesisCount == 0 ? 0
                        : BigDecimal.valueOf(finished * 100.0 / thesisCount).setScale(1, RoundingMode.HALF_UP));
                result.put("avgScore", round(scoreService.avgTotalScore()));
                result.put("pendingProposal", countThesis(ThesisStatus.PROPOSAL_SUBMITTED));
                result.put("pendingMidterm", countThesis(ThesisStatus.MIDTERM_SUBMITTED));
                result.put("pendingAssignReview", countThesis(ThesisStatus.FINAL_SUBMITTED));
                result.put("pendingSchedule", countThesis(ThesisStatus.REVIEW_PASSED));
                result.put("pendingArchive", countThesis(ThesisStatus.DEFENSE_DONE));
                result.put("pendingReview", reviewMapper.selectCount(new LambdaQueryWrapper<Review>()
                        .eq(Review::getStatus, "PENDING")));
                result.put("alerts", midtermService.alerts(null).size());
            }
            case Constants.ROLE_ADVISOR -> {
                Teacher self = userService.findTeacherByUser(user.getId());
                Long teacherId = self == null ? -1L : self.getId();
                List<Long> myThesisIds = myThesisIds(teacherId);
                result.put("myStudentCount", studentMapper.selectCount(new LambdaQueryWrapper<Student>()
                        .eq(Student::getAdvisorId, teacherId)));
                result.put("myThesisCount", (long) myThesisIds.size());
                result.put("pendingSelection", selectionPending(teacherId));
                result.put("pendingProposal", myThesisIds.isEmpty() ? 0 : thesisMapper.selectCount(
                        new LambdaQueryWrapper<Thesis>().in(Thesis::getId, myThesisIds)
                                .eq(Thesis::getStatus, ThesisStatus.PROPOSAL_SUBMITTED.name())));
                result.put("pendingMidterm", myThesisIds.isEmpty() ? 0 : thesisMapper.selectCount(
                        new LambdaQueryWrapper<Thesis>().in(Thesis::getId, myThesisIds)
                                .eq(Thesis::getStatus, ThesisStatus.MIDTERM_SUBMITTED.name())));
                result.put("finishedCount", myThesisIds.isEmpty() ? 0 : thesisMapper.selectCount(
                        new LambdaQueryWrapper<Thesis>().in(Thesis::getId, myThesisIds)
                                .in(Thesis::getStatus, ThesisStatus.DEFENSE_DONE.name(),
                                        ThesisStatus.ARCHIVED.name())));
            }
            case Constants.ROLE_REVIEWER -> {
                Teacher self = userService.findTeacherByUser(user.getId());
                Long teacherId = self == null ? -1L : self.getId();
                result.put("pendingCount", reviewMapper.selectCount(new LambdaQueryWrapper<Review>()
                        .eq(Review::getReviewerId, teacherId).eq(Review::getStatus, "PENDING")));
                result.put("submittedCount", reviewMapper.selectCount(new LambdaQueryWrapper<Review>()
                        .eq(Review::getReviewerId, teacherId).eq(Review::getStatus, "SUBMITTED")));
                List<Review> submitted = reviewMapper.selectList(new LambdaQueryWrapper<Review>()
                        .eq(Review::getReviewerId, teacherId).eq(Review::getStatus, "SUBMITTED")
                        .isNotNull(Review::getScore));
                double avg = submitted.stream().map(Review::getScore)
                        .filter(java.util.Objects::nonNull)
                        .mapToDouble(BigDecimal::doubleValue).average().orElse(0);
                result.put("avgScore", round(avg));
            }
            case Constants.ROLE_STUDENT -> {
                Student self = userService.findStudentByUser(user.getId());
                Thesis thesis = self == null ? null : thesisMapper.selectOne(new LambdaQueryWrapper<Thesis>()
                        .eq(Thesis::getStudentId, self.getId()).last("LIMIT 1"));
                result.put("thesis", thesis);
                if (thesis != null) {
                    result.put("statusLabel", ThesisStatus.labelOf(thesis.getStatus()));
                    result.put("progress", PROGRESS.getOrDefault(thesis.getStatus(), 0));
                    result.put("score", scoreService.getByThesis(thesis.getId()));
                } else {
                    result.put("progress", 0);
                }
                result.put("hasThesis", thesis != null);
            }
            default -> {
            }
        }
        return result;
    }

    public List<Map<String, Object>> stageDistribution() {
        Map<String, Long> counts = thesisMapper.countByStatus().stream()
                .collect(Collectors.toMap(m -> String.valueOf(m.get("status")),
                        m -> Long.parseLong(String.valueOf(m.get("cnt"))), (a, b) -> a));
        List<Map<String, Object>> list = new ArrayList<>();
        for (ThesisStatus status : ThesisStatus.values()) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("status", status.name());
            item.put("label", status.getLabel());
            item.put("count", counts.getOrDefault(status.name(), 0L));
            list.add(item);
        }
        return list;
    }

    /** 角色化待办 */
    public List<Map<String, Object>> todos() {
        LoginUser user = SecurityUtils.current();
        List<Map<String, Object>> list = new ArrayList<>();
        switch (user.getRole()) {
            case Constants.ROLE_ADMIN -> {
                add(list, "待审核开题报告", countThesis(ThesisStatus.PROPOSAL_SUBMITTED), "/proposal/list");
                add(list, "待检查中期报告", countThesis(ThesisStatus.MIDTERM_SUBMITTED), "/midterm/list");
                add(list, "待指派评阅", countThesis(ThesisStatus.FINAL_SUBMITTED), "/review/assign");
                add(list, "待编排答辩", countThesis(ThesisStatus.REVIEW_PASSED), "/defense/group");
                add(list, "待归档", countThesis(ThesisStatus.DEFENSE_DONE), "/thesis/list");
            }
            case Constants.ROLE_ADVISOR -> {
                Teacher self = userService.findTeacherByUser(user.getId());
                Long teacherId = self == null ? -1L : self.getId();
                List<Long> ids = myThesisIds(teacherId);
                add(list, "待审核选题申请", selectionPending(teacherId), "/topic/selection");
                add(list, "待审核开题报告", ids.isEmpty() ? 0 : thesisMapper.selectCount(
                        new LambdaQueryWrapper<Thesis>().in(Thesis::getId, ids)
                                .eq(Thesis::getStatus, ThesisStatus.PROPOSAL_SUBMITTED.name())),
                        "/proposal/list");
                add(list, "待检查中期报告", ids.isEmpty() ? 0 : thesisMapper.selectCount(
                        new LambdaQueryWrapper<Thesis>().in(Thesis::getId, ids)
                                .eq(Thesis::getStatus, ThesisStatus.MIDTERM_SUBMITTED.name())),
                        "/midterm/list");
            }
            case Constants.ROLE_REVIEWER -> {
                Teacher self = userService.findTeacherByUser(user.getId());
                Long teacherId = self == null ? -1L : self.getId();
                add(list, "待评阅论文", reviewMapper.selectCount(new LambdaQueryWrapper<Review>()
                        .eq(Review::getReviewerId, teacherId).eq(Review::getStatus, "PENDING")),
                        "/review/mine");
            }
            case Constants.ROLE_STUDENT -> {
                Student self = userService.findStudentByUser(user.getId());
                if (self == null) {
                    break;
                }
                Thesis thesis = thesisMapper.selectOne(new LambdaQueryWrapper<Thesis>()
                        .eq(Thesis::getStudentId, self.getId()).last("LIMIT 1"));
                if (thesis == null) {
                    add(list, "尚未选题，请前往课题大厅申报", 1L, "/topic/browse");
                } else {
                    add(list, nextAction(ThesisStatus.of(thesis.getStatus())), 1L, "/thesis/mine");
                    BigDecimal reviewScore = scoreService.getByThesis(thesis.getId()) == null ? null
                            : scoreService.getByThesis(thesis.getId()).getTotalScore();
                    if (reviewScore != null) {
                        add(list, "当前总评 " + reviewScore + " 分", 1L, "/thesis/mine");
                    }
                }
            }
            default -> {
            }
        }
        return list;
    }

    private String nextAction(ThesisStatus status) {
        return switch (status) {
            case DRAFT -> "下一步：提交开题报告";
            case PROPOSAL_SUBMITTED -> "开题报告审核中，请耐心等待";
            case PROPOSAL_APPROVED -> "下一步：提交中期报告";
            case MIDTERM_SUBMITTED -> "中期报告检查中，请耐心等待";
            case MIDTERM_PASSED -> "下一步：提交论文定稿";
            case FINAL_SUBMITTED -> "定稿已提交，等待指派评阅";
            case REVIEWING -> "评阅中，请耐心等待结果";
            case REVIEW_PASSED -> "评阅通过，等待安排答辩";
            case DEFENSE_SCHEDULED -> "请按通知参加答辩";
            case DEFENSE_DONE -> "答辩完成，等待归档";
            case ARCHIVED -> "流程已结束，论文已归档";
        };
    }

    private void add(List<Map<String, Object>> list, String title, Long count, String link) {
        if (count == null || count == 0) {
            return;
        }
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("title", title);
        item.put("count", count);
        item.put("link", link);
        list.add(item);
    }

    private long countThesis(ThesisStatus status) {
        Long count = thesisMapper.selectCount(new LambdaQueryWrapper<Thesis>()
                .eq(Thesis::getStatus, status.name()));
        return count == null ? 0 : count;
    }

    /** 该教师名下课题的待审选题申请数 */
    private long selectionPending(Long teacherId) {
        List<Long> topicIds = topicMapper.selectList(new LambdaQueryWrapper<Topic>()
                        .eq(Topic::getTeacherId, teacherId).select(Topic::getId)).stream()
                .map(Topic::getId).toList();
        if (topicIds.isEmpty()) {
            return 0L;
        }
        Long count = selectionMapper.selectCount(new LambdaQueryWrapper<Selection>()
                .in(Selection::getTopicId, topicIds)
                .eq(Selection::getStatus, "PENDING"));
        return count == null ? 0L : count;
    }

    private List<Long> myThesisIds(Long teacherId) {
        return thesisMapper.selectList(new LambdaQueryWrapper<Thesis>()
                        .eq(Thesis::getAdvisorId, teacherId).select(Thesis::getId)).stream()
                .map(Thesis::getId).toList();
    }

    private Double round(Double value) {
        return value == null ? 0d : BigDecimal.valueOf(value).setScale(1, RoundingMode.HALF_UP).doubleValue();
    }
}
