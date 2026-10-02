package com.example.thesis.domain;

import com.example.thesis.common.BizException;

import java.util.stream.Collectors;

/**
 * 流转守卫：所有论文状态变更必须经过这里。
 */
public final class FlowGuard {

    private FlowGuard() {
    }

    /**
     * 校验一次流转是否合法。
     *
     * @param fromCode 当前状态
     * @param toCode   目标状态
     * @param role     操作人角色
     */
    public static void ensure(String fromCode, String toCode, String role) {
        ThesisStatus from = ThesisStatus.of(fromCode);
        ThesisStatus to = ThesisStatus.of(toCode);
        if (from == to) {
            throw BizException.flow("论文已处于「" + to.getLabel() + "」状态，无需重复操作");
        }
        if (!from.canTransitTo(to)) {
            String allowed = from.nextStatuses().stream()
                    .map(ThesisStatus::getLabel)
                    .collect(Collectors.joining(" / "));
            throw BizException.flow(String.format("当前状态「%s」不能流转到「%s」，允许的下一步：%s",
                    from.getLabel(), to.getLabel(), allowed.isEmpty() ? "无（流程已结束）" : allowed));
        }
        if (!to.roleAllowed(role)) {
            throw BizException.flow(String.format("当前角色无权把论文推进到「%s」", to.getLabel()));
        }
    }

    /** 当前状态是否允许该角色继续操作 */
    public static boolean canOperate(String fromCode, String role) {
        return ThesisStatus.of(fromCode).nextStatuses().stream().anyMatch(s -> s.roleAllowed(role));
    }
}
