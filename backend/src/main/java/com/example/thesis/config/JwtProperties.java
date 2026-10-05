package com.example.thesis.config;

import jakarta.annotation.PostConstruct;
import lombok.Data;
import lombok.ToString;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.util.StringUtils;

import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.util.Base64;

/**
 * JWT 配置。
 *
 * <p>{@code thesis.jwt.secret} 不再提供默认值：未配置时在启动阶段随机生成一次，进程内保持一致。
 * 这样仓库里不存在任何可被利用的固定密钥，也避免「复制模板直接上线」。
 *
 * <p>注意：随机密钥每次重启都会变化，重启后旧 Token 立即失效。
 * 生产环境请通过 {@code application-local.yml} 或环境变量提供一个固定值。
 */
@Slf4j
@Data
@ConfigurationProperties(prefix = "thesis.jwt")
public class JwtProperties {

    /** HS256 要求密钥至少 32 字节 */
    private static final int MIN_SECRET_BYTES = 32;

    /** 随机密钥的原始字节数（Base64 编码后约 64 字符） */
    private static final int RANDOM_SECRET_BYTES = 48;

    /**
     * 签名密钥（HS256，长度需 >= 32 字节）。
     * <p>留空时由 {@link #getSecret()} 随机生成。
     */
    @ToString.Exclude
    private String secret;

    /** 过期时间（分钟） */
    private long expireMinutes = 720;

    /** 请求头名称 */
    private String header = "Authorization";

    /** Token 前缀 */
    private String prefix = "Bearer ";

    /** 运行时实际使用的密钥：配置了就用配置值，否则随机生成并缓存 */
    @ToString.Exclude
    private String runtimeSecret;

    @PostConstruct
    void init() {
        if (StringUtils.hasText(secret)) {
            this.runtimeSecret = validate(secret.trim());
            log.info("JWT 签名密钥来源：配置项 thesis.jwt.secret（{} 字节）",
                    this.runtimeSecret.getBytes(StandardCharsets.UTF_8).length);
        } else {
            this.runtimeSecret = generateRandomSecret();
            log.warn("未配置 thesis.jwt.secret，已随机生成签名密钥："
                    + "本次进程内有效，重启后旧 Token 将失效。"
                    + "生产环境请在 application-local.yml 或环境变量中配置固定值");
        }
    }

    /**
     * 供 {@code JwtUtil} 使用：优先取配置值，否则取运行时随机生成的密钥。
     * <p>配置值长度不足时直接抛异常，避免用一个弱密钥继续签发 Token。
     */
    public String getSecret() {
        if (StringUtils.hasText(secret)) {
            return validate(secret.trim());
        }
        if (!StringUtils.hasText(runtimeSecret)) {
            // 兜底：正常情况下 init() 已赋值，这里防止初始化顺序异常时拿到 null
            this.runtimeSecret = generateRandomSecret();
        }
        return runtimeSecret;
    }

    private String validate(String value) {
        int length = value.getBytes(StandardCharsets.UTF_8).length;
        if (length < MIN_SECRET_BYTES) {
            throw new IllegalStateException("thesis.jwt.secret 长度不足 " + MIN_SECRET_BYTES
                    + " 字节，无法用于 HS256 签名，请配置更长的随机字符串");
        }
        return value;
    }

    private String generateRandomSecret() {
        byte[] bytes = new byte[RANDOM_SECRET_BYTES];
        new SecureRandom().nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }
}
