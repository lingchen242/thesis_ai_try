package com.example.thesis.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 操作留痕 audit_log。论文详情页的时间轴即来源于此表。
 */
@Data
@TableName("audit_log")
public class AuditLog implements Serializable {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 操作人 sys_user.id */
    private Long actorId;

    private String actorName;

    /** 动作编码，见 Constants.ACT_* */
    private String action;

    /** THESIS / TOPIC / SELECTION / REVIEW / DEFENSE ... */
    private String targetType;

    private Long targetId;

    private String detail;

    private LocalDateTime createTime;
}
