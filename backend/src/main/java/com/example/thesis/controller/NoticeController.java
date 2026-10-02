package com.example.thesis.controller;

import com.example.thesis.common.R;
import com.example.thesis.entity.Notification;
import com.example.thesis.service.AuditService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 站内消息接口。
 */
@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NoticeController {

    private final AuditService auditService;

    @GetMapping
    public R<List<Notification>> list(@RequestParam(required = false) Boolean onlyUnread) {
        return R.ok(auditService.myNotifications(onlyUnread));
    }

    @GetMapping("/unread-count")
    public R<Long> unreadCount() {
        return R.ok(auditService.unreadCount());
    }

    @PutMapping("/{id}/read")
    public R<Void> markRead(@PathVariable Long id) {
        auditService.markRead(id);
        return R.ok();
    }

    @PutMapping("/read-all")
    public R<Void> markAllRead() {
        auditService.markAllRead();
        return R.ok();
    }
}
