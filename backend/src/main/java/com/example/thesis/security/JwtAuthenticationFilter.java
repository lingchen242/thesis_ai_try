package com.example.thesis.security;

import com.example.thesis.config.JwtProperties;
import com.example.thesis.entity.SysUser;
import com.example.thesis.mapper.SysUserMapper;
import io.jsonwebtoken.Claims;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.lang.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/**
 * JWT 认证过滤器：解析请求头中的 Token 并把用户放入 SecurityContext。
 * <p>每次请求都会回查用户状态，账号被禁用后已签发的 Token 立即失效。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtUtil jwtUtil;
    private final JwtProperties jwtProperties;
    private final TokenBlacklist tokenBlacklist;
    private final SysUserMapper sysUserMapper;

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest request,
                                    @NonNull HttpServletResponse response,
                                    @NonNull FilterChain filterChain) throws ServletException, IOException {
        String token = resolveToken(request);
        if (StringUtils.hasText(token)
                && !tokenBlacklist.contains(token)
                && SecurityContextHolder.getContext().getAuthentication() == null) {
            try {
                Claims claims = jwtUtil.parse(token);
                Long userId = Long.valueOf(claims.getSubject());
                SysUser user = sysUserMapper.selectById(userId);
                if (user != null && Integer.valueOf(1).equals(user.getStatus())) {
                    LoginUser loginUser = new LoginUser(user.getId(), user.getUsername(),
                            user.getPassword(), user.getRealName(), user.getRole(), true);
                    UsernamePasswordAuthenticationToken authentication =
                            new UsernamePasswordAuthenticationToken(loginUser, null, loginUser.getAuthorities());
                    authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                    SecurityContextHolder.getContext().setAuthentication(authentication);
                }
            } catch (Exception e) {
                log.debug("Token 校验失败: {}", e.getMessage());
            }
        }
        filterChain.doFilter(request, response);
    }

    public String resolveToken(HttpServletRequest request) {
        String header = request.getHeader(jwtProperties.getHeader());
        if (!StringUtils.hasText(header)) {
            return null;
        }
        String prefix = jwtProperties.getPrefix();
        if (StringUtils.hasText(prefix) && header.startsWith(prefix)) {
            return header.substring(prefix.length()).trim();
        }
        return header.trim();
    }
}
