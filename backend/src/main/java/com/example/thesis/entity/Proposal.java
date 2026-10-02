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
 * 开题报告 proposal。
 */
@Data
@TableName("proposal")
public class Proposal implements Serializable {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long thesisId;

    private String content;

    /** 附件 id，逗号分隔 */
    private String attachmentIds;

    private LocalDateTime submitTime;

    /** PENDING / APPROVED / REJECTED */
    private String reviewStatus;

    private String reviewComment;

    /** 审核人 teacher.id */
    private Long reviewerId;

    private LocalDateTime reviewTime;

    private BigDecimal score;

    private LocalDateTime createTime;

    private LocalDateTime updateTime;

    @TableLogic
    private Integer deleted;

    // ---------------------------------------------------- 展示用（不落库）
    @TableField(exist = false)
    private String studentName;

    @TableField(exist = false)
    private String studentNo;

    @TableField(exist = false)
    private String thesisTitle;

    @TableField(exist = false)
    private String advisorName;

    @TableField(exist = false)
    private String reviewerName;
}
