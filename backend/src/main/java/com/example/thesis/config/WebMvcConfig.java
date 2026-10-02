package com.example.thesis.config;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * 本地静态文件映射：把 {@code storage/uploads} 目录挂到 {@code /uploads/**}。
 * <p>启动时自动创建目录，避免首次上传失败。
 */
@Slf4j
@Configuration
@RequiredArgsConstructor
public class WebMvcConfig implements WebMvcConfigurer {

    private final StorageProperties storageProperties;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        Path root = Paths.get(storageProperties.getLocalPath()).toAbsolutePath().normalize();
        try {
            Files.createDirectories(root);
        } catch (IOException e) {
            log.error("创建本地存储目录失败: {}", root, e);
        }
        String uri = root.toUri().toString();
        if (!uri.endsWith("/")) {
            uri = uri + "/";
        }
        String pattern = storageProperties.getUrlPrefix();
        if (!pattern.endsWith("/")) {
            pattern = pattern + "/";
        }
        registry.addResourceHandler(pattern + "**")
                .addResourceLocations(uri)
                .setCachePeriod(3600);
        log.info("本地静态资源映射: {}** -> {}", pattern, uri);
    }
}
