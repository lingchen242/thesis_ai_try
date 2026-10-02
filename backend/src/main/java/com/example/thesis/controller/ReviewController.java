package com.example.thesis.controller;

import com.example.thesis.common.PageResult;
import com.example.thesis.common.R;
import com.example.thesis.dto.PageQuery;
import com.example.thesis.dto.Requests;
import com.example.thesis.entity.Review;
import com.example.thesis.service.ReviewService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 论文评阅接口。
 */
@RestController
@RequestMapping("/api/reviews")
@RequiredArgsConstructor
public class ReviewController {

    private final ReviewService reviewService;

    @GetMapping
    public R<PageResult<Review>> page(PageQuery query,
                                      @RequestParam(required = false) String status,
                                      @RequestParam(required = false) Long thesisId,
                                      @RequestParam(required = false) Long reviewerId,
                                      @RequestParam(required = false) String grade) {
        return R.ok(reviewService.page(query, status, thesisId, reviewerId, grade));
    }

    /** 评阅教师查看自己的任务 */
    @GetMapping("/mine")
    public R<List<Review>> mine(@RequestParam(required = false) Boolean onlyPending) {
        return R.ok(reviewService.mine(onlyPending));
    }

    /** 管理员指派评阅（不传 reviewerId 时自动挑选任务最少的评阅教师） */
    @PostMapping("/assign")
    public R<Review> assign(@Valid @RequestBody Requests.AssignReview req) {
        return R.ok(reviewService.assign(req));
    }

    /** 评阅教师提交评阅意见 */
    @PostMapping("/{id}/submit")
    public R<Review> submit(@PathVariable Long id, @RequestBody Requests.ReviewSubmit req) {
        return R.ok(reviewService.submit(id, req));
    }
}
