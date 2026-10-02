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
 * 学生档案 student。
 */
@Data
@TableName("student")
public class Student implements Serializable {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long userId;

    private String studentNo;

    private String realName;

    private Integer gender;

    /** 届别（字典 GRADE） */
    private String grade;

    /** 学院（字典 COLLEGE） */
    private String college;

    /** 专业（字典 MAJOR） */
    private String major;

    /** 班级（字典 CLASS） */
    private String className;

    /** 指导教师 teacher.id */
    private Long advisorId;

    private String phone;

    private String email;

    private LocalDateTime createTime;

    private LocalDateTime updateTime;

    @TableLogic
    private Integer deleted;

    // ---------------------------------------------------- 展示用（不落库）
    @TableField(exist = false)
    private String username;

    @TableField(exist = false)
    private String advisorName;

    /** 论文状态（冗余展示） */
    @TableField(exist = false)
    private String thesisStatus;
}
