package com.example.thesis.controller;

import com.example.thesis.common.R;
import com.example.thesis.service.DashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

/**
 * 数据看板接口。返回内容随当前登录角色变化。
 */
@RestController
@RequestMapping("/api/dashboard")
@RequiredArgsConstructor
public class DashboardController {

    private final DashboardService dashboardService;

    /** 角色化总览：概览指标 + 阶段分布 + 成绩分布 + 待办 */
    @GetMapping("/overview")
    public R<Map<String, Object>> overview() {
        return R.ok(dashboardService.overview());
    }

    @GetMapping("/stages")
    public R<List<Map<String, Object>>> stages() {
        return R.ok(dashboardService.stageDistribution());
    }

    @GetMapping("/todos")
    public R<List<Map<String, Object>>> todos() {
        return R.ok(dashboardService.todos());
    }
}
