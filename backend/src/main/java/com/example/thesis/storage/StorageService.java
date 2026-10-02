package com.example.thesis.storage;

import org.springframework.web.multipart.MultipartFile;

/**
 * 文件存储抽象。
 * <p>当前只提供 {@link LocalStorageService}（本地静态目录）。若将来接入云端，
 * 新增一个实现类并在配置中切换 {@code thesis.storage.driver} 即可，业务代码无需改动。
 */
public interface StorageService {

    /** 驱动标识：local / cloud */
    String driver();

    /**
     * 保存文件。
     *
     * @param file    上传文件
     * @param bizType 业务类型，决定子目录（PROPOSAL / MIDTERM / FINAL / OTHER）
     * @return 保存结果
     */
    StoredFile store(MultipartFile file, String bizType);

    /** 按相对访问路径删除文件，忽略不存在的文件 */
    void delete(String fileUrl);

    /**
     * 保存结果。
     *
     * @param fileName  原始文件名
     * @param fileUrl   相对访问路径，如 /uploads/proposal/202610/uuid.pdf
     * @param size      字节数
     * @param mimeType  内容类型
     */
    record StoredFile(String fileName, String fileUrl, long size, String mimeType) {
    }
}
