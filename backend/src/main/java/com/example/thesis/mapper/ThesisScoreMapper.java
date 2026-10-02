package com.example.thesis.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.thesis.entity.ThesisScore;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

import java.util.List;
import java.util.Map;

@Mapper
public interface ThesisScoreMapper extends BaseMapper<ThesisScore> {

    /** 总评分段分布（看板柱状图用）：0-59 / 60-69 / ... / 90-100 */
    @Select("SELECT CASE "
            + "  WHEN total_score < 60 THEN '不及格' "
            + "  WHEN total_score < 70 THEN '60-69' "
            + "  WHEN total_score < 80 THEN '70-79' "
            + "  WHEN total_score < 90 THEN '80-89' "
            + "  ELSE '90-100' END AS bucket, COUNT(*) AS cnt "
            + "FROM thesis_score WHERE deleted = 0 AND total_score IS NOT NULL "
            + "GROUP BY bucket")
    List<Map<String, Object>> countByScoreBucket();

    @Select("SELECT AVG(total_score) FROM thesis_score WHERE deleted = 0 AND total_score IS NOT NULL")
    Double avgTotalScore();
}
