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
 * 论文定稿 final_submission。
 */
@Data
@TableName("final_submission")
public class FinalSubmission implements Serializable {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long thesisId;

    /** 相对访问路径，如 /uploads/final/202610/xxx.pdf */
    private String fileUrl;

    private String fileName;

    private Long fileSize;

    private Integer version;

    private String note;

    private LocalDateTime submitTime;

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
    private String statusLabel;
}
