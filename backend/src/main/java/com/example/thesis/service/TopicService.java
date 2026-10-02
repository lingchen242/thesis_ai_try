package com.example.thesis.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.example.thesis.common.BizException;
import com.example.thesis.common.Constants;
import com.example.thesis.common.ErrorCode;
import com.example.thesis.common.PageResult;
import com.example.thesis.dto.PageQuery;
import com.example.thesis.entity.Selection;
import com.example.thesis.entity.Student;
import com.example.thesis.entity.Teacher;
import com.example.thesis.entity.Topic;
import com.example.thesis.mapper.SelectionMapper;
import com.example.thesis.mapper.TopicMapper;
import com.example.thesis.security.LoginUser;
import com.example.thesis.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

/**
 * 课题管理。
 * <p>数据范围：管理员看全部；指导教师看自己出的题；学生只看开放中的题。
 */
@Service
@RequiredArgsConstructor
public class TopicService {

    private final TopicMapper topicMapper;
    private final SelectionMapper selectionMapper;
    private final UserService userService;
    private final AuditService auditService;

    public PageResult<Topic> page(PageQuery query, String status, String grade,
                                  String major, Long teacherId, Boolean onlyOpen) {
        LambdaQueryWrapper<Topic> wrapper = new LambdaQueryWrapper<Topic>()
                .eq(StringUtils.hasText(status), Topic::getStatus, status)
                .eq(StringUtils.hasText(grade), Topic::getGrade, grade)
                .eq(StringUtils.hasText(major), Topic::getMajor, major)
                .eq(teacherId != null, Topic::getTeacherId, teacherId)
                .eq(Boolean.TRUE.equals(onlyOpen), Topic::getStatus, "OPEN")
                .and(StringUtils.hasText(query.getKeyword()), w -> w
                        .like(Topic::getTitle, query.getKeyword())
                        .or().like(Topic::getDescription, query.getKeyword()))
                .orderByDesc(Topic::getId);

        LoginUser user = SecurityUtils.current();
        if (Constants.ROLE_ADVISOR.equals(user.getRole())) {
            Teacher self = userService.findTeacherByUser(user.getId());
            wrapper.eq(Topic::getTeacherId, self == null ? -1L : self.getId());
        } else if (Constants.ROLE_STUDENT.equals(user.getRole())) {
            // 学生只能看开放中或自己已申请的课题
            Student self = userService.findStudentByUser(user.getId());
            List<Long> appliedTopicIds = self == null ? List.of()
                    : selectionMapper.selectList(new LambdaQueryWrapper<Selection>()
                            .eq(Selection::getStudentId, self.getId())
                            .select(Selection::getTopicId))
                    .stream().map(Selection::getTopicId).filter(Objects::nonNull).toList();
            wrapper.and(w -> {
                w.eq(Topic::getStatus, "OPEN");
                if (!appliedTopicIds.isEmpty()) {
                    w.or().in(Topic::getId, appliedTopicIds);
                }
            });
        }

        Page<Topic> page = topicMapper.selectPage(query.toPage(), wrapper);
        decorate(page.getRecords());
        return PageResult.of(page);
    }

    public Topic detail(Long id) {
        Topic topic = topicMapper.selectById(id);
        if (topic == null) {
            throw BizException.notFound("课题不存在");
        }
        decorate(List.of(topic));
        return topic;
    }

    @Transactional
    public Topic save(Topic topic) {
        if (!StringUtils.hasText(topic.getTitle())) {
            throw BizException.param("课题名称不能为空");
        }
        LoginUser user = SecurityUtils.current();
        if (topic.getId() == null) {
            Long teacherId = topic.getTeacherId();
            if (Constants.ROLE_ADVISOR.equals(user.getRole())) {
                Teacher self = userService.findTeacherByUser(user.getId());
                if (self == null) {
                    throw BizException.param("当前账号没有关联教师档案");
                }
                teacherId = self.getId();
            }
            if (teacherId == null) {
                throw BizException.param("请选择出题教师");
            }
            if (topic.getCapacity() == null || topic.getCapacity() < 1) {
                topic.setCapacity(1);
            }
            topic.setTeacherId(teacherId);
            topic.setSelectedCount(0);
            topic.setStatus("DRAFT");
            topicMapper.insert(topic);
            auditService.log("CREATE_TOPIC", "TOPIC", topic.getId(), "发布课题《" + topic.getTitle() + "》");
        } else {
            Topic exist = requireOwned(topic.getId());
            if (exist.getSelectedCount() != null && exist.getSelectedCount() > 0
                    && topic.getCapacity() != null && topic.getCapacity() < exist.getSelectedCount()) {
                throw BizException.param("容量不能小于已选人数 " + exist.getSelectedCount());
            }
            topic.setSelectedCount(exist.getSelectedCount());
            topic.setStatus(exist.getStatus());
            topicMapper.updateById(topic);
        }
        return topicMapper.selectById(topic.getId());
    }

    @Transactional
    public void publish(Long id) {
        Topic topic = requireOwned(id);
        if (!"DRAFT".equals(topic.getStatus())) {
            throw BizException.param("只有草稿状态的课题可以发布");
        }
        topic.setStatus("OPEN");
        topic.setPublishTime(LocalDateTime.now());
        topicMapper.updateById(topic);
        auditService.log("PUBLISH_TOPIC", "TOPIC", id, "发布课题《" + topic.getTitle() + "》供学生申报");
    }

    @Transactional
    public void close(Long id) {
        Topic topic = requireOwned(id);
        if ("CLOSED".equals(topic.getStatus())) {
            throw BizException.param("课题已关闭");
        }
        topic.setStatus("CLOSED");
        topicMapper.updateById(topic);
        auditService.log("CLOSE_TOPIC", "TOPIC", id, "关闭课题《" + topic.getTitle() + "》");
    }

    @Transactional
    public void delete(Long id) {
        Topic topic = requireOwned(id);
        Long applied = selectionMapper.selectCount(new LambdaQueryWrapper<Selection>()
                .eq(Selection::getTopicId, id));
        if (applied != null && applied > 0) {
            throw BizException.param("该课题已有 " + applied + " 条选题申请，无法删除");
        }
        topicMapper.deleteById(id);
        auditService.log("DELETE_TOPIC", "TOPIC", id, "删除课题《" + topic.getTitle() + "》");
    }

    /** 供其它服务使用：校验课题归属并返回 */
    public Topic requireOwned(Long id) {
        Topic topic = topicMapper.selectById(id);
        if (topic == null) {
            throw BizException.notFound("课题不存在");
        }
        LoginUser user = SecurityUtils.current();
        if (Constants.ROLE_ADMIN.equals(user.getRole())) {
            return topic;
        }
        if (Constants.ROLE_ADVISOR.equals(user.getRole())) {
            Teacher self = userService.findTeacherByUser(user.getId());
            if (self == null || !self.getId().equals(topic.getTeacherId())) {
                throw new BizException(ErrorCode.FORBIDDEN, "只能操作自己发布的课题");
            }
            return topic;
        }
        throw new BizException(ErrorCode.FORBIDDEN, "无权操作课题");
    }

    private void decorate(List<Topic> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        List<Long> teacherIds = records.stream().map(Topic::getTeacherId)
                .filter(Objects::nonNull).distinct().toList();
        Map<Long, Teacher> teachers = userService.teacherMap(teacherIds);

        List<Long> topicIds = records.stream().map(Topic::getId).toList();
        Map<Long, Long> applyCounts = selectionMapper.selectList(new LambdaQueryWrapper<Selection>()
                        .in(Selection::getTopicId, topicIds)).stream()
                .collect(Collectors.groupingBy(Selection::getTopicId, Collectors.counting()));

        LoginUser user = SecurityUtils.current();
        Map<Long, Long> myApplied = Collections.emptyMap();
        if (Constants.ROLE_STUDENT.equals(user.getRole())) {
            Student self = userService.findStudentByUser(user.getId());
            if (self != null) {
                myApplied = selectionMapper.selectList(new LambdaQueryWrapper<Selection>()
                                .eq(Selection::getStudentId, self.getId())).stream()
                        .collect(Collectors.toMap(Selection::getTopicId, Selection::getId, (a, b) -> a));
            }
        }
        for (Topic t : records) {
            Teacher teacher = teachers.get(t.getTeacherId());
            t.setTeacherName(teacher == null ? null : teacher.getRealName());
            t.setApplyCount(applyCounts.getOrDefault(t.getId(), 0L));
            t.setApplied(myApplied.containsKey(t.getId()));
        }
    }
}
