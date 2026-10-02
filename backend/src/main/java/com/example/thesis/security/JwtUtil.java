package com.example.thesis.security;

import com.example.thesis.config.JwtProperties;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

/**
 * JWT 签发与解析。
 */
@Component
@RequiredArgsConstructor
public class JwtUtil {

    private final JwtProperties jwtProperties;

    private SecretKey key() {
        return Keys.hmacShaKeyFor(jwtProperties.getSecret().getBytes(StandardCharsets.UTF_8));
    }

    public String generate(Long userId, String username, String role) {
        Date now = new Date();
        Date expire = new Date(now.getTime() + jwtProperties.getExpireMinutes() * 60_000L);
        return Jwts.builder()
                .setSubject(String.valueOf(userId))
                .claim("username", username)
                .claim("role", role)
                .setIssuedAt(now)
                .setExpiration(expire)
                .signWith(key(), SignatureAlgorithm.HS256)
                .compact();
    }

    /** 解析并校验签名与有效期，失败抛异常 */
    public Claims parse(String token) {
        return Jwts.parserBuilder()
                .setSigningKey(key())
                .build()
                .parseClaimsJws(token)
                .getBody();
    }

    /** 剩余有效毫秒数（用于黑名单过期清理） */
    public long remainMillis(String token) {
        try {
            Date exp = parse(token).getExpiration();
            return Math.max(0L, exp.getTime() - System.currentTimeMillis());
        } catch (Exception e) {
            return 0L;
        }
    }

    public long getExpireSeconds() {
        return jwtProperties.getExpireMinutes() * 60L;
    }
}
