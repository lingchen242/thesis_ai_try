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
 * 论文成绩汇总 thesis_score。
 */
@Data
@TableName("thesis_score")
public class ThesisScore implements Serializable {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long thesisId;

    private BigDecimal proposalScore;

    private BigDecimal midtermScore;

    private BigDecimal reviewScore;

    private BigDecimal defenseScore;

    /** 加权总评 */
    private BigDecimal totalScore;

    private LocalDateTime computedTime;

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
    private String grade;

    @TableField(exist = false)
    private String college;

    @TableField(exist = false)
    private String major;

    @TableField(exist = false)
    private String advisorName;

    @TableField(exist = false)
    private String level;
}
