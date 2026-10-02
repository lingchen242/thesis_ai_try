package com.example.thesis.storage;

import com.example.thesis.common.BizException;
import com.example.thesis.config.StorageProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

/**
 * 本地静态目录存储实现。
 * <p>落盘规则：{@code {localPath}/{业务类型}/{yyyyMM}/{uuid}.{ext}}
 * 访问路径：{@code {urlPrefix}/{业务类型}/{yyyyMM}/{uuid}.{ext}}，
 * 由 {@code WebMvcConfig} 映射为静态资源，前端可直接用该路径预览/下载。
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class LocalStorageService implements StorageService {

    private static final DateTimeFormatter MONTH_DIR = DateTimeFormatter.ofPattern("yyyyMM");
    private static final Set<String> KNOWN_BIZ =
            Set.of("PROPOSAL", "MIDTERM", "FINAL", "OTHER");

    private final StorageProperties properties;

    @Override
    public String driver() {
        return "local";
    }

    @Override
    public StoredFile store(MultipartFile file, String bizType) {
        if (file == null || file.isEmpty()) {
            throw BizException.file("上传文件为空");
        }
        if (file.getSize() > properties.getMaxFileSize()) {
            throw BizException.file(String.format("文件超过大小限制（最大 %d MB）",
                    properties.getMaxFileSize() / 1024 / 1024));
        }
        String original = StringUtils.hasText(file.getOriginalFilename())
                ? Paths.get(file.getOriginalFilename()).getFileName().toString()
                : "unnamed";
        String ext = extractExt(original);
        if (!properties.isAllowedExt(ext)) {
            throw BizException.file("不支持的文件类型：" + (ext.isEmpty() ? "无扩展名" : ext)
                    + "，允许：" + String.join("/", properties.getAllowedExt()));
        }

        String biz = KNOWN_BIZ.contains(bizType) ? bizType : "OTHER";
        String month = LocalDate.now().format(MONTH_DIR);
        String storedName = UUID.randomUUID().toString().replace("-", "") + "." + ext.toLowerCase(Locale.ROOT);

        Path root = Paths.get(properties.getLocalPath()).toAbsolutePath().normalize();
        Path targetDir = root.resolve(biz.toLowerCase(Locale.ROOT)).resolve(month).normalize();
        if (!targetDir.startsWith(root)) {
            throw BizException.file("非法的存储路径");
        }
        try {
            Files.createDirectories(targetDir);
            Path target = targetDir.resolve(storedName);
            try (InputStream in = file.getInputStream()) {
                Files.copy(in, target, StandardCopyOption.REPLACE_EXISTING);
            }
        } catch (IOException e) {
            log.error("保存文件失败: {}", targetDir, e);
            throw BizException.file("文件保存失败：" + e.getMessage());
        }

        String url = String.join("/", properties.getUrlPrefix(), biz.toLowerCase(Locale.ROOT), month, storedName);
        return new StoredFile(original, url, file.getSize(), file.getContentType());
    }

    @Override
    public void delete(String fileUrl) {
        if (!StringUtils.hasText(fileUrl)) {
            return;
        }
        String prefix = properties.getUrlPrefix();
        if (!fileUrl.startsWith(prefix)) {
            log.warn("跳过删除：路径不在本地存储范围内 {}", fileUrl);
            return;
        }
        String relative = fileUrl.substring(prefix.length());
        Path root = Paths.get(properties.getLocalPath()).toAbsolutePath().normalize();
        Path target = root.resolve(relative.startsWith("/") ? relative.substring(1) : relative).normalize();
        if (!target.startsWith(root)) {
            log.warn("跳过删除：路径越界 {}", fileUrl);
            return;
        }
        try {
            Files.deleteIfExists(target);
        } catch (IOException e) {
            log.warn("删除文件失败: {}", target, e);
        }
    }

    private String extractExt(String fileName) {
        int idx = fileName.lastIndexOf('.');
        return idx < 0 ? "" : fileName.substring(idx + 1);
    }
}
