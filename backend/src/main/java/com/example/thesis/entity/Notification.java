package com.example.thesis.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 站内消息 notification。
 */
@Data
@TableName("notification")
public class Notification implements Serializable {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 接收人 sys_user.id */
    private Long userId;

    private String title;

    private String content;

    /** 前端跳转路径 */
    private String link;

    /** SYSTEM / FLOW / SCORE */
    private String type;

    private Integer isRead;

    private LocalDateTime createTime;
}
