package com.example.thesis.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.thesis.entity.Thesis;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

import java.util.List;
import java.util.Map;

@Mapper
public interface ThesisMapper extends BaseMapper<Thesis> {

    /** 按状态统计数量（看板用） */
    @Select("SELECT status AS status, COUNT(*) AS cnt FROM thesis WHERE deleted = 0 GROUP BY status")
    List<Map<String, Object>> countByStatus();

    /** 按届别统计总数与完成数（看板用） */
    @Select("SELECT grade AS grade, COUNT(*) AS total, "
            + "SUM(CASE WHEN status IN ('DEFENSE_DONE','ARCHIVED') THEN 1 ELSE 0 END) AS finished "
            + "FROM thesis WHERE deleted = 0 GROUP BY grade ORDER BY grade")
    List<Map<String, Object>> countByGrade();
}
