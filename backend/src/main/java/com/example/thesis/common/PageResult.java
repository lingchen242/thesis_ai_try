package com.example.thesis.common;

import com.baomidou.mybatisplus.core.metadata.IPage;
import lombok.Data;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;
import java.util.function.Function;

/**
 * 分页结果。
 */
@Data
public class PageResult<T> implements Serializable {

    private long total;
    private long pageNum;
    private long pageSize;
    private List<T> records = new ArrayList<>();

    public static <T> PageResult<T> of(IPage<T> page) {
        PageResult<T> r = new PageResult<>();
        r.total = page.getTotal();
        r.pageNum = page.getCurrent();
        r.pageSize = page.getSize();
        r.records = page.getRecords();
        return r;
    }

    /** 把实体分页转换为 VO 分页 */
    public static <E, T> PageResult<T> of(IPage<E> page, Function<E, T> mapper) {
        PageResult<T> r = new PageResult<>();
        r.total = page.getTotal();
        r.pageNum = page.getCurrent();
        r.pageSize = page.getSize();
        r.records = page.getRecords().stream().map(mapper).toList();
        return r;
    }

    public static <T> PageResult<T> of(List<T> records, long total, long pageNum, long pageSize) {
        PageResult<T> r = new PageResult<>();
        r.total = total;
        r.pageNum = pageNum;
        r.pageSize = pageSize;
        r.records = records;
        return r;
    }
}
