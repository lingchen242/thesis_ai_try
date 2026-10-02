package com.example.thesis.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.thesis.entity.Student;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

import java.util.List;
import java.util.Map;

@Mapper
public interface StudentMapper extends BaseMapper<Student> {

    /** 每位指导教师的在指导学生数 */
    @Select("SELECT advisor_id AS advisorId, COUNT(*) AS cnt FROM student "
            + "WHERE deleted = 0 AND advisor_id IS NOT NULL GROUP BY advisor_id")
    List<Map<String, Object>> countByAdvisor();

    /** 各届别学生数 */
    @Select("SELECT grade AS grade, COUNT(*) AS cnt FROM student WHERE deleted = 0 GROUP BY grade")
    List<Map<String, Object>> countByGrade();
}
