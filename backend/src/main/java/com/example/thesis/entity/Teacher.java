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
 * 教师档案 teacher。
 */
@Data
@TableName("teacher")
public class Teacher implements Serializable {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long userId;

    private String teacherNo;

    private String realName;

    private Integer gender;

    /** 职称（字典 TITLE） */
    private String title;

    /** 学院（字典 COLLEGE） */
    private String college;

    /** 专业（字典 MAJOR） */
    private String major;

    /** ADVISOR / REVIEWER / BOTH */
    private String teacherType;

    private Integer canReview;

    private Integer maxQuota;

    private String phone;

    private String email;

    private LocalDateTime createTime;

    private LocalDateTime updateTime;

    @TableLogic
    private Integer deleted;

    // ---------------------------------------------------- 展示用（不落库）
    @TableField(exist = false)
    private String username;

    /** 当前在指导学生数 */
    @TableField(exist = false)
    private Long studentCount;
}
