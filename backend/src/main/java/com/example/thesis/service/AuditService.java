package com.example.thesis.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.thesis.common.BizException;
import com.example.thesis.common.Constants;
import com.example.thesis.entity.AuditLog;
import com.example.thesis.entity.Notification;
import com.example.thesis.mapper.AuditLogMapper;
import com.example.thesis.mapper.NotificationMapper;
import com.example.thesis.security.LoginUser;
import com.example.thesis.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 操作留痕 + 站内消息。
 * <p>论文详情页的时间轴读取 audit_log；顶栏红点读取 notification。
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AuditService {

    private final AuditLogMapper auditLogMapper;
    private final NotificationMapper notificationMapper;

    /** 以当前登录用户身份写一条留痕 */
    public void log(String action, String targetType, Long targetId, String detail) {
        LoginUser user = currentOrNull();
        log(user == null ? null : user.getId(),
                user == null ? "系统" : user.getRealName(),
                action, targetType, targetId, detail);
    }

    /** 指定操作人写留痕（用于系统自动流转） */
    public void log(Long actorId, String actorName, String action,
                    String targetType, Long targetId, String detail) {
        AuditLog entity = new AuditLog();
        entity.setActorId(actorId);
        entity.setActorName(actorName);
        entity.setAction(action);
        entity.setTargetType(targetType);
        entity.setTargetId(targetId);
        entity.setDetail(detail);
        entity.setCreateTime(LocalDateTime.now());
        auditLogMapper.insert(entity);
    }

    /** 某条业务记录的完整时间轴（按时间正序） */
    public List<AuditLog> timeline(String targetType, Long targetId) {
        return auditLogMapper.selectList(new LambdaQueryWrapper<AuditLog>()
                .eq(AuditLog::getTargetType, targetType)
                .eq(AuditLog::getTargetId, targetId)
                .orderByAsc(AuditLog::getCreateTime)
                .orderByAsc(AuditLog::getId));
    }

    public void notify(Long userId, String title, String content, String link, String type) {
        if (userId == null) {
            return;
        }
        Notification n = new Notification();
        n.setUserId(userId);
        n.setTitle(title);
        n.setContent(content);
        n.setLink(link);
        n.setType(type == null ? Constants.NOTE_SYSTEM : type);
        n.setIsRead(0);
        n.setCreateTime(LocalDateTime.now());
        notificationMapper.insert(n);
    }

    public List<Notification> myNotifications(Boolean onlyUnread) {
        LambdaQueryWrapper<Notification> wrapper = new LambdaQueryWrapper<Notification>()
                .eq(Notification::getUserId, SecurityUtils.userId())
                .orderByDesc(Notification::getCreateTime)
                .orderByDesc(Notification::getId);
        if (Boolean.TRUE.equals(onlyUnread)) {
            wrapper.eq(Notification::getIsRead, 0);
        }
        return notificationMapper.selectList(wrapper.last("LIMIT 200"));
    }

    public long unreadCount() {
        Long count = notificationMapper.selectCount(new LambdaQueryWrapper<Notification>()
                .eq(Notification::getUserId, SecurityUtils.userId())
                .eq(Notification::getIsRead, 0));
        return count == null ? 0 : count;
    }

    public void markRead(Long id) {
        Notification n = notificationMapper.selectById(id);
        if (n == null) {
            throw BizException.notFound("消息不存在");
        }
        if (!n.getUserId().equals(SecurityUtils.userId())) {
            throw new BizException(com.example.thesis.common.ErrorCode.FORBIDDEN, "不能操作他人的消息");
        }
        n.setIsRead(1);
        notificationMapper.updateById(n);
    }

    public void markAllRead() {
        Notification update = new Notification();
        update.setIsRead(1);
        notificationMapper.update(update, new LambdaQueryWrapper<Notification>()
                .eq(Notification::getUserId, SecurityUtils.userId())
                .eq(Notification::getIsRead, 0));
    }

    private LoginUser currentOrNull() {
        try {
            return SecurityUtils.current();
        } catch (RuntimeException e) {
            return null;
        }
    }
}
