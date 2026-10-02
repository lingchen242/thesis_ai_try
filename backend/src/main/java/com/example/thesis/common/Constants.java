package com.example.thesis.common;

/**
 * 全局常量。
 */
public final class Constants {

    private Constants() {
    }

    // ------------------------------------------------------------------ 角色
    public static final String ROLE_STUDENT = "STUDENT";
    public static final String ROLE_ADVISOR = "ADVISOR";
    public static final String ROLE_REVIEWER = "REVIEWER";
    public static final String ROLE_ADMIN = "ADMIN";

    // -------------------------------------------------------------- 字典类型
    public static final String DICT_COLLEGE = "COLLEGE";
    public static final String DICT_MAJOR = "MAJOR";
    public static final String DICT_CLASS = "CLASS";
    public static final String DICT_GRADE = "GRADE";
    public static final String DICT_TOPIC_TYPE = "TOPIC_TYPE";
    public static final String DICT_TOPIC_SOURCE = "TOPIC_SOURCE";
    public static final String DICT_TITLE = "TITLE";
    public static final String DICT_DEFENSE_RESULT = "DEFENSE_RESULT";

    // -------------------------------------------------------------- 附件业务
    public static final String BIZ_PROPOSAL = "PROPOSAL";
    public static final String BIZ_MIDTERM = "MIDTERM";
    public static final String BIZ_FINAL = "FINAL";
    public static final String BIZ_OTHER = "OTHER";

    // ------------------------------------------------------------ 存储驱动
    public static final String STORAGE_LOCAL = "local";
    public static final String STORAGE_CLOUD = "cloud";

    // ---------------------------------------------------------------- 审核态
    public static final String REVIEW_PENDING = "PENDING";
    public static final String REVIEW_APPROVED = "APPROVED";
    public static final String REVIEW_REJECTED = "REJECTED";

    // ------------------------------------------------------------ 操作留痕
    public static final String ACT_SUBMIT_PROPOSAL = "SUBMIT_PROPOSAL";
    public static final String ACT_APPROVE_PROPOSAL = "APPROVE_PROPOSAL";
    public static final String ACT_REJECT_PROPOSAL = "REJECT_PROPOSAL";
    public static final String ACT_SUBMIT_MIDTERM = "SUBMIT_MIDTERM";
    public static final String ACT_APPROVE_MIDTERM = "APPROVE_MIDTERM";
    public static final String ACT_REJECT_MIDTERM = "REJECT_MIDTERM";
    public static final String ACT_SUBMIT_FINAL = "SUBMIT_FINAL";
    public static final String ACT_ASSIGN_REVIEW = "ASSIGN_REVIEW";
    public static final String ACT_SUBMIT_REVIEW = "SUBMIT_REVIEW";
    public static final String ACT_RECORD_DEFENSE = "RECORD_DEFENSE";
    public static final String ACT_ARCHIVE = "ARCHIVE";
    public static final String ACT_APPROVE_SELECTION = "APPROVE_SELECTION";
    public static final String ACT_REJECT_SELECTION = "REJECT_SELECTION";

    // ------------------------------------------------------------ 站内消息
    public static final String NOTE_SYSTEM = "SYSTEM";
    public static final String NOTE_FLOW = "FLOW";
    public static final String NOTE_SCORE = "SCORE";
}
