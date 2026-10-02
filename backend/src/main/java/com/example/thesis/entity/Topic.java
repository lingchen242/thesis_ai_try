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
 * 课题 topic。
 */
@Data
@TableName("topic")
public class Topic implements Serializable {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String title;

    /** 课题类型（字典 TOPIC_TYPE） */
    private String topicType;

    /** 课题来源（字典 TOPIC_SOURCE） */
    private String source;

    /** 出题教师 teacher.id */
    private Long teacherId;

    private String grade;

    private String college;

    private String major;

    private String description;

    private String requirement;

    private Integer capacity;

    private Integer selectedCount;

    /** DRAFT / OPEN / SELECTED / CLOSED */
    private String status;

    private LocalDateTime publishTime;

    private LocalDateTime createTime;

    private LocalDateTime updateTime;

    @TableLogic
    private Integer deleted;

    // ---------------------------------------------------- 展示用（不落库）
    @TableField(exist = false)
    private String teacherName;

    /** 已提交的选题申请数 */
    @TableField(exist = false)
    private Long applyCount;

    /** 当前学生是否已申请（学生端用） */
    @TableField(exist = false)
    private Boolean applied;
}
