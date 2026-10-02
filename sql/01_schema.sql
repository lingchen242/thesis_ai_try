-- =============================================================================
-- 毕业论文管理系统 · 数据库结构 (MySQL 8.0)
-- 库名：thesis_mgmt
-- 说明：本文件只建表，不含业务数据。重复执行安全（先 DROP 后 CREATE）。
-- 导入：mysql -u root -p thesis_mgmt < sql/01_schema.sql
-- =============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- -----------------------------------------------------------------------------
-- 1. 账号表
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `sys_user`;
CREATE TABLE `sys_user` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `username`        VARCHAR(50)  NOT NULL COMMENT '登录账号',
  `password`        VARCHAR(100) NOT NULL COMMENT 'BCrypt 密码',
  `real_name`       VARCHAR(50)  NOT NULL COMMENT '姓名',
  `role`            VARCHAR(20)  NOT NULL COMMENT '角色 STUDENT/ADVISOR/REVIEWER/ADMIN',
  `gender`          TINYINT      DEFAULT 0 COMMENT '性别 0未知 1男 2女',
  `avatar`          VARCHAR(255) DEFAULT NULL COMMENT '头像URL',
  `phone`           VARCHAR(20)  DEFAULT NULL COMMENT '手机号',
  `email`           VARCHAR(100) DEFAULT NULL COMMENT '邮箱',
  `status`          TINYINT      NOT NULL DEFAULT 1 COMMENT '状态 1启用 0禁用',
  `last_login_time` DATETIME     DEFAULT NULL COMMENT '最近登录时间',
  `create_time`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`         TINYINT      NOT NULL DEFAULT 0 COMMENT '逻辑删除 0否 1是',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_sys_user_username` (`username`),
  KEY `idx_sys_user_role` (`role`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='账号表';

-- -----------------------------------------------------------------------------
-- 2. 教师档案
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `teacher`;
CREATE TABLE `teacher` (
  `id`           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id`      BIGINT UNSIGNED NOT NULL COMMENT '关联 sys_user.id',
  `teacher_no`   VARCHAR(32)  NOT NULL COMMENT '工号',
  `real_name`    VARCHAR(50)  NOT NULL,
  `gender`       TINYINT      DEFAULT 0,
  `title`        VARCHAR(32)  DEFAULT NULL COMMENT '职称 教授/副教授/讲师/助教',
  `college`      VARCHAR(64)  DEFAULT NULL COMMENT '学院',
  `major`        VARCHAR(64)  DEFAULT NULL COMMENT '专业',
  `teacher_type` VARCHAR(20)  NOT NULL DEFAULT 'ADVISOR' COMMENT 'ADVISOR指导教师/REVIEWER评阅教师/BOTH兼任',
  `can_review`   TINYINT      NOT NULL DEFAULT 0 COMMENT '是否可被指派评阅 0否 1是',
  `max_quota`    INT          NOT NULL DEFAULT 8 COMMENT '最大指导学生数',
  `phone`        VARCHAR(20)  DEFAULT NULL,
  `email`        VARCHAR(100) DEFAULT NULL,
  `create_time`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`      TINYINT      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_teacher_no` (`teacher_no`),
  UNIQUE KEY `uk_teacher_user` (`user_id`),
  KEY `idx_teacher_type` (`teacher_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='教师档案';

-- -----------------------------------------------------------------------------
-- 3. 学生档案
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `student`;
CREATE TABLE `student` (
  `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id`     BIGINT UNSIGNED NOT NULL COMMENT '关联 sys_user.id',
  `student_no`  VARCHAR(32)  NOT NULL COMMENT '学号',
  `real_name`   VARCHAR(50)  NOT NULL,
  `gender`      TINYINT      DEFAULT 0,
  `grade`       VARCHAR(16)  NOT NULL COMMENT '届别 如 2027',
  `college`     VARCHAR(64)  DEFAULT NULL COMMENT '学院',
  `major`       VARCHAR(64)  DEFAULT NULL COMMENT '专业',
  `class_name`  VARCHAR(64)  DEFAULT NULL COMMENT '班级',
  `advisor_id`  BIGINT UNSIGNED DEFAULT NULL COMMENT '指导教师 teacher.id',
  `phone`       VARCHAR(20)  DEFAULT NULL,
  `email`       VARCHAR(100) DEFAULT NULL,
  `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`     TINYINT      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_student_no` (`student_no`),
  UNIQUE KEY `uk_student_user` (`user_id`),
  KEY `idx_student_grade` (`grade`),
  KEY `idx_student_advisor` (`advisor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='学生档案';

-- -----------------------------------------------------------------------------
-- 4. 课题
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `topic`;
CREATE TABLE `topic` (
  `id`             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `title`          VARCHAR(200) NOT NULL COMMENT '课题名称',
  `topic_type`     VARCHAR(32)  DEFAULT NULL COMMENT '类型 理论研究/工程设计/软件开发/实验研究/调研报告',
  `source`         VARCHAR(32)  DEFAULT NULL COMMENT '来源 教师命题/学生自拟/企业真题',
  `teacher_id`     BIGINT UNSIGNED NOT NULL COMMENT '出题教师 teacher.id',
  `grade`          VARCHAR(16)  DEFAULT NULL COMMENT '适用届别',
  `college`        VARCHAR(64)  DEFAULT NULL,
  `major`          VARCHAR(64)  DEFAULT NULL,
  `description`    TEXT         COMMENT '课题简介',
  `requirement`    TEXT         COMMENT '任务与要求',
  `capacity`       INT          NOT NULL DEFAULT 1 COMMENT '可选人数上限',
  `selected_count` INT          NOT NULL DEFAULT 0 COMMENT '已选人数',
  `status`         VARCHAR(20)  NOT NULL DEFAULT 'DRAFT' COMMENT 'DRAFT草稿/OPEN开放/SELECTED已选满/CLOSED已关闭',
  `publish_time`   DATETIME     DEFAULT NULL,
  `create_time`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`        TINYINT      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_topic_teacher` (`teacher_id`),
  KEY `idx_topic_status` (`status`),
  KEY `idx_topic_grade` (`grade`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='课题';

-- -----------------------------------------------------------------------------
-- 5. 选题申请
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `selection`;
CREATE TABLE `selection` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `topic_id`        BIGINT UNSIGNED NOT NULL,
  `student_id`      BIGINT UNSIGNED NOT NULL COMMENT 'student.id',
  `status`          VARCHAR(20) NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING待审/APPROVED通过/REJECTED驳回',
  `student_remark`  VARCHAR(500) DEFAULT NULL COMMENT '学生申请说明',
  `teacher_comment` VARCHAR(500) DEFAULT NULL COMMENT '教师审核意见',
  `apply_time`      DATETIME     DEFAULT NULL,
  `handle_time`     DATETIME     DEFAULT NULL,
  `handler_id`      BIGINT UNSIGNED DEFAULT NULL COMMENT '处理人 teacher.id',
  `create_time`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`         TINYINT      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_selection_topic_student` (`topic_id`, `student_id`),
  KEY `idx_selection_status` (`status`),
  KEY `idx_selection_student` (`student_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='选题申请';

-- -----------------------------------------------------------------------------
-- 6. 论文主表
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `thesis`;
CREATE TABLE `thesis` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_id`    BIGINT UNSIGNED NOT NULL COMMENT 'student.id 一名学生一篇',
  `topic_id`      BIGINT UNSIGNED DEFAULT NULL,
  `advisor_id`    BIGINT UNSIGNED DEFAULT NULL COMMENT '指导教师 teacher.id',
  `title`         VARCHAR(200) NOT NULL COMMENT '论文题目',
  `grade`         VARCHAR(16)  DEFAULT NULL COMMENT '届别',
  `college`       VARCHAR(64)  DEFAULT NULL,
  `major`         VARCHAR(64)  DEFAULT NULL,
  `status`        VARCHAR(32)  NOT NULL DEFAULT 'DRAFT' COMMENT 'DRAFT/PROPOSAL_SUBMITTED/PROPOSAL_APPROVED/MIDTERM_SUBMITTED/MIDTERM_PASSED/FINAL_SUBMITTED/REVIEWING/REVIEW_PASSED/DEFENSE_SCHEDULED/DEFENSE_DONE/ARCHIVED',
  `current_stage` VARCHAR(32)  DEFAULT NULL COMMENT '当前阶段中文名（展示用）',
  `start_time`    DATETIME     DEFAULT NULL COMMENT '选题通过时间',
  `submit_time`   DATETIME     DEFAULT NULL COMMENT '定稿提交时间',
  `archive_time`  DATETIME     DEFAULT NULL COMMENT '归档时间',
  `create_time`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`       TINYINT      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_thesis_student` (`student_id`),
  KEY `idx_thesis_status_grade` (`status`, `grade`),
  KEY `idx_thesis_advisor` (`advisor_id`),
  KEY `idx_thesis_topic` (`topic_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='论文主表';

-- -----------------------------------------------------------------------------
-- 7. 开题报告
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `proposal`;
CREATE TABLE `proposal` (
  `id`             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `thesis_id`      BIGINT UNSIGNED NOT NULL,
  `content`        TEXT         COMMENT '开题报告正文（Markdown）',
  `attachment_ids` VARCHAR(255) DEFAULT NULL COMMENT '附件ID，逗号分隔',
  `submit_time`    DATETIME     DEFAULT NULL,
  `review_status`  VARCHAR(20)  NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING待审/APPROVED通过/REJECTED驳回',
  `review_comment` VARCHAR(1000) DEFAULT NULL,
  `reviewer_id`    BIGINT UNSIGNED DEFAULT NULL COMMENT '审核人 teacher.id',
  `review_time`    DATETIME     DEFAULT NULL,
  `score`          DECIMAL(5,2) DEFAULT NULL COMMENT '开题成绩',
  `create_time`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`        TINYINT      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_proposal_thesis` (`thesis_id`),
  KEY `idx_proposal_status` (`review_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='开题报告';

-- -----------------------------------------------------------------------------
-- 8. 中期报告
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `midterm_report`;
CREATE TABLE `midterm_report` (
  `id`               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `thesis_id`        BIGINT UNSIGNED NOT NULL,
  `progress_percent` TINYINT      DEFAULT NULL COMMENT '完成百分比 0-100',
  `content`          TEXT         COMMENT '中期报告正文（Markdown）',
  `attachment_ids`   VARCHAR(255) DEFAULT NULL,
  `submit_time`      DATETIME     DEFAULT NULL,
  `review_status`    VARCHAR(20)  NOT NULL DEFAULT 'PENDING',
  `review_comment`   VARCHAR(1000) DEFAULT NULL,
  `reviewer_id`      BIGINT UNSIGNED DEFAULT NULL,
  `review_time`      DATETIME     DEFAULT NULL,
  `score`            DECIMAL(5,2) DEFAULT NULL COMMENT '中期成绩',
  `create_time`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`          TINYINT      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_midterm_thesis` (`thesis_id`),
  KEY `idx_midterm_status` (`review_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='中期报告';

-- -----------------------------------------------------------------------------
-- 9. 定稿提交
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `final_submission`;
CREATE TABLE `final_submission` (
  `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `thesis_id`  BIGINT UNSIGNED NOT NULL,
  `file_url`   VARCHAR(500) NOT NULL COMMENT '云端文件地址',
  `file_name`  VARCHAR(255) DEFAULT NULL,
  `file_size`  BIGINT       DEFAULT NULL COMMENT '字节',
  `version`    INT          NOT NULL DEFAULT 1 COMMENT '版本号',
  `note`       VARCHAR(500) DEFAULT NULL COMMENT '提交说明',
  `submit_time` DATETIME    DEFAULT NULL,
  `create_time` DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`    TINYINT      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_final_thesis` (`thesis_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='论文定稿';

-- -----------------------------------------------------------------------------
-- 10. 评阅
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `review`;
CREATE TABLE `review` (
  `id`           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `thesis_id`    BIGINT UNSIGNED NOT NULL,
  `reviewer_id`  BIGINT UNSIGNED NOT NULL COMMENT '评阅教师 teacher.id',
  `assigned_by`  BIGINT UNSIGNED DEFAULT NULL COMMENT '指派人 sys_user.id',
  `score`        DECIMAL(5,2) DEFAULT NULL COMMENT '评阅成绩',
  `comment`      VARCHAR(2000) DEFAULT NULL COMMENT '评阅意见',
  `status`       VARCHAR(20) NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING待评阅/SUBMITTED已提交',
  `blind`        TINYINT     NOT NULL DEFAULT 0 COMMENT '是否盲审 0否 1是',
  `assign_time`  DATETIME    DEFAULT NULL,
  `submit_time`  DATETIME    DEFAULT NULL,
  `create_time`  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`      TINYINT     NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_review_thesis_reviewer` (`thesis_id`, `reviewer_id`),
  KEY `idx_review_reviewer_status` (`reviewer_id`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='论文评阅';

-- -----------------------------------------------------------------------------
-- 11. 答辩组
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `defense_group`;
CREATE TABLE `defense_group` (
  `id`           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`         VARCHAR(100) NOT NULL COMMENT '答辩组名称',
  `grade`        VARCHAR(16)  DEFAULT NULL COMMENT '届别',
  `college`      VARCHAR(64)  DEFAULT NULL,
  `defense_date` DATETIME     DEFAULT NULL COMMENT '答辩时间',
  `location`     VARCHAR(100) DEFAULT NULL COMMENT '答辩地点',
  `secretary_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '答辩秘书 teacher.id',
  `status`       VARCHAR(20)  NOT NULL DEFAULT 'PLANNED' COMMENT 'PLANNED待进行/FINISHED已结束',
  `remark`       VARCHAR(500) DEFAULT NULL,
  `create_time`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`      TINYINT      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_defense_group_grade` (`grade`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='答辩组';

-- -----------------------------------------------------------------------------
-- 12. 答辩组成员
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `defense_group_member`;
CREATE TABLE `defense_group_member` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `group_id`      BIGINT UNSIGNED NOT NULL,
  `teacher_id`    BIGINT UNSIGNED NOT NULL,
  `role_in_group` VARCHAR(20) DEFAULT 'MEMBER' COMMENT 'CHAIR主席/MEMBER委员/SECRETARY秘书',
  `create_time`   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_defense_member` (`group_id`, `teacher_id`),
  KEY `idx_defense_member_teacher` (`teacher_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='答辩组成员';

-- -----------------------------------------------------------------------------
-- 13. 答辩成绩
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `defense_record`;
CREATE TABLE `defense_record` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `thesis_id`     BIGINT UNSIGNED NOT NULL,
  `group_id`      BIGINT UNSIGNED NOT NULL,
  `score`         DECIMAL(5,2) DEFAULT NULL COMMENT '答辩成绩',
  `result`        VARCHAR(20) DEFAULT NULL COMMENT 'PASS通过/DEFER暂缓/FAIL不通过',
  `comment`       VARCHAR(1000) DEFAULT NULL,
  `recorded_by`   BIGINT UNSIGNED DEFAULT NULL COMMENT '录入人 sys_user.id',
  `recorded_time` DATETIME DEFAULT NULL,
  `create_time`   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`       TINYINT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_defense_record_thesis` (`thesis_id`),
  KEY `idx_defense_record_group` (`group_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='答辩成绩';

-- -----------------------------------------------------------------------------
-- 14. 成绩汇总
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `thesis_score`;
CREATE TABLE `thesis_score` (
  `id`             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `thesis_id`      BIGINT UNSIGNED NOT NULL,
  `proposal_score` DECIMAL(5,2) DEFAULT NULL COMMENT '开题成绩',
  `midterm_score`  DECIMAL(5,2) DEFAULT NULL COMMENT '中期成绩',
  `review_score`   DECIMAL(5,2) DEFAULT NULL COMMENT '评阅成绩',
  `defense_score`  DECIMAL(5,2) DEFAULT NULL COMMENT '答辩成绩',
  `total_score`    DECIMAL(5,2) DEFAULT NULL COMMENT '总评（加权）',
  `computed_time`  DATETIME DEFAULT NULL,
  `create_time`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`        TINYINT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_thesis_score_thesis` (`thesis_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='论文成绩汇总';

-- -----------------------------------------------------------------------------
-- 15. 附件
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `attachment`;
CREATE TABLE `attachment` (
  `id`             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `biz_type`       VARCHAR(32)  NOT NULL COMMENT '业务类型 PROPOSAL/MIDTERM/FINAL/OTHER',
  `biz_id`         BIGINT UNSIGNED NOT NULL COMMENT '业务ID',
  `file_name`      VARCHAR(255) NOT NULL,
  `file_url`       VARCHAR(500) NOT NULL COMMENT '云端地址',
  `file_size`      BIGINT       DEFAULT NULL COMMENT '字节',
  `mime_type`      VARCHAR(100) DEFAULT NULL,
  `storage_driver` VARCHAR(20)  NOT NULL DEFAULT 'cloud' COMMENT 'cloud云端/local本地',
  `uploader_id`    BIGINT UNSIGNED DEFAULT NULL,
  `create_time`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`        TINYINT      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_attachment_biz` (`biz_type`, `biz_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='附件';

-- -----------------------------------------------------------------------------
-- 16. 操作留痕
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `audit_log`;
CREATE TABLE `audit_log` (
  `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `actor_id`    BIGINT UNSIGNED DEFAULT NULL COMMENT '操作人 sys_user.id',
  `actor_name`  VARCHAR(50)  DEFAULT NULL,
  `action`      VARCHAR(64)  NOT NULL COMMENT '动作编码 如 APPROVE_PROPOSAL',
  `target_type` VARCHAR(32)  DEFAULT NULL COMMENT 'THESIS/TOPIC/SELECTION...',
  `target_id`   BIGINT UNSIGNED DEFAULT NULL,
  `detail`      VARCHAR(1000) DEFAULT NULL COMMENT '变更详情',
  `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_audit_target` (`target_type`, `target_id`),
  KEY `idx_audit_actor` (`actor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='操作留痕';

-- -----------------------------------------------------------------------------
-- 17. 站内消息
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `notification`;
CREATE TABLE `notification` (
  `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id`    BIGINT UNSIGNED NOT NULL COMMENT '接收人 sys_user.id',
  `title`      VARCHAR(200) NOT NULL,
  `content`    VARCHAR(1000) DEFAULT NULL,
  `link`       VARCHAR(255) DEFAULT NULL COMMENT '跳转路径',
  `type`       VARCHAR(32)  DEFAULT 'SYSTEM' COMMENT 'SYSTEM/FLOW/SCORE',
  `is_read`    TINYINT      NOT NULL DEFAULT 0,
  `create_time` DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_notification_user_read` (`user_id`, `is_read`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='站内消息';

-- -----------------------------------------------------------------------------
-- 18. 系统配置
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `sys_config`;
CREATE TABLE `sys_config` (
  `id`           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `config_key`   VARCHAR(64)  NOT NULL,
  `config_value` VARCHAR(500) DEFAULT NULL,
  `remark`       VARCHAR(255) DEFAULT NULL,
  `create_time`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_sys_config_key` (`config_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='系统配置';

SET FOREIGN_KEY_CHECKS = 1;
