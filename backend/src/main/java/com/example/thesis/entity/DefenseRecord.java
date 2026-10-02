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
 * 答辩成绩 defense_record。
 */
@Data
@TableName("defense_record")
public class DefenseRecord implements Serializable {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long thesisId;

    private Long groupId;

    private BigDecimal score;

    /** PASS / DEFER / FAIL */
    private String result;

    private String comment;

    private Long recordedBy;

    private LocalDateTime recordedTime;

    private LocalDateTime createTime;

    private LocalDateTime updateTime;

    @TableLogic
    private Integer deleted;

    // ---------------------------------------------------- 展示用（不落库）
    @TableField(exist = false)
    private String thesisTitle;

    @TableField(exist = false)
    private String studentName;

    @TableField(exist = false)
    private String studentNo;

    @TableField(exist = false)
    private String groupName;

    @TableField(exist = false)
    private String grade;
}
