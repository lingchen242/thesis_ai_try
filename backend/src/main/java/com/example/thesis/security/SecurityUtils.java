package com.example.thesis.security;

import com.example.thesis.common.BizException;
import com.example.thesis.common.ErrorCode;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Arrays;

/**
 * 当前登录用户工具。
 */
public final class SecurityUtils {

    private SecurityUtils() {
    }

    public static LoginUser current() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof LoginUser loginUser) {
            return loginUser;
        }
        throw new BizException(ErrorCode.UNAUTHORIZED, "未登录或登录状态已失效");
    }

    public static Long userId() {
        return current().getId();
    }

    public static String role() {
        return current().getRole();
    }

    public static boolean isAdmin() {
        return "ADMIN".equals(role());
    }

    public static boolean hasRole(String... roles) {
        String current = role();
        return Arrays.asList(roles).contains(current);
    }

    /** 非指定角色则抛出 403 */
    public static void requireRole(String... roles) {
        if (!hasRole(roles)) {
            throw new BizException(ErrorCode.FORBIDDEN, "当前角色无权执行该操作");
        }
    }

    public static void requireAdmin() {
        requireRole("ADMIN");
    }
}
