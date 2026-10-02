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
import com.example.thesis.entity.DefenseGroup;
import com.example.thesis.entity.DefenseGroupMember;
import com.example.thesis.entity.DefenseRecord;
import com.example.thesis.entity.Student;
import com.example.thesis.entity.Teacher;
import com.example.thesis.entity.Thesis;
import com.example.thesis.entity.ThesisScore;
import com.example.thesis.mapper.DefenseGroupMapper;
import com.example.thesis.mapper.DefenseGroupMemberMapper;
import com.example.thesis.mapper.DefenseRecordMapper;
import com.example.thesis.mapper.ThesisMapper;
import com.example.thesis.security.LoginUser;
import com.example.thesis.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.CollectionUtils;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

/**
 * 答辩管理：建组 → 编入学生 → 录入成绩。
 * <p>「编入答辩组」通过 defense_record 承载（一题一条），成绩为空表示已编排、待答辩。
 */
@Service
@RequiredArgsConstructor
public class DefenseService {

    private final DefenseGroupMapper groupMapper;
    private final DefenseGroupMemberMapper memberMapper;
    private final DefenseRecordMapper recordMapper;
    private final ThesisMapper thesisMapper;
    private final ThesisService thesisService;
    private final UserService userService;
    private final ScoreService scoreService;
    private final AuditService auditService;

    // ======================================================= 答辩组
    public PageResult<DefenseGroup> pageGroups(PageQuery query, String grade, String status) {
        Page<DefenseGroup> page = groupMapper.selectPage(query.toPage(),
                new LambdaQueryWrapper<DefenseGroup>()
                        .eq(StringUtils.hasText(grade), DefenseGroup::getGrade, grade)
                        .eq(StringUtils.hasText(status), DefenseGroup::getStatus, status)
                        .like(StringUtils.hasText(query.getKeyword()), DefenseGroup::getName, query.getKeyword())
                        .orderByDesc(DefenseGroup::getId));
        decorateGroups(page.getRecords());
        return PageResult.of(page);
    }

    public Map<String, Object> groupDetail(Long id) {
        DefenseGroup group = groupMapper.selectById(id);
        if (group == null) {
            throw BizException.notFound("答辩组不存在");
        }
        decorateGroups(List.of(group));
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("group", group);
        result.put("members", listMembers(id));
        result.put("theses", listGroupTheses(id));
        return result;
    }

    @Transactional
    public DefenseGroup saveGroup(DefenseGroup group) {
        SecurityUtils.requireAdmin();
        if (!StringUtils.hasText(group.getName())) {
            throw BizException.param("答辩组名称不能为空");
        }
        if (group.getId() == null) {
            if (group.getStatus() == null) {
                group.setStatus("PLANNED");
            }
            groupMapper.insert(group);
            auditService.log("CREATE_DEFENSE_GROUP", "DEFENSE", group.getId(),
                    "创建答辩组「" + group.getName() + "」");
        } else {
            groupMapper.updateById(group);
        }
        return groupMapper.selectById(group.getId());
    }

    @Transactional
    public void deleteGroup(Long id) {
        SecurityUtils.requireAdmin();
        Long theses = recordMapper.selectCount(new LambdaQueryWrapper<DefenseRecord>()
                .eq(DefenseRecord::getGroupId, id));
        if (theses != null && theses > 0) {
            throw BizException.param("该答辩组下还有 " + theses + " 名学生，请先移除");
        }
        memberMapper.delete(new LambdaQueryWrapper<DefenseGroupMember>()
                .eq(DefenseGroupMember::getGroupId, id));
        groupMapper.deleteById(id);
    }

    public List<DefenseGroupMember> listMembers(Long groupId) {
        List<DefenseGroupMember> members = memberMapper.selectList(new LambdaQueryWrapper<DefenseGroupMember>()
                .eq(DefenseGroupMember::getGroupId, groupId)
                .orderByAsc(DefenseGroupMember::getId));
        if (members.isEmpty()) {
            return members;
        }
        List<Long> teacherIds = members.stream().map(DefenseGroupMember::getTeacherId)
                .filter(Objects::nonNull).distinct().toList();
        Map<Long, Teacher> teachers = userService.teacherMap(teacherIds);
        for (DefenseGroupMember m : members) {
            Teacher teacher = teachers.get(m.getTeacherId());
            if (teacher != null) {
                m.setTeacherName(teacher.getRealName());
                m.setTitle(teacher.getTitle());
                m.setCollege(teacher.getCollege());
            }
        }
        return members;
    }

    @Transactional
    public void setMembers(Long groupId, Requests.GroupMembers req) {
        SecurityUtils.requireAdmin();
        DefenseGroup group = groupMapper.selectById(groupId);
        if (group == null) {
            throw BizException.notFound("答辩组不存在");
        }
        memberMapper.delete(new LambdaQueryWrapper<DefenseGroupMember>()
                .eq(DefenseGroupMember::getGroupId, groupId));

        List<Long> ids = new ArrayList<>(new java.util.LinkedHashSet<>(req.memberIds()));
        for (Long teacherId : ids) {
            String role = "MEMBER";
            if (teacherId.equals(req.chairId())) {
                role = "CHAIR";
            } else if (teacherId.equals(req.secretaryId())) {
                role = "SECRETARY";
            }
            DefenseGroupMember member = new DefenseGroupMember();
            member.setGroupId(groupId);
            member.setTeacherId(teacherId);
            member.setRoleInGroup(role);
            memberMapper.insert(member);
        }
        if (req.secretaryId() != null) {
            group.setSecretaryId(req.secretaryId());
            groupMapper.updateById(group);
        }
        auditService.log("SET_DEFENSE_MEMBERS", "DEFENSE", groupId,
                "设置答辩组成员 " + ids.size() + " 人");
    }

    // ======================================================= 编排与成绩
    /** 可编入答辩组的论文：评阅已通过 + 已编排 */
    public List<Thesis> candidates(Long groupId) {
        List<Thesis> list = thesisMapper.selectList(new LambdaQueryWrapper<Thesis>()
                .in(Thesis::getStatus, ThesisStatus.REVIEW_PASSED.name(), ThesisStatus.DEFENSE_SCHEDULED.name())
                .orderByAsc(Thesis::getGrade).orderByAsc(Thesis::getId));
        if (groupId == null) {
            return list;
        }
        List<Long> inGroup = recordMapper.selectList(new LambdaQueryWrapper<DefenseRecord>()
                        .eq(DefenseRecord::getGroupId, groupId).select(DefenseRecord::getThesisId))
                .stream().map(DefenseRecord::getThesisId).toList();
        // 已在其它组的学生不重复出现
        List<Long> inOther = recordMapper.selectList(new LambdaQueryWrapper<DefenseRecord>()
                        .ne(DefenseRecord::getGroupId, groupId).select(DefenseRecord::getThesisId))
                .stream().map(DefenseRecord::getThesisId).toList();
        return list.stream()
                .filter(t -> inGroup.contains(t.getId()) || !inOther.contains(t.getId()))
                .peek(t -> t.setStatusLabel(ThesisStatus.labelOf(t.getStatus())))
                .toList();
    }

    @Transactional
    public void schedule(Long groupId, List<Long> thesisIds) {
        SecurityUtils.requireAdmin();
        DefenseGroup group = groupMapper.selectById(groupId);
        if (group == null) {
            throw BizException.notFound("答辩组不存在");
        }
        if (CollectionUtils.isEmpty(thesisIds)) {
            return;
        }
        for (Long thesisId : thesisIds) {
            Thesis thesis = thesisMapper.selectById(thesisId);
            if (thesis == null) {
                continue;
            }
            DefenseRecord record = recordMapper.selectOne(new LambdaQueryWrapper<DefenseRecord>()
                    .eq(DefenseRecord::getThesisId, thesisId).last("LIMIT 1"));
            if (record == null) {
                record = new DefenseRecord();
                record.setThesisId(thesisId);
                record.setGroupId(groupId);
                recordMapper.insert(record);
            } else {
                record.setGroupId(groupId);
                recordMapper.updateById(record);
            }
            if (ThesisStatus.REVIEW_PASSED.name().equals(thesis.getStatus())) {
                FlowGuard.ensure(thesis.getStatus(), ThesisStatus.DEFENSE_SCHEDULED.name(),
                        SecurityUtils.role());
                thesis.setStatus(ThesisStatus.DEFENSE_SCHEDULED.name());
                thesis.setCurrentStage(ThesisStatus.DEFENSE_SCHEDULED.getLabel());
                thesisMapper.updateById(thesis);
            }
        }
        auditService.log("SCHEDULE_DEFENSE", "DEFENSE", groupId,
                "编入 " + thesisIds.size() + " 名学生到「" + group.getName() + "」");
    }

    @Transactional
    public void removeThesis(Long thesisId) {
        SecurityUtils.requireAdmin();
        DefenseRecord record = recordMapper.selectOne(new LambdaQueryWrapper<DefenseRecord>()
                .eq(DefenseRecord::getThesisId, thesisId).last("LIMIT 1"));
        if (record == null) {
            return;
        }
        if (record.getScore() != null) {
            throw BizException.param("已录入答辩成绩，无法移除");
        }
        recordMapper.deleteById(record.getId());
        Thesis thesis = thesisMapper.selectById(thesisId);
        if (thesis != null && ThesisStatus.DEFENSE_SCHEDULED.name().equals(thesis.getStatus())) {
            thesis.setStatus(ThesisStatus.REVIEW_PASSED.name());
            thesis.setCurrentStage(ThesisStatus.REVIEW_PASSED.getLabel());
            thesisMapper.updateById(thesis);
        }
    }

    public List<Thesis> listGroupTheses(Long groupId) {
        List<Long> thesisIds = recordMapper.selectList(new LambdaQueryWrapper<DefenseRecord>()
                        .eq(DefenseRecord::getGroupId, groupId).select(DefenseRecord::getThesisId))
                .stream().map(DefenseRecord::getThesisId).filter(Objects::nonNull).toList();
        if (thesisIds.isEmpty()) {
            return List.of();
        }
        List<Thesis> theses = thesisMapper.selectBatchIds(thesisIds);
        List<Long> studentIds = theses.stream().map(Thesis::getStudentId)
                .filter(Objects::nonNull).distinct().toList();
        Map<Long, Student> students = userService.studentMap(studentIds);
        for (Thesis t : theses) {
            Student student = students.get(t.getStudentId());
            if (student != null) {
                t.setStudentName(student.getRealName());
                t.setStudentNo(student.getStudentNo());
                t.setClassName(student.getClassName());
            }
            t.setStatusLabel(ThesisStatus.labelOf(t.getStatus()));
        }
        return theses;
    }

    public PageResult<DefenseRecord> pageRecords(PageQuery query, Long groupId, String grade, String result) {
        LambdaQueryWrapper<DefenseRecord> wrapper = new LambdaQueryWrapper<DefenseRecord>()
                .eq(groupId != null, DefenseRecord::getGroupId, groupId)
                .eq(StringUtils.hasText(result), DefenseRecord::getResult, result)
                .orderByDesc(DefenseRecord::getId);
        LoginUser user = SecurityUtils.current();
        if (Constants.ROLE_REVIEWER.equals(user.getRole())) {
            Teacher self = userService.findTeacherByUser(user.getId());
            List<Long> myGroups = memberMapper.selectList(new LambdaQueryWrapper<DefenseGroupMember>()
                            .eq(DefenseGroupMember::getTeacherId, self == null ? -1L : self.getId())
                            .select(DefenseGroupMember::getGroupId)).stream()
                    .map(DefenseGroupMember::getGroupId).toList();
            wrapper.in(DefenseRecord::getGroupId, myGroups.isEmpty() ? List.of(-1L) : myGroups);
        }
        Page<DefenseRecord> page = recordMapper.selectPage(query.toPage(), wrapper);
        decorateRecords(page.getRecords());
        return PageResult.of(page);
    }

    @Transactional
    public DefenseRecord record(Requests.DefenseRecord req) {
        LoginUser user = SecurityUtils.current();
        if (!Constants.ROLE_ADMIN.equals(user.getRole()) && !Constants.ROLE_REVIEWER.equals(user.getRole())) {
            throw new BizException(ErrorCode.FORBIDDEN, "只有管理员或答辩组成员可以录入答辩成绩");
        }
        DefenseGroup group = groupMapper.selectById(req.groupId());
        if (group == null) {
            throw BizException.notFound("答辩组不存在");
        }
        if (Constants.ROLE_REVIEWER.equals(user.getRole())) {
            Teacher self = userService.findTeacherByUser(user.getId());
            Long inGroup = memberMapper.selectCount(new LambdaQueryWrapper<DefenseGroupMember>()
                    .eq(DefenseGroupMember::getGroupId, req.groupId())
                    .eq(DefenseGroupMember::getTeacherId, self == null ? -1L : self.getId()));
            if (inGroup == null || inGroup == 0) {
                throw new BizException(ErrorCode.FORBIDDEN, "你不在该答辩组中，无法录入成绩");
            }
        }
        if (req.score() != null
                && (req.score().compareTo(BigDecimal.ZERO) < 0 || req.score().compareTo(new BigDecimal("100")) > 0)) {
            throw BizException.param("答辩成绩需在 0 ~ 100 之间");
        }

        Thesis thesis = thesisMapper.selectById(req.thesisId());
        if (thesis == null) {
            throw BizException.notFound("论文不存在");
        }
        DefenseRecord record = recordMapper.selectOne(new LambdaQueryWrapper<DefenseRecord>()
                .eq(DefenseRecord::getThesisId, req.thesisId()).last("LIMIT 1"));
        if (record == null) {
            record = new DefenseRecord();
            record.setThesisId(req.thesisId());
            record.setGroupId(req.groupId());
            recordMapper.insert(record);
        } else {
            record.setGroupId(req.groupId());
        }
        record.setScore(req.score());
        record.setResult(StringUtils.hasText(req.result()) ? req.result() : deriveResult(req.score()));
        record.setComment(req.comment());
        record.setRecordedBy(user.getId());
        record.setRecordedTime(LocalDateTime.now());
        recordMapper.updateById(record);

        if (ThesisStatus.DEFENSE_SCHEDULED.name().equals(thesis.getStatus())) {
            FlowGuard.ensure(thesis.getStatus(), ThesisStatus.DEFENSE_DONE.name(), user.getRole());
            thesis.setStatus(ThesisStatus.DEFENSE_DONE.name());
            thesis.setCurrentStage(ThesisStatus.DEFENSE_DONE.getLabel());
            thesisMapper.updateById(thesis);
        }
        ThesisScore score = scoreService.recompute(thesis.getId());

        auditService.log(Constants.ACT_RECORD_DEFENSE, "THESIS", thesis.getId(),
                "录入答辩成绩 " + req.score() + "，结论 " + record.getResult());
        Student student = userService.studentMap(List.of(thesis.getStudentId())).get(thesis.getStudentId());
        if (student != null) {
            auditService.notify(student.getUserId(), "答辩成绩已发布",
                    "你的答辩成绩为 " + req.score() + "，总评 "
                            + (score == null ? "-" : score.getTotalScore()) + "。",
                    "/thesis/mine", Constants.NOTE_SCORE);
        }
        return record;
    }

    private String deriveResult(BigDecimal score) {
        if (score == null) {
            return null;
        }
        if (score.compareTo(new BigDecimal("75")) >= 0) {
            return "PASS";
        }
        if (score.compareTo(new BigDecimal("60")) >= 0) {
            return "DEFER";
        }
        return "FAIL";
    }

    private void decorateGroups(List<DefenseGroup> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        List<Long> groupIds = records.stream().map(DefenseGroup::getId).toList();
        Map<Long, Long> memberCounts = memberMapper.selectList(new LambdaQueryWrapper<DefenseGroupMember>()
                        .in(DefenseGroupMember::getGroupId, groupIds)).stream()
                .collect(Collectors.groupingBy(DefenseGroupMember::getGroupId, Collectors.counting()));
        Map<Long, Long> thesisCounts = recordMapper.selectList(new LambdaQueryWrapper<DefenseRecord>()
                        .in(DefenseRecord::getGroupId, groupIds)).stream()
                .collect(Collectors.groupingBy(DefenseRecord::getGroupId, Collectors.counting()));
        List<Long> secretaryIds = records.stream().map(DefenseGroup::getSecretaryId)
                .filter(Objects::nonNull).distinct().toList();
        Map<Long, Teacher> teachers = userService.teacherMap(secretaryIds);
        for (DefenseGroup g : records) {
            g.setMemberCount(memberCounts.getOrDefault(g.getId(), 0L).intValue());
            g.setThesisCount(thesisCounts.getOrDefault(g.getId(), 0L).intValue());
            Teacher secretary = g.getSecretaryId() == null ? null : teachers.get(g.getSecretaryId());
            g.setSecretaryName(secretary == null ? null : secretary.getRealName());
        }
    }

    private void decorateRecords(List<DefenseRecord> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        List<Long> thesisIds = records.stream().map(DefenseRecord::getThesisId)
                .filter(Objects::nonNull).distinct().toList();
        Map<Long, Thesis> theses = thesisIds.isEmpty() ? Map.of()
                : thesisMapper.selectBatchIds(thesisIds).stream()
                .collect(Collectors.toMap(Thesis::getId, t -> t, (a, b) -> a));
        List<Long> studentIds = theses.values().stream().map(Thesis::getStudentId)
                .filter(Objects::nonNull).distinct().toList();
        Map<Long, Student> students = userService.studentMap(studentIds);
        List<Long> groupIds = records.stream().map(DefenseRecord::getGroupId)
                .filter(Objects::nonNull).distinct().toList();
        Map<Long, DefenseGroup> groups = groupIds.isEmpty() ? Map.of()
                : groupMapper.selectBatchIds(groupIds).stream()
                .collect(Collectors.toMap(DefenseGroup::getId, g -> g, (a, b) -> a));
        for (DefenseRecord r : records) {
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
            DefenseGroup group = groups.get(r.getGroupId());
            r.setGroupName(group == null ? null : group.getName());
        }
    }
}
