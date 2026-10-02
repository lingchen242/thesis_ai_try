package com.example.thesis.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 论文评阅 review。
 */
@Data
@TableName("review")
public class Review implements Serializable {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long thesisId;

    /** 评阅教师 teacher.id */
    private Long reviewerId;

    /** 指派人 sys_user.id */
    private Long assignedBy;

    private BigDecimal score;

    private String comment;

    /** PENDING / SUBMITTED */
    private String status;

    /** 是否盲审 */
    private Integer blind;

    private LocalDateTime assignTime;

    private LocalDateTime submitTime;

    private LocalDateTime createTime;

    private LocalDateTime updateTime;

    @TableLogic
    private Integer deleted;

    // ---------------------------------------------------- 展示用（不落库）
    @TableField(exist = false)
    private String thesisTitle;

    @TableField(exist = false)
    private String studentName;

    @TableField(exist = false)
    private String studentNo;

    @TableField(exist = false)
    private String reviewerName;

    @TableField(exist = false)
    private String grade;

    @TableField(exist = false)
    private String fileUrl;
}
