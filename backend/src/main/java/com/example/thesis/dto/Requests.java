package com.example.thesis.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.util.List;

/**
 * 请求体集合。使用嵌套 record 集中管理，避免为每个请求新建文件；
 * 实体类的增删改（学生、教师、课题、字典等）直接以实体作为请求体。
 */
public final class Requests {

    private Requests() {
    }

    /** 登录 */
    public record Login(
            @NotBlank(message = "请输入账号") String username,
            @NotBlank(message = "请输入密码") String password) {
    }

    /** 修改密码 */
    public record ChangePassword(
            @NotBlank(message = "请输入当前密码") String currentPassword,
            @NotBlank(message = "请输入新密码")
            @Size(min = 6, message = "新密码至少 6 位") String newPassword) {
    }

    /** 重置密码（管理员） */
    public record ResetPassword(String password) {
    }

    /** 论文状态流转 / 阶段审核统一入参 */
    public record Transition(
            @NotBlank(message = "缺少目标状态") String target,
            String comment,
            BigDecimal score) {
    }

    /** 开题 / 中期审核结论 */
    public record StageReview(
            @NotBlank(message = "请选择审核结论") String decision,
            String comment,
            BigDecimal score) {
    }

    /** 指定评阅 */
    public record AssignReview(
            @NotNull(message = "缺少论文 ID") Long thesisId,
            Long reviewerId,
            Boolean blind) {
    }

    /** 提交评阅意见 */
    public record ReviewSubmit(BigDecimal score, String comment) {
    }

    /** 录入答辩成绩 */
    public record DefenseRecord(
            @NotNull(message = "缺少论文 ID") Long thesisId,
            @NotNull(message = "缺少答辩组 ID") Long groupId,
            BigDecimal score,
            String result,
            String comment) {
    }

    /** 学生申报课题 */
    public record SelectionApply(
            @NotNull(message = "缺少课题 ID") Long topicId,
            String remark) {
    }

    /** 选题审核 */
    public record SelectionDecision(String comment) {
    }

    /** 设置答辩组成员 */
    public record GroupMembers(
            @NotEmpty(message = "请至少选择一名成员") List<Long> memberIds,
            Long chairId,
            Long secretaryId) {
    }

    /** 附件绑定到具体业务记录 */
    public record FileBind(
            @NotBlank(message = "缺少业务类型") String bizType,
            @NotNull(message = "缺少业务 ID") Long bizId,
            @NotEmpty(message = "缺少附件 ID") List<Long> ids) {
    }
}
