package com.example.thesis.security;

import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 登出 Token 黑名单（内存实现）。
 * <p>单机部署够用；若将来多实例部署，替换为 Redis 即可。
 */
@Component
public class TokenBlacklist {

    private final Map<String, Long> expiredAt = new ConcurrentHashMap<>();

    public void add(String token, long ttlMillis) {
        purge();
        expiredAt.put(token, System.currentTimeMillis() + Math.max(ttlMillis, 1000L));
    }

    public boolean contains(String token) {
        Long exp = expiredAt.get(token);
        if (exp == null) {
            return false;
        }
        if (exp < System.currentTimeMillis()) {
            expiredAt.remove(token);
            return false;
        }
        return true;
    }

    private void purge() {
        long now = System.currentTimeMillis();
        if (expiredAt.size() < 512) {
            return;
        }
        expiredAt.entrySet().removeIf(e -> e.getValue() < now);
    }
}
