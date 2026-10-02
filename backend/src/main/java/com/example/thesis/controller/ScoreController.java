package com.example.thesis.controller;

import com.example.thesis.common.PageResult;
import com.example.thesis.common.R;
import com.example.thesis.dto.PageQuery;
import com.example.thesis.entity.ThesisScore;
import com.example.thesis.service.ScoreService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * 成绩查询与重算接口。
 */
@RestController
@RequestMapping("/api/scores")
@RequiredArgsConstructor
public class ScoreController {

    private final ScoreService scoreService;

    @GetMapping
    public R<PageResult<ThesisScore>> page(PageQuery query,
                                           @RequestParam(required = false) String grade,
                                           @RequestParam(required = false) String college,
                                           @RequestParam(required = false) String major) {
        return R.ok(scoreService.page(query, grade, college, major));
    }

    @GetMapping("/{thesisId}")
    public R<ThesisScore> getByThesis(@PathVariable Long thesisId) {
        return R.ok(scoreService.getByThesis(thesisId));
    }

    /** 管理员手动重算总评（权重调整后使用） */
    @PostMapping("/{thesisId}/recompute")
    @PreAuthorize("hasRole('ADMIN')")
    public R<ThesisScore> recompute(@PathVariable Long thesisId) {
        return R.ok(scoreService.recompute(thesisId));
    }
}
