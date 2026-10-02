package com.example.thesis.dto;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import lombok.Data;

/**
 * 分页查询基类。控制器通过 @ModelAttribute 或单独 @RequestParam 接收。
 */
@Data
public class PageQuery {

    private long pageNum = 1;
    private long pageSize = 10;
    /** 模糊搜索关键字 */
    private String keyword;

    public <T> Page<T> toPage() {
        long num = pageNum < 1 ? 1 : pageNum;
        long size = pageSize < 1 ? 10 : Math.min(pageSize, 200);
        return new Page<>(num, size);
    }
}
