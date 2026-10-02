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
 * 中期报告 midterm_report。
 */
@Data
@TableName("midterm_report")
public class MidtermReport implements Serializable {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long thesisId;

    /** 完成百分比 0-100 */
    private Integer progressPercent;

    private String content;

    private String attachmentIds;

    private LocalDateTime submitTime;

    /** PENDING / APPROVED / REJECTED */
    private String reviewStatus;

    private String reviewComment;

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
}
