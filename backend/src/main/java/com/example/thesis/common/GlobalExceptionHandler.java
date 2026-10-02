package com.example.thesis.common;

import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.validation.BindException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.multipart.MaxUploadSizeExceededException;

import java.util.stream.Collectors;

/**
 * 全局异常处理：所有异常统一转换为 {@link R} 结构（HTTP 状态码保持 200），
 * 前端只需判断 body 中的 code 字段。
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(BizException.class)
    public R<Void> handleBiz(BizException e) {
        log.warn("业务异常: {}", e.getMessage());
        return R.fail(e.getCode(), e.getMessage());
    }

    @ExceptionHandler({MethodArgumentNotValidException.class, BindException.class})
    public R<Void> handleValidation(BindException e) {
        String msg = e.getBindingResult().getFieldErrors().stream()
                .map(f -> f.getField() + ": " + defaultMessage(f))
                .collect(Collectors.joining("；"));
        return R.fail(ErrorCode.PARAM_ERROR, msg.isEmpty() ? "参数校验失败" : msg);
    }

    @ExceptionHandler(MaxUploadSizeExceededException.class)
    public R<Void> handleUploadSize(MaxUploadSizeExceededException e) {
        return R.fail(ErrorCode.FILE_ERROR, "上传文件超过大小限制");
    }

    @ExceptionHandler(AccessDeniedException.class)
    public R<Void> handleAccessDenied(AccessDeniedException e) {
        return R.fail(ErrorCode.FORBIDDEN, "无权限访问该资源");
    }

    @ExceptionHandler(AuthenticationException.class)
    public R<Void> handleAuth(AuthenticationException e) {
        return R.fail(ErrorCode.UNAUTHORIZED, "登录状态已失效，请重新登录");
    }

    @ExceptionHandler(Exception.class)
    public R<Void> handleOther(Exception e) {
        log.error("系统异常", e);
        String msg = e.getMessage() == null ? e.getClass().getSimpleName() : e.getMessage();
        return R.fail(ErrorCode.SERVER_ERROR, "服务异常：" + msg);
    }

    private String defaultMessage(FieldError f) {
        return f.getDefaultMessage() == null ? "非法值" : f.getDefaultMessage();
    }
}
