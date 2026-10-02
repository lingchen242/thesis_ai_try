package com.example.thesis.security;

import lombok.Getter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.List;

/**
 * 登录用户上下文对象。
 */
@Getter
public class LoginUser implements UserDetails {

    private final Long id;
    private final String username;
    private final String password;
    private final String realName;
    /** STUDENT / ADVISOR / REVIEWER / ADMIN */
    private final String role;
    private final boolean enabled;

    public LoginUser(Long id, String username, String password, String realName, String role, boolean enabled) {
        this.id = id;
        this.username = username;
        this.password = password;
        this.realName = realName;
        this.role = role;
        this.enabled = enabled;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return List.of(new SimpleGrantedAuthority("ROLE_" + role));
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return true;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }
}
