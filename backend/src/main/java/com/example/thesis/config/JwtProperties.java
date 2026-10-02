package com.example.thesis.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * JWT 配置。
 */
@Data
@ConfigurationProperties(prefix = "thesis.jwt")
public class JwtProperties {

    /** 签名密钥（HS256，长度需 >= 32 字符） */
    private String secret = "thesis-management-demo-secret-key-please-change";

    /** 过期时间（分钟） */
    private long expireMinutes = 720;

    /** 请求头名称 */
    private String header = "Authorization";

    /** Token 前缀 */
    private String prefix = "Bearer ";
}
