package com.example.thesis.common;

import lombok.Data;

import java.io.Serializable;

/**
 * 统一响应体：{ "code": 0, "message": "ok", "data": ... }
 */
@Data
public class R<T> implements Serializable {

    /** 0 表示成功，非 0 为业务错误码 */
    private int code;
    private String message;
    private T data;

    public static <T> R<T> ok() {
        return ok(null);
    }

    public static <T> R<T> ok(T data) {
        R<T> r = new R<>();
        r.code = 0;
        r.message = "ok";
        r.data = data;
        return r;
    }

    public static <T> R<T> fail(String message) {
        return fail(ErrorCode.BIZ_ERROR, message);
    }

    public static <T> R<T> fail(int code, String message) {
        R<T> r = new R<>();
        r.code = code;
        r.message = message;
        return r;
    }
}
