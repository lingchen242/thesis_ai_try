package com.example.thesis.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.thesis.entity.SysDictItem;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

import java.util.List;
import java.util.Map;

@Mapper
public interface SysDictItemMapper extends BaseMapper<SysDictItem> {

    /** 各级字典项数量统计 */
    @Select("SELECT type_code AS typeCode, COUNT(*) AS cnt FROM sys_dict_item GROUP BY type_code")
    List<Map<String, Object>> countByType();
}
