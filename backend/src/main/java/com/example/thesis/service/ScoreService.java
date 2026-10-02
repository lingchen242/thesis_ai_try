package com.example.thesis.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.example.thesis.common.PageResult;
import com.example.thesis.domain.ScoreRule;
import com.example.thesis.dto.PageQuery;
import com.example.thesis.entity.DefenseRecord;
import com.example.thesis.entity.MidtermReport;
import com.example.thesis.entity.Proposal;
import com.example.thesis.entity.Review;
import com.example.thesis.entity.Student;
import com.example.thesis.entity.Teacher;
import com.example.thesis.entity.Thesis;
import com.example.thesis.entity.ThesisScore;
import com.example.thesis.mapper.DefenseRecordMapper;
import com.example.thesis.mapper.MidtermReportMapper;
import com.example.thesis.mapper.ProposalMapper;
import com.example.thesis.mapper.ReviewMapper;
import com.example.thesis.mapper.ThesisMapper;
import com.example.thesis.mapper.ThesisScoreMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

/**
 * 成绩汇总：按权重计算总评并持久化到 thesis_score。
 * <p>未评分的环节不计入分母，避免「还没答辩就把总分拉到 0」。
 */
@Service
@RequiredArgsConstructor
public class ScoreService {

    private final ThesisScoreMapper thesisScoreMapper;
    private final ThesisMapper thesisMapper;
    private final ProposalMapper proposalMapper;
    private final MidtermReportMapper midtermMapper;
    private final ReviewMapper reviewMapper;
    private final DefenseRecordMapper defenseRecordMapper;
    private final SystemService systemService;
    private final UserService userService;

    /** 重新计算并落库某篇论文的总评 */
    @Transactional
    public ThesisScore recompute(Long thesisId) {
        Proposal proposal = proposalMapper.selectOne(new LambdaQueryWrapper<Proposal>()
                .eq(Proposal::getThesisId, thesisId)
                .orderByDesc(Proposal::getId).last("LIMIT 1"));
        MidtermReport midterm = midtermMapper.selectOne(new LambdaQueryWrapper<MidtermReport>()
                .eq(MidtermReport::getThesisId, thesisId)
                .orderByDesc(MidtermReport::getId).last("LIMIT 1"));
        List<Review> reviews = reviewMapper.selectList(new LambdaQueryWrapper<Review>()
                .eq(Review::getThesisId, thesisId)
                .eq(Review::getStatus, "SUBMITTED")
                .isNotNull(Review::getScore));
        DefenseRecord defense = defenseRecordMapper.selectOne(new LambdaQueryWrapper<DefenseRecord>()
                .eq(DefenseRecord::getThesisId, thesisId).last("LIMIT 1"));

        BigDecimal proposalScore = proposal == null ? null : proposal.getScore();
        BigDecimal midtermScore = midterm == null ? null : midterm.getScore();
        BigDecimal reviewScore = average(reviews.stream().map(Review::getScore).toList());
        BigDecimal defenseScore = defense == null ? null : defense.getScore();

        BigDecimal total = ScoreRule.total(proposalScore, midtermScore, reviewScore, defenseScore,
                weight("score.weight.proposal", ScoreRule.DEFAULT_PROPOSAL_WEIGHT),
                weight("score.weight.midterm", ScoreRule.DEFAULT_MIDTERM_WEIGHT),
                weight("score.weight.review", ScoreRule.DEFAULT_REVIEW_WEIGHT),
                weight("score.weight.defense", ScoreRule.DEFAULT_DEFENSE_WEIGHT));

        ThesisScore exist = thesisScoreMapper.selectOne(new LambdaQueryWrapper<ThesisScore>()
                .eq(ThesisScore::getThesisId, thesisId).last("LIMIT 1"));
        ThesisScore entity = exist == null ? new ThesisScore() : exist;
        entity.setThesisId(thesisId);
        entity.setProposalScore(proposalScore);
        entity.setMidtermScore(midtermScore);
        entity.setReviewScore(reviewScore);
        entity.setDefenseScore(defenseScore);
        entity.setTotalScore(total);
        entity.setComputedTime(LocalDateTime.now());
        if (exist == null) {
            thesisScoreMapper.insert(entity);
        } else {
            thesisScoreMapper.updateById(entity);
        }
        return entity;
    }

    public ThesisScore getByThesis(Long thesisId) {
        ThesisScore score = thesisScoreMapper.selectOne(new LambdaQueryWrapper<ThesisScore>()
                .eq(ThesisScore::getThesisId, thesisId).last("LIMIT 1"));
        if (score != null) {
            score.setLevel(ScoreRule.levelOf(score.getTotalScore()));
        }
        return score;
    }

    public PageResult<ThesisScore> page(PageQuery query, String grade, String college, String major) {
        LambdaQueryWrapper<Thesis> thesisWrapper = new LambdaQueryWrapper<Thesis>()
                .eq(StringUtils.hasText(grade), Thesis::getGrade, grade)
                .eq(StringUtils.hasText(college), Thesis::getCollege, college)
                .eq(StringUtils.hasText(major), Thesis::getMajor, major)
                .like(StringUtils.hasText(query.getKeyword()), Thesis::getTitle, query.getKeyword());
        List<Long> thesisIds = thesisMapper.selectList(thesisWrapper.select(Thesis::getId)).stream()
                .map(Thesis::getId).toList();
        if (thesisIds.isEmpty()) {
            return PageResult.of(List.of(), 0, query.getPageNum(), query.getPageSize());
        }
        Page<ThesisScore> page = thesisScoreMapper.selectPage(query.toPage(),
                new LambdaQueryWrapper<ThesisScore>()
                        .in(ThesisScore::getThesisId, thesisIds)
                        .orderByDesc(ThesisScore::getTotalScore));
        decorate(page.getRecords());
        return PageResult.of(page);
    }

    /** 总评分段分布（看板） */
    public List<Map<String, Object>> scoreBuckets() {
        return thesisScoreMapper.countByScoreBucket();
    }

    public Double avgTotalScore() {
        return thesisScoreMapper.avgTotalScore();
    }

    private BigDecimal weight(String key, BigDecimal defaultValue) {
        String value = systemService.getConfig(key, null);
        if (!StringUtils.hasText(value)) {
            return defaultValue;
        }
        try {
            return new BigDecimal(value.trim());
        } catch (NumberFormatException e) {
            return defaultValue;
        }
    }

    private BigDecimal average(List<BigDecimal> values) {
        List<BigDecimal> valid = values.stream().filter(Objects::nonNull).toList();
        if (valid.isEmpty()) {
            return null;
        }
        BigDecimal sum = valid.stream().reduce(BigDecimal.ZERO, BigDecimal::add);
        return sum.divide(BigDecimal.valueOf(valid.size()), 1, RoundingMode.HALF_UP);
    }

    private void decorate(List<ThesisScore> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        List<Long> thesisIds = records.stream().map(ThesisScore::getThesisId)
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
        for (ThesisScore s : records) {
            Thesis thesis = theses.get(s.getThesisId());
            if (thesis == null) {
                continue;
            }
            s.setThesisTitle(thesis.getTitle());
            s.setGrade(thesis.getGrade());
            s.setCollege(thesis.getCollege());
            s.setMajor(thesis.getMajor());
            Student student = students.get(thesis.getStudentId());
            if (student != null) {
                s.setStudentName(student.getRealName());
                s.setStudentNo(student.getStudentNo());
            }
            Teacher teacher = thesis.getAdvisorId() == null ? null : teachers.get(thesis.getAdvisorId());
            s.setAdvisorName(teacher == null ? null : teacher.getRealName());
            s.setLevel(ScoreRule.levelOf(s.getTotalScore()));
        }
    }
}
