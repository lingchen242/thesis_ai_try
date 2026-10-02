package com.example.thesis.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;

import java.util.List;

/**
 * 跨域配置。
 */
@Data
@ConfigurationProperties(prefix = "thesis.cors")
public class CorsProperties {

    private List<String> allowedOrigins = List.of("http://localhost:5173", "http://127.0.0.1:5173");
}
