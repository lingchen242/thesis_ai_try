package com.example.thesis.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.thesis.entity.Teacher;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

import java.util.List;

@Mapper
public interface TeacherMapper extends BaseMapper<Teacher> {

    /** 查询可被指派评阅的教师（reviewer 角色或标记 can_review=1） */
    @Select("SELECT * FROM teacher WHERE deleted = 0 AND (teacher_type = 'REVIEWER' OR can_review = 1) ORDER BY id")
    List<Teacher> selectReviewers();
}
