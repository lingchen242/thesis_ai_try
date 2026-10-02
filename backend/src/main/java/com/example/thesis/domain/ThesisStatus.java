package com.example.thesis.domain;

import com.example.thesis.common.BizException;

import java.util.Collections;
import java.util.EnumMap;
import java.util.EnumSet;
import java.util.Map;
import java.util.Set;

/**
 * 论文状态机。
 * <pre>
 * DRAFT ──提交开题──▶ PROPOSAL_SUBMITTED ──审核──▶ PROPOSAL_APPROVED ──提交中期──▶ MIDTERM_SUBMITTED
 *   ▲                        │驳回                          │                                │驳回
 *   └────────────────────────┘                             ▼                                ▼
 *                                    MIDTERM_PASSED ◀──检查──┘                  PROPOSAL_APPROVED
 *                                          │提交定稿
 *                                          ▼
 *   FINAL_SUBMITTED ◀──退回── REVIEWING ──评阅──▶ REVIEW_PASSED ──编组──▶ DEFENSE_SCHEDULED
 *                                                                              │录入成绩
 *                                                                              ▼
 *                                    ARCHIVED ◀──归档── DEFENSE_DONE
 * </pre>
 * 枚举同时定义「允许的下一状态」与「允许执行该流转的角色」，是唯一的流转真源。
 */
public enum ThesisStatus {

    DRAFT("待提交开题"),
    PROPOSAL_SUBMITTED("开题待审核"),
    PROPOSAL_APPROVED("开题已通过"),
    MIDTERM_SUBMITTED("中期待检查"),
    MIDTERM_PASSED("中期已通过"),
    FINAL_SUBMITTED("定稿已提交"),
    REVIEWING("评阅中"),
    REVIEW_PASSED("评阅已通过"),
    DEFENSE_SCHEDULED("待答辩"),
    DEFENSE_DONE("答辩完成"),
    ARCHIVED("已归档");

    private final String label;

    private static final Map<ThesisStatus, Set<ThesisStatus>> TRANSITIONS = new EnumMap<>(ThesisStatus.class);
    private static final Map<ThesisStatus, Set<String>> TARGET_ROLES = new EnumMap<>(ThesisStatus.class);

    static {
        // 允许的流转
        allow(DRAFT, PROPOSAL_SUBMITTED);
        allow(PROPOSAL_SUBMITTED, PROPOSAL_APPROVED, DRAFT);          // 通过 / 驳回退回
        allow(PROPOSAL_APPROVED, MIDTERM_SUBMITTED);
        allow(MIDTERM_SUBMITTED, MIDTERM_PASSED, PROPOSAL_APPROVED);  // 通过 / 退回
        allow(MIDTERM_PASSED, FINAL_SUBMITTED);
        allow(FINAL_SUBMITTED, REVIEWING);
        allow(REVIEWING, REVIEW_PASSED, FINAL_SUBMITTED);             // 通过 / 退回重交
        allow(REVIEW_PASSED, DEFENSE_SCHEDULED);
        allow(DEFENSE_SCHEDULED, DEFENSE_DONE);
        allow(DEFENSE_DONE, ARCHIVED);

        // 每个目标状态允许的操作角色
        role(PROPOSAL_SUBMITTED, "STUDENT");
        role(DRAFT, "ADVISOR", "ADMIN");
        role(PROPOSAL_APPROVED, "ADVISOR", "ADMIN");
        role(MIDTERM_SUBMITTED, "STUDENT");
        role(MIDTERM_PASSED, "ADVISOR", "ADMIN");
        // 定稿：学生主动提交；评阅不合格时由评阅教师/管理员退回重交，因此一并放开
        role(FINAL_SUBMITTED, "STUDENT", "REVIEWER", "ADMIN");
        role(REVIEWING, "ADMIN");
        role(REVIEW_PASSED, "ADMIN", "REVIEWER");
        role(DEFENSE_SCHEDULED, "ADMIN", "REVIEWER");
        role(DEFENSE_DONE, "ADMIN", "REVIEWER");
        role(ARCHIVED, "ADMIN");
    }

    ThesisStatus(String label) {
        this.label = label;
    }

    private static void allow(ThesisStatus from, ThesisStatus... to) {
        TRANSITIONS.put(from, EnumSet.copyOf(java.util.Arrays.asList(to)));
    }

    private static void role(ThesisStatus target, String... roles) {
        TARGET_ROLES.put(target, Set.of(roles));
    }

    public String getLabel() {
        return label;
    }

    public Set<ThesisStatus> nextStatuses() {
        return Collections.unmodifiableSet(TRANSITIONS.getOrDefault(this, EnumSet.noneOf(ThesisStatus.class)));
    }

    public boolean canTransitTo(ThesisStatus target) {
        return nextStatuses().contains(target);
    }

    public boolean roleAllowed(String role) {
        return TARGET_ROLES.getOrDefault(this, Set.of()).contains(role);
    }

    /** 安全解析，未知状态抛出业务异常而不是 IllegalArgumentException */
    public static ThesisStatus of(String code) {
        if (code == null) {
            throw BizException.flow("论文状态为空");
        }
        for (ThesisStatus s : values()) {
            if (s.name().equalsIgnoreCase(code)) {
                return s;
            }
        }
        throw BizException.flow("未知的论文状态：" + code);
    }

    public static String labelOf(String code) {
        try {
            return of(code).getLabel();
        } catch (BizException e) {
            return code;
        }
    }
}
