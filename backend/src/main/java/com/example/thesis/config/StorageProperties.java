package com.example.thesis.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;

import java.util.List;

/**
 * 文件存储配置。当前只启用 local 驱动，云端实现类预留。
 */
@Data
@ConfigurationProperties(prefix = "thesis.storage")
public class StorageProperties {

    /** 存储驱动：local（默认） / cloud（预留，未实现） */
    private String driver = "local";

    /** 本地存储根目录，相对后端工作目录 */
    private String localPath = "storage/uploads";

    /** 静态访问前缀 */
    private String urlPrefix = "/uploads";

    /** 单文件大小上限（字节） */
    private long maxFileSize = 20L * 1024 * 1024;

    /** 允许的扩展名（小写，不含点） */
    private List<String> allowedExt = List.of("pdf", "doc", "docx", "xls", "xlsx", "zip", "jpg", "jpeg", "png");

    public boolean isAllowedExt(String ext) {
        return ext != null && allowedExt.contains(ext.toLowerCase());
    }
}
