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
 * 字典项 sys_dict_item。
 * <p>通过 parentId 支持树形：学院(COLLEGE) → 专业(MAJOR) → 班级(CLASS)。
 */
@Data
@TableName("sys_dict_item")
public class SysDictItem implements Serializable {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String typeCode;

    /** 项目编码，同一 typeCode 内唯一 */
    private String itemCode;

    /** 项目名称，业务表冗余存储该名称 */
    private String itemName;

    /** 上级字典项 id，顶级为 null */
    private Long parentId;

    private Integer sortNo;

    private Integer status;

    private String remark;

    private LocalDateTime createTime;

    private LocalDateTime updateTime;

    // ---------------------------------------------------- 展示用（不落库）
    @TableField(exist = false)
    private String parentName;

    @TableField(exist = false)
    private List<SysDictItem> children;
}
