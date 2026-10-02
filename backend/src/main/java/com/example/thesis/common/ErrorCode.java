package com.example.thesis.common;

/**
 * 业务错误码。
 */
public final class ErrorCode {

    private ErrorCode() {
    }

    /** 通用业务错误 */
    public static final int BIZ_ERROR = 1000;
    /** 参数校验失败 */
    public static final int PARAM_ERROR = 1001;
    /** 未登录 / Token 失效 */
    public static final int UNAUTHORIZED = 401;
    /** 无权限 */
    public static final int FORBIDDEN = 403;
    /** 资源不存在 */
    public static final int NOT_FOUND = 404;
    /** 状态流转非法 */
    public static final int FLOW_ERROR = 1002;
    /** 文件相关错误 */
    public static final int FILE_ERROR = 1003;
    /** 服务内部错误 */
    public static final int SERVER_ERROR = 500;
}
