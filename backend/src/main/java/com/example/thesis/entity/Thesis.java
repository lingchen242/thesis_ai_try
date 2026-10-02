package com.example.thesis.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 论文主表 thesis。状态流转规则见 {@code domain.ThesisStatus}。
 */
@Data
@TableName("thesis")
public class Thesis implements Serializable {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** student.id，一名学生一篇 */
    private Long studentId;

    private Long topicId;

    /** 指导教师 teacher.id */
    private Long advisorId;

    private String title;

    private String grade;

    private String college;

    private String major;

    /**
     * DRAFT / PROPOSAL_SUBMITTED / PROPOSAL_APPROVED / MIDTERM_SUBMITTED / MIDTERM_PASSED /
     * FINAL_SUBMITTED / REVIEWING / REVIEW_PASSED / DEFENSE_SCHEDULED / DEFENSE_DONE / ARCHIVED
     */
    private String status;

    private String currentStage;

    private LocalDateTime startTime;

    private LocalDateTime submitTime;

    private LocalDateTime archiveTime;

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
    private String className;

    @TableField(exist = false)
    private String advisorName;

    @TableField(exist = false)
    private String topicType;

    @TableField(exist = false)
    private String statusLabel;

    @TableField(exist = false)
    private Long totalScore;

    @TableField(exist = false)
    private String reviewerName;

    @TableField(exist = false)
    private String reviewStatus;
}
