package com.example.thesis.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.thesis.common.BizException;
import com.example.thesis.dto.Requests;
import com.example.thesis.entity.Student;
import com.example.thesis.entity.SysUser;
import com.example.thesis.entity.Teacher;
import com.example.thesis.mapper.StudentMapper;
import com.example.thesis.mapper.SysUserMapper;
import com.example.thesis.mapper.TeacherMapper;
import com.example.thesis.security.JwtUtil;
import com.example.thesis.security.LoginUser;
import com.example.thesis.security.SecurityUtils;
import com.example.thesis.security.TokenBlacklist;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 认证服务：登录、登出、当前用户资料、修改密码。
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final SysUserMapper sysUserMapper;
    private final StudentMapper studentMapper;
    private final TeacherMapper teacherMapper;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final TokenBlacklist tokenBlacklist;

    public Map<String, Object> login(Requests.Login req) {
        SysUser user = sysUserMapper.selectOne(new LambdaQueryWrapper<SysUser>()
                .eq(SysUser::getUsername, req.username().trim()));
        // 账号不存在与密码错误返回同一提示，避免账号枚举
        if (user == null || !passwordEncoder.matches(req.password(), user.getPassword())) {
            throw new BizException("账号或密码错误");
        }
        if (!Integer.valueOf(1).equals(user.getStatus())) {
            throw new BizException("账号已被禁用，请联系管理员");
        }

        user.setLastLoginTime(LocalDateTime.now());
        sysUserMapper.updateById(user);

        String token = jwtUtil.generate(user.getId(), user.getUsername(), user.getRole());
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("token", token);
        result.put("expireIn", jwtUtil.getExpireSeconds());
        result.putAll(loadProfile(user));
        return result;
    }

    public void logout(String token) {
        if (token != null && !token.isBlank()) {
            tokenBlacklist.add(token, jwtUtil.remainMillis(token));
        }
    }

    /** 当前登录用户的完整资料 */
    public Map<String, Object> currentProfile() {
        SysUser user = sysUserMapper.selectById(SecurityUtils.userId());
        if (user == null) {
            throw new BizException("账号不存在");
        }
        return loadProfile(user);
    }

    public void changePassword(Requests.ChangePassword req) {
        LoginUser loginUser = SecurityUtils.current();
        SysUser user = sysUserMapper.selectById(loginUser.getId());
        if (!passwordEncoder.matches(req.currentPassword(), user.getPassword())) {
            throw new BizException("当前密码不正确");
        }
        if (passwordEncoder.matches(req.newPassword(), user.getPassword())) {
            throw new BizException("新密码不能与当前密码相同");
        }
        SysUser update = new SysUser();
        update.setId(user.getId());
        update.setPassword(passwordEncoder.encode(req.newPassword()));
        sysUserMapper.updateById(update);
    }

    private Map<String, Object> loadProfile(SysUser user) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("user", user);
        map.put("student", studentMapper.selectOne(new LambdaQueryWrapper<Student>()
                .eq(Student::getUserId, user.getId()).last("LIMIT 1")));
        map.put("teacher", teacherMapper.selectOne(new LambdaQueryWrapper<Teacher>()
                .eq(Teacher::getUserId, user.getId()).last("LIMIT 1")));
        return map;
    }
}
