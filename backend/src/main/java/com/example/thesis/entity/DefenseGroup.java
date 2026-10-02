package com.example.thesis.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 答辩组 defense_group。
 */
@Data
@TableName("defense_group")
public class DefenseGroup implements Serializable {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String name;

    private String grade;

    private String college;

    private LocalDateTime defenseDate;

    private String location;

    /** 答辩秘书 teacher.id */
    private Long secretaryId;

    /** PLANNED / FINISHED */
    private String status;

    private String remark;

    private LocalDateTime createTime;

    private LocalDateTime updateTime;

    @TableLogic
    private Integer deleted;

    // ---------------------------------------------------- 展示用（不落库）
    @TableField(exist = false)
    private String secretaryName;

    @TableField(exist = false)
    private List<DefenseGroupMember> members;

    @TableField(exist = false)
    private Integer memberCount;

    @TableField(exist = false)
    private Integer thesisCount;
}
