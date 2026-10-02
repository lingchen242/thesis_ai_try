package com.example.thesis.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 附件 attachment。fileUrl 存相对路径，实际文件在本地静态目录。
 */
@Data
@TableName("attachment")
public class Attachment implements Serializable {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** PROPOSAL / MIDTERM / FINAL / OTHER */
    private String bizType;

    private Long bizId;

    private String fileName;

    /** 如 /uploads/proposal/202610/uuid.pdf */
    private String fileUrl;

    private Long fileSize;

    private String mimeType;

    /** local（默认） / cloud（预留） */
    private String storageDriver;

    private Long uploaderId;

    private LocalDateTime createTime;

    private LocalDateTime updateTime;

    @TableLogic
    private Integer deleted;
}
