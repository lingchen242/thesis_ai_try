package com.example.thesis.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 系统配置 sys_config。评分权重、各阶段截止时间等。
 */
@Data
@TableName("sys_config")
public class SysConfig implements Serializable {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String configKey;

    private String configValue;

    private String remark;

    private LocalDateTime createTime;

    private LocalDateTime updateTime;
}
