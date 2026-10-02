package com.example.thesis.common;

import lombok.Getter;

/**
 * 业务异常：由 GlobalExceptionHandler 统一转换为 R。
 */
@Getter
public class BizException extends RuntimeException {

    private final int code;

    public BizException(String message) {
        super(message);
        this.code = ErrorCode.BIZ_ERROR;
    }

    public BizException(int code, String message) {
        super(message);
        this.code = code;
    }

    public static BizException flow(String message) {
        return new BizException(ErrorCode.FLOW_ERROR, message);
    }

    public static BizException notFound(String message) {
        return new BizException(ErrorCode.NOT_FOUND, message);
    }

    public static BizException param(String message) {
        return new BizException(ErrorCode.PARAM_ERROR, message);
    }

    public static BizException file(String message) {
        return new BizException(ErrorCode.FILE_ERROR, message);
    }
}
