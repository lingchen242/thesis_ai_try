package com.example.thesis.controller;

import com.example.thesis.common.PageResult;
import com.example.thesis.common.R;
import com.example.thesis.dto.PageQuery;
import com.example.thesis.dto.Requests;
import com.example.thesis.entity.AuditLog;
import com.example.thesis.entity.FinalSubmission;
import com.example.thesis.entity.MidtermReport;
import com.example.thesis.entity.Proposal;
import com.example.thesis.entity.Thesis;
import com.example.thesis.service.MidtermService;
import com.example.thesis.service.ProposalService;
import com.example.thesis.service.ThesisService;
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
import java.util.Map;

/**
 * 论文主流程接口：论文 / 开题 / 中期 / 定稿。
 */
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class ThesisController {

    private final ThesisService thesisService;
    private final ProposalService proposalService;
    private final MidtermService midtermService;

    // ======================================================= 论文
    @GetMapping("/theses")
    public R<PageResult<Thesis>> pageTheses(PageQuery query,
                                            @RequestParam(required = false) String status,
                                            @RequestParam(required = false) String grade,
                                            @RequestParam(required = false) String college,
                                            @RequestParam(required = false) Long advisorId,
                                            @RequestParam(required = false) Long studentId) {
        return R.ok(thesisService.page(query, status, grade, college, advisorId, studentId));
    }

    /** 学生查看自己的论文 */
    @GetMapping("/theses/mine")
    public R<Thesis> myThesis() {
        return R.ok(thesisService.myThesis());
    }

    @GetMapping("/theses/{id}")
    public R<Thesis> thesisDetail(@PathVariable Long id) {
        return R.ok(thesisService.detail(id));
    }

    /** 详情页聚合数据：论文 + 时间轴 + 各阶段材料 + 成绩 */
    @GetMapping("/theses/{id}/detail")
    public R<Map<String, Object>> thesisBundle(@PathVariable Long id) {
        return R.ok(thesisService.detailBundle(id));
    }

    @GetMapping("/theses/{id}/timeline")
    public R<List<AuditLog>> timeline(@PathVariable Long id) {
        return R.ok(thesisService.timeline(id));
    }

    /** 通用状态流转（答辩安排、归档、退回等） */
    @PostMapping("/theses/{id}/transition")
    public R<Thesis> transition(@PathVariable Long id, @Valid @RequestBody Requests.Transition req) {
        return R.ok(thesisService.transition(id, req));
    }

    // ======================================================= 开题报告
    @GetMapping("/proposals")
    public R<PageResult<Proposal>> pageProposals(PageQuery query,
                                                 @RequestParam(required = false) Long thesisId,
                                                 @RequestParam(required = false) String reviewStatus) {
        return R.ok(proposalService.page(query, thesisId, reviewStatus));
    }

    /** 学生查看自己的开题报告 */
    @GetMapping("/proposals/mine")
    public R<Proposal> myProposal() {
        return R.ok(proposalService.myProposal());
    }

    /** 学生提交开题报告 */
    @PostMapping("/proposals")
    public R<Proposal> submitProposal(@RequestBody Proposal proposal) {
        return R.ok(proposalService.submit(proposal));
    }

    /** 指导教师审核开题报告 */
    @PostMapping("/proposals/{id}/review")
    public R<Proposal> reviewProposal(@PathVariable Long id,
                                      @Valid @RequestBody Requests.StageReview req) {
        return R.ok(proposalService.review(id, req));
    }

    // ======================================================= 中期报告
    @GetMapping("/midterms")
    public R<PageResult<MidtermReport>> pageMidterms(PageQuery query,
                                                     @RequestParam(required = false) Long thesisId,
                                                     @RequestParam(required = false) String reviewStatus) {
        return R.ok(midtermService.page(query, thesisId, reviewStatus));
    }

    @GetMapping("/midterms/mine")
    public R<MidtermReport> myMidterm() {
        return R.ok(midtermService.myReport());
    }

    /** 超期未提交预警名单 */
    @GetMapping("/midterms/alerts")
    public R<List<Map<String, Object>>> alerts(@RequestParam(required = false) String grade) {
        return R.ok(midtermService.alerts(grade));
    }

    @PostMapping("/midterms")
    public R<MidtermReport> submitMidterm(@RequestBody MidtermReport report) {
        return R.ok(midtermService.submit(report));
    }

    @PostMapping("/midterms/{id}/review")
    public R<MidtermReport> reviewMidterm(@PathVariable Long id,
                                          @Valid @RequestBody Requests.StageReview req) {
        return R.ok(midtermService.review(id, req));
    }

    // ======================================================= 定稿
    @GetMapping("/finals")
    public R<PageResult<FinalSubmission>> pageFinals(PageQuery query,
                                                     @RequestParam(required = false) String grade) {
        return R.ok(thesisService.pageFinals(query, grade));
    }

    /** 学生提交论文定稿 */
    @PostMapping("/finals")
    public R<FinalSubmission> submitFinal(@RequestBody FinalSubmission submission) {
        return R.ok(thesisService.submitFinal(submission));
    }
}
