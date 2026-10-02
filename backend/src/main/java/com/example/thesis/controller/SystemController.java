package com.example.thesis.controller;

import com.example.thesis.common.R;
import com.example.thesis.entity.SysConfig;
import com.example.thesis.entity.SysDictItem;
import com.example.thesis.entity.SysDictType;
import com.example.thesis.service.ImportService;
import com.example.thesis.service.SystemService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;

/**
 * 系统管理接口：字典 / 系统配置 / 账号批量导入。
 */
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class SystemController {

    private final SystemService systemService;
    private final ImportService importService;

    // ======================================================= 字典类型
    @GetMapping("/dict/types")
    public R<List<SysDictType>> listTypes() {
        return R.ok(systemService.listTypes());
    }

    @PostMapping("/dict/types")
    @PreAuthorize("hasRole('ADMIN')")
    public R<SysDictType> createType(@RequestBody SysDictType type) {
        type.setId(null);
        return R.ok(systemService.saveType(type));
    }

    @PutMapping("/dict/types/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public R<SysDictType> updateType(@PathVariable Long id, @RequestBody SysDictType type) {
        type.setId(id);
        return R.ok(systemService.saveType(type));
    }

    @DeleteMapping("/dict/types/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public R<Void> deleteType(@PathVariable Long id) {
        systemService.deleteType(id);
        return R.ok();
    }

    // ======================================================= 字典项
    /**
     * 字典项查询。
     *
     * @param typeCode    类型编码，必填
     * @param parentId    父级 id，传 0 表示只取顶级
     * @param onlyEnabled 只返回启用项（下拉框用）
     * @param asTree      是否返回树形（字典管理页用）
     */
    @GetMapping("/dict/items")
    public R<List<SysDictItem>> listItems(@RequestParam String typeCode,
                                          @RequestParam(required = false) Long parentId,
                                          @RequestParam(required = false) Boolean onlyEnabled,
                                          @RequestParam(required = false) Boolean asTree) {
        if (Boolean.TRUE.equals(asTree)) {
            return R.ok(systemService.tree(typeCode));
        }
        if (parentId != null && parentId == 0L) {
            // parentId = 0 表示「只取顶级」
            return R.ok(systemService.listItems(typeCode, null, onlyEnabled).stream()
                    .filter(item -> item.getParentId() == null)
                    .toList());
        }
        return R.ok(systemService.listItems(typeCode, parentId, onlyEnabled));
    }

    @PostMapping("/dict/items")
    @PreAuthorize("hasRole('ADMIN')")
    public R<SysDictItem> createItem(@RequestBody SysDictItem item) {
        item.setId(null);
        return R.ok(systemService.saveItem(item));
    }

    @PutMapping("/dict/items/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public R<SysDictItem> updateItem(@PathVariable Long id, @RequestBody SysDictItem item) {
        item.setId(id);
        return R.ok(systemService.saveItem(item));
    }

    @DeleteMapping("/dict/items/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public R<Void> deleteItem(@PathVariable Long id) {
        systemService.deleteItem(id);
        return R.ok();
    }

    // ======================================================= 系统配置
    @GetMapping("/configs")
    public R<List<SysConfig>> listConfigs() {
        return R.ok(systemService.listConfigs());
    }

    @PutMapping("/configs")
    @PreAuthorize("hasRole('ADMIN')")
    public R<Void> updateConfigs(@RequestBody List<SysConfig> configs) {
        systemService.updateConfigs(configs);
        return R.ok();
    }

    // ======================================================= 批量导入
    @GetMapping("/import/template")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<byte[]> template() {
        byte[] bytes = importService.buildTemplate();
        String fileName = URLEncoder.encode("账号导入模板.xlsx", StandardCharsets.UTF_8);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename*=UTF-8''" + fileName)
                .contentType(MediaType.parseMediaType(
                        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                .body(bytes);
    }

    @PostMapping("/import/users")
    @PreAuthorize("hasRole('ADMIN')")
    public R<Map<String, Object>> importUsers(@RequestPart("file") MultipartFile file) {
        return R.ok(importService.importUsers(file));
    }
}
