package com.example.thesis.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.thesis.common.BizException;
import com.example.thesis.common.Constants;
import com.example.thesis.entity.Attachment;
import com.example.thesis.mapper.AttachmentMapper;
import com.example.thesis.security.SecurityUtils;
import com.example.thesis.storage.StorageService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.List;

/**
 * 附件管理：上传落到本地静态目录，数据库只登记相对路径。
 */
@Service
@RequiredArgsConstructor
public class FileService {

    private final AttachmentMapper attachmentMapper;
    private final StorageService storageService;

    /** 上传文件，返回附件记录（此时尚未绑定业务 ID） */
    public Attachment upload(MultipartFile file, String bizType) {
        String type = StringUtils.hasText(bizType) ? bizType.toUpperCase() : Constants.BIZ_OTHER;
        StorageService.StoredFile stored = storageService.store(file, type);

        Attachment attachment = new Attachment();
        attachment.setBizType(type);
        attachment.setBizId(0L);
        attachment.setFileName(stored.fileName());
        attachment.setFileUrl(stored.fileUrl());
        attachment.setFileSize(stored.size());
        attachment.setMimeType(stored.mimeType());
        attachment.setStorageDriver(storageService.driver());
        attachment.setUploaderId(SecurityUtils.userId());
        attachmentMapper.insert(attachment);
        return attachment;
    }

    /** 把已上传的附件绑定到具体业务记录（材料保存后调用） */
    public void bind(String bizType, Long bizId, List<Long> ids) {
        if (ids == null || ids.isEmpty() || bizId == null) {
            return;
        }
        for (Long id : ids) {
            Attachment attachment = attachmentMapper.selectById(id);
            if (attachment == null) {
                continue;
            }
            attachment.setBizType(bizType.toUpperCase());
            attachment.setBizId(bizId);
            attachmentMapper.updateById(attachment);
        }
    }

    public List<Attachment> list(String bizType, Long bizId) {
        if (!StringUtils.hasText(bizType) || bizId == null) {
            return List.of();
        }
        return attachmentMapper.selectList(new LambdaQueryWrapper<Attachment>()
                .eq(Attachment::getBizType, bizType.toUpperCase())
                .eq(Attachment::getBizId, bizId)
                .orderByAsc(Attachment::getId));
    }

    /** 按 id 批量取附件（详情页展示用） */
    public List<Attachment> listByIds(String idsText) {
        if (!StringUtils.hasText(idsText)) {
            return List.of();
        }
        List<Long> ids = new ArrayList<>();
        for (String part : idsText.split(",")) {
            String trimmed = part.trim();
            if (trimmed.isEmpty()) {
                continue;
            }
            try {
                ids.add(Long.parseLong(trimmed));
            } catch (NumberFormatException ignored) {
                // 忽略非法 id
            }
        }
        return ids.isEmpty() ? List.of() : attachmentMapper.selectBatchIds(ids);
    }

    /** 删除附件：先删文件再删记录 */
    public void delete(Long id) {
        Attachment attachment = attachmentMapper.selectById(id);
        if (attachment == null) {
            throw BizException.notFound("附件不存在");
        }
        storageService.delete(attachment.getFileUrl());
        attachmentMapper.deleteById(id);
    }
}
