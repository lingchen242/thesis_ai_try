package com.example.thesis.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.example.thesis.common.BizException;
import com.example.thesis.common.Constants;
import com.example.thesis.common.ErrorCode;
import com.example.thesis.common.PageResult;
import com.example.thesis.domain.ThesisStatus;
import com.example.thesis.dto.PageQuery;
import com.example.thesis.dto.Requests;
import com.example.thesis.entity.Selection;
import com.example.thesis.entity.Student;
import com.example.thesis.entity.Teacher;
import com.example.thesis.entity.Thesis;
import com.example.thesis.entity.Topic;
import com.example.thesis.mapper.SelectionMapper;
import com.example.thesis.mapper.StudentMapper;
import com.example.thesis.mapper.ThesisMapper;
import com.example.thesis.mapper.TopicMapper;
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
 * 选题申报与录取。
 * <p>录取时会自动为学生建立论文记录（DRAFT），并回填学生档案的指导教师。
 */
@Service
@RequiredArgsConstructor
public class SelectionService {

    private final SelectionMapper selectionMapper;
    private final TopicMapper topicMapper;
    private final ThesisMapper thesisMapper;
    private final StudentMapper studentMapper;
    private final UserService userService;
    private final TopicService topicService;
    private final AuditService auditService;

    public PageResult<Selection> page(PageQuery query, String status, Long topicId, String grade) {
        LambdaQueryWrapper<Selection> wrapper = new LambdaQueryWrapper<Selection>()
                .eq(StringUtils.hasText(status), Selection::getStatus, status)
                .eq(topicId != null, Selection::getTopicId, topicId)
                .orderByDesc(Selection::getApplyTime)
                .orderByDesc(Selection::getId);

        LoginUser user = SecurityUtils.current();
        Teacher self = null;
        if (Constants.ROLE_ADVISOR.equals(user.getRole())) {
            self = userService.findTeacherByUser(user.getId());
            if (self == null) {
                return PageResult.of(List.of(), 0, query.getPageNum(), query.getPageSize());
            }
            List<Long> myTopicIds = topicMapper.selectList(new LambdaQueryWrapper<Topic>()
                            .eq(Topic::getTeacherId, self.getId()).select(Topic::getId)).stream()
                    .map(Topic::getId).toList();
            if (myTopicIds.isEmpty()) {
                return PageResult.of(List.of(), 0, query.getPageNum(), query.getPageSize());
            }
            wrapper.in(Selection::getTopicId, myTopicIds);
        } else if (Constants.ROLE_STUDENT.equals(user.getRole())) {
            Student me = userService.findStudentByUser(user.getId());
            wrapper.eq(Selection::getStudentId, me == null ? -1L : me.getId());
        }

        Page<Selection> page = selectionMapper.selectPage(query.toPage(), wrapper);
        decorate(page.getRecords(), grade);
        return PageResult.of(page);
    }

    public Selection myApplication() {
        Student me = requireStudent();
        return selectionMapper.selectOne(new LambdaQueryWrapper<Selection>()
                .eq(Selection::getStudentId, me.getId())
                .orderByDesc(Selection::getId)
                .last("LIMIT 1"));
    }

    @Transactional
    public Selection apply(Requests.SelectionApply req) {
        Student me = requireStudent();
        Long existsThesis = thesisMapper.selectCount(new LambdaQueryWrapper<Thesis>()
                .eq(Thesis::getStudentId, me.getId()));
        if (existsThesis != null && existsThesis > 0) {
            throw BizException.param("你已确定课题，无法再次申报");
        }
        Long active = selectionMapper.selectCount(new LambdaQueryWrapper<Selection>()
                .eq(Selection::getStudentId, me.getId())
                .in(Selection::getStatus, "PENDING", "APPROVED"));
        if (active != null && active > 0) {
            throw BizException.param("你已有待审核或已通过的选题申请，请勿重复申报");
        }
        Topic topic = topicMapper.selectById(req.topicId());
        if (topic == null) {
            throw BizException.notFound("课题不存在");
        }
        if (!"OPEN".equals(topic.getStatus())) {
            throw BizException.param("该课题当前不可申报");
        }
        int capacity = topic.getCapacity() == null ? 1 : topic.getCapacity();
        int selected = topic.getSelectedCount() == null ? 0 : topic.getSelectedCount();
        if (selected >= capacity) {
            throw BizException.param("该课题名额已满");
        }

        Selection selection = new Selection();
        selection.setTopicId(topic.getId());
        selection.setStudentId(me.getId());
        selection.setStatus("PENDING");
        selection.setStudentRemark(req.remark());
        selection.setApplyTime(LocalDateTime.now());
        selectionMapper.insert(selection);

        auditService.log("APPLY_TOPIC", "SELECTION", selection.getId(),
                "申报课题《" + topic.getTitle() + "》");
        auditService.notify(topic.getTeacherId() == null ? null : teacherUserId(topic.getTeacherId()),
                "新的选题申请",
                me.getRealName() + " 申报了课题《" + topic.getTitle() + "》，请及时审核。",
                "/topic/selection", Constants.NOTE_FLOW);
        return selection;
    }

    @Transactional
    public void approve(Long id, String comment) {
        Selection selection = requirePending(id);
        Topic topic = topicMapper.selectById(selection.getTopicId());
        Student student = studentMapper.selectById(selection.getStudentId());
        if (topic == null || student == null) {
            throw BizException.notFound("选题或学生数据异常");
        }
        int capacity = topic.getCapacity() == null ? 1 : topic.getCapacity();
        int selected = topic.getSelectedCount() == null ? 0 : topic.getSelectedCount();
        if (selected >= capacity) {
            throw BizException.param("该课题名额已满，无法录取");
        }

        selection.setStatus("APPROVED");
        selection.setTeacherComment(comment);
        selection.setHandlerId(currentTeacherId());
        selection.setHandleTime(LocalDateTime.now());
        selectionMapper.updateById(selection);

        topic.setSelectedCount(selected + 1);
        if (topic.getSelectedCount() >= capacity) {
            topic.setStatus("SELECTED");
        }
        topicMapper.updateById(topic);

        // 建立论文记录
        Thesis thesis = new Thesis();
        thesis.setStudentId(student.getId());
        thesis.setTopicId(topic.getId());
        thesis.setAdvisorId(topic.getTeacherId());
        thesis.setTitle(topic.getTitle());
        thesis.setGrade(student.getGrade());
        thesis.setCollege(student.getCollege());
        thesis.setMajor(student.getMajor());
        thesis.setStatus(ThesisStatus.DRAFT.name());
        thesis.setCurrentStage(ThesisStatus.DRAFT.getLabel());
        thesis.setStartTime(LocalDateTime.now());
        thesisMapper.insert(thesis);

        // 回填学生档案的指导教师
        Student update = new Student();
        update.setId(student.getId());
        update.setAdvisorId(topic.getTeacherId());
        studentMapper.updateById(update);

        // 同一学生其它待审申请自动驳回
        List<Selection> others = selectionMapper.selectList(new LambdaQueryWrapper<Selection>()
                .eq(Selection::getStudentId, student.getId())
                .eq(Selection::getStatus, "PENDING")
                .ne(Selection::getId, id));
        for (Selection other : others) {
            other.setStatus("REJECTED");
            other.setTeacherComment("该生已被其它课题录取");
            other.setHandleTime(LocalDateTime.now());
            selectionMapper.updateById(other);
        }

        auditService.log(Constants.ACT_APPROVE_SELECTION, "SELECTION", id,
                "录取 " + student.getRealName() + " 申报的课题《" + topic.getTitle() + "》");
        auditService.log("CREATE_THESIS", "THESIS", thesis.getId(),
                "建立论文记录，进入「" + ThesisStatus.DRAFT.getLabel() + "」");
        auditService.notify(student.getUserId(), "选题已录取",
                "你申报的课题《" + topic.getTitle() + "》已被录取，请尽快准备开题。",
                "/thesis/mine", Constants.NOTE_FLOW);
    }

    @Transactional
    public void reject(Long id, String comment) {
        Selection selection = requirePending(id);
        selection.setStatus("REJECTED");
        selection.setTeacherComment(StringUtils.hasText(comment) ? comment : "未通过审核");
        selection.setHandlerId(currentTeacherId());
        selection.setHandleTime(LocalDateTime.now());
        selectionMapper.updateById(selection);

        Student student = studentMapper.selectById(selection.getStudentId());
        auditService.log(Constants.ACT_REJECT_SELECTION, "SELECTION", id,
                "驳回 " + (student == null ? "" : student.getRealName()) + " 的选题申请");
        if (student != null) {
            auditService.notify(student.getUserId(), "选题未通过",
                    StringUtils.hasText(comment) ? comment : "你的选题申请未通过，请重新选择课题。",
                    "/topic/browse", Constants.NOTE_FLOW);
        }
    }

    private Selection requirePending(Long id) {
        Selection selection = selectionMapper.selectById(id);
        if (selection == null) {
            throw BizException.notFound("选题申请不存在");
        }
        if (!"PENDING".equals(selection.getStatus())) {
            throw BizException.param("该申请已处理，当前状态：" + selection.getStatus());
        }
        Topic topic = topicMapper.selectById(selection.getTopicId());
        if (topic != null) {
            LoginUser user = SecurityUtils.current();
            if (Constants.ROLE_ADVISOR.equals(user.getRole())) {
                Teacher self = userService.findTeacherByUser(user.getId());
                if (self == null || !self.getId().equals(topic.getTeacherId())) {
                    throw new BizException(ErrorCode.FORBIDDEN, "只能审核自己课题的申请");
                }
            } else if (!Constants.ROLE_ADMIN.equals(user.getRole())) {
                throw new BizException(ErrorCode.FORBIDDEN, "无权审核选题申请");
            }
        }
        return selection;
    }

    private Student requireStudent() {
        LoginUser user = SecurityUtils.current();
        if (!Constants.ROLE_STUDENT.equals(user.getRole())) {
            throw new BizException(ErrorCode.FORBIDDEN, "只有学生可以申报课题");
        }
        Student student = userService.findStudentByUser(user.getId());
        if (student == null) {
            throw BizException.param("当前账号没有关联学生档案");
        }
        return student;
    }

    private Long currentTeacherId() {
        LoginUser user = SecurityUtils.current();
        Teacher self = userService.findTeacherByUser(user.getId());
        return self == null ? null : self.getId();
    }

    private Long teacherUserId(Long teacherId) {
        Teacher teacher = userService.teacherMap(List.of(teacherId)).get(teacherId);
        return teacher == null ? null : teacher.getUserId();
    }

    private void decorate(List<Selection> records, String grade) {
        if (records == null || records.isEmpty()) {
            return;
        }
        List<Long> topicIds = records.stream().map(Selection::getTopicId)
                .filter(Objects::nonNull).distinct().toList();
        Map<Long, Topic> topics = topicIds.isEmpty() ? Map.of()
                : topicMapper.selectBatchIds(topicIds).stream()
                .collect(java.util.stream.Collectors.toMap(Topic::getId, t -> t, (a, b) -> a));
        List<Long> studentIds = records.stream().map(Selection::getStudentId)
                .filter(Objects::nonNull).distinct().toList();
        Map<Long, Student> students = userService.studentMap(studentIds);
        List<Long> teacherIds = topics.values().stream().map(Topic::getTeacherId)
                .filter(Objects::nonNull).distinct().toList();
        Map<Long, Teacher> teachers = userService.teacherMap(teacherIds);

        for (Selection s : records) {
            Topic topic = topics.get(s.getTopicId());
            s.setTopicTitle(topic == null ? null : topic.getTitle());
            if (topic != null) {
                Teacher teacher = teachers.get(topic.getTeacherId());
                s.setTeacherName(teacher == null ? null : teacher.getRealName());
                s.setGrade(topic.getGrade());
            }
            Student student = students.get(s.getStudentId());
            if (student != null) {
                s.setStudentName(student.getRealName());
                s.setStudentNo(student.getStudentNo());
                s.setClassName(student.getClassName());
            }
        }
    }
}
