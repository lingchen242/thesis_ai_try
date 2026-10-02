package com.example.thesis.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 答辩组成员 defense_group_member。
 */
@Data
@TableName("defense_group_member")
public class DefenseGroupMember implements Serializable {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long groupId;

    private Long teacherId;

    /** CHAIR / MEMBER / SECRETARY */
    private String roleInGroup;

    private LocalDateTime createTime;

    // ---------------------------------------------------- 展示用（不落库）
    @TableField(exist = false)
    private String teacherName;

    @TableField(exist = false)
    private String title;

    @TableField(exist = false)
    private String college;
}
