package com.example.thesis.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 字典类型 sys_dict_type。
 */
@Data
@TableName("sys_dict_type")
public class SysDictType implements Serializable {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 类型编码，如 COLLEGE / MAJOR / CLASS */
    private String typeCode;

    private String typeName;

    private String remark;

    private LocalDateTime createTime;

    private LocalDateTime updateTime;

    // ---------------------------------------------------- 展示用（不落库）
    @TableField(exist = false)
    private Integer itemCount;

    @TableField(exist = false)
    private List<SysDictItem> items;
}
