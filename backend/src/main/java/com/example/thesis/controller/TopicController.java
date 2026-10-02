package com.example.thesis.controller;

import com.example.thesis.common.PageResult;
import com.example.thesis.common.R;
import com.example.thesis.dto.PageQuery;
import com.example.thesis.dto.Requests;
import com.example.thesis.entity.Selection;
import com.example.thesis.entity.Topic;
import com.example.thesis.service.SelectionService;
import com.example.thesis.service.TopicService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * 课题与选题接口。
 */
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class TopicController {

    private final TopicService topicService;
    private final SelectionService selectionService;

    // ======================================================= 课题
    @GetMapping("/topics")
    public R<PageResult<Topic>> pageTopics(PageQuery query,
                                           @RequestParam(required = false) String status,
                                           @RequestParam(required = false) String grade,
                                           @RequestParam(required = false) String major,
                                           @RequestParam(required = false) Long teacherId,
                                           @RequestParam(required = false) Boolean onlyOpen) {
        return R.ok(topicService.page(query, status, grade, major, teacherId, onlyOpen));
    }

    @GetMapping("/topics/{id}")
    public R<Topic> topicDetail(@PathVariable Long id) {
        return R.ok(topicService.detail(id));
    }

    @PostMapping("/topics")
    public R<Topic> createTopic(@RequestBody Topic topic) {
        topic.setId(null);
        return R.ok(topicService.save(topic));
    }

    @PutMapping("/topics/{id}")
    public R<Topic> updateTopic(@PathVariable Long id, @RequestBody Topic topic) {
        topic.setId(id);
        return R.ok(topicService.save(topic));
    }

    @PostMapping("/topics/{id}/publish")
    public R<Void> publish(@PathVariable Long id) {
        topicService.publish(id);
        return R.ok();
    }

    @PostMapping("/topics/{id}/close")
    public R<Void> close(@PathVariable Long id) {
        topicService.close(id);
        return R.ok();
    }

    @DeleteMapping("/topics/{id}")
    public R<Void> deleteTopic(@PathVariable Long id) {
        topicService.delete(id);
        return R.ok();
    }

    // ======================================================= 选题申请
    @GetMapping("/selections")
    public R<PageResult<Selection>> pageSelections(PageQuery query,
                                                   @RequestParam(required = false) String status,
                                                   @RequestParam(required = false) Long topicId,
                                                   @RequestParam(required = false) String grade) {
        return R.ok(selectionService.page(query, status, topicId, grade));
    }

    /** 学生查看自己的选题申请 */
    @GetMapping("/selections/mine")
    public R<Selection> mySelection() {
        return R.ok(selectionService.myApplication());
    }

    /** 学生申报课题 */
    @PostMapping("/selections")
    public R<Selection> apply(@Valid @RequestBody Requests.SelectionApply req) {
        return R.ok(selectionService.apply(req));
    }

    @PostMapping("/selections/{id}/approve")
    public R<Void> approve(@PathVariable Long id,
                           @RequestBody(required = false) Requests.SelectionDecision req) {
        selectionService.approve(id, req == null ? null : req.comment());
        return R.ok();
    }

    @PostMapping("/selections/{id}/reject")
    public R<Void> reject(@PathVariable Long id,
                          @RequestBody(required = false) Requests.SelectionDecision req) {
        selectionService.reject(id, req == null ? null : req.comment());
        return R.ok();
    }
}
