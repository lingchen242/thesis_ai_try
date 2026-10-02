package com.example.thesis.controller;

import com.example.thesis.common.Constants;
import com.example.thesis.common.R;
import com.example.thesis.dto.Requests;
import com.example.thesis.entity.Attachment;
import com.example.thesis.service.FileService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

/**
 * 附件接口。
 * <p>文件保存到本地静态目录 {@code backend/storage/uploads/{业务类型}/{yyyyMM}/}，
 * 返回的 fileUrl 形如 {@code /uploads/proposal/202610/xxx.pdf}，前端可直接用于预览下载。
 */
@RestController
@RequestMapping("/api/files")
@RequiredArgsConstructor
public class FileController {

    private final FileService fileService;

    /** 上传文件。bizType 取 PROPOSAL / MIDTERM / FINAL / OTHER */
    @PostMapping("/upload")
    public R<Attachment> upload(@RequestPart("file") MultipartFile file,
                               @RequestParam(defaultValue = Constants.BIZ_OTHER) String bizType) {
        return R.ok(fileService.upload(file, bizType));
    }

    /** 材料保存后，把已上传的附件绑定到具体业务记录 */
    @PostMapping("/bind")
    public R<Void> bind(@Valid @RequestBody Requests.FileBind req) {
        fileService.bind(req.bizType(), req.bizId(), req.ids());
        return R.ok();
    }

    @GetMapping
    public R<List<Attachment>> list(@RequestParam String bizType, @RequestParam Long bizId) {
        return R.ok(fileService.list(bizType, bizId));
    }

    /** 按 id 批量取附件（详情页展示，ids 用逗号分隔） */
    @GetMapping("/by-ids")
    public R<List<Attachment>> listByIds(@RequestParam String ids) {
        return R.ok(fileService.listByIds(ids));
    }

    @DeleteMapping("/{id}")
    public R<Void> delete(@PathVariable Long id) {
        fileService.delete(id);
        return R.ok();
    }
}
