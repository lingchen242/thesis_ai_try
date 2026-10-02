package com.example.thesis.controller;

import com.example.thesis.common.PageResult;
import com.example.thesis.common.R;
import com.example.thesis.dto.PageQuery;
import com.example.thesis.dto.Requests;
import com.example.thesis.entity.DefenseGroup;
import com.example.thesis.entity.DefenseRecord;
import com.example.thesis.entity.Thesis;
import com.example.thesis.service.DefenseService;
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

import java.util.List;
import java.util.Map;

/**
 * 答辩管理接口。
 */
@RestController
@RequestMapping("/api/defense")
@RequiredArgsConstructor
public class DefenseController {

    private final DefenseService defenseService;

    // ======================================================= 答辩组
    @GetMapping("/groups")
    public R<PageResult<DefenseGroup>> pageGroups(PageQuery query,
                                                  @RequestParam(required = false) String grade,
                                                  @RequestParam(required = false) String status) {
        return R.ok(defenseService.pageGroups(query, grade, status));
    }

    @GetMapping("/groups/{id}")
    public R<Map<String, Object>> groupDetail(@PathVariable Long id) {
        return R.ok(defenseService.groupDetail(id));
    }

    @PostMapping("/groups")
    public R<DefenseGroup> createGroup(@RequestBody DefenseGroup group) {
        group.setId(null);
        return R.ok(defenseService.saveGroup(group));
    }

    @PutMapping("/groups/{id}")
    public R<DefenseGroup> updateGroup(@PathVariable Long id, @RequestBody DefenseGroup group) {
        group.setId(id);
        return R.ok(defenseService.saveGroup(group));
    }

    @DeleteMapping("/groups/{id}")
    public R<Void> deleteGroup(@PathVariable Long id) {
        defenseService.deleteGroup(id);
        return R.ok();
    }

    @PostMapping("/groups/{id}/members")
    public R<Void> setMembers(@PathVariable Long id,
                              @Valid @RequestBody Requests.GroupMembers req) {
        defenseService.setMembers(id, req);
        return R.ok();
    }

    /** 可编入答辩组的论文（评阅已通过） */
    @GetMapping("/candidates")
    public R<List<Thesis>> candidates(@RequestParam(required = false) Long groupId) {
        return R.ok(defenseService.candidates(groupId));
    }

    @GetMapping("/groups/{id}/theses")
    public R<List<Thesis>> groupTheses(@PathVariable Long id) {
        return R.ok(defenseService.listGroupTheses(id));
    }

    /** 把论文编入答辩组 */
    @PostMapping("/groups/{id}/schedule")
    public R<Void> schedule(@PathVariable Long id, @RequestBody List<Long> thesisIds) {
        defenseService.schedule(id, thesisIds);
        return R.ok();
    }

    @DeleteMapping("/groups/theses/{thesisId}")
    public R<Void> removeThesis(@PathVariable Long thesisId) {
        defenseService.removeThesis(thesisId);
        return R.ok();
    }

    // ======================================================= 答辩成绩
    @GetMapping("/records")
    public R<PageResult<DefenseRecord>> pageRecords(PageQuery query,
                                                    @RequestParam(required = false) Long groupId,
                                                    @RequestParam(required = false) String grade,
                                                    @RequestParam(required = false) String result) {
        return R.ok(defenseService.pageRecords(query, groupId, grade, result));
    }

    @PostMapping("/records")
    public R<DefenseRecord> record(@Valid @RequestBody Requests.DefenseRecord req) {
        return R.ok(defenseService.record(req));
    }
}
