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
 * 选题申请 selection。
 */
@Data
@TableName("selection")
public class Selection implements Serializable {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long topicId;

    /** student.id */
    private Long studentId;

    /** PENDING / APPROVED / REJECTED */
    private String status;

    private String studentRemark;

    private String teacherComment;

    private LocalDateTime applyTime;

    private LocalDateTime handleTime;

    /** 处理人 teacher.id */
    private Long handlerId;

    private LocalDateTime createTime;

    private LocalDateTime updateTime;

    @TableLogic
    private Integer deleted;

    // ---------------------------------------------------- 展示用（不落库）
    @TableField(exist = false)
    private String topicTitle;

    @TableField(exist = false)
    private String studentName;

    @TableField(exist = false)
    private String studentNo;

    @TableField(exist = false)
    private String className;

    @TableField(exist = false)
    private String teacherName;

    @TableField(exist = false)
    private String grade;
}
