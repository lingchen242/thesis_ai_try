package com.example.thesis.controller;

import com.example.thesis.common.R;
import com.example.thesis.dto.Requests;
import com.example.thesis.security.JwtAuthenticationFilter;
import com.example.thesis.service.AuthService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * 认证接口。
 */
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final JwtAuthenticationFilter jwtAuthenticationFilter;

    @PostMapping("/login")
    public R<Map<String, Object>> login(@Valid @RequestBody Requests.Login req) {
        return R.ok(authService.login(req));
    }

    @PostMapping("/logout")
    public R<Void> logout(HttpServletRequest request) {
        authService.logout(jwtAuthenticationFilter.resolveToken(request));
        return R.ok();
    }

    /** 当前登录用户资料（含学生 / 教师档案） */
    @GetMapping("/me")
    public R<Map<String, Object>> me() {
        return R.ok(authService.currentProfile());
    }

    @PutMapping("/password")
    public R<Void> changePassword(@Valid @RequestBody Requests.ChangePassword req) {
        authService.changePassword(req);
        return R.ok();
    }
}
