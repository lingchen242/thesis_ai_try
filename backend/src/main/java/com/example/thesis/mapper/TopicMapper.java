package com.example.thesis.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.thesis.entity.Topic;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Update;

@Mapper
public interface TopicMapper extends BaseMapper<Topic> {

    /**
     * 原子占用一个名额：把「判断是否满员」与「自增」合并为一条 SQL，
     * 由数据库行锁保证并发安全，避免两名教师同时录取导致超录。
     * <p>命中条件：课题未删除且已选人数小于容量。满员时一并把状态置为 SELECTED。
     *
     * <p><b>注意 SET 子句的书写顺序不可调整</b>：MySQL 对 SET 采用从左到右求值，
     * 后面的表达式引用已赋值的列会拿到「新值」；而标准 SQL 一律取原始值。
     * 这里把 {@code status} 放在 {@code selected_count} 之前，使两种语义下
     * {@code status} 都基于「自增前的原始值」计算，从而 {@code 原值 + 1 >= 容量} 的判断成立。
     * 若把顺序调换，MySQL 会按 {@code 原值 + 2} 判断，导致课题提前一个名额被标记为已选满。
     *
     * @param topicId 课题 ID
     * @return 受影响行数，0 表示名额已满（未抢到）
     */
    @Update("UPDATE topic SET "
            + "status = CASE WHEN selected_count + 1 >= capacity THEN 'SELECTED' ELSE status END, "
            + "selected_count = selected_count + 1 "
            + "WHERE id = #{topicId} AND deleted = 0 AND selected_count < capacity")
    int claimSeat(@Param("topicId") Long topicId);
}
