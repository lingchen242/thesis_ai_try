-- =============================================================================
-- 毕业论文管理系统 · 演示数据（含字典基础数据）
-- 生成脚本：scripts/gen_demo_sql.py（固定随机种子，可重复生成）
-- 导入：mysql -u root -p thesis_mgmt < database/02_demo_data.sql
--
-- 账号与密码（BCrypt 加密，cost=10）：
--   管理员      admin          / admin123
--   指导教师    t2001~t2018    / 123456
--   评阅教师    r3001~r3006    / 123456
--   学生        s20260001...   / 123456
--
-- 数据规模：
--   字典类型 8 / 字典项 55（学院 3、专业 7、班级 28）
--   管理员 1 / 指导教师 18 / 评阅教师 6 / 学生 55（2026届 12，2027届 43）
--   课题 60（已选 50，开放 10） / 选题申请 55 / 论文 50（覆盖 11 种状态）
--   开题 47 / 中期 37 / 定稿 27 / 评阅 22 / 答辩组 3 / 答辩成绩 12
--   附件 111 / 操作日志 341 / 站内消息 70
--
-- 时间线说明：为便于一次性演示全部状态，2026 届按 2026-01~06 的真实节奏排布，
-- 2027 届各环节集中在 2026-08~09（压缩时间线），答辩计划于 2026-10-15 进行。
-- =============================================================================

SET NAMES utf8mb4;

TRUNCATE TABLE `audit_log`;
TRUNCATE TABLE `notification`;
TRUNCATE TABLE `attachment`;
TRUNCATE TABLE `thesis_score`;
TRUNCATE TABLE `defense_record`;
TRUNCATE TABLE `defense_group_member`;
TRUNCATE TABLE `defense_group`;
TRUNCATE TABLE `review`;
TRUNCATE TABLE `final_submission`;
TRUNCATE TABLE `midterm_report`;
TRUNCATE TABLE `proposal`;
TRUNCATE TABLE `thesis`;
TRUNCATE TABLE `selection`;
TRUNCATE TABLE `topic`;
TRUNCATE TABLE `student`;
TRUNCATE TABLE `teacher`;
TRUNCATE TABLE `sys_user`;
TRUNCATE TABLE `sys_config`;
TRUNCATE TABLE `sys_dict_item`;
TRUNCATE TABLE `sys_dict_type`;

-- 0.1 字典类型（sys_dict_type）
INSERT INTO `sys_dict_type` (`id`, `type_code`, `type_name`, `remark`, `create_time`, `update_time`) VALUES
  (1, 'COLLEGE', '学院', '组织架构一级：学院', NOW(), NOW()),
  (2, 'MAJOR', '专业', '组织架构二级：专业（父级为学院）', NOW(), NOW()),
  (3, 'CLASS', '班级', '组织架构三级：班级（父级为专业）', NOW(), NOW()),
  (4, 'GRADE', '届别', '毕业届别', NOW(), NOW()),
  (5, 'TOPIC_TYPE', '课题类型', '课题性质分类', NOW(), NOW()),
  (6, 'TOPIC_SOURCE', '课题来源', '课题来源渠道', NOW(), NOW()),
  (7, 'TITLE', '教师职称', '教师专业技术职称', NOW(), NOW()),
  (8, 'DEFENSE_RESULT', '答辩结论', '答辩结果结论', NOW(), NOW());

-- 0.2 字典项（sys_dict_item）：学院 -> 专业 -> 班级 三级树 + 平铺字典
INSERT INTO `sys_dict_item` (`id`, `type_code`, `item_code`, `item_name`, `parent_id`, `sort_no`, `status`, `remark`, `create_time`, `update_time`) VALUES
  (1, 'COLLEGE', 'C01', '计算机与人工智能学院', NULL, 1, 1, NULL, NOW(), NOW()),
  (2, 'MAJOR', 'M001', '计算机科学与技术', 1, 1, 1, NULL, NOW(), NOW()),
  (3, 'CLASS', 'K0001', '计科22-1班', 2, 1, 1, NULL, NOW(), NOW()),
  (4, 'CLASS', 'K0002', '计科22-2班', 2, 2, 1, NULL, NOW(), NOW()),
  (5, 'CLASS', 'K0003', '计科23-1班', 2, 3, 1, NULL, NOW(), NOW()),
  (6, 'CLASS', 'K0004', '计科23-2班', 2, 4, 1, NULL, NOW(), NOW()),
  (7, 'MAJOR', 'M002', '人工智能', 1, 2, 1, NULL, NOW(), NOW()),
  (8, 'CLASS', 'K0005', '智能22-1班', 7, 5, 1, NULL, NOW(), NOW()),
  (9, 'CLASS', 'K0006', '智能22-2班', 7, 6, 1, NULL, NOW(), NOW()),
  (10, 'CLASS', 'K0007', '智能23-1班', 7, 7, 1, NULL, NOW(), NOW()),
  (11, 'CLASS', 'K0008', '智能23-2班', 7, 8, 1, NULL, NOW(), NOW()),
  (12, 'MAJOR', 'M003', '数据科学与大数据技术', 1, 3, 1, NULL, NOW(), NOW()),
  (13, 'CLASS', 'K0009', '数科22-1班', 12, 9, 1, NULL, NOW(), NOW()),
  (14, 'CLASS', 'K0010', '数科22-2班', 12, 10, 1, NULL, NOW(), NOW()),
  (15, 'CLASS', 'K0011', '数科23-1班', 12, 11, 1, NULL, NOW(), NOW()),
  (16, 'CLASS', 'K0012', '数科23-2班', 12, 12, 1, NULL, NOW(), NOW()),
  (17, 'COLLEGE', 'C02', '软件学院', NULL, 2, 1, NULL, NOW(), NOW()),
  (18, 'MAJOR', 'M004', '软件工程', 17, 4, 1, NULL, NOW(), NOW()),
  (19, 'CLASS', 'K0013', '软工22-1班', 18, 13, 1, NULL, NOW(), NOW()),
  (20, 'CLASS', 'K0014', '软工22-2班', 18, 14, 1, NULL, NOW(), NOW());

INSERT INTO `sys_dict_item` (`id`, `type_code`, `item_code`, `item_name`, `parent_id`, `sort_no`, `status`, `remark`, `create_time`, `update_time`) VALUES
  (21, 'CLASS', 'K0015', '软工23-1班', 18, 15, 1, NULL, NOW(), NOW()),
  (22, 'CLASS', 'K0016', '软工23-2班', 18, 16, 1, NULL, NOW(), NOW()),
  (23, 'MAJOR', 'M005', '网络空间安全', 17, 5, 1, NULL, NOW(), NOW()),
  (24, 'CLASS', 'K0017', '网安22-1班', 23, 17, 1, NULL, NOW(), NOW()),
  (25, 'CLASS', 'K0018', '网安22-2班', 23, 18, 1, NULL, NOW(), NOW()),
  (26, 'CLASS', 'K0019', '网安23-1班', 23, 19, 1, NULL, NOW(), NOW()),
  (27, 'CLASS', 'K0020', '网安23-2班', 23, 20, 1, NULL, NOW(), NOW()),
  (28, 'COLLEGE', 'C03', '电子信息学院', NULL, 3, 1, NULL, NOW(), NOW()),
  (29, 'MAJOR', 'M006', '电子信息工程', 28, 6, 1, NULL, NOW(), NOW()),
  (30, 'CLASS', 'K0021', '电信22-1班', 29, 21, 1, NULL, NOW(), NOW()),
  (31, 'CLASS', 'K0022', '电信22-2班', 29, 22, 1, NULL, NOW(), NOW()),
  (32, 'CLASS', 'K0023', '电信23-1班', 29, 23, 1, NULL, NOW(), NOW()),
  (33, 'CLASS', 'K0024', '电信23-2班', 29, 24, 1, NULL, NOW(), NOW()),
  (34, 'MAJOR', 'M007', '通信工程', 28, 7, 1, NULL, NOW(), NOW()),
  (35, 'CLASS', 'K0025', '通信22-1班', 34, 25, 1, NULL, NOW(), NOW()),
  (36, 'CLASS', 'K0026', '通信22-2班', 34, 26, 1, NULL, NOW(), NOW()),
  (37, 'CLASS', 'K0027', '通信23-1班', 34, 27, 1, NULL, NOW(), NOW()),
  (38, 'CLASS', 'K0028', '通信23-2班', 34, 28, 1, NULL, NOW(), NOW()),
  (39, 'GRADE', 'G2026', '2026', NULL, 1, 1, NULL, NOW(), NOW()),
  (40, 'GRADE', 'G2027', '2027', NULL, 2, 1, NULL, NOW(), NOW());

INSERT INTO `sys_dict_item` (`id`, `type_code`, `item_code`, `item_name`, `parent_id`, `sort_no`, `status`, `remark`, `create_time`, `update_time`) VALUES
  (41, 'TOPIC_TYPE', 'TT01', '理论研究', NULL, 1, 1, NULL, NOW(), NOW()),
  (42, 'TOPIC_TYPE', 'TT02', '工程设计', NULL, 2, 1, NULL, NOW(), NOW()),
  (43, 'TOPIC_TYPE', 'TT03', '软件开发', NULL, 3, 1, NULL, NOW(), NOW()),
  (44, 'TOPIC_TYPE', 'TT04', '实验研究', NULL, 4, 1, NULL, NOW(), NOW()),
  (45, 'TOPIC_TYPE', 'TT05', '调研报告', NULL, 5, 1, NULL, NOW(), NOW()),
  (46, 'TOPIC_SOURCE', 'TS01', '教师命题', NULL, 1, 1, NULL, NOW(), NOW()),
  (47, 'TOPIC_SOURCE', 'TS02', '企业真题', NULL, 2, 1, NULL, NOW(), NOW()),
  (48, 'TOPIC_SOURCE', 'TS03', '学生自拟', NULL, 3, 1, NULL, NOW(), NOW()),
  (49, 'TITLE', 'TI01', '教授', NULL, 1, 1, NULL, NOW(), NOW()),
  (50, 'TITLE', 'TI02', '副教授', NULL, 2, 1, NULL, NOW(), NOW()),
  (51, 'TITLE', 'TI03', '讲师', NULL, 3, 1, NULL, NOW(), NOW()),
  (52, 'TITLE', 'TI04', '助教', NULL, 4, 1, NULL, NOW(), NOW()),
  (53, 'DEFENSE_RESULT', 'DR01', '通过', NULL, 1, 1, NULL, NOW(), NOW()),
  (54, 'DEFENSE_RESULT', 'DR02', '暂缓', NULL, 2, 1, NULL, NOW(), NOW()),
  (55, 'DEFENSE_RESULT', 'DR03', '不通过', NULL, 3, 1, NULL, NOW(), NOW());

-- 1. 账号（sys_user）
INSERT INTO `sys_user` (`id`, `username`, `password`, `real_name`, `role`, `gender`, `avatar`, `phone`, `email`, `status`, `last_login_time`, `create_time`, `update_time`, `deleted`) VALUES
  (1, 'admin', '$2a$10$B0DN4NcVDQTLlq4hyezXdeTopWNssjHZ2kt.8ut2.2oNg3poHnr86', '系统管理员', 'ADMIN', 1, NULL, '13800000000', 'admin@thesis.edu.cn', 1, '2026-09-28 10:43:00', NOW(), NOW(), 0),
  (2, 't2001', '$2a$10$TIZGFZZEeBJ1spXsZzTum.GBgmHyhYQWleRyvaJLKU9xkDpfPXX8O', '熊军', 'ADVISOR', 2, NULL, '13857415971', 't2001@thesis.edu.cn', 1, '2026-09-21 18:57:00', NOW(), NOW(), 0),
  (3, 't2002', '$2a$10$74TNoqaSZOuHxbqimwyqi.GMHCHPweblJjL0cemGDMzixqh42hapO', '侯志强', 'ADVISOR', 2, NULL, '13811820639', 't2002@thesis.edu.cn', 1, '2026-09-27 19:13:00', NOW(), NOW(), 0),
  (4, 't2003', '$2a$10$TcJc8ND9vdRrtDQ/0yTWsuK85kXTnPJXetkWbLYVzRu8e3pLhC7gW', '方辉', 'ADVISOR', 1, NULL, '13812153934', 't2003@thesis.edu.cn', 1, '2026-09-23 18:07:00', NOW(), NOW(), 0),
  (5, 't2004', '$2a$10$myk/eRzHQIOJLsoNVosHSuqkjD/hoL0Y5GMc7eMchBACP38RPjtki', '钱雨欣', 'ADVISOR', 1, NULL, '13893633452', 't2004@thesis.edu.cn', 1, '2026-09-27 14:16:00', NOW(), NOW(), 0);

INSERT INTO `sys_user` (`id`, `username`, `password`, `real_name`, `role`, `gender`, `avatar`, `phone`, `email`, `status`, `last_login_time`, `create_time`, `update_time`, `deleted`) VALUES
  (6, 't2005', '$2a$10$njG..Ci0i/ZLvo5EanZcLOZo8vYIyM2ItCQM9MTJLfOwSN5gAtLb6', '彭明', 'ADVISOR', 2, NULL, '13863267468', 't2005@thesis.edu.cn', 1, '2026-09-22 14:55:00', NOW(), NOW(), 0),
  (7, 't2006', '$2a$10$sKJVTGTZfqwRFe95Hd4PJuhfDrjsgeIodwhBL5YkUbeCmZErAFl4u', '曹明', 'ADVISOR', 2, NULL, '13811130575', 't2006@thesis.edu.cn', 1, '2026-09-24 10:45:00', NOW(), NOW(), 0),
  (8, 't2007', '$2a$10$fWW11WJwFSiC3AdVgRgxyOIzZH46Rl62O1HeNNJPScwTZcAfoMIXy', '熊宇航', 'ADVISOR', 1, NULL, '13841730443', 't2007@thesis.edu.cn', 1, '2026-09-24 13:35:00', NOW(), NOW(), 0),
  (9, 't2008', '$2a$10$dDLF4qKZEzLAD3hIYTPNEermnbwWfHBPO3vmInej2voSKhsz.SoRO', '严嘉怡', 'ADVISOR', 2, NULL, '13873483815', 't2008@thesis.edu.cn', 1, '2026-09-21 10:40:00', NOW(), NOW(), 0),
  (10, 't2009', '$2a$10$J0fpA8JMHwQqEKBcZXaBCONsqwW35Xdw4eECDkQ0WBpo2eeiPJU4q', '陈桂英', 'ADVISOR', 1, NULL, '13827112433', 't2009@thesis.edu.cn', 1, '2026-09-23 08:32:00', NOW(), NOW(), 0);

INSERT INTO `sys_user` (`id`, `username`, `password`, `real_name`, `role`, `gender`, `avatar`, `phone`, `email`, `status`, `last_login_time`, `create_time`, `update_time`, `deleted`) VALUES
  (11, 't2010', '$2a$10$z/cWOFcTjyu4mq56oiPGuujqG62Ozg7zuwG5ekV6S84ivNd.Owa0S', '朱文博', 'ADVISOR', 2, NULL, '13863189418', 't2010@thesis.edu.cn', 1, '2026-09-27 12:02:00', NOW(), NOW(), 0),
  (12, 't2011', '$2a$10$zTc/ecTMsTbEgw36XsbNkeW7.5wdi3DBR2O6qA1YXEFZYj4tZVaR.', '史一鸣', 'ADVISOR', 1, NULL, '13862279550', 't2011@thesis.edu.cn', 1, '2026-09-26 12:24:00', NOW(), NOW(), 0),
  (13, 't2012', '$2a$10$z5toqv2KPpKmHHhDQekcu.Qnq3kV600Ll3rszvnnpndzGMsTUEM0G', '姜超', 'ADVISOR', 2, NULL, '13862091334', 't2012@thesis.edu.cn', 1, '2026-09-20 16:45:00', NOW(), NOW(), 0),
  (14, 't2013', '$2a$10$IXfJJRaYJxQhdvg4O8dXd.aZhApNOw/NrTDRb4EE3YfNnTwKTjZSq', '刘洋', 'ADVISOR', 1, NULL, '13864626760', 't2013@thesis.edu.cn', 1, '2026-09-29 11:41:00', NOW(), NOW(), 0),
  (15, 't2014', '$2a$10$9FtsDXu76.Bzxod0UKCpj.wmb5mNzDG0oZe18HIC.uGgces9dDDWG', '毛梓萱', 'ADVISOR', 2, NULL, '13810181964', 't2014@thesis.edu.cn', 1, '2026-09-29 14:09:00', NOW(), NOW(), 0);

INSERT INTO `sys_user` (`id`, `username`, `password`, `real_name`, `role`, `gender`, `avatar`, `phone`, `email`, `status`, `last_login_time`, `create_time`, `update_time`, `deleted`) VALUES
  (16, 't2015', '$2a$10$4tlFq2H89aVLYe60wp1wWePUdSCsLKYzt3pXy3kA8sEgYbNjJvYee', '蔡斌', 'ADVISOR', 2, NULL, '13862674515', 't2015@thesis.edu.cn', 1, '2026-09-24 21:51:00', NOW(), NOW(), 0),
  (17, 't2016', '$2a$10$SWz51INd6E5q2sMsFpOqUO424sTK3pBJoO81RxZu6f5rmaMwLzWR.', '韩丹', 'ADVISOR', 2, NULL, '13895350791', 't2016@thesis.edu.cn', 1, '2026-09-26 20:40:00', NOW(), NOW(), 0),
  (18, 't2017', '$2a$10$LqMgDaBZ2dVAsWxgiQ1VS.5XS8lzwxCZd1/FX6rUQW7Z.rVUeTnO6', '郝文博', 'ADVISOR', 1, NULL, '13820486985', 't2017@thesis.edu.cn', 1, '2026-09-22 20:22:00', NOW(), NOW(), 0),
  (19, 't2018', '$2a$10$AfebmP2R6k1w8m0QEi9Z9e7NajuiCl5mwPoDsw6ozUyivNrT4Mkfi', '魏书瑶', 'ADVISOR', 2, NULL, '13863830527', 't2018@thesis.edu.cn', 1, '2026-09-27 17:11:00', NOW(), NOW(), 0),
  (20, 'r3001', '$2a$10$ljrM0nBedmbLBO/D1O3YrO.smraZqdbH8qqjthzBr8hKOQ9kzp2E2', '邓桂英', 'REVIEWER', 2, NULL, '13950572332', 'r3001@thesis.edu.cn', 1, '2026-09-26 14:58:00', NOW(), NOW(), 0);

INSERT INTO `sys_user` (`id`, `username`, `password`, `real_name`, `role`, `gender`, `avatar`, `phone`, `email`, `status`, `last_login_time`, `create_time`, `update_time`, `deleted`) VALUES
  (21, 'r3002', '$2a$10$IIq/csJdcNtbS4LrxLZ4QeAKfQwhE/mNAxEgLYf/o0xgBMKs.Ef.q', '雷娜', 'REVIEWER', 2, NULL, '13913774721', 'r3002@thesis.edu.cn', 1, '2026-09-20 09:25:00', NOW(), NOW(), 0),
  (22, 'r3003', '$2a$10$zXUEbx1FIYcFTjcJmITUy.bhH7sEFkmbVxPoAKvl4B/85SsFFAcFq', '范勇', 'REVIEWER', 1, NULL, '13978449078', 'r3003@thesis.edu.cn', 1, '2026-09-28 17:27:00', NOW(), NOW(), 0),
  (23, 'r3004', '$2a$10$AV1cYmOVwN999loxqtcrJuOUc/LNpbH.bjTSsu0IAz.SqWGcOSs/e', '董雅静', 'REVIEWER', 1, NULL, '13976492523', 'r3004@thesis.edu.cn', 1, '2026-09-24 15:19:00', NOW(), NOW(), 0),
  (24, 'r3005', '$2a$10$9kc7ji9L/73QHAAzEzDA3.lqFy/t02J71DlKAJ/6M8tkeDESLbbbW', '苏伟', 'REVIEWER', 2, NULL, '13999945438', 'r3005@thesis.edu.cn', 1, '2026-09-26 21:52:00', NOW(), NOW(), 0),
  (25, 'r3006', '$2a$10$BoYyPubJC55CD9cOO4XAPeArUW6fpaZiGzMMCEHgjDXkxYIwn9lH2', '贾丹', 'REVIEWER', 2, NULL, '13960148001', 'r3006@thesis.edu.cn', 1, '2026-09-22 19:01:00', NOW(), NOW(), 0);

INSERT INTO `sys_user` (`id`, `username`, `password`, `real_name`, `role`, `gender`, `avatar`, `phone`, `email`, `status`, `last_login_time`, `create_time`, `update_time`, `deleted`) VALUES
  (26, 's20260001', '$2a$10$aF6S2cNzVL73RvT8W.p9p.IjENar2t0uPPb6R.6B1ItDThfgUK/mG', '王建国', 'STUDENT', 2, NULL, '13719744261', 's20260001@stu.thesis.edu.cn', 1, '2026-09-27 21:29:00', NOW(), NOW(), 0),
  (27, 's20260002', '$2a$10$.dB59ftAfYqTkNKWKPGvk.VBy0olQPwOa4hcbrnax66OP4mSpV7Dy', '钟宇轩', 'STUDENT', 2, NULL, '13770462714', 's20260002@stu.thesis.edu.cn', 1, '2026-09-20 19:21:00', NOW(), NOW(), 0),
  (28, 's20260003', '$2a$10$5TAqs5Jkj6hzsyDpdBpdeeoFLB84xc0sbDUfV5ocxavml8bxcDWyK', '莫宇航', 'STUDENT', 2, NULL, '13782911358', 's20260003@stu.thesis.edu.cn', 1, '2026-09-28 13:25:00', NOW(), NOW(), 0),
  (29, 's20260004', '$2a$10$sNgLkDzw2KGOZAmawcSI8eLUSjmwqafDQoxhgJJrg6ohbAWcocTgG', '刘艳', 'STUDENT', 1, NULL, '13775126722', 's20260004@stu.thesis.edu.cn', 1, '2026-09-28 11:56:00', NOW(), NOW(), 0),
  (30, 's20260005', '$2a$10$WaQJVHCc83XWJakqQasSoOLLKcvmJ14rPati8igsLpKSg8qI5Q7TS', '尹雅静', 'STUDENT', 2, NULL, '13776811913', 's20260005@stu.thesis.edu.cn', 1, '2026-09-24 14:00:00', NOW(), NOW(), 0);

INSERT INTO `sys_user` (`id`, `username`, `password`, `real_name`, `role`, `gender`, `avatar`, `phone`, `email`, `status`, `last_login_time`, `create_time`, `update_time`, `deleted`) VALUES
  (31, 's20260006', '$2a$10$jSj1Ts6a6ep0O2K2o1Ao4eYS6it3xKME7J16R6SxFNKaJTKRN1gRi', '苏春燕', 'STUDENT', 2, NULL, '13719011546', 's20260006@stu.thesis.edu.cn', 1, '2026-09-17 14:16:00', NOW(), NOW(), 0),
  (32, 's20260007', '$2a$10$0OCv0OsJD1NJv0MzNONvOOJx71FKALd2O1Ts9LHojeqFDVCg4C1Li', '邹杰', 'STUDENT', 2, NULL, '13759156582', 's20260007@stu.thesis.edu.cn', 1, '2026-09-18 15:45:00', NOW(), NOW(), 0),
  (33, 's20260008', '$2a$10$ViRZa2i6pbkeXQ0feqW/9ehhl7MiPVK1RqOfK3RaINqPR7DJlP27u', '龚斌', 'STUDENT', 1, NULL, '13779872111', 's20260008@stu.thesis.edu.cn', 1, '2026-09-29 18:49:00', NOW(), NOW(), 0),
  (34, 's20260009', '$2a$10$9ACR5cAchT2Q0Vc9yq3H2.xo2zh4zR1ChPXDuHFxrM3.j2jLQBGAu', '吴洋', 'STUDENT', 2, NULL, '13788585239', 's20260009@stu.thesis.edu.cn', 1, '2026-09-29 08:47:00', NOW(), NOW(), 0),
  (35, 's20260010', '$2a$10$kmtDjYgZ5ZSuqmz7YTGL0ewPoGxKqHSx0H8Re352qm8dAssAe.lZq', '钟伟', 'STUDENT', 2, NULL, '13739321811', 's20260010@stu.thesis.edu.cn', 1, '2026-09-15 15:14:00', NOW(), NOW(), 0);

INSERT INTO `sys_user` (`id`, `username`, `password`, `real_name`, `role`, `gender`, `avatar`, `phone`, `email`, `status`, `last_login_time`, `create_time`, `update_time`, `deleted`) VALUES
  (36, 's20260011', '$2a$10$Tz30/KKYn86jaeMa7kQNNOvB.2asQT32sPEAsaEzOwUvPvAdoR2l6', '廖伟', 'STUDENT', 1, NULL, '13751783015', 's20260011@stu.thesis.edu.cn', 1, '2026-09-18 14:23:00', NOW(), NOW(), 0),
  (37, 's20260012', '$2a$10$yq/skhjk3JMw3QhSbRcImOmLQ3WnJ.pcut0t9pxcsgDgqL3VXAJQe', '魏洋', 'STUDENT', 1, NULL, '13773803038', 's20260012@stu.thesis.edu.cn', 1, '2026-09-23 08:56:00', NOW(), NOW(), 0),
  (38, 's20270013', '$2a$10$vqRbfvYbsLZtAuoOlSr57efKrqBQvKyWAlwhJPxa/yXhTQKiOGjpy', '蒋丹', 'STUDENT', 1, NULL, '13762360457', 's20270013@stu.thesis.edu.cn', 1, '2026-09-25 12:25:00', NOW(), NOW(), 0),
  (39, 's20270014', '$2a$10$8Tq/xn8VIZ/G.Tillvrb0uvz9gSO/ntdIYf56aReSck6bFrT9jSi2', '邹丽', 'STUDENT', 1, NULL, '13791398287', 's20270014@stu.thesis.edu.cn', 1, '2026-09-26 21:46:00', NOW(), NOW(), 0),
  (40, 's20270015', '$2a$10$6ylo3y5WY8jCp51z1jwD/.YqBE/JC9GZol2amRBgzg7wnCe5MhEQK', '曹娜', 'STUDENT', 2, NULL, '13731220019', 's20270015@stu.thesis.edu.cn', 1, '2026-09-20 20:49:00', NOW(), NOW(), 0);

INSERT INTO `sys_user` (`id`, `username`, `password`, `real_name`, `role`, `gender`, `avatar`, `phone`, `email`, `status`, `last_login_time`, `create_time`, `update_time`, `deleted`) VALUES
  (41, 's20270016', '$2a$10$t59dZmBaz70zdDD18s9FhuuSalg.ToSun8PTzhNELODGjqKQsags2', '于丹', 'STUDENT', 1, NULL, '13724626521', 's20270016@stu.thesis.edu.cn', 1, '2026-09-28 08:36:00', NOW(), NOW(), 0),
  (42, 's20270017', '$2a$10$fNT8g7xy/1S1fuZAcNAo6uOAPje8drdtBuTyOyXJiDQxjTLNtu5xe', '孙辉', 'STUDENT', 1, NULL, '13744158511', 's20270017@stu.thesis.edu.cn', 1, '2026-09-22 13:37:00', NOW(), NOW(), 0),
  (43, 's20270018', '$2a$10$fT0356ZBBqDODbM3eWFPmevkzMPyAwEbaN/NJezig4ThPuJ8u4K82', '方涛', 'STUDENT', 2, NULL, '13774783306', 's20270018@stu.thesis.edu.cn', 1, '2026-09-17 20:42:00', NOW(), NOW(), 0),
  (44, 's20270019', '$2a$10$rWJxAxt5jMAWdr8cvQkEv.rJrsrgu8QwctegNPF0lLH1Dxr9Srjfy', '钱雨欣', 'STUDENT', 2, NULL, '13793980585', 's20270019@stu.thesis.edu.cn', 1, '2026-09-29 10:19:00', NOW(), NOW(), 0),
  (45, 's20270020', '$2a$10$R9ElWfZ/9nr4M1d.O5mRLezQ.FoBm5c9CWy9nX7bdzzG6gPBivAku', '魏宇航', 'STUDENT', 1, NULL, '13760145224', 's20270020@stu.thesis.edu.cn', 1, '2026-09-24 21:39:00', NOW(), NOW(), 0);

INSERT INTO `sys_user` (`id`, `username`, `password`, `real_name`, `role`, `gender`, `avatar`, `phone`, `email`, `status`, `last_login_time`, `create_time`, `update_time`, `deleted`) VALUES
  (46, 's20270021', '$2a$10$7xzugq5DQ5GYaX.GbjhRtOlC0YTGahiDCAl9mWY5fteaI6wPT8oW2', '薛明', 'STUDENT', 2, NULL, '13715780319', 's20270021@stu.thesis.edu.cn', 1, '2026-09-21 16:22:00', NOW(), NOW(), 0),
  (47, 's20270022', '$2a$10$mQNe7shsQS4slSiRkMnN7eUAAAmWl6QOnvXkY2cDn2OmKYzBWG73W', '韩芳', 'STUDENT', 1, NULL, '13790849730', 's20270022@stu.thesis.edu.cn', 1, '2026-09-20 10:12:00', NOW(), NOW(), 0),
  (48, 's20270023', '$2a$10$W9D6uvqvM9qlMwOqS7jliuS210D.MgMNe/1I7EPzIkUDmM96fAwPW', '余辉', 'STUDENT', 1, NULL, '13796196108', 's20270023@stu.thesis.edu.cn', 1, '2026-09-16 15:58:00', NOW(), NOW(), 0),
  (49, 's20270024', '$2a$10$JHYx1zgDeP65Ddf66Gr/quHIawzzh0yqOaNvsczKuBEDB9V2xq9Pe', '曾勇', 'STUDENT', 2, NULL, '13762847017', 's20270024@stu.thesis.edu.cn', 1, '2026-09-25 16:40:00', NOW(), NOW(), 0),
  (50, 's20270025', '$2a$10$TnlIWRmY.78MajERChjmxOtuiQxIKiKc5LQZ698K2JWNrAneXI8d.', '钱婷', 'STUDENT', 1, NULL, '13730658535', 's20270025@stu.thesis.edu.cn', 1, '2026-09-24 11:25:00', NOW(), NOW(), 0);

INSERT INTO `sys_user` (`id`, `username`, `password`, `real_name`, `role`, `gender`, `avatar`, `phone`, `email`, `status`, `last_login_time`, `create_time`, `update_time`, `deleted`) VALUES
  (51, 's20270026', '$2a$10$7R/vsEM1Mc5sbz6Y3uA6tu2COjxcMWoIledxrljHuBGmC8zGtqn26', '唐军', 'STUDENT', 2, NULL, '13798145678', 's20270026@stu.thesis.edu.cn', 1, '2026-09-27 15:18:00', NOW(), NOW(), 0),
  (52, 's20270027', '$2a$10$3B9EVy4pLj.QNPzvB76MwuYYZkw6IRDaq9qczBlDl0ILYXXUFfDSC', '于浩然', 'STUDENT', 2, NULL, '13715615497', 's20270027@stu.thesis.edu.cn', 1, '2026-09-22 16:36:00', NOW(), NOW(), 0),
  (53, 's20270028', '$2a$10$AScG3HY.CNdxkojz0DMwourOalSXG7ncvte5JEwL8dyqICSjC/yy2', '黎娟', 'STUDENT', 2, NULL, '13773740838', 's20270028@stu.thesis.edu.cn', 1, '2026-09-23 17:58:00', NOW(), NOW(), 0),
  (54, 's20270029', '$2a$10$o7ULyRb0Ynwc6VnsqMsx8O0mxljuI/.p9fP9RicI6EhQvhj1rBlvC', '于刚', 'STUDENT', 2, NULL, '13724915907', 's20270029@stu.thesis.edu.cn', 1, '2026-09-16 17:27:00', NOW(), NOW(), 0),
  (55, 's20270030', '$2a$10$6C93Vbjt23NJp6J1Slv17uPcfRxQl4o5kZVgR1WEb14PdJj4OWtLu', '魏峰', 'STUDENT', 2, NULL, '13798285950', 's20270030@stu.thesis.edu.cn', 1, '2026-09-24 14:33:00', NOW(), NOW(), 0);

INSERT INTO `sys_user` (`id`, `username`, `password`, `real_name`, `role`, `gender`, `avatar`, `phone`, `email`, `status`, `last_login_time`, `create_time`, `update_time`, `deleted`) VALUES
  (56, 's20270031', '$2a$10$6PqIFxAtM721XDZ7go/n/em6KoCtobPNHi7x9BMxxxWmmv6VcCDMW', '曹志强', 'STUDENT', 2, NULL, '13726237467', 's20270031@stu.thesis.edu.cn', 1, '2026-09-29 16:12:00', NOW(), NOW(), 0),
  (57, 's20270032', '$2a$10$s0By9hBw9RQePTAihi7UneFQSwVQBiSsrgV2.tjwLf5Fid2O7JDVa', '何浩然', 'STUDENT', 1, NULL, '13742233631', 's20270032@stu.thesis.edu.cn', 1, '2026-09-20 13:02:00', NOW(), NOW(), 0),
  (58, 's20270033', '$2a$10$JGbsle0Omx1CkGRGPufVV.R55sDtOUVeHmjK08b8Ugwf2DCTvl4B6', '蒋书瑶', 'STUDENT', 2, NULL, '13722042309', 's20270033@stu.thesis.edu.cn', 1, '2026-09-25 17:21:00', NOW(), NOW(), 0),
  (59, 's20270034', '$2a$10$y8gpLrHNzpEEYm0y5ip0LeZytUxDkuJxMNjhSzVpKywFQ57vozRWi', '韦琳', 'STUDENT', 1, NULL, '13744258308', 's20270034@stu.thesis.edu.cn', 1, '2026-09-21 13:59:00', NOW(), NOW(), 0),
  (60, 's20270035', '$2a$10$ZJT6LLfpqRo/ZnZf0TVg8OSh.NHZAFlqYTZgZFPvlciGsOpHcLsgS', '钱琳', 'STUDENT', 1, NULL, '13788899721', 's20270035@stu.thesis.edu.cn', 1, '2026-09-29 09:24:00', NOW(), NOW(), 0);

INSERT INTO `sys_user` (`id`, `username`, `password`, `real_name`, `role`, `gender`, `avatar`, `phone`, `email`, `status`, `last_login_time`, `create_time`, `update_time`, `deleted`) VALUES
  (61, 's20270036', '$2a$10$fnobImidFGdxFu7QP3j6q.tc4P31vQVBDwpggqmbV5Y46wBnmS3w2', '曾子涵', 'STUDENT', 1, NULL, '13767665138', 's20270036@stu.thesis.edu.cn', 1, '2026-09-22 16:27:00', NOW(), NOW(), 0),
  (62, 's20270037', '$2a$10$ddExydkOwhnW2oJTRb3orOybd02lfoe26.QGREjgWbV/ljceahqji', '宋雨欣', 'STUDENT', 1, NULL, '13796713825', 's20270037@stu.thesis.edu.cn', 1, '2026-09-18 15:10:00', NOW(), NOW(), 0),
  (63, 's20270038', '$2a$10$k6YQN3Y/qxzfgppy4URZZuq.nr0gQM9LwSK31vjGJM5NBRa.oPXRq', '朱丹', 'STUDENT', 1, NULL, '13717721081', 's20270038@stu.thesis.edu.cn', 1, '2026-09-15 09:16:00', NOW(), NOW(), 0),
  (64, 's20270039', '$2a$10$oJus/EfHZ9SM.3KZUPv/5OzUSkfG.D9/lwvezzNfIoSzFLblKFZ6K', '向浩然', 'STUDENT', 1, NULL, '13797250254', 's20270039@stu.thesis.edu.cn', 1, '2026-09-25 18:20:00', NOW(), NOW(), 0),
  (65, 's20270040', '$2a$10$gQZlY0v8c6JWl7Z7IzpODOR0WVjeT1gwP.Ce6R3Q9ka/4tgfCDVca', '尹斌', 'STUDENT', 1, NULL, '13744378141', 's20270040@stu.thesis.edu.cn', 1, '2026-09-26 18:44:00', NOW(), NOW(), 0);

INSERT INTO `sys_user` (`id`, `username`, `password`, `real_name`, `role`, `gender`, `avatar`, `phone`, `email`, `status`, `last_login_time`, `create_time`, `update_time`, `deleted`) VALUES
  (66, 's20270041', '$2a$10$wLnA75AJ3SziPTDkHQjt4u7W43h2m0cG0PRWnEO8EvH6A7mrDNBmW', '魏若曦', 'STUDENT', 2, NULL, '13782389880', 's20270041@stu.thesis.edu.cn', 1, '2026-09-15 20:40:00', NOW(), NOW(), 0),
  (67, 's20270042', '$2a$10$GIzRjl9iMoxB.sN6rguxY.AGZKw3NPuFpYafrhx83yltNVxR/x/tK', '林丽', 'STUDENT', 2, NULL, '13728963335', 's20270042@stu.thesis.edu.cn', 1, '2026-09-19 14:29:00', NOW(), NOW(), 0),
  (68, 's20270043', '$2a$10$32EypqyxbBTISvnm//L36.ib920dvJYFRogVzXmCP7G5yoD8XOtJK', '刘伟', 'STUDENT', 2, NULL, '13797755947', 's20270043@stu.thesis.edu.cn', 1, '2026-09-27 16:35:00', NOW(), NOW(), 0),
  (69, 's20270044', '$2a$10$YkfWI3RTx.RoLLnN587Asukzu3cuEMDvQGvxXr58x7P20xJC5S3Q.', '曾洋', 'STUDENT', 2, NULL, '13764293255', 's20270044@stu.thesis.edu.cn', 1, '2026-09-16 19:57:00', NOW(), NOW(), 0),
  (70, 's20270045', '$2a$10$yk3wyvFhJv8KMWvvJm6VKOu77UVq5DP5vCsqofXr1zvjzsC6Rmv2e', '宋娟', 'STUDENT', 2, NULL, '13773647039', 's20270045@stu.thesis.edu.cn', 1, '2026-09-19 17:30:00', NOW(), NOW(), 0);

INSERT INTO `sys_user` (`id`, `username`, `password`, `real_name`, `role`, `gender`, `avatar`, `phone`, `email`, `status`, `last_login_time`, `create_time`, `update_time`, `deleted`) VALUES
  (71, 's20270046', '$2a$10$VW..EBrsTxpJj8MhXemSi.ICdgPYkfdPcjL0SP1Bcj8gDkrjGvpme', '吕天佑', 'STUDENT', 2, NULL, '13714756793', 's20270046@stu.thesis.edu.cn', 1, '2026-09-15 16:48:00', NOW(), NOW(), 0),
  (72, 's20270047', '$2a$10$97L9dOS1NoQg6QKOcPW65u36Fol8XoOViRTM6O6PZxz/vemH2P18O', '汤子涵', 'STUDENT', 2, NULL, '13743858426', 's20270047@stu.thesis.edu.cn', 1, '2026-09-16 14:02:00', NOW(), NOW(), 0),
  (73, 's20270048', '$2a$10$yByzDsb4nZ6kHeFUXBthEeBBl2kYiMbk7n7jKYpQi3ZFe5MkoLhs.', '余子涵', 'STUDENT', 1, NULL, '13777355454', 's20270048@stu.thesis.edu.cn', 1, '2026-09-22 21:35:00', NOW(), NOW(), 0),
  (74, 's20270049', '$2a$10$p8Dqd6WngcZ/I7qhgRFnIu3onhrYDXR5K2U2jOEyfpt0F.5goci8y', '马丹', 'STUDENT', 1, NULL, '13723926698', 's20270049@stu.thesis.edu.cn', 1, '2026-09-22 11:54:00', NOW(), NOW(), 0),
  (75, 's20270050', '$2a$10$o6LuvI2eXQWBl1A1eeN35uBcOqPpK6gyKMVgKQ2gP/ReXLerV1xSe', '魏文博', 'STUDENT', 2, NULL, '13799791544', 's20270050@stu.thesis.edu.cn', 1, '2026-09-26 16:01:00', NOW(), NOW(), 0);

INSERT INTO `sys_user` (`id`, `username`, `password`, `real_name`, `role`, `gender`, `avatar`, `phone`, `email`, `status`, `last_login_time`, `create_time`, `update_time`, `deleted`) VALUES
  (76, 's20270051', '$2a$10$UXxto4HjjxSbXxRWkZyii.dVgtCA/61gdg72/HslOP4pZKAhu5z2C', '白磊', 'STUDENT', 1, NULL, '13782152550', 's20270051@stu.thesis.edu.cn', 1, '2026-09-16 08:41:00', NOW(), NOW(), 0),
  (77, 's20270052', '$2a$10$dVPabMXrRnh5PU.O0/eJm.g8Pp8FoVjQgoMe6OXVq23YDXy577qNK', '毛军', 'STUDENT', 2, NULL, '13739456503', 's20270052@stu.thesis.edu.cn', 1, '2026-09-28 12:32:00', NOW(), NOW(), 0),
  (78, 's20270053', '$2a$10$pO061QBiBQQU/9xOreq.ZedDgfZef0ZLWbDRaayIvt7PoyO3RcnE.', '薛俊杰', 'STUDENT', 2, NULL, '13791570551', 's20270053@stu.thesis.edu.cn', 1, '2026-09-26 12:22:00', NOW(), NOW(), 0),
  (79, 's20270054', '$2a$10$YFEqqY41V6Y5m/rnby4gde1BvQTffmBvfxToOhZfZiwNH8w2rqeAK', '田桂英', 'STUDENT', 1, NULL, '13716904673', 's20270054@stu.thesis.edu.cn', 1, '2026-09-27 08:08:00', NOW(), NOW(), 0),
  (80, 's20270055', '$2a$10$OiEIw2.AUH0VUiYS8BiR1OgijLrsT6VSIsh9WlFU7S3Pa8Zqdgku.', '严琳', 'STUDENT', 2, NULL, '13757109509', 's20270055@stu.thesis.edu.cn', 1, '2026-09-15 08:52:00', NOW(), NOW(), 0);

-- 2. 教师档案（teacher）
INSERT INTO `teacher` (`id`, `user_id`, `teacher_no`, `real_name`, `gender`, `title`, `college`, `major`, `teacher_type`, `can_review`, `max_quota`, `phone`, `email`, `create_time`, `update_time`, `deleted`) VALUES
  (1, 2, 'T2001', '熊军', 2, '助教', '软件学院', '软件工程', 'ADVISOR', 0, 8, '13857415971', 't2001@thesis.edu.cn', NOW(), NOW(), 0),
  (2, 3, 'T2002', '侯志强', 2, '讲师', '电子信息学院', '通信工程', 'ADVISOR', 0, 8, '13811820639', 't2002@thesis.edu.cn', NOW(), NOW(), 0),
  (3, 4, 'T2003', '方辉', 1, '副教授', '计算机与人工智能学院', '人工智能', 'ADVISOR', 0, 8, '13812153934', 't2003@thesis.edu.cn', NOW(), NOW(), 0),
  (4, 5, 'T2004', '钱雨欣', 1, '讲师', '软件学院', '网络空间安全', 'ADVISOR', 0, 8, '13893633452', 't2004@thesis.edu.cn', NOW(), NOW(), 0),
  (5, 6, 'T2005', '彭明', 2, '副教授', '电子信息学院', '通信工程', 'ADVISOR', 0, 8, '13863267468', 't2005@thesis.edu.cn', NOW(), NOW(), 0),
  (6, 7, 'T2006', '曹明', 2, '助教', '计算机与人工智能学院', '计算机科学与技术', 'ADVISOR', 0, 8, '13811130575', 't2006@thesis.edu.cn', NOW(), NOW(), 0),
  (7, 8, 'T2007', '熊宇航', 1, '讲师', '软件学院', '软件工程', 'ADVISOR', 0, 8, '13841730443', 't2007@thesis.edu.cn', NOW(), NOW(), 0),
  (8, 9, 'T2008', '严嘉怡', 2, '教授', '电子信息学院', '通信工程', 'ADVISOR', 0, 8, '13873483815', 't2008@thesis.edu.cn', NOW(), NOW(), 0),
  (9, 10, 'T2009', '陈桂英', 1, '教授', '计算机与人工智能学院', '计算机科学与技术', 'ADVISOR', 0, 8, '13827112433', 't2009@thesis.edu.cn', NOW(), NOW(), 0),
  (10, 11, 'T2010', '朱文博', 2, '助教', '软件学院', '网络空间安全', 'ADVISOR', 0, 8, '13863189418', 't2010@thesis.edu.cn', NOW(), NOW(), 0),
  (11, 12, 'T2011', '史一鸣', 1, '讲师', '电子信息学院', '通信工程', 'ADVISOR', 0, 8, '13862279550', 't2011@thesis.edu.cn', NOW(), NOW(), 0),
  (12, 13, 'T2012', '姜超', 2, '副教授', '计算机与人工智能学院', '人工智能', 'ADVISOR', 0, 8, '13862091334', 't2012@thesis.edu.cn', NOW(), NOW(), 0),
  (13, 14, 'T2013', '刘洋', 1, '教授', '软件学院', '网络空间安全', 'ADVISOR', 0, 8, '13864626760', 't2013@thesis.edu.cn', NOW(), NOW(), 0),
  (14, 15, 'T2014', '毛梓萱', 2, '教授', '电子信息学院', '电子信息工程', 'ADVISOR', 0, 8, '13810181964', 't2014@thesis.edu.cn', NOW(), NOW(), 0),
  (15, 16, 'T2015', '蔡斌', 2, '副教授', '计算机与人工智能学院', '人工智能', 'ADVISOR', 0, 8, '13862674515', 't2015@thesis.edu.cn', NOW(), NOW(), 0),
  (16, 17, 'T2016', '韩丹', 2, '讲师', '软件学院', '网络空间安全', 'ADVISOR', 0, 8, '13895350791', 't2016@thesis.edu.cn', NOW(), NOW(), 0),
  (17, 18, 'T2017', '郝文博', 1, '讲师', '电子信息学院', '通信工程', 'ADVISOR', 0, 8, '13820486985', 't2017@thesis.edu.cn', NOW(), NOW(), 0),
  (18, 19, 'T2018', '魏书瑶', 2, '讲师', '计算机与人工智能学院', '数据科学与大数据技术', 'ADVISOR', 0, 8, '13863830527', 't2018@thesis.edu.cn', NOW(), NOW(), 0),
  (19, 20, 'T3001', '邓桂英', 2, '副教授', '电子信息学院', '电子信息工程', 'REVIEWER', 1, 0, '13950572332', 'r3001@thesis.edu.cn', NOW(), NOW(), 0),
  (20, 21, 'T3002', '雷娜', 2, '副教授', '计算机与人工智能学院', '数据科学与大数据技术', 'REVIEWER', 1, 0, '13913774721', 'r3002@thesis.edu.cn', NOW(), NOW(), 0);

INSERT INTO `teacher` (`id`, `user_id`, `teacher_no`, `real_name`, `gender`, `title`, `college`, `major`, `teacher_type`, `can_review`, `max_quota`, `phone`, `email`, `create_time`, `update_time`, `deleted`) VALUES
  (21, 22, 'T3003', '范勇', 1, '副教授', '软件学院', '软件工程', 'REVIEWER', 1, 0, '13978449078', 'r3003@thesis.edu.cn', NOW(), NOW(), 0),
  (22, 23, 'T3004', '董雅静', 1, '副教授', '电子信息学院', '通信工程', 'REVIEWER', 1, 0, '13976492523', 'r3004@thesis.edu.cn', NOW(), NOW(), 0),
  (23, 24, 'T3005', '苏伟', 2, '讲师', '计算机与人工智能学院', '计算机科学与技术', 'REVIEWER', 1, 0, '13999945438', 'r3005@thesis.edu.cn', NOW(), NOW(), 0),
  (24, 25, 'T3006', '贾丹', 2, '教授', '软件学院', '网络空间安全', 'REVIEWER', 1, 0, '13960148001', 'r3006@thesis.edu.cn', NOW(), NOW(), 0);

-- 3. 学生档案（student）
INSERT INTO `student` (`id`, `user_id`, `student_no`, `real_name`, `gender`, `grade`, `college`, `major`, `class_name`, `advisor_id`, `phone`, `email`, `create_time`, `update_time`, `deleted`) VALUES
  (1, 26, '20260001', '王建国', 2, '2026', '计算机与人工智能学院', '计算机科学与技术', '计科22-1班', 1, '13719744261', 's20260001@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (2, 27, '20260002', '钟宇轩', 2, '2026', '软件学院', '网络空间安全', '网安22-2班', 2, '13770462714', 's20260002@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (3, 28, '20260003', '莫宇航', 2, '2026', '电子信息学院', '电子信息工程', '电信22-1班', 3, '13782911358', 's20260003@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (4, 29, '20260004', '刘艳', 1, '2026', '计算机与人工智能学院', '计算机科学与技术', '计科22-2班', 4, '13775126722', 's20260004@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (5, 30, '20260005', '尹雅静', 2, '2026', '软件学院', '软件工程', '软工22-1班', 5, '13776811913', 's20260005@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (6, 31, '20260006', '苏春燕', 2, '2026', '电子信息学院', '通信工程', '通信22-2班', 6, '13719011546', 's20260006@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (7, 32, '20260007', '邹杰', 2, '2026', '计算机与人工智能学院', '计算机科学与技术', '计科22-1班', 7, '13759156582', 's20260007@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (8, 33, '20260008', '龚斌', 1, '2026', '软件学院', '网络空间安全', '网安22-2班', 8, '13779872111', 's20260008@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (9, 34, '20260009', '吴洋', 2, '2026', '电子信息学院', '电子信息工程', '电信22-1班', 9, '13788585239', 's20260009@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (10, 35, '20260010', '钟伟', 2, '2026', '计算机与人工智能学院', '计算机科学与技术', '计科22-2班', 10, '13739321811', 's20260010@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (11, 36, '20260011', '廖伟', 1, '2026', '软件学院', '软件工程', '软工22-1班', 11, '13751783015', 's20260011@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (12, 37, '20260012', '魏洋', 1, '2026', '电子信息学院', '通信工程', '通信22-2班', 12, '13773803038', 's20260012@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (13, 38, '20270013', '蒋丹', 1, '2027', '计算机与人工智能学院', '计算机科学与技术', '计科23-1班', 13, '13762360457', 's20270013@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (14, 39, '20270014', '邹丽', 1, '2027', '软件学院', '网络空间安全', '网安23-2班', 14, '13791398287', 's20270014@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (15, 40, '20270015', '曹娜', 2, '2027', '电子信息学院', '电子信息工程', '电信23-1班', 15, '13731220019', 's20270015@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (16, 41, '20270016', '于丹', 1, '2027', '计算机与人工智能学院', '计算机科学与技术', '计科23-2班', 16, '13724626521', 's20270016@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (17, 42, '20270017', '孙辉', 1, '2027', '软件学院', '软件工程', '软工23-1班', 17, '13744158511', 's20270017@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (18, 43, '20270018', '方涛', 2, '2027', '电子信息学院', '通信工程', '通信23-2班', 18, '13774783306', 's20270018@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (19, 44, '20270019', '钱雨欣', 2, '2027', '计算机与人工智能学院', '计算机科学与技术', '计科23-1班', 1, '13793980585', 's20270019@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (20, 45, '20270020', '魏宇航', 1, '2027', '软件学院', '网络空间安全', '网安23-2班', 2, '13760145224', 's20270020@stu.thesis.edu.cn', NOW(), NOW(), 0);

INSERT INTO `student` (`id`, `user_id`, `student_no`, `real_name`, `gender`, `grade`, `college`, `major`, `class_name`, `advisor_id`, `phone`, `email`, `create_time`, `update_time`, `deleted`) VALUES
  (21, 46, '20270021', '薛明', 2, '2027', '电子信息学院', '电子信息工程', '电信23-1班', 3, '13715780319', 's20270021@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (22, 47, '20270022', '韩芳', 1, '2027', '计算机与人工智能学院', '计算机科学与技术', '计科23-2班', 4, '13790849730', 's20270022@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (23, 48, '20270023', '余辉', 1, '2027', '软件学院', '软件工程', '软工23-1班', 5, '13796196108', 's20270023@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (24, 49, '20270024', '曾勇', 2, '2027', '电子信息学院', '通信工程', '通信23-2班', 6, '13762847017', 's20270024@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (25, 50, '20270025', '钱婷', 1, '2027', '计算机与人工智能学院', '计算机科学与技术', '计科23-1班', 7, '13730658535', 's20270025@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (26, 51, '20270026', '唐军', 2, '2027', '软件学院', '网络空间安全', '网安23-2班', 8, '13798145678', 's20270026@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (27, 52, '20270027', '于浩然', 2, '2027', '电子信息学院', '电子信息工程', '电信23-1班', 9, '13715615497', 's20270027@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (28, 53, '20270028', '黎娟', 2, '2027', '计算机与人工智能学院', '计算机科学与技术', '计科23-2班', 10, '13773740838', 's20270028@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (29, 54, '20270029', '于刚', 2, '2027', '软件学院', '软件工程', '软工23-1班', 11, '13724915907', 's20270029@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (30, 55, '20270030', '魏峰', 2, '2027', '电子信息学院', '通信工程', '通信23-2班', 12, '13798285950', 's20270030@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (31, 56, '20270031', '曹志强', 2, '2027', '计算机与人工智能学院', '计算机科学与技术', '计科23-1班', 13, '13726237467', 's20270031@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (32, 57, '20270032', '何浩然', 1, '2027', '软件学院', '网络空间安全', '网安23-2班', 14, '13742233631', 's20270032@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (33, 58, '20270033', '蒋书瑶', 2, '2027', '电子信息学院', '电子信息工程', '电信23-1班', 15, '13722042309', 's20270033@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (34, 59, '20270034', '韦琳', 1, '2027', '计算机与人工智能学院', '计算机科学与技术', '计科23-2班', 16, '13744258308', 's20270034@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (35, 60, '20270035', '钱琳', 1, '2027', '软件学院', '软件工程', '软工23-1班', 17, '13788899721', 's20270035@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (36, 61, '20270036', '曾子涵', 1, '2027', '电子信息学院', '通信工程', '通信23-2班', 18, '13767665138', 's20270036@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (37, 62, '20270037', '宋雨欣', 1, '2027', '计算机与人工智能学院', '计算机科学与技术', '计科23-1班', 1, '13796713825', 's20270037@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (38, 63, '20270038', '朱丹', 1, '2027', '软件学院', '网络空间安全', '网安23-2班', 2, '13717721081', 's20270038@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (39, 64, '20270039', '向浩然', 1, '2027', '电子信息学院', '电子信息工程', '电信23-1班', 3, '13797250254', 's20270039@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (40, 65, '20270040', '尹斌', 1, '2027', '计算机与人工智能学院', '计算机科学与技术', '计科23-2班', 4, '13744378141', 's20270040@stu.thesis.edu.cn', NOW(), NOW(), 0);

INSERT INTO `student` (`id`, `user_id`, `student_no`, `real_name`, `gender`, `grade`, `college`, `major`, `class_name`, `advisor_id`, `phone`, `email`, `create_time`, `update_time`, `deleted`) VALUES
  (41, 66, '20270041', '魏若曦', 2, '2027', '软件学院', '软件工程', '软工23-1班', 5, '13782389880', 's20270041@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (42, 67, '20270042', '林丽', 2, '2027', '电子信息学院', '通信工程', '通信23-2班', 6, '13728963335', 's20270042@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (43, 68, '20270043', '刘伟', 2, '2027', '计算机与人工智能学院', '计算机科学与技术', '计科23-1班', 7, '13797755947', 's20270043@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (44, 69, '20270044', '曾洋', 2, '2027', '软件学院', '网络空间安全', '网安23-2班', 8, '13764293255', 's20270044@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (45, 70, '20270045', '宋娟', 2, '2027', '电子信息学院', '电子信息工程', '电信23-1班', 9, '13773647039', 's20270045@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (46, 71, '20270046', '吕天佑', 2, '2027', '计算机与人工智能学院', '计算机科学与技术', '计科23-2班', 10, '13714756793', 's20270046@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (47, 72, '20270047', '汤子涵', 2, '2027', '软件学院', '软件工程', '软工23-1班', 11, '13743858426', 's20270047@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (48, 73, '20270048', '余子涵', 1, '2027', '电子信息学院', '通信工程', '通信23-2班', 12, '13777355454', 's20270048@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (49, 74, '20270049', '马丹', 1, '2027', '计算机与人工智能学院', '计算机科学与技术', '计科23-1班', 13, '13723926698', 's20270049@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (50, 75, '20270050', '魏文博', 2, '2027', '软件学院', '网络空间安全', '网安23-2班', 14, '13799791544', 's20270050@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (51, 76, '20270051', '白磊', 1, '2027', '电子信息学院', '电子信息工程', '电信23-1班', NULL, '13782152550', 's20270051@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (52, 77, '20270052', '毛军', 2, '2027', '计算机与人工智能学院', '计算机科学与技术', '计科23-2班', NULL, '13739456503', 's20270052@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (53, 78, '20270053', '薛俊杰', 2, '2027', '软件学院', '软件工程', '软工23-1班', NULL, '13791570551', 's20270053@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (54, 79, '20270054', '田桂英', 1, '2027', '电子信息学院', '通信工程', '通信23-2班', NULL, '13716904673', 's20270054@stu.thesis.edu.cn', NOW(), NOW(), 0),
  (55, 80, '20270055', '严琳', 2, '2027', '计算机与人工智能学院', '计算机科学与技术', '计科23-1班', NULL, '13757109509', 's20270055@stu.thesis.edu.cn', NOW(), NOW(), 0);

-- 4. 课题（topic）
INSERT INTO `topic` (`id`, `title`, `topic_type`, `source`, `teacher_id`, `grade`, `college`, `major`, `description`, `requirement`, `capacity`, `selected_count`, `status`, `publish_time`, `create_time`, `update_time`, `deleted`) VALUES
  (1, '基于数据挖掘的学生就业去向分析', '工程设计', '企业真题', 1, '2026', '软件学院', '软件工程', '本课题围绕《基于数据挖掘的学生就业去向分析》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'CLOSED', '2026-01-06 08:16:00', NOW(), NOW(), 0),
  (2, '基于边缘计算的车联网消息认证', '理论研究', '企业真题', 2, '2026', '电子信息学院', '通信工程', '本课题围绕《基于边缘计算的车联网消息认证》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'CLOSED', '2026-01-06 21:24:00', NOW(), NOW(), 0),
  (3, '基于图神经网络的交通路网流量预测', '实验研究', '教师命题', 3, '2026', '计算机与人工智能学院', '人工智能', '本课题围绕《基于图神经网络的交通路网流量预测》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'CLOSED', '2026-01-06 16:43:00', NOW(), NOW(), 0),
  (4, '基于计算机视觉的工业缺陷检测', '理论研究', '企业真题', 4, '2026', '软件学院', '网络空间安全', '本课题围绕《基于计算机视觉的工业缺陷检测》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'CLOSED', '2026-01-06 10:07:00', NOW(), NOW(), 0),
  (5, '基于自然语言处理的舆情监测系统', '工程设计', '学生自拟', 5, '2026', '电子信息学院', '通信工程', '本课题围绕《基于自然语言处理的舆情监测系统》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'CLOSED', '2026-01-06 12:09:00', NOW(), NOW(), 0),
  (6, '基于自然语言处理的新闻文本分类', '调研报告', '企业真题', 6, '2026', '计算机与人工智能学院', '计算机科学与技术', '本课题围绕《基于自然语言处理的新闻文本分类》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'CLOSED', '2026-01-06 16:31:00', NOW(), NOW(), 0),
  (7, '实验设备预约与管控的设计与实现', '软件开发', '教师命题', 7, '2026', '软件学院', '软件工程', '本课题围绕《实验设备预约与管控的设计与实现》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'CLOSED', '2026-01-06 15:57:00', NOW(), NOW(), 0),
  (8, '基于注意力机制的长文本摘要生成', '实验研究', '学生自拟', 8, '2026', '电子信息学院', '通信工程', '本课题围绕《基于注意力机制的长文本摘要生成》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'CLOSED', '2026-01-06 21:08:00', NOW(), NOW(), 0),
  (9, '在线考试系统弹性部署的设计与实现', '实验研究', '学生自拟', 9, '2026', '计算机与人工智能学院', '计算机科学与技术', '本课题围绕《在线考试系统弹性部署的设计与实现》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'CLOSED', '2026-01-06 16:48:00', NOW(), NOW(), 0),
  (10, '基于机器学习的财务风险预警', '实验研究', '学生自拟', 10, '2026', '软件学院', '网络空间安全', '本课题围绕《基于机器学习的财务风险预警》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'CLOSED', '2026-01-06 08:25:00', NOW(), NOW(), 0),
  (11, '基于大语言模型的代码缺陷自动定位', '调研报告', '学生自拟', 11, '2026', '电子信息学院', '通信工程', '本课题围绕《基于大语言模型的代码缺陷自动定位》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'CLOSED', '2026-01-06 18:35:00', NOW(), NOW(), 0),
  (12, '基于数据挖掘的图书借阅模式挖掘', '实验研究', '教师命题', 12, '2026', '计算机与人工智能学院', '人工智能', '本课题围绕《基于数据挖掘的图书借阅模式挖掘》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'CLOSED', '2026-01-06 17:30:00', NOW(), NOW(), 0),
  (13, '基于深度学习的医学影像分割', '软件开发', '教师命题', 13, '2027', '软件学院', '网络空间安全', '本课题围绕《基于深度学习的医学影像分割》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 08:17:00', NOW(), NOW(), 0),
  (14, '基于多模态融合的短视频内容审核', '理论研究', '企业真题', 14, '2027', '电子信息学院', '电子信息工程', '本课题围绕《基于多模态融合的短视频内容审核》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 12:28:00', NOW(), NOW(), 0),
  (15, '基于迁移学习的跨领域情感分析', '实验研究', '学生自拟', 15, '2027', '计算机与人工智能学院', '人工智能', '本课题围绕《基于迁移学习的跨领域情感分析》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 13:57:00', NOW(), NOW(), 0),
  (16, '基于强化学习的动态资源调度', '工程设计', '教师命题', 16, '2027', '软件学院', '网络空间安全', '本课题围绕《基于强化学习的动态资源调度》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 11:48:00', NOW(), NOW(), 0),
  (17, '基于机器学习的用户流失预测', '工程设计', '教师命题', 17, '2027', '电子信息学院', '通信工程', '本课题围绕《基于机器学习的用户流失预测》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 17:13:00', NOW(), NOW(), 0),
  (18, '在线考试系统的设计与实现', '工程设计', '学生自拟', 18, '2027', '计算机与人工智能学院', '数据科学与大数据技术', '本课题围绕《在线考试系统的设计与实现》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 16:34:00', NOW(), NOW(), 0),
  (19, '基于数字孪生的智能制造产线仿真', '调研报告', '教师命题', 1, '2027', '软件学院', '软件工程', '本课题围绕《基于数字孪生的智能制造产线仿真》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 19:16:00', NOW(), NOW(), 0),
  (20, '基于迁移学习的小样本医学影像分类', '实验研究', '教师命题', 2, '2027', '电子信息学院', '通信工程', '本课题围绕《基于迁移学习的小样本医学影像分类》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 09:15:00', NOW(), NOW(), 0);

INSERT INTO `topic` (`id`, `title`, `topic_type`, `source`, `teacher_id`, `grade`, `college`, `major`, `description`, `requirement`, `capacity`, `selected_count`, `status`, `publish_time`, `create_time`, `update_time`, `deleted`) VALUES
  (21, '基于时序分析的城市短时交通流量预测', '调研报告', '企业真题', 3, '2027', '计算机与人工智能学院', '人工智能', '本课题围绕《基于时序分析的城市短时交通流量预测》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 21:57:00', NOW(), NOW(), 0),
  (22, '基于强化学习的仓储机器人路径规划', '软件开发', '教师命题', 4, '2027', '软件学院', '网络空间安全', '本课题围绕《基于强化学习的仓储机器人路径规划》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 09:30:00', NOW(), NOW(), 0),
  (23, '微服务链路追踪平台的设计与实现', '实验研究', '学生自拟', 5, '2027', '电子信息学院', '通信工程', '本课题围绕《微服务链路追踪平台的设计与实现》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 16:27:00', NOW(), NOW(), 0),
  (24, '基于时序分析的食堂人流预测', '工程设计', '教师命题', 6, '2027', '计算机与人工智能学院', '计算机科学与技术', '本课题围绕《基于时序分析的食堂人流预测》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 21:22:00', NOW(), NOW(), 0),
  (25, '供应链溯源系统的设计与实现', '实验研究', '教师命题', 7, '2027', '软件学院', '软件工程', '本课题围绕《供应链溯源系统的设计与实现》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 15:14:00', NOW(), NOW(), 0),
  (26, '基于机器学习的学生成绩分析', '调研报告', '企业真题', 8, '2027', '电子信息学院', '通信工程', '本课题围绕《基于机器学习的学生成绩分析》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 16:46:00', NOW(), NOW(), 0),
  (27, '基于多模态融合的远程心电监测', '工程设计', '教师命题', 9, '2027', '计算机与人工智能学院', '计算机科学与技术', '本课题围绕《基于多模态融合的远程心电监测》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 16:03:00', NOW(), NOW(), 0),
  (28, '基于计算机视觉的人脸考勤系统', '软件开发', '学生自拟', 10, '2027', '软件学院', '网络空间安全', '本课题围绕《基于计算机视觉的人脸考勤系统》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 09:41:00', NOW(), NOW(), 0),
  (29, '基于机器学习的能耗异常检测', '理论研究', '学生自拟', 11, '2027', '电子信息学院', '通信工程', '本课题围绕《基于机器学习的能耗异常检测》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 15:06:00', NOW(), NOW(), 0),
  (30, '停车位检测系统的设计与实现', '理论研究', '学生自拟', 12, '2027', '计算机与人工智能学院', '人工智能', '本课题围绕《停车位检测系统的设计与实现》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 15:06:00', NOW(), NOW(), 0),
  (31, '基于大语言模型的智能问答系统', '实验研究', '学生自拟', 13, '2027', '软件学院', '网络空间安全', '本课题围绕《基于大语言模型的智能问答系统》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 10:19:00', NOW(), NOW(), 0),
  (32, '基于知识图谱的智能问答系统', '工程设计', '企业真题', 14, '2027', '电子信息学院', '电子信息工程', '本课题围绕《基于知识图谱的智能问答系统》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 21:01:00', NOW(), NOW(), 0),
  (33, '基于时序分析的校园网流量预测', '软件开发', '教师命题', 15, '2027', '计算机与人工智能学院', '人工智能', '本课题围绕《基于时序分析的校园网流量预测》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 20:11:00', NOW(), NOW(), 0),
  (34, '基于知识图谱的医疗知识图谱构建', '实验研究', '学生自拟', 16, '2027', '软件学院', '网络空间安全', '本课题围绕《基于知识图谱的医疗知识图谱构建》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 09:40:00', NOW(), NOW(), 0),
  (35, '基于大语言模型的题库自动组卷', '调研报告', '企业真题', 17, '2027', '电子信息学院', '通信工程', '本课题围绕《基于大语言模型的题库自动组卷》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 14:32:00', NOW(), NOW(), 0),
  (36, '电子成绩单存证的设计与实现', '工程设计', '学生自拟', 18, '2027', '计算机与人工智能学院', '数据科学与大数据技术', '本课题围绕《电子成绩单存证的设计与实现》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 21:26:00', NOW(), NOW(), 0),
  (37, '基于数据挖掘的校园一卡通消费行为分析', '软件开发', '教师命题', 1, '2027', '软件学院', '软件工程', '本课题围绕《基于数据挖掘的校园一卡通消费行为分析》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 20:27:00', NOW(), NOW(), 0),
  (38, '智慧农业环境监测的设计与实现', '软件开发', '学生自拟', 2, '2027', '电子信息学院', '通信工程', '本课题围绕《智慧农业环境监测的设计与实现》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 21:57:00', NOW(), NOW(), 0),
  (39, '基于计算机视觉的停车位检测', '实验研究', '教师命题', 3, '2027', '计算机与人工智能学院', '人工智能', '本课题围绕《基于计算机视觉的停车位检测》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 08:16:00', NOW(), NOW(), 0),
  (40, '基于自然语言处理的电商评论情感分析', '理论研究', '教师命题', 4, '2027', '软件学院', '网络空间安全', '本课题围绕《基于自然语言处理的电商评论情感分析》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 16:36:00', NOW(), NOW(), 0);

INSERT INTO `topic` (`id`, `title`, `topic_type`, `source`, `teacher_id`, `grade`, `college`, `major`, `description`, `requirement`, `capacity`, `selected_count`, `status`, `publish_time`, `create_time`, `update_time`, `deleted`) VALUES
  (41, '基于深度学习的工业缺陷检测', '调研报告', '企业真题', 5, '2027', '电子信息学院', '通信工程', '本课题围绕《基于深度学习的工业缺陷检测》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 08:38:00', NOW(), NOW(), 0),
  (42, '基于时序分析的供应链需求预测', '工程设计', '教师命题', 6, '2027', '计算机与人工智能学院', '计算机科学与技术', '本课题围绕《基于时序分析的供应链需求预测》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 13:05:00', NOW(), NOW(), 0),
  (43, '基于注意力机制的语音情感识别', '工程设计', '企业真题', 7, '2027', '软件学院', '软件工程', '本课题围绕《基于注意力机制的语音情感识别》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 13:47:00', NOW(), NOW(), 0),
  (44, '基于边缘计算的无人零售结算', '实验研究', '企业真题', 8, '2027', '电子信息学院', '通信工程', '本课题围绕《基于边缘计算的无人零售结算》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 16:15:00', NOW(), NOW(), 0),
  (45, '基于自然语言处理的短视频内容审核', '工程设计', '企业真题', 9, '2027', '计算机与人工智能学院', '计算机科学与技术', '本课题围绕《基于自然语言处理的短视频内容审核》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 18:26:00', NOW(), NOW(), 0),
  (46, '基于深度学习的手写公式识别', '调研报告', '企业真题', 10, '2027', '软件学院', '网络空间安全', '本课题围绕《基于深度学习的手写公式识别》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 10:30:00', NOW(), NOW(), 0),
  (47, '基于知识图谱的课程知识点推荐', '调研报告', '企业真题', 11, '2027', '电子信息学院', '通信工程', '本课题围绕《基于知识图谱的课程知识点推荐》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 18:59:00', NOW(), NOW(), 0),
  (48, '基于知识图谱的论文文献推荐', '软件开发', '学生自拟', 12, '2027', '计算机与人工智能学院', '人工智能', '本课题围绕《基于知识图谱的论文文献推荐》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 09:11:00', NOW(), NOW(), 0),
  (49, '图书馆推荐系统的设计与实现', '理论研究', '企业真题', 13, '2027', '软件学院', '网络空间安全', '本课题围绕《图书馆推荐系统的设计与实现》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 18:27:00', NOW(), NOW(), 0),
  (50, '基于边缘计算的智能家居协同控制', '工程设计', '学生自拟', 14, '2027', '电子信息学院', '电子信息工程', '本课题围绕《基于边缘计算的智能家居协同控制》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，最终提交完整论文与可运行成果。', '1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；3. 按时参加开题、中期与答辩各环节。', 1, 1, 'SELECTED', '2026-08-28 10:10:00', NOW(), NOW(), 0),
  (51, '基于深度学习的语音情感识别', '实验研究', '企业真题', 15, '2027', '计算机与人工智能学院', '人工智能', '本课题围绕《基于深度学习的语音情感识别》展开，欢迎对该方向感兴趣的同学申报。', '具备相关课程基础，能独立完成设计与实现。', 1, 0, 'OPEN', '2026-08-30 19:08:00', NOW(), NOW(), 0),
  (52, '基于深度学习的农作物病害识别', '软件开发', '教师命题', 16, '2027', '软件学院', '网络空间安全', '本课题围绕《基于深度学习的农作物病害识别》展开，欢迎对该方向感兴趣的同学申报。', '具备相关课程基础，能独立完成设计与实现。', 1, 0, 'OPEN', '2026-08-30 10:09:00', NOW(), NOW(), 0),
  (53, '实验设备预约系统的设计与实现', '软件开发', '学生自拟', 17, '2027', '电子信息学院', '通信工程', '本课题围绕《实验设备预约系统的设计与实现》展开，欢迎对该方向感兴趣的同学申报。', '具备相关课程基础，能独立完成设计与实现。', 1, 0, 'OPEN', '2026-08-30 15:55:00', NOW(), NOW(), 0),
  (54, '基于边缘计算的视频流实时分析', '软件开发', '教师命题', 18, '2027', '计算机与人工智能学院', '数据科学与大数据技术', '本课题围绕《基于边缘计算的视频流实时分析》展开，欢迎对该方向感兴趣的同学申报。', '具备相关课程基础，能独立完成设计与实现。', 1, 0, 'OPEN', '2026-08-30 15:54:00', NOW(), NOW(), 0),
  (55, '基于数字孪生的校园能耗可视化', '软件开发', '教师命题', 1, '2027', '软件学院', '软件工程', '本课题围绕《基于数字孪生的校园能耗可视化》展开，欢迎对该方向感兴趣的同学申报。', '具备相关课程基础，能独立完成设计与实现。', 1, 0, 'OPEN', '2026-08-30 13:17:00', NOW(), NOW(), 0),
  (56, '基于联邦学习的跨机构医疗数据建模', '理论研究', '教师命题', 2, '2027', '电子信息学院', '通信工程', '本课题围绕《基于联邦学习的跨机构医疗数据建模》展开，欢迎对该方向感兴趣的同学申报。', '具备相关课程基础，能独立完成设计与实现。', 1, 0, 'OPEN', '2026-08-30 14:30:00', NOW(), NOW(), 0),
  (57, '基于图神经网络的社交网络链路预测', '软件开发', '企业真题', 3, '2027', '计算机与人工智能学院', '人工智能', '本课题围绕《基于图神经网络的社交网络链路预测》展开，欢迎对该方向感兴趣的同学申报。', '具备相关课程基础，能独立完成设计与实现。', 1, 0, 'OPEN', '2026-08-30 21:38:00', NOW(), NOW(), 0),
  (58, '基于机器学习的课程成绩预警', '调研报告', '教师命题', 4, '2027', '软件学院', '网络空间安全', '本课题围绕《基于机器学习的课程成绩预警》展开，欢迎对该方向感兴趣的同学申报。', '具备相关课程基础，能独立完成设计与实现。', 1, 0, 'OPEN', '2026-08-30 15:34:00', NOW(), NOW(), 0),
  (59, '基于联邦学习的隐私保护下的用户行为建模', '理论研究', '学生自拟', 5, '2027', '电子信息学院', '通信工程', '本课题围绕《基于联邦学习的隐私保护下的用户行为建模》展开，欢迎对该方向感兴趣的同学申报。', '具备相关课程基础，能独立完成设计与实现。', 1, 0, 'OPEN', '2026-08-30 12:42:00', NOW(), NOW(), 0),
  (60, '校园二手交易平台的设计与实现', '工程设计', '企业真题', 6, '2027', '计算机与人工智能学院', '计算机科学与技术', '本课题围绕《校园二手交易平台的设计与实现》展开，欢迎对该方向感兴趣的同学申报。', '具备相关课程基础，能独立完成设计与实现。', 1, 0, 'OPEN', '2026-08-30 13:22:00', NOW(), NOW(), 0);

-- 5. 选题申请（selection）
INSERT INTO `selection` (`id`, `topic_id`, `student_id`, `status`, `student_remark`, `teacher_comment`, `apply_time`, `handle_time`, `handler_id`, `create_time`, `update_time`, `deleted`) VALUES
  (1, 1, 1, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-01-10 19:34:00', '2026-01-12 05:34:00', 1, NOW(), NOW(), 0),
  (2, 2, 2, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-01-11 13:47:00', '2026-01-13 08:47:00', 2, NOW(), NOW(), 0),
  (3, 3, 3, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-01-10 08:34:00', '2026-01-10 21:34:00', 3, NOW(), NOW(), 0),
  (4, 4, 4, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-01-12 13:08:00', '2026-01-14 11:08:00', 4, NOW(), NOW(), 0),
  (5, 5, 5, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-01-14 08:34:00', '2026-01-16 06:34:00', 5, NOW(), NOW(), 0),
  (6, 6, 6, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-01-14 11:10:00', '2026-01-15 00:10:00', 6, NOW(), NOW(), 0),
  (7, 7, 7, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-01-10 14:02:00', '2026-01-11 00:02:00', 7, NOW(), NOW(), 0),
  (8, 8, 8, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-01-12 08:28:00', '2026-01-13 18:28:00', 8, NOW(), NOW(), 0),
  (9, 9, 9, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-01-11 20:21:00', '2026-01-13 05:21:00', 9, NOW(), NOW(), 0),
  (10, 10, 10, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-01-10 09:12:00', '2026-01-10 19:12:00', 10, NOW(), NOW(), 0),
  (11, 11, 11, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-01-11 15:10:00', '2026-01-11 17:10:00', 11, NOW(), NOW(), 0),
  (12, 12, 12, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-01-12 09:47:00', '2026-01-12 18:47:00', 12, NOW(), NOW(), 0),
  (13, 13, 13, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-03 08:19:00', '2026-09-04 17:19:00', 13, NOW(), NOW(), 0),
  (14, 14, 14, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-03 08:05:00', '2026-09-03 22:05:00', 14, NOW(), NOW(), 0),
  (15, 15, 15, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-01 08:55:00', '2026-09-01 14:55:00', 15, NOW(), NOW(), 0),
  (16, 16, 16, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-03 20:59:00', '2026-09-05 18:59:00', 16, NOW(), NOW(), 0),
  (17, 17, 17, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-04 12:31:00', '2026-09-06 07:31:00', 17, NOW(), NOW(), 0),
  (18, 18, 18, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-02 10:03:00', '2026-09-04 09:03:00', 18, NOW(), NOW(), 0),
  (19, 19, 19, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-03 14:36:00', '2026-09-03 22:36:00', 1, NOW(), NOW(), 0),
  (20, 20, 20, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-04 16:19:00', '2026-09-06 06:19:00', 2, NOW(), NOW(), 0);

INSERT INTO `selection` (`id`, `topic_id`, `student_id`, `status`, `student_remark`, `teacher_comment`, `apply_time`, `handle_time`, `handler_id`, `create_time`, `update_time`, `deleted`) VALUES
  (21, 21, 21, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-02 21:36:00', '2026-09-03 08:36:00', 3, NOW(), NOW(), 0),
  (22, 22, 22, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-04 12:13:00', '2026-09-06 01:13:00', 4, NOW(), NOW(), 0),
  (23, 23, 23, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-03 19:01:00', '2026-09-04 01:01:00', 5, NOW(), NOW(), 0),
  (24, 24, 24, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-03 14:21:00', '2026-09-04 07:21:00', 6, NOW(), NOW(), 0),
  (25, 25, 25, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-01 10:39:00', '2026-09-02 00:39:00', 7, NOW(), NOW(), 0),
  (26, 26, 26, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-01 17:36:00', '2026-09-02 14:36:00', 8, NOW(), NOW(), 0),
  (27, 27, 27, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-02 15:21:00', '2026-09-03 19:21:00', 9, NOW(), NOW(), 0),
  (28, 28, 28, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-03 10:25:00', '2026-09-04 11:25:00', 10, NOW(), NOW(), 0),
  (29, 29, 29, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-04 21:37:00', '2026-09-05 07:37:00', 11, NOW(), NOW(), 0),
  (30, 30, 30, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-04 10:42:00', '2026-09-06 09:42:00', 12, NOW(), NOW(), 0),
  (31, 31, 31, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-04 20:54:00', '2026-09-05 02:54:00', 13, NOW(), NOW(), 0),
  (32, 32, 32, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-04 15:08:00', '2026-09-05 23:08:00', 14, NOW(), NOW(), 0),
  (33, 33, 33, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-04 14:10:00', '2026-09-06 00:10:00', 15, NOW(), NOW(), 0),
  (34, 34, 34, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-01 12:09:00', '2026-09-03 12:09:00', 16, NOW(), NOW(), 0),
  (35, 35, 35, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-03 12:12:00', '2026-09-04 09:12:00', 17, NOW(), NOW(), 0),
  (36, 36, 36, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-04 17:51:00', '2026-09-05 21:51:00', 18, NOW(), NOW(), 0),
  (37, 37, 37, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-01 21:10:00', '2026-09-03 13:10:00', 1, NOW(), NOW(), 0),
  (38, 38, 38, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-02 12:54:00', '2026-09-03 01:54:00', 2, NOW(), NOW(), 0),
  (39, 39, 39, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-02 08:30:00', '2026-09-02 16:30:00', 3, NOW(), NOW(), 0),
  (40, 40, 40, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-02 08:12:00', '2026-09-02 13:12:00', 4, NOW(), NOW(), 0);

INSERT INTO `selection` (`id`, `topic_id`, `student_id`, `status`, `student_remark`, `teacher_comment`, `apply_time`, `handle_time`, `handler_id`, `create_time`, `update_time`, `deleted`) VALUES
  (41, 41, 41, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-02 11:03:00', '2026-09-04 00:03:00', 5, NOW(), NOW(), 0),
  (42, 42, 42, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-03 18:58:00', '2026-09-04 10:58:00', 6, NOW(), NOW(), 0),
  (43, 43, 43, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-02 10:03:00', '2026-09-04 05:03:00', 7, NOW(), NOW(), 0),
  (44, 44, 44, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-04 17:37:00', '2026-09-05 12:37:00', 8, NOW(), NOW(), 0),
  (45, 45, 45, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-04 16:37:00', '2026-09-06 16:37:00', 9, NOW(), NOW(), 0),
  (46, 46, 46, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-04 18:50:00', '2026-09-05 05:50:00', 10, NOW(), NOW(), 0),
  (47, 47, 47, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-01 14:03:00', '2026-09-02 10:03:00', 11, NOW(), NOW(), 0),
  (48, 48, 48, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-01 13:57:00', '2026-09-01 16:57:00', 12, NOW(), NOW(), 0),
  (49, 49, 49, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-01 19:17:00', '2026-09-02 07:17:00', 13, NOW(), NOW(), 0),
  (50, 50, 50, 'APPROVED', '对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。', '同意录取，请按时准备开题。', '2026-09-04 20:54:00', '2026-09-06 12:54:00', 14, NOW(), NOW(), 0),
  (51, 51, 51, 'PENDING', '希望申报本课题，已自学相关技术栈。', NULL, '2026-09-25 19:21:00', NULL, NULL, NOW(), NOW(), 0),
  (52, 52, 52, 'PENDING', '希望申报本课题，已自学相关技术栈。', NULL, '2026-09-29 08:32:00', NULL, NULL, NOW(), NOW(), 0),
  (53, 53, 53, 'PENDING', '希望申报本课题，已自学相关技术栈。', NULL, '2026-09-29 18:28:00', NULL, NULL, NOW(), NOW(), 0),
  (54, 54, 54, 'REJECTED', '希望申报本课题，已自学相关技术栈。', '名额已满，建议改选其他课题。', '2026-09-24 12:26:00', '2026-09-29 11:00:00', 18, NOW(), NOW(), 0),
  (55, 55, 55, 'REJECTED', '希望申报本课题，已自学相关技术栈。', '名额已满，建议改选其他课题。', '2026-09-28 11:15:00', '2026-09-29 14:41:00', 1, NOW(), NOW(), 0);

-- 6. 论文主表（thesis）
INSERT INTO `thesis` (`id`, `student_id`, `topic_id`, `advisor_id`, `title`, `grade`, `college`, `major`, `status`, `current_stage`, `start_time`, `submit_time`, `archive_time`, `create_time`, `update_time`, `deleted`) VALUES
  (1, 1, 1, 1, '基于数据挖掘的学生就业去向分析', '2026', '计算机与人工智能学院', '计算机科学与技术', 'ARCHIVED', '已归档', '2026-01-10 19:34:00', '2026-05-27 16:59:00', '2026-06-22 10:14:00', NOW(), NOW(), 0),
  (2, 2, 2, 2, '基于边缘计算的车联网消息认证', '2026', '软件学院', '网络空间安全', 'DEFENSE_DONE', '答辩完成', '2026-01-11 13:47:00', '2026-05-24 20:23:00', NULL, NOW(), NOW(), 0),
  (3, 3, 3, 3, '基于图神经网络的交通路网流量预测', '2026', '电子信息学院', '电子信息工程', 'ARCHIVED', '已归档', '2026-01-10 08:34:00', '2026-05-29 08:21:00', '2026-06-23 08:20:00', NOW(), NOW(), 0),
  (4, 4, 4, 4, '基于计算机视觉的工业缺陷检测', '2026', '计算机与人工智能学院', '计算机科学与技术', 'DEFENSE_DONE', '答辩完成', '2026-01-12 13:08:00', '2026-05-25 08:50:00', NULL, NOW(), NOW(), 0),
  (5, 5, 5, 5, '基于自然语言处理的舆情监测系统', '2026', '软件学院', '软件工程', 'ARCHIVED', '已归档', '2026-01-14 08:34:00', '2026-05-28 19:53:00', '2026-06-24 16:54:00', NOW(), NOW(), 0),
  (6, 6, 6, 6, '基于自然语言处理的新闻文本分类', '2026', '电子信息学院', '通信工程', 'DEFENSE_DONE', '答辩完成', '2026-01-14 11:10:00', '2026-05-29 12:18:00', NULL, NOW(), NOW(), 0),
  (7, 7, 7, 7, '实验设备预约与管控的设计与实现', '2026', '计算机与人工智能学院', '计算机科学与技术', 'DEFENSE_DONE', '答辩完成', '2026-01-10 14:02:00', '2026-05-25 13:17:00', NULL, NOW(), NOW(), 0),
  (8, 8, 8, 8, '基于注意力机制的长文本摘要生成', '2026', '软件学院', '网络空间安全', 'ARCHIVED', '已归档', '2026-01-12 08:28:00', '2026-05-29 10:29:00', '2026-06-25 08:13:00', NOW(), NOW(), 0),
  (9, 9, 9, 9, '在线考试系统弹性部署的设计与实现', '2026', '电子信息学院', '电子信息工程', 'DEFENSE_DONE', '答辩完成', '2026-01-11 20:21:00', '2026-05-25 14:41:00', NULL, NOW(), NOW(), 0),
  (10, 10, 10, 10, '基于机器学习的财务风险预警', '2026', '计算机与人工智能学院', '计算机科学与技术', 'ARCHIVED', '已归档', '2026-01-10 09:12:00', '2026-05-28 10:42:00', '2026-06-22 21:34:00', NOW(), NOW(), 0),
  (11, 11, 11, 11, '基于大语言模型的代码缺陷自动定位', '2026', '软件学院', '软件工程', 'DEFENSE_DONE', '答辩完成', '2026-01-11 15:10:00', '2026-05-29 09:27:00', NULL, NOW(), NOW(), 0),
  (12, 12, 12, 12, '基于数据挖掘的图书借阅模式挖掘', '2026', '电子信息学院', '通信工程', 'ARCHIVED', '已归档', '2026-01-12 09:47:00', '2026-05-26 19:51:00', '2026-06-20 18:48:00', NOW(), NOW(), 0),
  (13, 13, 13, 13, '基于深度学习的医学影像分割', '2027', '计算机与人工智能学院', '计算机科学与技术', 'REVIEWING', '评阅中', '2026-09-03 08:19:00', '2026-09-25 21:40:00', NULL, NOW(), NOW(), 0),
  (14, 14, 14, 14, '基于多模态融合的短视频内容审核', '2027', '软件学院', '网络空间安全', 'PROPOSAL_SUBMITTED', '开题待审核', '2026-09-03 08:05:00', NULL, NULL, NOW(), NOW(), 0),
  (15, 15, 15, 15, '基于迁移学习的跨领域情感分析', '2027', '电子信息学院', '电子信息工程', 'MIDTERM_SUBMITTED', '中期待检查', '2026-09-01 08:55:00', NULL, NULL, NOW(), NOW(), 0),
  (16, 16, 16, 16, '基于强化学习的动态资源调度', '2027', '计算机与人工智能学院', '计算机科学与技术', 'PROPOSAL_SUBMITTED', '开题待审核', '2026-09-03 20:59:00', NULL, NULL, NOW(), NOW(), 0),
  (17, 17, 17, 17, '基于机器学习的用户流失预测', '2027', '软件学院', '软件工程', 'MIDTERM_SUBMITTED', '中期待检查', '2026-09-04 12:31:00', NULL, NULL, NOW(), NOW(), 0),
  (18, 18, 18, 18, '在线考试系统的设计与实现', '2027', '电子信息学院', '通信工程', 'REVIEW_PASSED', '评阅已通过', '2026-09-02 10:03:00', '2026-09-26 19:46:00', NULL, NOW(), NOW(), 0),
  (19, 19, 19, 1, '基于数字孪生的智能制造产线仿真', '2027', '计算机与人工智能学院', '计算机科学与技术', 'DRAFT', '待提交开题', '2026-09-03 14:36:00', NULL, NULL, NOW(), NOW(), 0),
  (20, 20, 20, 2, '基于迁移学习的小样本医学影像分类', '2027', '软件学院', '网络空间安全', 'PROPOSAL_SUBMITTED', '开题待审核', '2026-09-04 16:19:00', NULL, NULL, NOW(), NOW(), 0);

INSERT INTO `thesis` (`id`, `student_id`, `topic_id`, `advisor_id`, `title`, `grade`, `college`, `major`, `status`, `current_stage`, `start_time`, `submit_time`, `archive_time`, `create_time`, `update_time`, `deleted`) VALUES
  (21, 21, 21, 3, '基于时序分析的城市短时交通流量预测', '2027', '电子信息学院', '电子信息工程', 'PROPOSAL_APPROVED', '开题已通过', '2026-09-02 21:36:00', NULL, NULL, NOW(), NOW(), 0),
  (22, 22, 22, 4, '基于强化学习的仓储机器人路径规划', '2027', '计算机与人工智能学院', '计算机科学与技术', 'MIDTERM_SUBMITTED', '中期待检查', '2026-09-04 12:13:00', NULL, NULL, NOW(), NOW(), 0),
  (23, 23, 23, 5, '微服务链路追踪平台的设计与实现', '2027', '软件学院', '软件工程', 'REVIEWING', '评阅中', '2026-09-03 19:01:00', '2026-09-26 12:56:00', NULL, NOW(), NOW(), 0),
  (24, 24, 24, 6, '基于时序分析的食堂人流预测', '2027', '电子信息学院', '通信工程', 'MIDTERM_PASSED', '中期已通过', '2026-09-03 14:21:00', NULL, NULL, NOW(), NOW(), 0),
  (25, 25, 25, 7, '供应链溯源系统的设计与实现', '2027', '计算机与人工智能学院', '计算机科学与技术', 'PROPOSAL_APPROVED', '开题已通过', '2026-09-01 10:39:00', NULL, NULL, NOW(), NOW(), 0),
  (26, 26, 26, 8, '基于机器学习的学生成绩分析', '2027', '软件学院', '网络空间安全', 'REVIEWING', '评阅中', '2026-09-01 17:36:00', '2026-09-26 20:32:00', NULL, NOW(), NOW(), 0),
  (27, 27, 27, 9, '基于多模态融合的远程心电监测', '2027', '电子信息学院', '电子信息工程', 'MIDTERM_SUBMITTED', '中期待检查', '2026-09-02 15:21:00', NULL, NULL, NOW(), NOW(), 0),
  (28, 28, 28, 10, '基于计算机视觉的人脸考勤系统', '2027', '计算机与人工智能学院', '计算机科学与技术', 'FINAL_SUBMITTED', '定稿已提交', '2026-09-03 10:25:00', '2026-09-25 12:58:00', NULL, NOW(), NOW(), 0),
  (29, 29, 29, 11, '基于机器学习的能耗异常检测', '2027', '软件学院', '软件工程', 'MIDTERM_PASSED', '中期已通过', '2026-09-04 21:37:00', NULL, NULL, NOW(), NOW(), 0),
  (30, 30, 30, 12, '停车位检测系统的设计与实现', '2027', '电子信息学院', '通信工程', 'PROPOSAL_SUBMITTED', '开题待审核', '2026-09-04 10:42:00', NULL, NULL, NOW(), NOW(), 0),
  (31, 31, 31, 13, '基于大语言模型的智能问答系统', '2027', '计算机与人工智能学院', '计算机科学与技术', 'PROPOSAL_APPROVED', '开题已通过', '2026-09-04 20:54:00', NULL, NULL, NOW(), NOW(), 0),
  (32, 32, 32, 14, '基于知识图谱的智能问答系统', '2027', '软件学院', '网络空间安全', 'REVIEW_PASSED', '评阅已通过', '2026-09-04 15:08:00', '2026-09-27 11:00:00', NULL, NOW(), NOW(), 0),
  (33, 33, 33, 15, '基于时序分析的校园网流量预测', '2027', '电子信息学院', '电子信息工程', 'PROPOSAL_APPROVED', '开题已通过', '2026-09-04 14:10:00', NULL, NULL, NOW(), NOW(), 0),
  (34, 34, 34, 16, '基于知识图谱的医疗知识图谱构建', '2027', '计算机与人工智能学院', '计算机科学与技术', 'MIDTERM_SUBMITTED', '中期待检查', '2026-09-01 12:09:00', NULL, NULL, NOW(), NOW(), 0),
  (35, 35, 35, 17, '基于大语言模型的题库自动组卷', '2027', '软件学院', '软件工程', 'REVIEWING', '评阅中', '2026-09-03 12:12:00', '2026-09-28 17:35:00', NULL, NOW(), NOW(), 0),
  (36, 36, 36, 18, '电子成绩单存证的设计与实现', '2027', '电子信息学院', '通信工程', 'MIDTERM_SUBMITTED', '中期待检查', '2026-09-04 17:51:00', NULL, NULL, NOW(), NOW(), 0),
  (37, 37, 37, 1, '基于数据挖掘的校园一卡通消费行为分析', '2027', '计算机与人工智能学院', '计算机科学与技术', 'MIDTERM_PASSED', '中期已通过', '2026-09-01 21:10:00', NULL, NULL, NOW(), NOW(), 0),
  (38, 38, 38, 2, '智慧农业环境监测的设计与实现', '2027', '软件学院', '网络空间安全', 'FINAL_SUBMITTED', '定稿已提交', '2026-09-02 12:54:00', '2026-09-27 10:13:00', NULL, NOW(), NOW(), 0),
  (39, 39, 39, 3, '基于计算机视觉的停车位检测', '2027', '电子信息学院', '电子信息工程', 'MIDTERM_PASSED', '中期已通过', '2026-09-02 08:30:00', NULL, NULL, NOW(), NOW(), 0),
  (40, 40, 40, 4, '基于自然语言处理的电商评论情感分析', '2027', '计算机与人工智能学院', '计算机科学与技术', 'PROPOSAL_APPROVED', '开题已通过', '2026-09-02 08:12:00', NULL, NULL, NOW(), NOW(), 0);

INSERT INTO `thesis` (`id`, `student_id`, `topic_id`, `advisor_id`, `title`, `grade`, `college`, `major`, `status`, `current_stage`, `start_time`, `submit_time`, `archive_time`, `create_time`, `update_time`, `deleted`) VALUES
  (41, 41, 41, 5, '基于深度学习的工业缺陷检测', '2027', '软件学院', '软件工程', 'DRAFT', '待提交开题', '2026-09-02 11:03:00', NULL, NULL, NOW(), NOW(), 0),
  (42, 42, 42, 6, '基于时序分析的供应链需求预测', '2027', '电子信息学院', '通信工程', 'DEFENSE_SCHEDULED', '待答辩', '2026-09-03 18:58:00', '2026-09-25 13:49:00', NULL, NOW(), NOW(), 0),
  (43, 43, 43, 7, '基于注意力机制的语音情感识别', '2027', '计算机与人工智能学院', '计算机科学与技术', 'FINAL_SUBMITTED', '定稿已提交', '2026-09-02 10:03:00', '2026-09-26 12:29:00', NULL, NOW(), NOW(), 0),
  (44, 44, 44, 8, '基于边缘计算的无人零售结算', '2027', '软件学院', '网络空间安全', 'REVIEWING', '评阅中', '2026-09-04 17:37:00', '2026-09-25 09:52:00', NULL, NOW(), NOW(), 0),
  (45, 45, 45, 9, '基于自然语言处理的短视频内容审核', '2027', '电子信息学院', '电子信息工程', 'FINAL_SUBMITTED', '定稿已提交', '2026-09-04 16:37:00', '2026-09-26 09:00:00', NULL, NOW(), NOW(), 0),
  (46, 46, 46, 10, '基于深度学习的手写公式识别', '2027', '计算机与人工智能学院', '计算机科学与技术', 'DEFENSE_SCHEDULED', '待答辩', '2026-09-04 18:50:00', '2026-09-26 11:34:00', NULL, NOW(), NOW(), 0),
  (47, 47, 47, 11, '基于知识图谱的课程知识点推荐', '2027', '软件学院', '软件工程', 'REVIEW_PASSED', '评阅已通过', '2026-09-01 14:03:00', '2026-09-26 09:24:00', NULL, NOW(), NOW(), 0),
  (48, 48, 48, 12, '基于知识图谱的论文文献推荐', '2027', '电子信息学院', '通信工程', 'DRAFT', '待提交开题', '2026-09-01 13:57:00', NULL, NULL, NOW(), NOW(), 0),
  (49, 49, 49, 13, '图书馆推荐系统的设计与实现', '2027', '计算机与人工智能学院', '计算机科学与技术', 'PROPOSAL_SUBMITTED', '开题待审核', '2026-09-01 19:17:00', NULL, NULL, NOW(), NOW(), 0),
  (50, 50, 50, 14, '基于边缘计算的智能家居协同控制', '2027', '软件学院', '网络空间安全', 'FINAL_SUBMITTED', '定稿已提交', '2026-09-04 20:54:00', '2026-09-26 12:59:00', NULL, NOW(), NOW(), 0);

-- 7. 开题报告（proposal）
INSERT INTO `proposal` (`id`, `thesis_id`, `content`, `attachment_ids`, `submit_time`, `review_status`, `review_comment`, `reviewer_id`, `review_time`, `score`, `create_time`, `update_time`, `deleted`) VALUES
  (1, 1, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于数据挖掘的学生就业去向分析》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '1', '2026-03-05 14:54:00', 'APPROVED', '目标明确，技术路线清晰，同意开题，注意控制工作量。', 1, '2026-03-09 14:54:00', 90.5, NOW(), NOW(), 0),
  (2, 2, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于边缘计算的车联网消息认证》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '4', '2026-03-07 19:37:00', 'APPROVED', '方案整体可行，建议补充对比实验设计，同意开题。', 2, '2026-03-11 19:37:00', 87.7, NOW(), NOW(), 0),
  (3, 3, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于图神经网络的交通路网流量预测》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '7', '2026-03-04 17:43:00', 'APPROVED', '研究内容饱满，进度安排合理，同意开题。', 3, '2026-03-10 17:43:00', 94.1, NOW(), NOW(), 0),
  (4, 4, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于计算机视觉的工业缺陷检测》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '10', '2026-03-07 08:28:00', 'APPROVED', '目标明确，技术路线清晰，同意开题，注意控制工作量。', 4, '2026-03-13 08:28:00', 92.6, NOW(), NOW(), 0),
  (5, 5, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于自然语言处理的舆情监测系统》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '13', '2026-03-04 09:31:00', 'APPROVED', '研究内容饱满，进度安排合理，同意开题。', 5, '2026-03-07 09:31:00', 90.0, NOW(), NOW(), 0),
  (6, 6, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于自然语言处理的新闻文本分类》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '16', '2026-03-07 08:02:00', 'APPROVED', '方案整体可行，建议补充对比实验设计，同意开题。', 6, '2026-03-10 08:02:00', 91.7, NOW(), NOW(), 0),
  (7, 7, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《实验设备预约与管控的设计与实现》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '19', '2026-03-08 20:10:00', 'APPROVED', '方案整体可行，建议补充对比实验设计，同意开题。', 7, '2026-03-11 20:10:00', 82.1, NOW(), NOW(), 0),
  (8, 8, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于注意力机制的长文本摘要生成》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '22', '2026-03-07 09:10:00', 'APPROVED', '方案整体可行，建议补充对比实验设计，同意开题。', 8, '2026-03-13 09:10:00', 84.6, NOW(), NOW(), 0),
  (9, 9, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《在线考试系统弹性部署的设计与实现》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '25', '2026-03-02 17:58:00', 'APPROVED', '选题具有较强的实用价值，研究方案可行，同意开题。', 9, '2026-03-08 17:58:00', 92.9, NOW(), NOW(), 0),
  (10, 10, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于机器学习的财务风险预警》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '28', '2026-03-08 18:17:00', 'APPROVED', '选题具有较强的实用价值，研究方案可行，同意开题。', 10, '2026-03-11 18:17:00', 86.6, NOW(), NOW(), 0),
  (11, 11, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于大语言模型的代码缺陷自动定位》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '31', '2026-03-07 16:45:00', 'APPROVED', '方案整体可行，建议补充对比实验设计，同意开题。', 11, '2026-03-13 16:45:00', 90.1, NOW(), NOW(), 0),
  (12, 12, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于数据挖掘的图书借阅模式挖掘》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '34', '2026-03-08 20:28:00', 'APPROVED', '研究内容饱满，进度安排合理，同意开题。', 12, '2026-03-14 20:28:00', 87.9, NOW(), NOW(), 0),
  (13, 13, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于深度学习的医学影像分割》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '37', '2026-09-08 11:37:00', 'APPROVED', '选题具有较强的实用价值，研究方案可行，同意开题。', 13, '2026-09-09 11:37:00', 93.7, NOW(), NOW(), 0),
  (14, 14, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于多模态融合的短视频内容审核》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '40', '2026-09-10 08:01:00', 'PENDING', NULL, NULL, NULL, NULL, NOW(), NOW(), 0),
  (15, 15, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于迁移学习的跨领域情感分析》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '41', '2026-09-10 18:38:00', 'APPROVED', '目标明确，技术路线清晰，同意开题，注意控制工作量。', 15, '2026-09-11 18:38:00', 86.5, NOW(), NOW(), 0),
  (16, 16, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于强化学习的动态资源调度》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '43', '2026-09-08 11:57:00', 'PENDING', NULL, NULL, NULL, NULL, NOW(), NOW(), 0),
  (17, 17, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于机器学习的用户流失预测》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '44', '2026-09-09 18:39:00', 'APPROVED', '方案整体可行，建议补充对比实验设计，同意开题。', 17, '2026-09-12 18:39:00', 93.2, NOW(), NOW(), 0),
  (18, 18, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《在线考试系统的设计与实现》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '46', '2026-09-11 14:46:00', 'APPROVED', '研究内容饱满，进度安排合理，同意开题。', 18, '2026-09-12 14:46:00', 93.5, NOW(), NOW(), 0),
  (19, 20, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于迁移学习的小样本医学影像分类》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '49', '2026-09-09 13:00:00', 'PENDING', NULL, NULL, NULL, NULL, NOW(), NOW(), 0),
  (20, 21, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于时序分析的城市短时交通流量预测》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '50', '2026-09-12 18:21:00', 'APPROVED', '目标明确，技术路线清晰，同意开题，注意控制工作量。', 3, '2026-09-13 18:21:00', 93.2, NOW(), NOW(), 0);

INSERT INTO `proposal` (`id`, `thesis_id`, `content`, `attachment_ids`, `submit_time`, `review_status`, `review_comment`, `reviewer_id`, `review_time`, `score`, `create_time`, `update_time`, `deleted`) VALUES
  (21, 22, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于强化学习的仓储机器人路径规划》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '51', '2026-09-11 19:07:00', 'APPROVED', '选题具有较强的实用价值，研究方案可行，同意开题。', 4, '2026-09-13 19:07:00', 91.1, NOW(), NOW(), 0),
  (22, 23, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《微服务链路追踪平台的设计与实现》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '53', '2026-09-08 21:25:00', 'APPROVED', '目标明确，技术路线清晰，同意开题，注意控制工作量。', 5, '2026-09-09 21:25:00', 94.8, NOW(), NOW(), 0),
  (23, 24, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于时序分析的食堂人流预测》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '56', '2026-09-11 14:08:00', 'APPROVED', '选题具有较强的实用价值，研究方案可行，同意开题。', 6, '2026-09-12 14:08:00', 85.0, NOW(), NOW(), 0),
  (24, 25, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《供应链溯源系统的设计与实现》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '58', '2026-09-12 18:14:00', 'APPROVED', '选题具有较强的实用价值，研究方案可行，同意开题。', 7, '2026-09-15 18:14:00', 84.2, NOW(), NOW(), 0),
  (25, 26, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于机器学习的学生成绩分析》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '59', '2026-09-10 14:23:00', 'APPROVED', '目标明确，技术路线清晰，同意开题，注意控制工作量。', 8, '2026-09-12 14:23:00', 81.5, NOW(), NOW(), 0),
  (26, 27, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于多模态融合的远程心电监测》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '62', '2026-09-10 15:37:00', 'APPROVED', '研究内容饱满，进度安排合理，同意开题。', 9, '2026-09-12 15:37:00', 89.0, NOW(), NOW(), 0),
  (27, 28, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于计算机视觉的人脸考勤系统》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '64', '2026-09-12 14:30:00', 'APPROVED', '目标明确，技术路线清晰，同意开题，注意控制工作量。', 10, '2026-09-14 14:30:00', 93.9, NOW(), NOW(), 0),
  (28, 29, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于机器学习的能耗异常检测》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '67', '2026-09-08 10:29:00', 'APPROVED', '研究内容饱满，进度安排合理，同意开题。', 11, '2026-09-11 10:29:00', 82.1, NOW(), NOW(), 0),
  (29, 30, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《停车位检测系统的设计与实现》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '69', '2026-09-10 19:56:00', 'PENDING', NULL, NULL, NULL, NULL, NOW(), NOW(), 0),
  (30, 31, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于大语言模型的智能问答系统》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '70', '2026-09-08 17:22:00', 'APPROVED', '研究内容饱满，进度安排合理，同意开题。', 13, '2026-09-10 17:22:00', 80.3, NOW(), NOW(), 0),
  (31, 32, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于知识图谱的智能问答系统》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '71', '2026-09-08 09:50:00', 'APPROVED', '方案整体可行，建议补充对比实验设计，同意开题。', 14, '2026-09-09 09:50:00', 88.1, NOW(), NOW(), 0),
  (32, 33, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于时序分析的校园网流量预测》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '74', '2026-09-12 08:30:00', 'APPROVED', '选题具有较强的实用价值，研究方案可行，同意开题。', 15, '2026-09-13 08:30:00', 89.5, NOW(), NOW(), 0),
  (33, 34, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于知识图谱的医疗知识图谱构建》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '75', '2026-09-11 10:08:00', 'APPROVED', '目标明确，技术路线清晰，同意开题，注意控制工作量。', 16, '2026-09-13 10:08:00', 85.5, NOW(), NOW(), 0),
  (34, 35, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于大语言模型的题库自动组卷》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '77', '2026-09-10 19:41:00', 'APPROVED', '选题具有较强的实用价值，研究方案可行，同意开题。', 17, '2026-09-12 19:41:00', 87.0, NOW(), NOW(), 0),
  (35, 36, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《电子成绩单存证的设计与实现》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '80', '2026-09-11 10:49:00', 'APPROVED', '方案整体可行，建议补充对比实验设计，同意开题。', 18, '2026-09-14 10:49:00', 85.2, NOW(), NOW(), 0),
  (36, 37, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于数据挖掘的校园一卡通消费行为分析》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '82', '2026-09-11 20:31:00', 'APPROVED', '方案整体可行，建议补充对比实验设计，同意开题。', 1, '2026-09-13 20:31:00', 88.6, NOW(), NOW(), 0),
  (37, 38, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《智慧农业环境监测的设计与实现》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '84', '2026-09-08 10:40:00', 'APPROVED', '选题具有较强的实用价值，研究方案可行，同意开题。', 2, '2026-09-10 10:40:00', 93.2, NOW(), NOW(), 0),
  (38, 39, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于计算机视觉的停车位检测》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '87', '2026-09-09 14:21:00', 'APPROVED', '方案整体可行，建议补充对比实验设计，同意开题。', 3, '2026-09-10 14:21:00', 90.5, NOW(), NOW(), 0),
  (39, 40, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于自然语言处理的电商评论情感分析》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '89', '2026-09-10 14:59:00', 'APPROVED', '方案整体可行，建议补充对比实验设计，同意开题。', 4, '2026-09-11 14:59:00', 94.7, NOW(), NOW(), 0),
  (40, 42, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于时序分析的供应链需求预测》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '90', '2026-09-08 17:49:00', 'APPROVED', '方案整体可行，建议补充对比实验设计，同意开题。', 6, '2026-09-11 17:49:00', 93.4, NOW(), NOW(), 0);

INSERT INTO `proposal` (`id`, `thesis_id`, `content`, `attachment_ids`, `submit_time`, `review_status`, `review_comment`, `reviewer_id`, `review_time`, `score`, `create_time`, `update_time`, `deleted`) VALUES
  (41, 43, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于注意力机制的语音情感识别》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '93', '2026-09-09 09:18:00', 'APPROVED', '选题具有较强的实用价值，研究方案可行，同意开题。', 7, '2026-09-10 09:18:00', 80.3, NOW(), NOW(), 0),
  (42, 44, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于边缘计算的无人零售结算》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '96', '2026-09-09 14:28:00', 'APPROVED', '选题具有较强的实用价值，研究方案可行，同意开题。', 8, '2026-09-11 14:28:00', 84.5, NOW(), NOW(), 0),
  (43, 45, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于自然语言处理的短视频内容审核》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '99', '2026-09-09 17:53:00', 'APPROVED', '方案整体可行，建议补充对比实验设计，同意开题。', 9, '2026-09-10 17:53:00', 90.1, NOW(), NOW(), 0),
  (44, 46, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于深度学习的手写公式识别》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '102', '2026-09-11 18:25:00', 'APPROVED', '研究内容饱满，进度安排合理，同意开题。', 10, '2026-09-13 18:25:00', 82.5, NOW(), NOW(), 0),
  (45, 47, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于知识图谱的课程知识点推荐》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '105', '2026-09-08 17:17:00', 'APPROVED', '目标明确，技术路线清晰，同意开题，注意控制工作量。', 11, '2026-09-11 17:17:00', 83.0, NOW(), NOW(), 0),
  (46, 49, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《图书馆推荐系统的设计与实现》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '108', '2026-09-08 09:43:00', 'PENDING', NULL, NULL, NULL, NULL, NOW(), NOW(), 0),
  (47, 50, '## 研究背景

随着相关技术的快速发展，该问题具有较高的研究与应用价值。

## 研究内容

围绕《基于边缘计算的智能家居协同控制》开展需求分析与方案设计。

## 技术路线

采用主流技术栈完成原型实现，并通过实验验证有效性。

## 进度安排

按开题、中期、定稿、答辩四阶段推进。', '109', '2026-09-09 21:59:00', 'APPROVED', '方案整体可行，建议补充对比实验设计，同意开题。', 14, '2026-09-11 21:59:00', 85.6, NOW(), NOW(), 0);

-- 8. 中期报告（midterm_report）
INSERT INTO `midterm_report` (`id`, `thesis_id`, `progress_percent`, `content`, `attachment_ids`, `submit_time`, `review_status`, `review_comment`, `reviewer_id`, `review_time`, `score`, `create_time`, `update_time`, `deleted`) VALUES
  (1, 1, 91, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '2', '2026-04-18 14:34:00', 'APPROVED', '进度正常，已完成核心工作，同意通过中期检查。', 1, '2026-04-22 14:34:00', 87.3, NOW(), NOW(), 0),
  (2, 2, 91, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '5', '2026-04-20 15:07:00', 'APPROVED', '进展良好，注意补充实验对比，同意通过。', 2, '2026-04-25 15:07:00', 92.7, NOW(), NOW(), 0),
  (3, 3, 87, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '8', '2026-04-18 13:41:00', 'APPROVED', '进度正常，已完成核心工作，同意通过中期检查。', 3, '2026-04-23 13:41:00', 88.0, NOW(), NOW(), 0),
  (4, 4, 82, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '11', '2026-04-24 19:17:00', 'APPROVED', '进展良好，注意补充实验对比，同意通过。', 4, '2026-04-30 19:17:00', 81.8, NOW(), NOW(), 0),
  (5, 5, 93, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '14', '2026-04-21 16:22:00', 'APPROVED', '进度正常，已完成核心工作，同意通过中期检查。', 5, '2026-04-26 16:22:00', 83.0, NOW(), NOW(), 0),
  (6, 6, 89, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '17', '2026-04-19 11:51:00', 'APPROVED', '工作量饱满，建议加快论文撰写进度。', 6, '2026-04-25 11:51:00', 80.4, NOW(), NOW(), 0),
  (7, 7, 93, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '20', '2026-04-19 15:09:00', 'APPROVED', '工作量饱满，建议加快论文撰写进度。', 7, '2026-04-23 15:09:00', 82.8, NOW(), NOW(), 0),
  (8, 8, 94, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '23', '2026-04-21 20:15:00', 'APPROVED', '进展良好，注意补充实验对比，同意通过。', 8, '2026-04-26 20:15:00', 80.3, NOW(), NOW(), 0),
  (9, 9, 73, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '26', '2026-04-18 11:57:00', 'APPROVED', '工作量饱满，建议加快论文撰写进度。', 9, '2026-04-23 11:57:00', 85.5, NOW(), NOW(), 0),
  (10, 10, 78, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '29', '2026-04-23 11:57:00', 'APPROVED', '工作量饱满，建议加快论文撰写进度。', 10, '2026-04-29 11:57:00', 92.2, NOW(), NOW(), 0),
  (11, 11, 72, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '32', '2026-04-19 12:27:00', 'APPROVED', '进展良好，注意补充实验对比，同意通过。', 11, '2026-04-24 12:27:00', 79.8, NOW(), NOW(), 0),
  (12, 12, 89, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '35', '2026-04-19 20:03:00', 'APPROVED', '工作量饱满，建议加快论文撰写进度。', 12, '2026-04-21 20:03:00', 78.4, NOW(), NOW(), 0),
  (13, 13, 76, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '38', '2026-09-18 21:04:00', 'APPROVED', '进展良好，注意补充实验对比，同意通过。', 13, '2026-09-21 21:04:00', 82.2, NOW(), NOW(), 0),
  (14, 15, 55, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '42', '2026-09-19 21:13:00', 'PENDING', NULL, NULL, NULL, NULL, NOW(), NOW(), 0),
  (15, 17, 46, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '45', '2026-09-19 21:28:00', 'PENDING', NULL, NULL, NULL, NULL, NOW(), NOW(), 0),
  (16, 18, 74, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '47', '2026-09-19 18:35:00', 'APPROVED', '进度正常，已完成核心工作，同意通过中期检查。', 18, '2026-09-21 18:35:00', 79.6, NOW(), NOW(), 0),
  (17, 22, 52, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '52', '2026-09-18 12:25:00', 'PENDING', NULL, NULL, NULL, NULL, NOW(), NOW(), 0),
  (18, 23, 85, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '54', '2026-09-19 20:12:00', 'APPROVED', '进度正常，已完成核心工作，同意通过中期检查。', 5, '2026-09-22 20:12:00', 86.1, NOW(), NOW(), 0),
  (19, 24, 83, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '57', '2026-09-22 11:34:00', 'APPROVED', '进展良好，注意补充实验对比，同意通过。', 6, '2026-09-23 11:34:00', 78.1, NOW(), NOW(), 0),
  (20, 26, 93, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '60', '2026-09-20 18:52:00', 'APPROVED', '工作量饱满，建议加快论文撰写进度。', 8, '2026-09-23 18:52:00', 82.3, NOW(), NOW(), 0);

INSERT INTO `midterm_report` (`id`, `thesis_id`, `progress_percent`, `content`, `attachment_ids`, `submit_time`, `review_status`, `review_comment`, `reviewer_id`, `review_time`, `score`, `create_time`, `update_time`, `deleted`) VALUES
  (21, 27, 53, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '63', '2026-09-21 10:04:00', 'PENDING', NULL, NULL, NULL, NULL, NOW(), NOW(), 0),
  (22, 28, 73, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '65', '2026-09-20 19:14:00', 'APPROVED', '工作量饱满，建议加快论文撰写进度。', 10, '2026-09-21 19:14:00', 82.5, NOW(), NOW(), 0),
  (23, 29, 85, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '68', '2026-09-22 15:05:00', 'APPROVED', '进度正常，已完成核心工作，同意通过中期检查。', 11, '2026-09-23 15:05:00', 93.0, NOW(), NOW(), 0),
  (24, 32, 78, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '72', '2026-09-20 10:45:00', 'APPROVED', '进度正常，已完成核心工作，同意通过中期检查。', 14, '2026-09-22 10:45:00', 79.8, NOW(), NOW(), 0),
  (25, 34, 59, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '76', '2026-09-18 11:41:00', 'PENDING', NULL, NULL, NULL, NULL, NOW(), NOW(), 0),
  (26, 35, 82, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '78', '2026-09-21 17:57:00', 'APPROVED', '进展良好，注意补充实验对比，同意通过。', 17, '2026-09-23 17:57:00', 82.7, NOW(), NOW(), 0),
  (27, 36, 55, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '81', '2026-09-18 12:52:00', 'PENDING', NULL, NULL, NULL, NULL, NOW(), NOW(), 0),
  (28, 37, 92, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '83', '2026-09-18 08:26:00', 'APPROVED', '工作量饱满，建议加快论文撰写进度。', 1, '2026-09-21 08:26:00', 93.9, NOW(), NOW(), 0),
  (29, 38, 93, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '85', '2026-09-21 17:38:00', 'APPROVED', '工作量饱满，建议加快论文撰写进度。', 2, '2026-09-22 17:38:00', 88.2, NOW(), NOW(), 0),
  (30, 39, 76, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '88', '2026-09-19 20:58:00', 'APPROVED', '进展良好，注意补充实验对比，同意通过。', 3, '2026-09-22 20:58:00', 90.8, NOW(), NOW(), 0),
  (31, 42, 94, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '91', '2026-09-18 17:07:00', 'APPROVED', '进度正常，已完成核心工作，同意通过中期检查。', 6, '2026-09-20 17:07:00', 90.6, NOW(), NOW(), 0),
  (32, 43, 71, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '94', '2026-09-18 15:04:00', 'APPROVED', '工作量饱满，建议加快论文撰写进度。', 7, '2026-09-21 15:04:00', 82.1, NOW(), NOW(), 0),
  (33, 44, 74, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '97', '2026-09-20 11:16:00', 'APPROVED', '进展良好，注意补充实验对比，同意通过。', 8, '2026-09-22 11:16:00', 82.1, NOW(), NOW(), 0),
  (34, 45, 91, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '100', '2026-09-22 16:03:00', 'APPROVED', '进度正常，已完成核心工作，同意通过中期检查。', 9, '2026-09-24 16:03:00', 92.5, NOW(), NOW(), 0),
  (35, 46, 90, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '103', '2026-09-18 18:33:00', 'APPROVED', '进度正常，已完成核心工作，同意通过中期检查。', 10, '2026-09-19 18:33:00', 92.9, NOW(), NOW(), 0),
  (36, 47, 93, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '106', '2026-09-20 16:49:00', 'APPROVED', '进度正常，已完成核心工作，同意通过中期检查。', 11, '2026-09-23 16:49:00', 91.9, NOW(), NOW(), 0),
  (37, 50, 94, '## 已完成工作

完成需求分析与总体设计，核心模块已实现。

## 存在问题

部分边界场景处理不够完善，实验数据尚需补充。

## 后续计划

完善实验，开始论文撰写。', '110', '2026-09-20 17:14:00', 'APPROVED', '工作量饱满，建议加快论文撰写进度。', 14, '2026-09-23 17:14:00', 92.5, NOW(), NOW(), 0);

-- 9. 论文定稿（final_submission）
INSERT INTO `final_submission` (`id`, `thesis_id`, `file_url`, `file_name`, `file_size`, `version`, `note`, `submit_time`, `create_time`, `update_time`, `deleted`) VALUES
  (1, 1, 'https://cdn.workbuddy.cloud/thesis-demo/final/1/论文定稿_20260001.pdf', '论文定稿_20260001.pdf', 3931278, 1, '按导师意见修改后提交定稿。', '2026-05-27 16:59:00', NOW(), NOW(), 0),
  (2, 2, 'https://cdn.workbuddy.cloud/thesis-demo/final/2/论文定稿_20260002.pdf', '论文定稿_20260002.pdf', 1453929, 1, '按导师意见修改后提交定稿。', '2026-05-24 20:23:00', NOW(), NOW(), 0),
  (3, 3, 'https://cdn.workbuddy.cloud/thesis-demo/final/3/论文定稿_20260003.pdf', '论文定稿_20260003.pdf', 5072996, 1, '按导师意见修改后提交定稿。', '2026-05-29 08:21:00', NOW(), NOW(), 0),
  (4, 4, 'https://cdn.workbuddy.cloud/thesis-demo/final/4/论文定稿_20260004.pdf', '论文定稿_20260004.pdf', 2468041, 1, '按导师意见修改后提交定稿。', '2026-05-25 08:50:00', NOW(), NOW(), 0),
  (5, 5, 'https://cdn.workbuddy.cloud/thesis-demo/final/5/论文定稿_20260005.pdf', '论文定稿_20260005.pdf', 5675926, 1, '按导师意见修改后提交定稿。', '2026-05-28 19:53:00', NOW(), NOW(), 0),
  (6, 6, 'https://cdn.workbuddy.cloud/thesis-demo/final/6/论文定稿_20260006.pdf', '论文定稿_20260006.pdf', 5057791, 1, '按导师意见修改后提交定稿。', '2026-05-29 12:18:00', NOW(), NOW(), 0),
  (7, 7, 'https://cdn.workbuddy.cloud/thesis-demo/final/7/论文定稿_20260007.pdf', '论文定稿_20260007.pdf', 4137218, 1, '按导师意见修改后提交定稿。', '2026-05-25 13:17:00', NOW(), NOW(), 0),
  (8, 8, 'https://cdn.workbuddy.cloud/thesis-demo/final/8/论文定稿_20260008.pdf', '论文定稿_20260008.pdf', 5080124, 1, '按导师意见修改后提交定稿。', '2026-05-29 10:29:00', NOW(), NOW(), 0),
  (9, 9, 'https://cdn.workbuddy.cloud/thesis-demo/final/9/论文定稿_20260009.pdf', '论文定稿_20260009.pdf', 3778717, 1, '按导师意见修改后提交定稿。', '2026-05-25 14:41:00', NOW(), NOW(), 0),
  (10, 10, 'https://cdn.workbuddy.cloud/thesis-demo/final/10/论文定稿_20260010.pdf', '论文定稿_20260010.pdf', 2803562, 1, '按导师意见修改后提交定稿。', '2026-05-28 10:42:00', NOW(), NOW(), 0),
  (11, 11, 'https://cdn.workbuddy.cloud/thesis-demo/final/11/论文定稿_20260011.pdf', '论文定稿_20260011.pdf', 5294346, 1, '按导师意见修改后提交定稿。', '2026-05-29 09:27:00', NOW(), NOW(), 0),
  (12, 12, 'https://cdn.workbuddy.cloud/thesis-demo/final/12/论文定稿_20260012.pdf', '论文定稿_20260012.pdf', 1440620, 1, '按导师意见修改后提交定稿。', '2026-05-26 19:51:00', NOW(), NOW(), 0),
  (13, 13, 'https://cdn.workbuddy.cloud/thesis-demo/final/13/论文定稿_20270013.pdf', '论文定稿_20270013.pdf', 4997133, 1, '按导师意见修改后提交定稿。', '2026-09-25 21:40:00', NOW(), NOW(), 0),
  (14, 18, 'https://cdn.workbuddy.cloud/thesis-demo/final/14/论文定稿_20270018.pdf', '论文定稿_20270018.pdf', 6257123, 1, '按导师意见修改后提交定稿。', '2026-09-26 19:46:00', NOW(), NOW(), 0),
  (15, 23, 'https://cdn.workbuddy.cloud/thesis-demo/final/15/论文定稿_20270023.pdf', '论文定稿_20270023.pdf', 4759989, 1, '按导师意见修改后提交定稿。', '2026-09-26 12:56:00', NOW(), NOW(), 0),
  (16, 26, 'https://cdn.workbuddy.cloud/thesis-demo/final/16/论文定稿_20270026.pdf', '论文定稿_20270026.pdf', 3789907, 1, '按导师意见修改后提交定稿。', '2026-09-26 20:32:00', NOW(), NOW(), 0),
  (17, 28, 'https://cdn.workbuddy.cloud/thesis-demo/final/17/论文定稿_20270028.pdf', '论文定稿_20270028.pdf', 3861528, 1, '按导师意见修改后提交定稿。', '2026-09-25 12:58:00', NOW(), NOW(), 0),
  (18, 32, 'https://cdn.workbuddy.cloud/thesis-demo/final/18/论文定稿_20270032.pdf', '论文定稿_20270032.pdf', 2739669, 1, '按导师意见修改后提交定稿。', '2026-09-27 11:00:00', NOW(), NOW(), 0),
  (19, 35, 'https://cdn.workbuddy.cloud/thesis-demo/final/19/论文定稿_20270035.pdf', '论文定稿_20270035.pdf', 3443528, 1, '按导师意见修改后提交定稿。', '2026-09-28 17:35:00', NOW(), NOW(), 0),
  (20, 38, 'https://cdn.workbuddy.cloud/thesis-demo/final/20/论文定稿_20270038.pdf', '论文定稿_20270038.pdf', 3607024, 1, '按导师意见修改后提交定稿。', '2026-09-27 10:13:00', NOW(), NOW(), 0);

INSERT INTO `final_submission` (`id`, `thesis_id`, `file_url`, `file_name`, `file_size`, `version`, `note`, `submit_time`, `create_time`, `update_time`, `deleted`) VALUES
  (21, 42, 'https://cdn.workbuddy.cloud/thesis-demo/final/21/论文定稿_20270042.pdf', '论文定稿_20270042.pdf', 3201543, 1, '按导师意见修改后提交定稿。', '2026-09-25 13:49:00', NOW(), NOW(), 0),
  (22, 43, 'https://cdn.workbuddy.cloud/thesis-demo/final/22/论文定稿_20270043.pdf', '论文定稿_20270043.pdf', 3716467, 1, '按导师意见修改后提交定稿。', '2026-09-26 12:29:00', NOW(), NOW(), 0),
  (23, 44, 'https://cdn.workbuddy.cloud/thesis-demo/final/23/论文定稿_20270044.pdf', '论文定稿_20270044.pdf', 3274212, 1, '按导师意见修改后提交定稿。', '2026-09-25 09:52:00', NOW(), NOW(), 0),
  (24, 45, 'https://cdn.workbuddy.cloud/thesis-demo/final/24/论文定稿_20270045.pdf', '论文定稿_20270045.pdf', 2862955, 1, '按导师意见修改后提交定稿。', '2026-09-26 09:00:00', NOW(), NOW(), 0),
  (25, 46, 'https://cdn.workbuddy.cloud/thesis-demo/final/25/论文定稿_20270046.pdf', '论文定稿_20270046.pdf', 6496011, 1, '按导师意见修改后提交定稿。', '2026-09-26 11:34:00', NOW(), NOW(), 0),
  (26, 47, 'https://cdn.workbuddy.cloud/thesis-demo/final/26/论文定稿_20270047.pdf', '论文定稿_20270047.pdf', 6343237, 1, '按导师意见修改后提交定稿。', '2026-09-26 09:24:00', NOW(), NOW(), 0),
  (27, 50, 'https://cdn.workbuddy.cloud/thesis-demo/final/27/论文定稿_20270050.pdf', '论文定稿_20270050.pdf', 6028684, 1, '按导师意见修改后提交定稿。', '2026-09-26 12:59:00', NOW(), NOW(), 0);

-- 10. 评阅（review）
INSERT INTO `review` (`id`, `thesis_id`, `reviewer_id`, `assigned_by`, `score`, `comment`, `status`, `blind`, `assign_time`, `submit_time`, `create_time`, `update_time`, `deleted`) VALUES
  (1, 1, 19, 1, 84.3, '选题有实用价值，实现较为完整，建议在讨论部分加强与已有工作的对比。', 'SUBMITTED', 0, '2026-06-01 13:31:00', '2026-06-05 12:56:00', NOW(), NOW(), 0),
  (2, 2, 20, 1, 82.2, '论述清晰，代码与文档齐全，同意参加答辩。', 'SUBMITTED', 0, '2026-06-01 17:05:00', '2026-06-06 19:56:00', NOW(), NOW(), 0),
  (3, 3, 21, 1, 78.7, '整体质量较好，个别图表说明需规范，同意答辩。', 'SUBMITTED', 1, '2026-06-01 14:43:00', '2026-06-05 16:58:00', NOW(), NOW(), 0),
  (4, 4, 22, 1, 83.6, '论文结构完整，工作量饱满，实验设计合理，达到本科毕业论文要求。', 'SUBMITTED', 0, '2026-06-01 19:45:00', '2026-06-04 13:29:00', NOW(), NOW(), 0),
  (5, 5, 23, 1, 87.4, '论文结构完整，工作量饱满，实验设计合理，达到本科毕业论文要求。', 'SUBMITTED', 0, '2026-06-01 09:11:00', '2026-06-03 21:56:00', NOW(), NOW(), 0),
  (6, 6, 24, 1, 79.1, '选题有实用价值，实现较为完整，建议在讨论部分加强与已有工作的对比。', 'SUBMITTED', 1, '2026-06-01 15:40:00', '2026-06-06 18:58:00', NOW(), NOW(), 0),
  (7, 7, 19, 1, 85.4, '论述清晰，代码与文档齐全，同意参加答辩。', 'SUBMITTED', 0, '2026-06-01 15:06:00', '2026-06-06 08:05:00', NOW(), NOW(), 0),
  (8, 8, 20, 1, 87.4, '论文结构完整，工作量饱满，实验设计合理，达到本科毕业论文要求。', 'SUBMITTED', 0, '2026-06-01 15:33:00', '2026-06-06 08:02:00', NOW(), NOW(), 0),
  (9, 9, 21, 1, 92.5, '整体质量较好，个别图表说明需规范，同意答辩。', 'SUBMITTED', 1, '2026-06-01 14:37:00', '2026-06-05 19:59:00', NOW(), NOW(), 0),
  (10, 10, 22, 1, 82.4, '论述清晰，代码与文档齐全，同意参加答辩。', 'SUBMITTED', 0, '2026-06-01 14:38:00', '2026-06-04 10:22:00', NOW(), NOW(), 0),
  (11, 11, 23, 1, 80.4, '选题有实用价值，实现较为完整，建议在讨论部分加强与已有工作的对比。', 'SUBMITTED', 0, '2026-06-01 20:23:00', '2026-06-06 11:11:00', NOW(), NOW(), 0),
  (12, 12, 24, 1, 78.9, '论文结构完整，工作量饱满，实验设计合理，达到本科毕业论文要求。', 'SUBMITTED', 1, '2026-06-01 19:31:00', '2026-06-04 10:40:00', NOW(), NOW(), 0),
  (13, 13, 19, 1, NULL, NULL, 'PENDING', 0, '2026-09-28 15:55:00', NULL, NOW(), NOW(), 0),
  (14, 18, 20, 1, 77.7, '论文结构完整，工作量饱满，实验设计合理，达到本科毕业论文要求。', 'SUBMITTED', 1, '2026-09-28 16:00:00', '2026-09-29 20:52:00', NOW(), NOW(), 0),
  (15, 23, 21, 1, NULL, NULL, 'PENDING', 0, '2026-09-28 11:07:00', NULL, NOW(), NOW(), 0),
  (16, 26, 22, 1, NULL, NULL, 'PENDING', 0, '2026-09-28 15:19:00', NULL, NOW(), NOW(), 0),
  (17, 32, 23, 1, 89.7, '选题有实用价值，实现较为完整，建议在讨论部分加强与已有工作的对比。', 'SUBMITTED', 0, '2026-09-28 19:57:00', '2026-09-28 15:19:00', NOW(), NOW(), 0),
  (18, 35, 24, 1, NULL, NULL, 'PENDING', 0, '2026-09-28 20:47:00', NULL, NOW(), NOW(), 0),
  (19, 42, 19, 1, 76.3, '论述清晰，代码与文档齐全，同意参加答辩。', 'SUBMITTED', 1, '2026-09-28 19:06:00', '2026-09-29 08:49:00', NOW(), NOW(), 0),
  (20, 44, 20, 1, NULL, NULL, 'PENDING', 0, '2026-09-28 19:39:00', NULL, NOW(), NOW(), 0);

INSERT INTO `review` (`id`, `thesis_id`, `reviewer_id`, `assigned_by`, `score`, `comment`, `status`, `blind`, `assign_time`, `submit_time`, `create_time`, `update_time`, `deleted`) VALUES
  (21, 46, 21, 1, 83.7, '论文结构完整，工作量饱满，实验设计合理，达到本科毕业论文要求。', 'SUBMITTED', 0, '2026-09-28 21:08:00', '2026-09-29 13:00:00', NOW(), NOW(), 0),
  (22, 47, 22, 1, 78.4, '选题有实用价值，实现较为完整，建议在讨论部分加强与已有工作的对比。', 'SUBMITTED', 0, '2026-09-28 11:15:00', '2026-09-29 15:30:00', NOW(), NOW(), 0);

-- 11. 答辩组（defense_group）
INSERT INTO `defense_group` (`id`, `name`, `grade`, `college`, `defense_date`, `location`, `secretary_id`, `status`, `remark`, `create_time`, `update_time`, `deleted`) VALUES
  (1, '2026届答辩一组', '2026', '计算机与人工智能学院', '2026-06-11 09:00:00', '实验楼 1-202', 3, 'FINISHED', '请提前 15 分钟到场，携带论文纸质版三份。', NOW(), NOW(), 0),
  (2, '2026届答辩二组', '2026', '计算机与人工智能学院', '2026-06-12 09:00:00', '实验楼 2-203', 1, 'FINISHED', '请提前 15 分钟到场，携带论文纸质版三份。', NOW(), NOW(), 0),
  (3, '2027届答辩一组', '2027', '计算机与人工智能学院', '2026-10-15 09:00:00', '实验楼 3-204', 2, 'PLANNED', '请提前 15 分钟到场，携带论文纸质版三份。', NOW(), NOW(), 0);

-- 12. 答辩组成员（defense_group_member）
INSERT INTO `defense_group_member` (`id`, `group_id`, `teacher_id`, `role_in_group`, `create_time`) VALUES
  (1, 1, 19, 'CHAIR', NOW()),
  (2, 1, 3, 'SECRETARY', NOW()),
  (3, 1, 6, 'MEMBER', NOW()),
  (4, 1, 9, 'MEMBER', NOW()),
  (5, 2, 20, 'CHAIR', NOW()),
  (6, 2, 1, 'SECRETARY', NOW()),
  (7, 2, 4, 'MEMBER', NOW()),
  (8, 2, 7, 'MEMBER', NOW()),
  (9, 3, 21, 'CHAIR', NOW()),
  (10, 3, 2, 'SECRETARY', NOW()),
  (11, 3, 5, 'MEMBER', NOW()),
  (12, 3, 8, 'MEMBER', NOW());

-- 13. 答辩成绩（defense_record）
INSERT INTO `defense_record` (`id`, `thesis_id`, `group_id`, `score`, `result`, `comment`, `recorded_by`, `recorded_time`, `create_time`, `update_time`, `deleted`) VALUES
  (1, 1, 1, 77.9, 'PASS', '整体表现良好，建议进一步完善文档，通过答辩。', 1, '2026-06-11 09:15:00', NOW(), NOW(), 0),
  (2, 2, 1, 91.1, 'PASS', '整体表现良好，建议进一步完善文档，通过答辩。', 1, '2026-06-11 09:30:00', NOW(), NOW(), 0),
  (3, 3, 1, 90.3, 'PASS', '整体表现良好，建议进一步完善文档，通过答辩。', 1, '2026-06-11 09:45:00', NOW(), NOW(), 0),
  (4, 4, 1, 92.5, 'PASS', '整体表现良好，建议进一步完善文档，通过答辩。', 1, '2026-06-11 10:00:00', NOW(), NOW(), 0),
  (5, 5, 1, 76.5, 'PASS', '演示完整，对关键技术理解到位，通过答辩。', 1, '2026-06-11 10:15:00', NOW(), NOW(), 0),
  (6, 6, 1, 76.0, 'PASS', '整体表现良好，建议进一步完善文档，通过答辩。', 1, '2026-06-11 10:30:00', NOW(), NOW(), 0),
  (7, 7, 2, 84.8, 'PASS', '整体表现良好，建议进一步完善文档，通过答辩。', 1, '2026-06-12 09:15:00', NOW(), NOW(), 0),
  (8, 8, 2, 82.6, 'PASS', '陈述清楚，回答问题准确，答辩通过。', 1, '2026-06-12 09:30:00', NOW(), NOW(), 0),
  (9, 9, 2, 86.2, 'PASS', '演示完整，对关键技术理解到位，通过答辩。', 1, '2026-06-12 09:45:00', NOW(), NOW(), 0),
  (10, 10, 2, 85.6, 'PASS', '陈述清楚，回答问题准确，答辩通过。', 1, '2026-06-12 10:00:00', NOW(), NOW(), 0),
  (11, 11, 2, 84.4, 'PASS', '演示完整，对关键技术理解到位，通过答辩。', 1, '2026-06-12 10:15:00', NOW(), NOW(), 0),
  (12, 12, 2, 86.3, 'PASS', '陈述清楚，回答问题准确，答辩通过。', 1, '2026-06-12 10:30:00', NOW(), NOW(), 0);

-- 14. 成绩汇总（thesis_score）
INSERT INTO `thesis_score` (`id`, `thesis_id`, `proposal_score`, `midterm_score`, `review_score`, `defense_score`, `total_score`, `computed_time`, `create_time`, `update_time`, `deleted`) VALUES
  (1, 1, 90.5, 87.3, 84.3, 77.9, 84.2, '2026-06-12 09:15:00', NOW(), NOW(), 0),
  (2, 2, 87.7, 92.7, 82.2, 91.1, 88.1, '2026-06-12 09:30:00', NOW(), NOW(), 0),
  (3, 3, 94.1, 88.0, 78.7, 90.3, 87.1, '2026-06-12 09:45:00', NOW(), NOW(), 0),
  (4, 4, 92.6, 81.8, 83.6, 92.5, 87.7, '2026-06-12 10:00:00', NOW(), NOW(), 0),
  (5, 5, 90.0, 83.0, 87.4, 76.5, 83.8, '2026-06-12 10:15:00', NOW(), NOW(), 0),
  (6, 6, 91.7, 80.4, 79.1, 76.0, 81.0, '2026-06-12 10:30:00', NOW(), NOW(), 0),
  (7, 7, 82.1, 82.8, 85.4, 84.8, 84.0, '2026-06-13 09:15:00', NOW(), NOW(), 0),
  (8, 8, 84.6, 80.3, 87.4, 82.6, 84.0, '2026-06-13 09:30:00', NOW(), NOW(), 0),
  (9, 9, 92.9, 85.5, 92.5, 86.2, 89.3, '2026-06-13 09:45:00', NOW(), NOW(), 0),
  (10, 10, 86.6, 92.2, 82.4, 85.6, 86.2, '2026-06-13 10:00:00', NOW(), NOW(), 0),
  (11, 11, 90.1, 79.8, 80.4, 84.4, 83.4, '2026-06-13 10:15:00', NOW(), NOW(), 0),
  (12, 12, 87.9, 78.4, 78.9, 86.3, 82.8, '2026-06-13 10:30:00', NOW(), NOW(), 0);

-- 15. 附件（attachment）
INSERT INTO `attachment` (`id`, `biz_type`, `biz_id`, `file_name`, `file_url`, `file_size`, `mime_type`, `storage_driver`, `uploader_id`, `create_time`, `update_time`, `deleted`) VALUES
  (1, 'PROPOSAL', 1, '开题报告_20260001.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/1/开题报告_20260001.pdf', 2054742, 'application/pdf', 'cloud', 26, '2026-03-05 14:54:00', NOW(), 0),
  (2, 'MIDTERM', 1, '中期报告_20260001.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/1/中期报告_20260001.pdf', 874852, 'application/pdf', 'cloud', 26, '2026-04-18 14:34:00', NOW(), 0),
  (3, 'FINAL', 1, '论文定稿_20260001.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/final/1/论文定稿_20260001.pdf', 3749985, 'application/pdf', 'cloud', 26, '2026-05-27 16:59:00', NOW(), 0),
  (4, 'PROPOSAL', 2, '开题报告_20260002.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/2/开题报告_20260002.pdf', 611043, 'application/pdf', 'cloud', 27, '2026-03-07 19:37:00', NOW(), 0),
  (5, 'MIDTERM', 2, '中期报告_20260002.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/2/中期报告_20260002.pdf', 2583942, 'application/pdf', 'cloud', 27, '2026-04-20 15:07:00', NOW(), 0),
  (6, 'FINAL', 2, '论文定稿_20260002.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/final/2/论文定稿_20260002.pdf', 5325165, 'application/pdf', 'cloud', 27, '2026-05-24 20:23:00', NOW(), 0),
  (7, 'PROPOSAL', 3, '开题报告_20260003.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/3/开题报告_20260003.pdf', 1841622, 'application/pdf', 'cloud', 28, '2026-03-04 17:43:00', NOW(), 0),
  (8, 'MIDTERM', 3, '中期报告_20260003.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/3/中期报告_20260003.pdf', 1109961, 'application/pdf', 'cloud', 28, '2026-04-18 13:41:00', NOW(), 0),
  (9, 'FINAL', 3, '论文定稿_20260003.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/final/3/论文定稿_20260003.pdf', 6046492, 'application/pdf', 'cloud', 28, '2026-05-29 08:21:00', NOW(), 0),
  (10, 'PROPOSAL', 4, '开题报告_20260004.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/4/开题报告_20260004.pdf', 1249178, 'application/pdf', 'cloud', 29, '2026-03-07 08:28:00', NOW(), 0),
  (11, 'MIDTERM', 4, '中期报告_20260004.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/4/中期报告_20260004.pdf', 1272936, 'application/pdf', 'cloud', 29, '2026-04-24 19:17:00', NOW(), 0),
  (12, 'FINAL', 4, '论文定稿_20260004.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/final/4/论文定稿_20260004.pdf', 2088404, 'application/pdf', 'cloud', 29, '2026-05-25 08:50:00', NOW(), 0),
  (13, 'PROPOSAL', 5, '开题报告_20260005.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/5/开题报告_20260005.pdf', 1986206, 'application/pdf', 'cloud', 30, '2026-03-04 09:31:00', NOW(), 0),
  (14, 'MIDTERM', 5, '中期报告_20260005.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/5/中期报告_20260005.pdf', 2317560, 'application/pdf', 'cloud', 30, '2026-04-21 16:22:00', NOW(), 0),
  (15, 'FINAL', 5, '论文定稿_20260005.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/final/5/论文定稿_20260005.pdf', 4564872, 'application/pdf', 'cloud', 30, '2026-05-28 19:53:00', NOW(), 0),
  (16, 'PROPOSAL', 6, '开题报告_20260006.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/6/开题报告_20260006.pdf', 1104811, 'application/pdf', 'cloud', 31, '2026-03-07 08:02:00', NOW(), 0),
  (17, 'MIDTERM', 6, '中期报告_20260006.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/6/中期报告_20260006.pdf', 2493733, 'application/pdf', 'cloud', 31, '2026-04-19 11:51:00', NOW(), 0),
  (18, 'FINAL', 6, '论文定稿_20260006.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/final/6/论文定稿_20260006.pdf', 2731779, 'application/pdf', 'cloud', 31, '2026-05-29 12:18:00', NOW(), 0),
  (19, 'PROPOSAL', 7, '开题报告_20260007.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/7/开题报告_20260007.pdf', 1743857, 'application/pdf', 'cloud', 32, '2026-03-08 20:10:00', NOW(), 0),
  (20, 'MIDTERM', 7, '中期报告_20260007.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/7/中期报告_20260007.pdf', 2025003, 'application/pdf', 'cloud', 32, '2026-04-19 15:09:00', NOW(), 0);

INSERT INTO `attachment` (`id`, `biz_type`, `biz_id`, `file_name`, `file_url`, `file_size`, `mime_type`, `storage_driver`, `uploader_id`, `create_time`, `update_time`, `deleted`) VALUES
  (21, 'FINAL', 7, '论文定稿_20260007.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/final/7/论文定稿_20260007.pdf', 2748535, 'application/pdf', 'cloud', 32, '2026-05-25 13:17:00', NOW(), 0),
  (22, 'PROPOSAL', 8, '开题报告_20260008.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/8/开题报告_20260008.pdf', 2241432, 'application/pdf', 'cloud', 33, '2026-03-07 09:10:00', NOW(), 0),
  (23, 'MIDTERM', 8, '中期报告_20260008.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/8/中期报告_20260008.pdf', 901719, 'application/pdf', 'cloud', 33, '2026-04-21 20:15:00', NOW(), 0),
  (24, 'FINAL', 8, '论文定稿_20260008.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/final/8/论文定稿_20260008.pdf', 1608717, 'application/pdf', 'cloud', 33, '2026-05-29 10:29:00', NOW(), 0),
  (25, 'PROPOSAL', 9, '开题报告_20260009.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/9/开题报告_20260009.pdf', 695792, 'application/pdf', 'cloud', 34, '2026-03-02 17:58:00', NOW(), 0),
  (26, 'MIDTERM', 9, '中期报告_20260009.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/9/中期报告_20260009.pdf', 1464470, 'application/pdf', 'cloud', 34, '2026-04-18 11:57:00', NOW(), 0),
  (27, 'FINAL', 9, '论文定稿_20260009.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/final/9/论文定稿_20260009.pdf', 2776251, 'application/pdf', 'cloud', 34, '2026-05-25 14:41:00', NOW(), 0),
  (28, 'PROPOSAL', 10, '开题报告_20260010.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/10/开题报告_20260010.pdf', 1903469, 'application/pdf', 'cloud', 35, '2026-03-08 18:17:00', NOW(), 0),
  (29, 'MIDTERM', 10, '中期报告_20260010.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/10/中期报告_20260010.pdf', 555450, 'application/pdf', 'cloud', 35, '2026-04-23 11:57:00', NOW(), 0),
  (30, 'FINAL', 10, '论文定稿_20260010.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/final/10/论文定稿_20260010.pdf', 1882679, 'application/pdf', 'cloud', 35, '2026-05-28 10:42:00', NOW(), 0),
  (31, 'PROPOSAL', 11, '开题报告_20260011.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/11/开题报告_20260011.pdf', 1493788, 'application/pdf', 'cloud', 36, '2026-03-07 16:45:00', NOW(), 0),
  (32, 'MIDTERM', 11, '中期报告_20260011.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/11/中期报告_20260011.pdf', 2431406, 'application/pdf', 'cloud', 36, '2026-04-19 12:27:00', NOW(), 0),
  (33, 'FINAL', 11, '论文定稿_20260011.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/final/11/论文定稿_20260011.pdf', 3938877, 'application/pdf', 'cloud', 36, '2026-05-29 09:27:00', NOW(), 0),
  (34, 'PROPOSAL', 12, '开题报告_20260012.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/12/开题报告_20260012.pdf', 1404747, 'application/pdf', 'cloud', 37, '2026-03-08 20:28:00', NOW(), 0),
  (35, 'MIDTERM', 12, '中期报告_20260012.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/12/中期报告_20260012.pdf', 1496165, 'application/pdf', 'cloud', 37, '2026-04-19 20:03:00', NOW(), 0),
  (36, 'FINAL', 12, '论文定稿_20260012.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/final/12/论文定稿_20260012.pdf', 5562649, 'application/pdf', 'cloud', 37, '2026-05-26 19:51:00', NOW(), 0),
  (37, 'PROPOSAL', 13, '开题报告_20270013.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/13/开题报告_20270013.pdf', 894673, 'application/pdf', 'cloud', 38, '2026-09-08 11:37:00', NOW(), 0),
  (38, 'MIDTERM', 13, '中期报告_20270013.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/13/中期报告_20270013.pdf', 702982, 'application/pdf', 'cloud', 38, '2026-09-18 21:04:00', NOW(), 0),
  (39, 'FINAL', 13, '论文定稿_20270013.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/final/13/论文定稿_20270013.pdf', 2776047, 'application/pdf', 'cloud', 38, '2026-09-25 21:40:00', NOW(), 0),
  (40, 'PROPOSAL', 14, '开题报告_20270014.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/14/开题报告_20270014.pdf', 1710044, 'application/pdf', 'cloud', 39, '2026-09-10 08:01:00', NOW(), 0);

INSERT INTO `attachment` (`id`, `biz_type`, `biz_id`, `file_name`, `file_url`, `file_size`, `mime_type`, `storage_driver`, `uploader_id`, `create_time`, `update_time`, `deleted`) VALUES
  (41, 'PROPOSAL', 15, '开题报告_20270015.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/15/开题报告_20270015.pdf', 1784812, 'application/pdf', 'cloud', 40, '2026-09-10 18:38:00', NOW(), 0),
  (42, 'MIDTERM', 14, '中期报告_20270015.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/14/中期报告_20270015.pdf', 1281544, 'application/pdf', 'cloud', 40, '2026-09-19 21:13:00', NOW(), 0),
  (43, 'PROPOSAL', 16, '开题报告_20270016.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/16/开题报告_20270016.pdf', 678790, 'application/pdf', 'cloud', 41, '2026-09-08 11:57:00', NOW(), 0),
  (44, 'PROPOSAL', 17, '开题报告_20270017.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/17/开题报告_20270017.pdf', 2376626, 'application/pdf', 'cloud', 42, '2026-09-09 18:39:00', NOW(), 0),
  (45, 'MIDTERM', 15, '中期报告_20270017.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/15/中期报告_20270017.pdf', 2333874, 'application/pdf', 'cloud', 42, '2026-09-19 21:28:00', NOW(), 0),
  (46, 'PROPOSAL', 18, '开题报告_20270018.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/18/开题报告_20270018.pdf', 594431, 'application/pdf', 'cloud', 43, '2026-09-11 14:46:00', NOW(), 0),
  (47, 'MIDTERM', 16, '中期报告_20270018.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/16/中期报告_20270018.pdf', 1377099, 'application/pdf', 'cloud', 43, '2026-09-19 18:35:00', NOW(), 0),
  (48, 'FINAL', 14, '论文定稿_20270018.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/final/14/论文定稿_20270018.pdf', 2655287, 'application/pdf', 'cloud', 43, '2026-09-26 19:46:00', NOW(), 0),
  (49, 'PROPOSAL', 19, '开题报告_20270020.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/19/开题报告_20270020.pdf', 1137691, 'application/pdf', 'cloud', 45, '2026-09-09 13:00:00', NOW(), 0),
  (50, 'PROPOSAL', 20, '开题报告_20270021.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/20/开题报告_20270021.pdf', 2145037, 'application/pdf', 'cloud', 46, '2026-09-12 18:21:00', NOW(), 0),
  (51, 'PROPOSAL', 21, '开题报告_20270022.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/21/开题报告_20270022.pdf', 1302325, 'application/pdf', 'cloud', 47, '2026-09-11 19:07:00', NOW(), 0),
  (52, 'MIDTERM', 17, '中期报告_20270022.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/17/中期报告_20270022.pdf', 1143760, 'application/pdf', 'cloud', 47, '2026-09-18 12:25:00', NOW(), 0),
  (53, 'PROPOSAL', 22, '开题报告_20270023.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/22/开题报告_20270023.pdf', 2064446, 'application/pdf', 'cloud', 48, '2026-09-08 21:25:00', NOW(), 0),
  (54, 'MIDTERM', 18, '中期报告_20270023.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/18/中期报告_20270023.pdf', 2676934, 'application/pdf', 'cloud', 48, '2026-09-19 20:12:00', NOW(), 0),
  (55, 'FINAL', 15, '论文定稿_20270023.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/final/15/论文定稿_20270023.pdf', 3560874, 'application/pdf', 'cloud', 48, '2026-09-26 12:56:00', NOW(), 0),
  (56, 'PROPOSAL', 23, '开题报告_20270024.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/23/开题报告_20270024.pdf', 1404534, 'application/pdf', 'cloud', 49, '2026-09-11 14:08:00', NOW(), 0),
  (57, 'MIDTERM', 19, '中期报告_20270024.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/19/中期报告_20270024.pdf', 1975700, 'application/pdf', 'cloud', 49, '2026-09-22 11:34:00', NOW(), 0),
  (58, 'PROPOSAL', 24, '开题报告_20270025.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/24/开题报告_20270025.pdf', 732026, 'application/pdf', 'cloud', 50, '2026-09-12 18:14:00', NOW(), 0),
  (59, 'PROPOSAL', 25, '开题报告_20270026.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/25/开题报告_20270026.pdf', 2116256, 'application/pdf', 'cloud', 51, '2026-09-10 14:23:00', NOW(), 0),
  (60, 'MIDTERM', 20, '中期报告_20270026.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/20/中期报告_20270026.pdf', 2197792, 'application/pdf', 'cloud', 51, '2026-09-20 18:52:00', NOW(), 0);

INSERT INTO `attachment` (`id`, `biz_type`, `biz_id`, `file_name`, `file_url`, `file_size`, `mime_type`, `storage_driver`, `uploader_id`, `create_time`, `update_time`, `deleted`) VALUES
  (61, 'FINAL', 16, '论文定稿_20270026.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/final/16/论文定稿_20270026.pdf', 4829681, 'application/pdf', 'cloud', 51, '2026-09-26 20:32:00', NOW(), 0),
  (62, 'PROPOSAL', 26, '开题报告_20270027.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/26/开题报告_20270027.pdf', 1548073, 'application/pdf', 'cloud', 52, '2026-09-10 15:37:00', NOW(), 0),
  (63, 'MIDTERM', 21, '中期报告_20270027.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/21/中期报告_20270027.pdf', 1811560, 'application/pdf', 'cloud', 52, '2026-09-21 10:04:00', NOW(), 0),
  (64, 'PROPOSAL', 27, '开题报告_20270028.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/27/开题报告_20270028.pdf', 1654779, 'application/pdf', 'cloud', 53, '2026-09-12 14:30:00', NOW(), 0),
  (65, 'MIDTERM', 22, '中期报告_20270028.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/22/中期报告_20270028.pdf', 2676376, 'application/pdf', 'cloud', 53, '2026-09-20 19:14:00', NOW(), 0),
  (66, 'FINAL', 17, '论文定稿_20270028.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/final/17/论文定稿_20270028.pdf', 3237348, 'application/pdf', 'cloud', 53, '2026-09-25 12:58:00', NOW(), 0),
  (67, 'PROPOSAL', 28, '开题报告_20270029.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/28/开题报告_20270029.pdf', 1240137, 'application/pdf', 'cloud', 54, '2026-09-08 10:29:00', NOW(), 0),
  (68, 'MIDTERM', 23, '中期报告_20270029.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/23/中期报告_20270029.pdf', 914115, 'application/pdf', 'cloud', 54, '2026-09-22 15:05:00', NOW(), 0),
  (69, 'PROPOSAL', 29, '开题报告_20270030.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/29/开题报告_20270030.pdf', 799810, 'application/pdf', 'cloud', 55, '2026-09-10 19:56:00', NOW(), 0),
  (70, 'PROPOSAL', 30, '开题报告_20270031.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/30/开题报告_20270031.pdf', 480593, 'application/pdf', 'cloud', 56, '2026-09-08 17:22:00', NOW(), 0),
  (71, 'PROPOSAL', 31, '开题报告_20270032.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/31/开题报告_20270032.pdf', 1873532, 'application/pdf', 'cloud', 57, '2026-09-08 09:50:00', NOW(), 0),
  (72, 'MIDTERM', 24, '中期报告_20270032.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/24/中期报告_20270032.pdf', 879824, 'application/pdf', 'cloud', 57, '2026-09-20 10:45:00', NOW(), 0),
  (73, 'FINAL', 18, '论文定稿_20270032.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/final/18/论文定稿_20270032.pdf', 6204517, 'application/pdf', 'cloud', 57, '2026-09-27 11:00:00', NOW(), 0),
  (74, 'PROPOSAL', 32, '开题报告_20270033.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/32/开题报告_20270033.pdf', 1005719, 'application/pdf', 'cloud', 58, '2026-09-12 08:30:00', NOW(), 0),
  (75, 'PROPOSAL', 33, '开题报告_20270034.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/33/开题报告_20270034.pdf', 731222, 'application/pdf', 'cloud', 59, '2026-09-11 10:08:00', NOW(), 0),
  (76, 'MIDTERM', 25, '中期报告_20270034.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/25/中期报告_20270034.pdf', 969040, 'application/pdf', 'cloud', 59, '2026-09-18 11:41:00', NOW(), 0),
  (77, 'PROPOSAL', 34, '开题报告_20270035.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/34/开题报告_20270035.pdf', 2044608, 'application/pdf', 'cloud', 60, '2026-09-10 19:41:00', NOW(), 0),
  (78, 'MIDTERM', 26, '中期报告_20270035.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/26/中期报告_20270035.pdf', 501449, 'application/pdf', 'cloud', 60, '2026-09-21 17:57:00', NOW(), 0),
  (79, 'FINAL', 19, '论文定稿_20270035.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/final/19/论文定稿_20270035.pdf', 2922115, 'application/pdf', 'cloud', 60, '2026-09-28 17:35:00', NOW(), 0),
  (80, 'PROPOSAL', 35, '开题报告_20270036.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/35/开题报告_20270036.pdf', 757244, 'application/pdf', 'cloud', 61, '2026-09-11 10:49:00', NOW(), 0);

INSERT INTO `attachment` (`id`, `biz_type`, `biz_id`, `file_name`, `file_url`, `file_size`, `mime_type`, `storage_driver`, `uploader_id`, `create_time`, `update_time`, `deleted`) VALUES
  (81, 'MIDTERM', 27, '中期报告_20270036.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/27/中期报告_20270036.pdf', 1368765, 'application/pdf', 'cloud', 61, '2026-09-18 12:52:00', NOW(), 0),
  (82, 'PROPOSAL', 36, '开题报告_20270037.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/36/开题报告_20270037.pdf', 1457506, 'application/pdf', 'cloud', 62, '2026-09-11 20:31:00', NOW(), 0),
  (83, 'MIDTERM', 28, '中期报告_20270037.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/28/中期报告_20270037.pdf', 672306, 'application/pdf', 'cloud', 62, '2026-09-18 08:26:00', NOW(), 0),
  (84, 'PROPOSAL', 37, '开题报告_20270038.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/37/开题报告_20270038.pdf', 368209, 'application/pdf', 'cloud', 63, '2026-09-08 10:40:00', NOW(), 0),
  (85, 'MIDTERM', 29, '中期报告_20270038.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/29/中期报告_20270038.pdf', 1076327, 'application/pdf', 'cloud', 63, '2026-09-21 17:38:00', NOW(), 0),
  (86, 'FINAL', 20, '论文定稿_20270038.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/final/20/论文定稿_20270038.pdf', 2779206, 'application/pdf', 'cloud', 63, '2026-09-27 10:13:00', NOW(), 0),
  (87, 'PROPOSAL', 38, '开题报告_20270039.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/38/开题报告_20270039.pdf', 683357, 'application/pdf', 'cloud', 64, '2026-09-09 14:21:00', NOW(), 0),
  (88, 'MIDTERM', 30, '中期报告_20270039.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/30/中期报告_20270039.pdf', 825780, 'application/pdf', 'cloud', 64, '2026-09-19 20:58:00', NOW(), 0),
  (89, 'PROPOSAL', 39, '开题报告_20270040.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/39/开题报告_20270040.pdf', 1089598, 'application/pdf', 'cloud', 65, '2026-09-10 14:59:00', NOW(), 0),
  (90, 'PROPOSAL', 40, '开题报告_20270042.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/40/开题报告_20270042.pdf', 1835306, 'application/pdf', 'cloud', 67, '2026-09-08 17:49:00', NOW(), 0),
  (91, 'MIDTERM', 31, '中期报告_20270042.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/31/中期报告_20270042.pdf', 1663589, 'application/pdf', 'cloud', 67, '2026-09-18 17:07:00', NOW(), 0),
  (92, 'FINAL', 21, '论文定稿_20270042.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/final/21/论文定稿_20270042.pdf', 2516987, 'application/pdf', 'cloud', 67, '2026-09-25 13:49:00', NOW(), 0),
  (93, 'PROPOSAL', 41, '开题报告_20270043.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/41/开题报告_20270043.pdf', 780211, 'application/pdf', 'cloud', 68, '2026-09-09 09:18:00', NOW(), 0),
  (94, 'MIDTERM', 32, '中期报告_20270043.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/32/中期报告_20270043.pdf', 454763, 'application/pdf', 'cloud', 68, '2026-09-18 15:04:00', NOW(), 0),
  (95, 'FINAL', 22, '论文定稿_20270043.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/final/22/论文定稿_20270043.pdf', 5982007, 'application/pdf', 'cloud', 68, '2026-09-26 12:29:00', NOW(), 0),
  (96, 'PROPOSAL', 42, '开题报告_20270044.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/42/开题报告_20270044.pdf', 477990, 'application/pdf', 'cloud', 69, '2026-09-09 14:28:00', NOW(), 0),
  (97, 'MIDTERM', 33, '中期报告_20270044.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/33/中期报告_20270044.pdf', 1688846, 'application/pdf', 'cloud', 69, '2026-09-20 11:16:00', NOW(), 0),
  (98, 'FINAL', 23, '论文定稿_20270044.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/final/23/论文定稿_20270044.pdf', 4816449, 'application/pdf', 'cloud', 69, '2026-09-25 09:52:00', NOW(), 0),
  (99, 'PROPOSAL', 43, '开题报告_20270045.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/43/开题报告_20270045.pdf', 2282432, 'application/pdf', 'cloud', 70, '2026-09-09 17:53:00', NOW(), 0),
  (100, 'MIDTERM', 34, '中期报告_20270045.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/34/中期报告_20270045.pdf', 949738, 'application/pdf', 'cloud', 70, '2026-09-22 16:03:00', NOW(), 0);

INSERT INTO `attachment` (`id`, `biz_type`, `biz_id`, `file_name`, `file_url`, `file_size`, `mime_type`, `storage_driver`, `uploader_id`, `create_time`, `update_time`, `deleted`) VALUES
  (101, 'FINAL', 24, '论文定稿_20270045.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/final/24/论文定稿_20270045.pdf', 3534756, 'application/pdf', 'cloud', 70, '2026-09-26 09:00:00', NOW(), 0),
  (102, 'PROPOSAL', 44, '开题报告_20270046.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/44/开题报告_20270046.pdf', 1266979, 'application/pdf', 'cloud', 71, '2026-09-11 18:25:00', NOW(), 0),
  (103, 'MIDTERM', 35, '中期报告_20270046.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/35/中期报告_20270046.pdf', 1752401, 'application/pdf', 'cloud', 71, '2026-09-18 18:33:00', NOW(), 0),
  (104, 'FINAL', 25, '论文定稿_20270046.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/final/25/论文定稿_20270046.pdf', 4250527, 'application/pdf', 'cloud', 71, '2026-09-26 11:34:00', NOW(), 0),
  (105, 'PROPOSAL', 45, '开题报告_20270047.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/45/开题报告_20270047.pdf', 2349847, 'application/pdf', 'cloud', 72, '2026-09-08 17:17:00', NOW(), 0),
  (106, 'MIDTERM', 36, '中期报告_20270047.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/36/中期报告_20270047.pdf', 1251414, 'application/pdf', 'cloud', 72, '2026-09-20 16:49:00', NOW(), 0),
  (107, 'FINAL', 26, '论文定稿_20270047.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/final/26/论文定稿_20270047.pdf', 6395692, 'application/pdf', 'cloud', 72, '2026-09-26 09:24:00', NOW(), 0),
  (108, 'PROPOSAL', 46, '开题报告_20270049.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/46/开题报告_20270049.pdf', 2230755, 'application/pdf', 'cloud', 74, '2026-09-08 09:43:00', NOW(), 0),
  (109, 'PROPOSAL', 47, '开题报告_20270050.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/proposal/47/开题报告_20270050.pdf', 434268, 'application/pdf', 'cloud', 75, '2026-09-09 21:59:00', NOW(), 0),
  (110, 'MIDTERM', 37, '中期报告_20270050.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/midterm/37/中期报告_20270050.pdf', 2186027, 'application/pdf', 'cloud', 75, '2026-09-20 17:14:00', NOW(), 0),
  (111, 'FINAL', 27, '论文定稿_20270050.pdf', 'https://cdn.workbuddy.cloud/thesis-demo/final/27/论文定稿_20270050.pdf', 3604520, 'application/pdf', 'cloud', 75, '2026-09-26 12:59:00', NOW(), 0);

-- 16. 操作留痕（audit_log）
INSERT INTO `audit_log` (`id`, `actor_id`, `actor_name`, `action`, `target_type`, `target_id`, `detail`, `create_time`) VALUES
  (1, 2, '熊军', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 王建国 申报的课题《基于数据挖掘的学生就业去向分析》', '2026-01-10 19:34:00'),
  (2, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 1, '生成论文记录，当前阶段：已归档', '2026-01-10 19:34:00'),
  (3, 26, '王建国', 'SUBMIT_PROPOSAL', 'PROPOSAL', 1, '提交开题报告', '2026-03-05 14:54:00'),
  (4, 2, '熊军', 'APPROVE_PROPOSAL', 'PROPOSAL', 1, '开题审核通过', '2026-03-09 14:54:00'),
  (5, 26, '王建国', 'SUBMIT_MIDTERM', 'MIDTERM', 1, '提交中期报告', '2026-04-18 14:34:00'),
  (6, 2, '熊军', 'APPROVE_MIDTERM', 'MIDTERM', 1, '中期检查通过', '2026-04-22 14:34:00'),
  (7, 26, '王建国', 'SUBMIT_FINAL', 'FINAL', 1, '提交论文定稿', '2026-05-27 16:59:00'),
  (8, 1, '系统管理员', 'ASSIGN_REVIEW', 'REVIEW', 1, '指派 邓桂英 评阅《基于数据挖掘的学生就业去向分析》', '2026-06-01 13:31:00'),
  (9, 20, '邓桂英', 'SUBMIT_REVIEW', 'REVIEW', 1, '提交评阅意见，成绩 84.3', '2026-06-05 12:56:00'),
  (10, 3, '侯志强', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 钟宇轩 申报的课题《基于边缘计算的车联网消息认证》', '2026-01-11 13:47:00'),
  (11, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 2, '生成论文记录，当前阶段：答辩完成', '2026-01-11 13:47:00'),
  (12, 27, '钟宇轩', 'SUBMIT_PROPOSAL', 'PROPOSAL', 2, '提交开题报告', '2026-03-07 19:37:00'),
  (13, 3, '侯志强', 'APPROVE_PROPOSAL', 'PROPOSAL', 2, '开题审核通过', '2026-03-11 19:37:00'),
  (14, 27, '钟宇轩', 'SUBMIT_MIDTERM', 'MIDTERM', 2, '提交中期报告', '2026-04-20 15:07:00'),
  (15, 3, '侯志强', 'APPROVE_MIDTERM', 'MIDTERM', 2, '中期检查通过', '2026-04-25 15:07:00'),
  (16, 27, '钟宇轩', 'SUBMIT_FINAL', 'FINAL', 2, '提交论文定稿', '2026-05-24 20:23:00'),
  (17, 1, '系统管理员', 'ASSIGN_REVIEW', 'REVIEW', 2, '指派 雷娜 评阅《基于边缘计算的车联网消息认证》', '2026-06-01 17:05:00'),
  (18, 21, '雷娜', 'SUBMIT_REVIEW', 'REVIEW', 2, '提交评阅意见，成绩 82.2', '2026-06-06 19:56:00'),
  (19, 4, '方辉', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 莫宇航 申报的课题《基于图神经网络的交通路网流量预测》', '2026-01-10 08:34:00'),
  (20, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 3, '生成论文记录，当前阶段：已归档', '2026-01-10 08:34:00');

INSERT INTO `audit_log` (`id`, `actor_id`, `actor_name`, `action`, `target_type`, `target_id`, `detail`, `create_time`) VALUES
  (21, 28, '莫宇航', 'SUBMIT_PROPOSAL', 'PROPOSAL', 3, '提交开题报告', '2026-03-04 17:43:00'),
  (22, 4, '方辉', 'APPROVE_PROPOSAL', 'PROPOSAL', 3, '开题审核通过', '2026-03-10 17:43:00'),
  (23, 28, '莫宇航', 'SUBMIT_MIDTERM', 'MIDTERM', 3, '提交中期报告', '2026-04-18 13:41:00'),
  (24, 4, '方辉', 'APPROVE_MIDTERM', 'MIDTERM', 3, '中期检查通过', '2026-04-23 13:41:00'),
  (25, 28, '莫宇航', 'SUBMIT_FINAL', 'FINAL', 3, '提交论文定稿', '2026-05-29 08:21:00'),
  (26, 1, '系统管理员', 'ASSIGN_REVIEW', 'REVIEW', 3, '指派 范勇 评阅《基于图神经网络的交通路网流量预测》', '2026-06-01 14:43:00'),
  (27, 22, '范勇', 'SUBMIT_REVIEW', 'REVIEW', 3, '提交评阅意见，成绩 78.7', '2026-06-05 16:58:00'),
  (28, 5, '钱雨欣', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 刘艳 申报的课题《基于计算机视觉的工业缺陷检测》', '2026-01-12 13:08:00'),
  (29, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 4, '生成论文记录，当前阶段：答辩完成', '2026-01-12 13:08:00'),
  (30, 29, '刘艳', 'SUBMIT_PROPOSAL', 'PROPOSAL', 4, '提交开题报告', '2026-03-07 08:28:00'),
  (31, 5, '钱雨欣', 'APPROVE_PROPOSAL', 'PROPOSAL', 4, '开题审核通过', '2026-03-13 08:28:00'),
  (32, 29, '刘艳', 'SUBMIT_MIDTERM', 'MIDTERM', 4, '提交中期报告', '2026-04-24 19:17:00'),
  (33, 5, '钱雨欣', 'APPROVE_MIDTERM', 'MIDTERM', 4, '中期检查通过', '2026-04-30 19:17:00'),
  (34, 29, '刘艳', 'SUBMIT_FINAL', 'FINAL', 4, '提交论文定稿', '2026-05-25 08:50:00'),
  (35, 1, '系统管理员', 'ASSIGN_REVIEW', 'REVIEW', 4, '指派 董雅静 评阅《基于计算机视觉的工业缺陷检测》', '2026-06-01 19:45:00'),
  (36, 23, '董雅静', 'SUBMIT_REVIEW', 'REVIEW', 4, '提交评阅意见，成绩 83.6', '2026-06-04 13:29:00'),
  (37, 6, '彭明', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 尹雅静 申报的课题《基于自然语言处理的舆情监测系统》', '2026-01-14 08:34:00'),
  (38, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 5, '生成论文记录，当前阶段：已归档', '2026-01-14 08:34:00'),
  (39, 30, '尹雅静', 'SUBMIT_PROPOSAL', 'PROPOSAL', 5, '提交开题报告', '2026-03-04 09:31:00'),
  (40, 6, '彭明', 'APPROVE_PROPOSAL', 'PROPOSAL', 5, '开题审核通过', '2026-03-07 09:31:00');

INSERT INTO `audit_log` (`id`, `actor_id`, `actor_name`, `action`, `target_type`, `target_id`, `detail`, `create_time`) VALUES
  (41, 30, '尹雅静', 'SUBMIT_MIDTERM', 'MIDTERM', 5, '提交中期报告', '2026-04-21 16:22:00'),
  (42, 6, '彭明', 'APPROVE_MIDTERM', 'MIDTERM', 5, '中期检查通过', '2026-04-26 16:22:00'),
  (43, 30, '尹雅静', 'SUBMIT_FINAL', 'FINAL', 5, '提交论文定稿', '2026-05-28 19:53:00'),
  (44, 1, '系统管理员', 'ASSIGN_REVIEW', 'REVIEW', 5, '指派 苏伟 评阅《基于自然语言处理的舆情监测系统》', '2026-06-01 09:11:00'),
  (45, 24, '苏伟', 'SUBMIT_REVIEW', 'REVIEW', 5, '提交评阅意见，成绩 87.4', '2026-06-03 21:56:00'),
  (46, 7, '曹明', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 苏春燕 申报的课题《基于自然语言处理的新闻文本分类》', '2026-01-14 11:10:00'),
  (47, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 6, '生成论文记录，当前阶段：答辩完成', '2026-01-14 11:10:00'),
  (48, 31, '苏春燕', 'SUBMIT_PROPOSAL', 'PROPOSAL', 6, '提交开题报告', '2026-03-07 08:02:00'),
  (49, 7, '曹明', 'APPROVE_PROPOSAL', 'PROPOSAL', 6, '开题审核通过', '2026-03-10 08:02:00'),
  (50, 31, '苏春燕', 'SUBMIT_MIDTERM', 'MIDTERM', 6, '提交中期报告', '2026-04-19 11:51:00'),
  (51, 7, '曹明', 'APPROVE_MIDTERM', 'MIDTERM', 6, '中期检查通过', '2026-04-25 11:51:00'),
  (52, 31, '苏春燕', 'SUBMIT_FINAL', 'FINAL', 6, '提交论文定稿', '2026-05-29 12:18:00'),
  (53, 1, '系统管理员', 'ASSIGN_REVIEW', 'REVIEW', 6, '指派 贾丹 评阅《基于自然语言处理的新闻文本分类》', '2026-06-01 15:40:00'),
  (54, 25, '贾丹', 'SUBMIT_REVIEW', 'REVIEW', 6, '提交评阅意见，成绩 79.1', '2026-06-06 18:58:00'),
  (55, 8, '熊宇航', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 邹杰 申报的课题《实验设备预约与管控的设计与实现》', '2026-01-10 14:02:00'),
  (56, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 7, '生成论文记录，当前阶段：答辩完成', '2026-01-10 14:02:00'),
  (57, 32, '邹杰', 'SUBMIT_PROPOSAL', 'PROPOSAL', 7, '提交开题报告', '2026-03-08 20:10:00'),
  (58, 8, '熊宇航', 'APPROVE_PROPOSAL', 'PROPOSAL', 7, '开题审核通过', '2026-03-11 20:10:00'),
  (59, 32, '邹杰', 'SUBMIT_MIDTERM', 'MIDTERM', 7, '提交中期报告', '2026-04-19 15:09:00'),
  (60, 8, '熊宇航', 'APPROVE_MIDTERM', 'MIDTERM', 7, '中期检查通过', '2026-04-23 15:09:00');

INSERT INTO `audit_log` (`id`, `actor_id`, `actor_name`, `action`, `target_type`, `target_id`, `detail`, `create_time`) VALUES
  (61, 32, '邹杰', 'SUBMIT_FINAL', 'FINAL', 7, '提交论文定稿', '2026-05-25 13:17:00'),
  (62, 1, '系统管理员', 'ASSIGN_REVIEW', 'REVIEW', 7, '指派 邓桂英 评阅《实验设备预约与管控的设计与实现》', '2026-06-01 15:06:00'),
  (63, 20, '邓桂英', 'SUBMIT_REVIEW', 'REVIEW', 7, '提交评阅意见，成绩 85.4', '2026-06-06 08:05:00'),
  (64, 9, '严嘉怡', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 龚斌 申报的课题《基于注意力机制的长文本摘要生成》', '2026-01-12 08:28:00'),
  (65, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 8, '生成论文记录，当前阶段：已归档', '2026-01-12 08:28:00'),
  (66, 33, '龚斌', 'SUBMIT_PROPOSAL', 'PROPOSAL', 8, '提交开题报告', '2026-03-07 09:10:00'),
  (67, 9, '严嘉怡', 'APPROVE_PROPOSAL', 'PROPOSAL', 8, '开题审核通过', '2026-03-13 09:10:00'),
  (68, 33, '龚斌', 'SUBMIT_MIDTERM', 'MIDTERM', 8, '提交中期报告', '2026-04-21 20:15:00'),
  (69, 9, '严嘉怡', 'APPROVE_MIDTERM', 'MIDTERM', 8, '中期检查通过', '2026-04-26 20:15:00'),
  (70, 33, '龚斌', 'SUBMIT_FINAL', 'FINAL', 8, '提交论文定稿', '2026-05-29 10:29:00'),
  (71, 1, '系统管理员', 'ASSIGN_REVIEW', 'REVIEW', 8, '指派 雷娜 评阅《基于注意力机制的长文本摘要生成》', '2026-06-01 15:33:00'),
  (72, 21, '雷娜', 'SUBMIT_REVIEW', 'REVIEW', 8, '提交评阅意见，成绩 87.4', '2026-06-06 08:02:00'),
  (73, 10, '陈桂英', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 吴洋 申报的课题《在线考试系统弹性部署的设计与实现》', '2026-01-11 20:21:00'),
  (74, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 9, '生成论文记录，当前阶段：答辩完成', '2026-01-11 20:21:00'),
  (75, 34, '吴洋', 'SUBMIT_PROPOSAL', 'PROPOSAL', 9, '提交开题报告', '2026-03-02 17:58:00'),
  (76, 10, '陈桂英', 'APPROVE_PROPOSAL', 'PROPOSAL', 9, '开题审核通过', '2026-03-08 17:58:00'),
  (77, 34, '吴洋', 'SUBMIT_MIDTERM', 'MIDTERM', 9, '提交中期报告', '2026-04-18 11:57:00'),
  (78, 10, '陈桂英', 'APPROVE_MIDTERM', 'MIDTERM', 9, '中期检查通过', '2026-04-23 11:57:00'),
  (79, 34, '吴洋', 'SUBMIT_FINAL', 'FINAL', 9, '提交论文定稿', '2026-05-25 14:41:00'),
  (80, 1, '系统管理员', 'ASSIGN_REVIEW', 'REVIEW', 9, '指派 范勇 评阅《在线考试系统弹性部署的设计与实现》', '2026-06-01 14:37:00');

INSERT INTO `audit_log` (`id`, `actor_id`, `actor_name`, `action`, `target_type`, `target_id`, `detail`, `create_time`) VALUES
  (81, 22, '范勇', 'SUBMIT_REVIEW', 'REVIEW', 9, '提交评阅意见，成绩 92.5', '2026-06-05 19:59:00'),
  (82, 11, '朱文博', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 钟伟 申报的课题《基于机器学习的财务风险预警》', '2026-01-10 09:12:00'),
  (83, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 10, '生成论文记录，当前阶段：已归档', '2026-01-10 09:12:00'),
  (84, 35, '钟伟', 'SUBMIT_PROPOSAL', 'PROPOSAL', 10, '提交开题报告', '2026-03-08 18:17:00'),
  (85, 11, '朱文博', 'APPROVE_PROPOSAL', 'PROPOSAL', 10, '开题审核通过', '2026-03-11 18:17:00'),
  (86, 35, '钟伟', 'SUBMIT_MIDTERM', 'MIDTERM', 10, '提交中期报告', '2026-04-23 11:57:00'),
  (87, 11, '朱文博', 'APPROVE_MIDTERM', 'MIDTERM', 10, '中期检查通过', '2026-04-29 11:57:00'),
  (88, 35, '钟伟', 'SUBMIT_FINAL', 'FINAL', 10, '提交论文定稿', '2026-05-28 10:42:00'),
  (89, 1, '系统管理员', 'ASSIGN_REVIEW', 'REVIEW', 10, '指派 董雅静 评阅《基于机器学习的财务风险预警》', '2026-06-01 14:38:00'),
  (90, 23, '董雅静', 'SUBMIT_REVIEW', 'REVIEW', 10, '提交评阅意见，成绩 82.4', '2026-06-04 10:22:00'),
  (91, 12, '史一鸣', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 廖伟 申报的课题《基于大语言模型的代码缺陷自动定位》', '2026-01-11 15:10:00'),
  (92, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 11, '生成论文记录，当前阶段：答辩完成', '2026-01-11 15:10:00'),
  (93, 36, '廖伟', 'SUBMIT_PROPOSAL', 'PROPOSAL', 11, '提交开题报告', '2026-03-07 16:45:00'),
  (94, 12, '史一鸣', 'APPROVE_PROPOSAL', 'PROPOSAL', 11, '开题审核通过', '2026-03-13 16:45:00'),
  (95, 36, '廖伟', 'SUBMIT_MIDTERM', 'MIDTERM', 11, '提交中期报告', '2026-04-19 12:27:00'),
  (96, 12, '史一鸣', 'APPROVE_MIDTERM', 'MIDTERM', 11, '中期检查通过', '2026-04-24 12:27:00'),
  (97, 36, '廖伟', 'SUBMIT_FINAL', 'FINAL', 11, '提交论文定稿', '2026-05-29 09:27:00'),
  (98, 1, '系统管理员', 'ASSIGN_REVIEW', 'REVIEW', 11, '指派 苏伟 评阅《基于大语言模型的代码缺陷自动定位》', '2026-06-01 20:23:00'),
  (99, 24, '苏伟', 'SUBMIT_REVIEW', 'REVIEW', 11, '提交评阅意见，成绩 80.4', '2026-06-06 11:11:00'),
  (100, 13, '姜超', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 魏洋 申报的课题《基于数据挖掘的图书借阅模式挖掘》', '2026-01-12 09:47:00');

INSERT INTO `audit_log` (`id`, `actor_id`, `actor_name`, `action`, `target_type`, `target_id`, `detail`, `create_time`) VALUES
  (101, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 12, '生成论文记录，当前阶段：已归档', '2026-01-12 09:47:00'),
  (102, 37, '魏洋', 'SUBMIT_PROPOSAL', 'PROPOSAL', 12, '提交开题报告', '2026-03-08 20:28:00'),
  (103, 13, '姜超', 'APPROVE_PROPOSAL', 'PROPOSAL', 12, '开题审核通过', '2026-03-14 20:28:00'),
  (104, 37, '魏洋', 'SUBMIT_MIDTERM', 'MIDTERM', 12, '提交中期报告', '2026-04-19 20:03:00'),
  (105, 13, '姜超', 'APPROVE_MIDTERM', 'MIDTERM', 12, '中期检查通过', '2026-04-21 20:03:00'),
  (106, 37, '魏洋', 'SUBMIT_FINAL', 'FINAL', 12, '提交论文定稿', '2026-05-26 19:51:00'),
  (107, 1, '系统管理员', 'ASSIGN_REVIEW', 'REVIEW', 12, '指派 贾丹 评阅《基于数据挖掘的图书借阅模式挖掘》', '2026-06-01 19:31:00'),
  (108, 25, '贾丹', 'SUBMIT_REVIEW', 'REVIEW', 12, '提交评阅意见，成绩 78.9', '2026-06-04 10:40:00'),
  (109, 14, '刘洋', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 蒋丹 申报的课题《基于深度学习的医学影像分割》', '2026-09-03 08:19:00'),
  (110, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 13, '生成论文记录，当前阶段：评阅中', '2026-09-03 08:19:00'),
  (111, 38, '蒋丹', 'SUBMIT_PROPOSAL', 'PROPOSAL', 13, '提交开题报告', '2026-09-08 11:37:00'),
  (112, 14, '刘洋', 'APPROVE_PROPOSAL', 'PROPOSAL', 13, '开题审核通过', '2026-09-09 11:37:00'),
  (113, 38, '蒋丹', 'SUBMIT_MIDTERM', 'MIDTERM', 13, '提交中期报告', '2026-09-18 21:04:00'),
  (114, 14, '刘洋', 'APPROVE_MIDTERM', 'MIDTERM', 13, '中期检查通过', '2026-09-21 21:04:00'),
  (115, 38, '蒋丹', 'SUBMIT_FINAL', 'FINAL', 13, '提交论文定稿', '2026-09-25 21:40:00'),
  (116, 1, '系统管理员', 'ASSIGN_REVIEW', 'REVIEW', 13, '指派 邓桂英 评阅《基于深度学习的医学影像分割》', '2026-09-28 15:55:00'),
  (117, 15, '毛梓萱', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 邹丽 申报的课题《基于多模态融合的短视频内容审核》', '2026-09-03 08:05:00'),
  (118, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 14, '生成论文记录，当前阶段：开题待审核', '2026-09-03 08:05:00'),
  (119, 39, '邹丽', 'SUBMIT_PROPOSAL', 'PROPOSAL', 14, '提交开题报告', '2026-09-10 08:01:00'),
  (120, 16, '蔡斌', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 曹娜 申报的课题《基于迁移学习的跨领域情感分析》', '2026-09-01 08:55:00');

INSERT INTO `audit_log` (`id`, `actor_id`, `actor_name`, `action`, `target_type`, `target_id`, `detail`, `create_time`) VALUES
  (121, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 15, '生成论文记录，当前阶段：中期待检查', '2026-09-01 08:55:00'),
  (122, 40, '曹娜', 'SUBMIT_PROPOSAL', 'PROPOSAL', 15, '提交开题报告', '2026-09-10 18:38:00'),
  (123, 16, '蔡斌', 'APPROVE_PROPOSAL', 'PROPOSAL', 15, '开题审核通过', '2026-09-11 18:38:00'),
  (124, 40, '曹娜', 'SUBMIT_MIDTERM', 'MIDTERM', 14, '提交中期报告', '2026-09-19 21:13:00'),
  (125, 17, '韩丹', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 于丹 申报的课题《基于强化学习的动态资源调度》', '2026-09-03 20:59:00'),
  (126, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 16, '生成论文记录，当前阶段：开题待审核', '2026-09-03 20:59:00'),
  (127, 41, '于丹', 'SUBMIT_PROPOSAL', 'PROPOSAL', 16, '提交开题报告', '2026-09-08 11:57:00'),
  (128, 18, '郝文博', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 孙辉 申报的课题《基于机器学习的用户流失预测》', '2026-09-04 12:31:00'),
  (129, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 17, '生成论文记录，当前阶段：中期待检查', '2026-09-04 12:31:00'),
  (130, 42, '孙辉', 'SUBMIT_PROPOSAL', 'PROPOSAL', 17, '提交开题报告', '2026-09-09 18:39:00'),
  (131, 18, '郝文博', 'APPROVE_PROPOSAL', 'PROPOSAL', 17, '开题审核通过', '2026-09-12 18:39:00'),
  (132, 42, '孙辉', 'SUBMIT_MIDTERM', 'MIDTERM', 15, '提交中期报告', '2026-09-19 21:28:00'),
  (133, 19, '魏书瑶', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 方涛 申报的课题《在线考试系统的设计与实现》', '2026-09-02 10:03:00'),
  (134, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 18, '生成论文记录，当前阶段：评阅已通过', '2026-09-02 10:03:00'),
  (135, 43, '方涛', 'SUBMIT_PROPOSAL', 'PROPOSAL', 18, '提交开题报告', '2026-09-11 14:46:00'),
  (136, 19, '魏书瑶', 'APPROVE_PROPOSAL', 'PROPOSAL', 18, '开题审核通过', '2026-09-12 14:46:00'),
  (137, 43, '方涛', 'SUBMIT_MIDTERM', 'MIDTERM', 16, '提交中期报告', '2026-09-19 18:35:00'),
  (138, 19, '魏书瑶', 'APPROVE_MIDTERM', 'MIDTERM', 16, '中期检查通过', '2026-09-21 18:35:00'),
  (139, 43, '方涛', 'SUBMIT_FINAL', 'FINAL', 14, '提交论文定稿', '2026-09-26 19:46:00'),
  (140, 1, '系统管理员', 'ASSIGN_REVIEW', 'REVIEW', 14, '指派 雷娜 评阅《在线考试系统的设计与实现》', '2026-09-28 16:00:00');

INSERT INTO `audit_log` (`id`, `actor_id`, `actor_name`, `action`, `target_type`, `target_id`, `detail`, `create_time`) VALUES
  (141, 21, '雷娜', 'SUBMIT_REVIEW', 'REVIEW', 14, '提交评阅意见，成绩 77.7', '2026-09-29 20:52:00'),
  (142, 2, '熊军', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 钱雨欣 申报的课题《基于数字孪生的智能制造产线仿真》', '2026-09-03 14:36:00'),
  (143, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 19, '生成论文记录，当前阶段：待提交开题', '2026-09-03 14:36:00'),
  (144, 3, '侯志强', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 魏宇航 申报的课题《基于迁移学习的小样本医学影像分类》', '2026-09-04 16:19:00'),
  (145, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 20, '生成论文记录，当前阶段：开题待审核', '2026-09-04 16:19:00'),
  (146, 45, '魏宇航', 'SUBMIT_PROPOSAL', 'PROPOSAL', 19, '提交开题报告', '2026-09-09 13:00:00'),
  (147, 4, '方辉', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 薛明 申报的课题《基于时序分析的城市短时交通流量预测》', '2026-09-02 21:36:00'),
  (148, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 21, '生成论文记录，当前阶段：开题已通过', '2026-09-02 21:36:00'),
  (149, 46, '薛明', 'SUBMIT_PROPOSAL', 'PROPOSAL', 20, '提交开题报告', '2026-09-12 18:21:00'),
  (150, 4, '方辉', 'APPROVE_PROPOSAL', 'PROPOSAL', 20, '开题审核通过', '2026-09-13 18:21:00'),
  (151, 5, '钱雨欣', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 韩芳 申报的课题《基于强化学习的仓储机器人路径规划》', '2026-09-04 12:13:00'),
  (152, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 22, '生成论文记录，当前阶段：中期待检查', '2026-09-04 12:13:00'),
  (153, 47, '韩芳', 'SUBMIT_PROPOSAL', 'PROPOSAL', 21, '提交开题报告', '2026-09-11 19:07:00'),
  (154, 5, '钱雨欣', 'APPROVE_PROPOSAL', 'PROPOSAL', 21, '开题审核通过', '2026-09-13 19:07:00'),
  (155, 47, '韩芳', 'SUBMIT_MIDTERM', 'MIDTERM', 17, '提交中期报告', '2026-09-18 12:25:00'),
  (156, 6, '彭明', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 余辉 申报的课题《微服务链路追踪平台的设计与实现》', '2026-09-03 19:01:00'),
  (157, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 23, '生成论文记录，当前阶段：评阅中', '2026-09-03 19:01:00'),
  (158, 48, '余辉', 'SUBMIT_PROPOSAL', 'PROPOSAL', 22, '提交开题报告', '2026-09-08 21:25:00'),
  (159, 6, '彭明', 'APPROVE_PROPOSAL', 'PROPOSAL', 22, '开题审核通过', '2026-09-09 21:25:00'),
  (160, 48, '余辉', 'SUBMIT_MIDTERM', 'MIDTERM', 18, '提交中期报告', '2026-09-19 20:12:00');

INSERT INTO `audit_log` (`id`, `actor_id`, `actor_name`, `action`, `target_type`, `target_id`, `detail`, `create_time`) VALUES
  (161, 6, '彭明', 'APPROVE_MIDTERM', 'MIDTERM', 18, '中期检查通过', '2026-09-22 20:12:00'),
  (162, 48, '余辉', 'SUBMIT_FINAL', 'FINAL', 15, '提交论文定稿', '2026-09-26 12:56:00'),
  (163, 1, '系统管理员', 'ASSIGN_REVIEW', 'REVIEW', 15, '指派 范勇 评阅《微服务链路追踪平台的设计与实现》', '2026-09-28 11:07:00'),
  (164, 7, '曹明', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 曾勇 申报的课题《基于时序分析的食堂人流预测》', '2026-09-03 14:21:00'),
  (165, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 24, '生成论文记录，当前阶段：中期已通过', '2026-09-03 14:21:00'),
  (166, 49, '曾勇', 'SUBMIT_PROPOSAL', 'PROPOSAL', 23, '提交开题报告', '2026-09-11 14:08:00'),
  (167, 7, '曹明', 'APPROVE_PROPOSAL', 'PROPOSAL', 23, '开题审核通过', '2026-09-12 14:08:00'),
  (168, 49, '曾勇', 'SUBMIT_MIDTERM', 'MIDTERM', 19, '提交中期报告', '2026-09-22 11:34:00'),
  (169, 7, '曹明', 'APPROVE_MIDTERM', 'MIDTERM', 19, '中期检查通过', '2026-09-23 11:34:00'),
  (170, 8, '熊宇航', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 钱婷 申报的课题《供应链溯源系统的设计与实现》', '2026-09-01 10:39:00'),
  (171, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 25, '生成论文记录，当前阶段：开题已通过', '2026-09-01 10:39:00'),
  (172, 50, '钱婷', 'SUBMIT_PROPOSAL', 'PROPOSAL', 24, '提交开题报告', '2026-09-12 18:14:00'),
  (173, 8, '熊宇航', 'APPROVE_PROPOSAL', 'PROPOSAL', 24, '开题审核通过', '2026-09-15 18:14:00'),
  (174, 9, '严嘉怡', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 唐军 申报的课题《基于机器学习的学生成绩分析》', '2026-09-01 17:36:00'),
  (175, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 26, '生成论文记录，当前阶段：评阅中', '2026-09-01 17:36:00'),
  (176, 51, '唐军', 'SUBMIT_PROPOSAL', 'PROPOSAL', 25, '提交开题报告', '2026-09-10 14:23:00'),
  (177, 9, '严嘉怡', 'APPROVE_PROPOSAL', 'PROPOSAL', 25, '开题审核通过', '2026-09-12 14:23:00'),
  (178, 51, '唐军', 'SUBMIT_MIDTERM', 'MIDTERM', 20, '提交中期报告', '2026-09-20 18:52:00'),
  (179, 9, '严嘉怡', 'APPROVE_MIDTERM', 'MIDTERM', 20, '中期检查通过', '2026-09-23 18:52:00'),
  (180, 51, '唐军', 'SUBMIT_FINAL', 'FINAL', 16, '提交论文定稿', '2026-09-26 20:32:00');

INSERT INTO `audit_log` (`id`, `actor_id`, `actor_name`, `action`, `target_type`, `target_id`, `detail`, `create_time`) VALUES
  (181, 1, '系统管理员', 'ASSIGN_REVIEW', 'REVIEW', 16, '指派 董雅静 评阅《基于机器学习的学生成绩分析》', '2026-09-28 15:19:00'),
  (182, 10, '陈桂英', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 于浩然 申报的课题《基于多模态融合的远程心电监测》', '2026-09-02 15:21:00'),
  (183, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 27, '生成论文记录，当前阶段：中期待检查', '2026-09-02 15:21:00'),
  (184, 52, '于浩然', 'SUBMIT_PROPOSAL', 'PROPOSAL', 26, '提交开题报告', '2026-09-10 15:37:00'),
  (185, 10, '陈桂英', 'APPROVE_PROPOSAL', 'PROPOSAL', 26, '开题审核通过', '2026-09-12 15:37:00'),
  (186, 52, '于浩然', 'SUBMIT_MIDTERM', 'MIDTERM', 21, '提交中期报告', '2026-09-21 10:04:00'),
  (187, 11, '朱文博', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 黎娟 申报的课题《基于计算机视觉的人脸考勤系统》', '2026-09-03 10:25:00'),
  (188, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 28, '生成论文记录，当前阶段：定稿已提交', '2026-09-03 10:25:00'),
  (189, 53, '黎娟', 'SUBMIT_PROPOSAL', 'PROPOSAL', 27, '提交开题报告', '2026-09-12 14:30:00'),
  (190, 11, '朱文博', 'APPROVE_PROPOSAL', 'PROPOSAL', 27, '开题审核通过', '2026-09-14 14:30:00'),
  (191, 53, '黎娟', 'SUBMIT_MIDTERM', 'MIDTERM', 22, '提交中期报告', '2026-09-20 19:14:00'),
  (192, 11, '朱文博', 'APPROVE_MIDTERM', 'MIDTERM', 22, '中期检查通过', '2026-09-21 19:14:00'),
  (193, 53, '黎娟', 'SUBMIT_FINAL', 'FINAL', 17, '提交论文定稿', '2026-09-25 12:58:00'),
  (194, 12, '史一鸣', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 于刚 申报的课题《基于机器学习的能耗异常检测》', '2026-09-04 21:37:00'),
  (195, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 29, '生成论文记录，当前阶段：中期已通过', '2026-09-04 21:37:00'),
  (196, 54, '于刚', 'SUBMIT_PROPOSAL', 'PROPOSAL', 28, '提交开题报告', '2026-09-08 10:29:00'),
  (197, 12, '史一鸣', 'APPROVE_PROPOSAL', 'PROPOSAL', 28, '开题审核通过', '2026-09-11 10:29:00'),
  (198, 54, '于刚', 'SUBMIT_MIDTERM', 'MIDTERM', 23, '提交中期报告', '2026-09-22 15:05:00'),
  (199, 12, '史一鸣', 'APPROVE_MIDTERM', 'MIDTERM', 23, '中期检查通过', '2026-09-23 15:05:00'),
  (200, 13, '姜超', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 魏峰 申报的课题《停车位检测系统的设计与实现》', '2026-09-04 10:42:00');

INSERT INTO `audit_log` (`id`, `actor_id`, `actor_name`, `action`, `target_type`, `target_id`, `detail`, `create_time`) VALUES
  (201, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 30, '生成论文记录，当前阶段：开题待审核', '2026-09-04 10:42:00'),
  (202, 55, '魏峰', 'SUBMIT_PROPOSAL', 'PROPOSAL', 29, '提交开题报告', '2026-09-10 19:56:00'),
  (203, 14, '刘洋', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 曹志强 申报的课题《基于大语言模型的智能问答系统》', '2026-09-04 20:54:00'),
  (204, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 31, '生成论文记录，当前阶段：开题已通过', '2026-09-04 20:54:00'),
  (205, 56, '曹志强', 'SUBMIT_PROPOSAL', 'PROPOSAL', 30, '提交开题报告', '2026-09-08 17:22:00'),
  (206, 14, '刘洋', 'APPROVE_PROPOSAL', 'PROPOSAL', 30, '开题审核通过', '2026-09-10 17:22:00'),
  (207, 15, '毛梓萱', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 何浩然 申报的课题《基于知识图谱的智能问答系统》', '2026-09-04 15:08:00'),
  (208, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 32, '生成论文记录，当前阶段：评阅已通过', '2026-09-04 15:08:00'),
  (209, 57, '何浩然', 'SUBMIT_PROPOSAL', 'PROPOSAL', 31, '提交开题报告', '2026-09-08 09:50:00'),
  (210, 15, '毛梓萱', 'APPROVE_PROPOSAL', 'PROPOSAL', 31, '开题审核通过', '2026-09-09 09:50:00'),
  (211, 57, '何浩然', 'SUBMIT_MIDTERM', 'MIDTERM', 24, '提交中期报告', '2026-09-20 10:45:00'),
  (212, 15, '毛梓萱', 'APPROVE_MIDTERM', 'MIDTERM', 24, '中期检查通过', '2026-09-22 10:45:00'),
  (213, 57, '何浩然', 'SUBMIT_FINAL', 'FINAL', 18, '提交论文定稿', '2026-09-27 11:00:00'),
  (214, 1, '系统管理员', 'ASSIGN_REVIEW', 'REVIEW', 17, '指派 苏伟 评阅《基于知识图谱的智能问答系统》', '2026-09-28 19:57:00'),
  (215, 24, '苏伟', 'SUBMIT_REVIEW', 'REVIEW', 17, '提交评阅意见，成绩 89.7', '2026-09-28 15:19:00'),
  (216, 16, '蔡斌', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 蒋书瑶 申报的课题《基于时序分析的校园网流量预测》', '2026-09-04 14:10:00'),
  (217, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 33, '生成论文记录，当前阶段：开题已通过', '2026-09-04 14:10:00'),
  (218, 58, '蒋书瑶', 'SUBMIT_PROPOSAL', 'PROPOSAL', 32, '提交开题报告', '2026-09-12 08:30:00'),
  (219, 16, '蔡斌', 'APPROVE_PROPOSAL', 'PROPOSAL', 32, '开题审核通过', '2026-09-13 08:30:00'),
  (220, 17, '韩丹', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 韦琳 申报的课题《基于知识图谱的医疗知识图谱构建》', '2026-09-01 12:09:00');

INSERT INTO `audit_log` (`id`, `actor_id`, `actor_name`, `action`, `target_type`, `target_id`, `detail`, `create_time`) VALUES
  (221, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 34, '生成论文记录，当前阶段：中期待检查', '2026-09-01 12:09:00'),
  (222, 59, '韦琳', 'SUBMIT_PROPOSAL', 'PROPOSAL', 33, '提交开题报告', '2026-09-11 10:08:00'),
  (223, 17, '韩丹', 'APPROVE_PROPOSAL', 'PROPOSAL', 33, '开题审核通过', '2026-09-13 10:08:00'),
  (224, 59, '韦琳', 'SUBMIT_MIDTERM', 'MIDTERM', 25, '提交中期报告', '2026-09-18 11:41:00'),
  (225, 18, '郝文博', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 钱琳 申报的课题《基于大语言模型的题库自动组卷》', '2026-09-03 12:12:00'),
  (226, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 35, '生成论文记录，当前阶段：评阅中', '2026-09-03 12:12:00'),
  (227, 60, '钱琳', 'SUBMIT_PROPOSAL', 'PROPOSAL', 34, '提交开题报告', '2026-09-10 19:41:00'),
  (228, 18, '郝文博', 'APPROVE_PROPOSAL', 'PROPOSAL', 34, '开题审核通过', '2026-09-12 19:41:00'),
  (229, 60, '钱琳', 'SUBMIT_MIDTERM', 'MIDTERM', 26, '提交中期报告', '2026-09-21 17:57:00'),
  (230, 18, '郝文博', 'APPROVE_MIDTERM', 'MIDTERM', 26, '中期检查通过', '2026-09-23 17:57:00'),
  (231, 60, '钱琳', 'SUBMIT_FINAL', 'FINAL', 19, '提交论文定稿', '2026-09-28 17:35:00'),
  (232, 1, '系统管理员', 'ASSIGN_REVIEW', 'REVIEW', 18, '指派 贾丹 评阅《基于大语言模型的题库自动组卷》', '2026-09-28 20:47:00'),
  (233, 19, '魏书瑶', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 曾子涵 申报的课题《电子成绩单存证的设计与实现》', '2026-09-04 17:51:00'),
  (234, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 36, '生成论文记录，当前阶段：中期待检查', '2026-09-04 17:51:00'),
  (235, 61, '曾子涵', 'SUBMIT_PROPOSAL', 'PROPOSAL', 35, '提交开题报告', '2026-09-11 10:49:00'),
  (236, 19, '魏书瑶', 'APPROVE_PROPOSAL', 'PROPOSAL', 35, '开题审核通过', '2026-09-14 10:49:00'),
  (237, 61, '曾子涵', 'SUBMIT_MIDTERM', 'MIDTERM', 27, '提交中期报告', '2026-09-18 12:52:00'),
  (238, 2, '熊军', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 宋雨欣 申报的课题《基于数据挖掘的校园一卡通消费行为分析》', '2026-09-01 21:10:00'),
  (239, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 37, '生成论文记录，当前阶段：中期已通过', '2026-09-01 21:10:00'),
  (240, 62, '宋雨欣', 'SUBMIT_PROPOSAL', 'PROPOSAL', 36, '提交开题报告', '2026-09-11 20:31:00');

INSERT INTO `audit_log` (`id`, `actor_id`, `actor_name`, `action`, `target_type`, `target_id`, `detail`, `create_time`) VALUES
  (241, 2, '熊军', 'APPROVE_PROPOSAL', 'PROPOSAL', 36, '开题审核通过', '2026-09-13 20:31:00'),
  (242, 62, '宋雨欣', 'SUBMIT_MIDTERM', 'MIDTERM', 28, '提交中期报告', '2026-09-18 08:26:00'),
  (243, 2, '熊军', 'APPROVE_MIDTERM', 'MIDTERM', 28, '中期检查通过', '2026-09-21 08:26:00'),
  (244, 3, '侯志强', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 朱丹 申报的课题《智慧农业环境监测的设计与实现》', '2026-09-02 12:54:00'),
  (245, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 38, '生成论文记录，当前阶段：定稿已提交', '2026-09-02 12:54:00'),
  (246, 63, '朱丹', 'SUBMIT_PROPOSAL', 'PROPOSAL', 37, '提交开题报告', '2026-09-08 10:40:00'),
  (247, 3, '侯志强', 'APPROVE_PROPOSAL', 'PROPOSAL', 37, '开题审核通过', '2026-09-10 10:40:00'),
  (248, 63, '朱丹', 'SUBMIT_MIDTERM', 'MIDTERM', 29, '提交中期报告', '2026-09-21 17:38:00'),
  (249, 3, '侯志强', 'APPROVE_MIDTERM', 'MIDTERM', 29, '中期检查通过', '2026-09-22 17:38:00'),
  (250, 63, '朱丹', 'SUBMIT_FINAL', 'FINAL', 20, '提交论文定稿', '2026-09-27 10:13:00'),
  (251, 4, '方辉', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 向浩然 申报的课题《基于计算机视觉的停车位检测》', '2026-09-02 08:30:00'),
  (252, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 39, '生成论文记录，当前阶段：中期已通过', '2026-09-02 08:30:00'),
  (253, 64, '向浩然', 'SUBMIT_PROPOSAL', 'PROPOSAL', 38, '提交开题报告', '2026-09-09 14:21:00'),
  (254, 4, '方辉', 'APPROVE_PROPOSAL', 'PROPOSAL', 38, '开题审核通过', '2026-09-10 14:21:00'),
  (255, 64, '向浩然', 'SUBMIT_MIDTERM', 'MIDTERM', 30, '提交中期报告', '2026-09-19 20:58:00'),
  (256, 4, '方辉', 'APPROVE_MIDTERM', 'MIDTERM', 30, '中期检查通过', '2026-09-22 20:58:00'),
  (257, 5, '钱雨欣', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 尹斌 申报的课题《基于自然语言处理的电商评论情感分析》', '2026-09-02 08:12:00'),
  (258, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 40, '生成论文记录，当前阶段：开题已通过', '2026-09-02 08:12:00'),
  (259, 65, '尹斌', 'SUBMIT_PROPOSAL', 'PROPOSAL', 39, '提交开题报告', '2026-09-10 14:59:00'),
  (260, 5, '钱雨欣', 'APPROVE_PROPOSAL', 'PROPOSAL', 39, '开题审核通过', '2026-09-11 14:59:00');

INSERT INTO `audit_log` (`id`, `actor_id`, `actor_name`, `action`, `target_type`, `target_id`, `detail`, `create_time`) VALUES
  (261, 6, '彭明', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 魏若曦 申报的课题《基于深度学习的工业缺陷检测》', '2026-09-02 11:03:00'),
  (262, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 41, '生成论文记录，当前阶段：待提交开题', '2026-09-02 11:03:00'),
  (263, 7, '曹明', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 林丽 申报的课题《基于时序分析的供应链需求预测》', '2026-09-03 18:58:00'),
  (264, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 42, '生成论文记录，当前阶段：待答辩', '2026-09-03 18:58:00'),
  (265, 67, '林丽', 'SUBMIT_PROPOSAL', 'PROPOSAL', 40, '提交开题报告', '2026-09-08 17:49:00'),
  (266, 7, '曹明', 'APPROVE_PROPOSAL', 'PROPOSAL', 40, '开题审核通过', '2026-09-11 17:49:00'),
  (267, 67, '林丽', 'SUBMIT_MIDTERM', 'MIDTERM', 31, '提交中期报告', '2026-09-18 17:07:00'),
  (268, 7, '曹明', 'APPROVE_MIDTERM', 'MIDTERM', 31, '中期检查通过', '2026-09-20 17:07:00'),
  (269, 67, '林丽', 'SUBMIT_FINAL', 'FINAL', 21, '提交论文定稿', '2026-09-25 13:49:00'),
  (270, 1, '系统管理员', 'ASSIGN_REVIEW', 'REVIEW', 19, '指派 邓桂英 评阅《基于时序分析的供应链需求预测》', '2026-09-28 19:06:00'),
  (271, 20, '邓桂英', 'SUBMIT_REVIEW', 'REVIEW', 19, '提交评阅意见，成绩 76.3', '2026-09-29 08:49:00'),
  (272, 8, '熊宇航', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 刘伟 申报的课题《基于注意力机制的语音情感识别》', '2026-09-02 10:03:00'),
  (273, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 43, '生成论文记录，当前阶段：定稿已提交', '2026-09-02 10:03:00'),
  (274, 68, '刘伟', 'SUBMIT_PROPOSAL', 'PROPOSAL', 41, '提交开题报告', '2026-09-09 09:18:00'),
  (275, 8, '熊宇航', 'APPROVE_PROPOSAL', 'PROPOSAL', 41, '开题审核通过', '2026-09-10 09:18:00'),
  (276, 68, '刘伟', 'SUBMIT_MIDTERM', 'MIDTERM', 32, '提交中期报告', '2026-09-18 15:04:00'),
  (277, 8, '熊宇航', 'APPROVE_MIDTERM', 'MIDTERM', 32, '中期检查通过', '2026-09-21 15:04:00'),
  (278, 68, '刘伟', 'SUBMIT_FINAL', 'FINAL', 22, '提交论文定稿', '2026-09-26 12:29:00'),
  (279, 9, '严嘉怡', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 曾洋 申报的课题《基于边缘计算的无人零售结算》', '2026-09-04 17:37:00'),
  (280, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 44, '生成论文记录，当前阶段：评阅中', '2026-09-04 17:37:00');

INSERT INTO `audit_log` (`id`, `actor_id`, `actor_name`, `action`, `target_type`, `target_id`, `detail`, `create_time`) VALUES
  (281, 69, '曾洋', 'SUBMIT_PROPOSAL', 'PROPOSAL', 42, '提交开题报告', '2026-09-09 14:28:00'),
  (282, 9, '严嘉怡', 'APPROVE_PROPOSAL', 'PROPOSAL', 42, '开题审核通过', '2026-09-11 14:28:00'),
  (283, 69, '曾洋', 'SUBMIT_MIDTERM', 'MIDTERM', 33, '提交中期报告', '2026-09-20 11:16:00'),
  (284, 9, '严嘉怡', 'APPROVE_MIDTERM', 'MIDTERM', 33, '中期检查通过', '2026-09-22 11:16:00'),
  (285, 69, '曾洋', 'SUBMIT_FINAL', 'FINAL', 23, '提交论文定稿', '2026-09-25 09:52:00'),
  (286, 1, '系统管理员', 'ASSIGN_REVIEW', 'REVIEW', 20, '指派 雷娜 评阅《基于边缘计算的无人零售结算》', '2026-09-28 19:39:00'),
  (287, 10, '陈桂英', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 宋娟 申报的课题《基于自然语言处理的短视频内容审核》', '2026-09-04 16:37:00'),
  (288, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 45, '生成论文记录，当前阶段：定稿已提交', '2026-09-04 16:37:00'),
  (289, 70, '宋娟', 'SUBMIT_PROPOSAL', 'PROPOSAL', 43, '提交开题报告', '2026-09-09 17:53:00'),
  (290, 10, '陈桂英', 'APPROVE_PROPOSAL', 'PROPOSAL', 43, '开题审核通过', '2026-09-10 17:53:00'),
  (291, 70, '宋娟', 'SUBMIT_MIDTERM', 'MIDTERM', 34, '提交中期报告', '2026-09-22 16:03:00'),
  (292, 10, '陈桂英', 'APPROVE_MIDTERM', 'MIDTERM', 34, '中期检查通过', '2026-09-24 16:03:00'),
  (293, 70, '宋娟', 'SUBMIT_FINAL', 'FINAL', 24, '提交论文定稿', '2026-09-26 09:00:00'),
  (294, 11, '朱文博', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 吕天佑 申报的课题《基于深度学习的手写公式识别》', '2026-09-04 18:50:00'),
  (295, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 46, '生成论文记录，当前阶段：待答辩', '2026-09-04 18:50:00'),
  (296, 71, '吕天佑', 'SUBMIT_PROPOSAL', 'PROPOSAL', 44, '提交开题报告', '2026-09-11 18:25:00'),
  (297, 11, '朱文博', 'APPROVE_PROPOSAL', 'PROPOSAL', 44, '开题审核通过', '2026-09-13 18:25:00'),
  (298, 71, '吕天佑', 'SUBMIT_MIDTERM', 'MIDTERM', 35, '提交中期报告', '2026-09-18 18:33:00'),
  (299, 11, '朱文博', 'APPROVE_MIDTERM', 'MIDTERM', 35, '中期检查通过', '2026-09-19 18:33:00'),
  (300, 71, '吕天佑', 'SUBMIT_FINAL', 'FINAL', 25, '提交论文定稿', '2026-09-26 11:34:00');

INSERT INTO `audit_log` (`id`, `actor_id`, `actor_name`, `action`, `target_type`, `target_id`, `detail`, `create_time`) VALUES
  (301, 1, '系统管理员', 'ASSIGN_REVIEW', 'REVIEW', 21, '指派 范勇 评阅《基于深度学习的手写公式识别》', '2026-09-28 21:08:00'),
  (302, 22, '范勇', 'SUBMIT_REVIEW', 'REVIEW', 21, '提交评阅意见，成绩 83.7', '2026-09-29 13:00:00'),
  (303, 12, '史一鸣', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 汤子涵 申报的课题《基于知识图谱的课程知识点推荐》', '2026-09-01 14:03:00'),
  (304, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 47, '生成论文记录，当前阶段：评阅已通过', '2026-09-01 14:03:00'),
  (305, 72, '汤子涵', 'SUBMIT_PROPOSAL', 'PROPOSAL', 45, '提交开题报告', '2026-09-08 17:17:00'),
  (306, 12, '史一鸣', 'APPROVE_PROPOSAL', 'PROPOSAL', 45, '开题审核通过', '2026-09-11 17:17:00'),
  (307, 72, '汤子涵', 'SUBMIT_MIDTERM', 'MIDTERM', 36, '提交中期报告', '2026-09-20 16:49:00'),
  (308, 12, '史一鸣', 'APPROVE_MIDTERM', 'MIDTERM', 36, '中期检查通过', '2026-09-23 16:49:00'),
  (309, 72, '汤子涵', 'SUBMIT_FINAL', 'FINAL', 26, '提交论文定稿', '2026-09-26 09:24:00'),
  (310, 1, '系统管理员', 'ASSIGN_REVIEW', 'REVIEW', 22, '指派 董雅静 评阅《基于知识图谱的课程知识点推荐》', '2026-09-28 11:15:00'),
  (311, 23, '董雅静', 'SUBMIT_REVIEW', 'REVIEW', 22, '提交评阅意见，成绩 78.4', '2026-09-29 15:30:00'),
  (312, 13, '姜超', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 余子涵 申报的课题《基于知识图谱的论文文献推荐》', '2026-09-01 13:57:00'),
  (313, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 48, '生成论文记录，当前阶段：待提交开题', '2026-09-01 13:57:00'),
  (314, 14, '刘洋', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 马丹 申报的课题《图书馆推荐系统的设计与实现》', '2026-09-01 19:17:00'),
  (315, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 49, '生成论文记录，当前阶段：开题待审核', '2026-09-01 19:17:00'),
  (316, 74, '马丹', 'SUBMIT_PROPOSAL', 'PROPOSAL', 46, '提交开题报告', '2026-09-08 09:43:00'),
  (317, 15, '毛梓萱', 'APPROVE_SELECTION', 'SELECTION', NULL, '录取 魏文博 申报的课题《基于边缘计算的智能家居协同控制》', '2026-09-04 20:54:00'),
  (318, 1, '系统管理员', 'CREATE_THESIS', 'THESIS', 50, '生成论文记录，当前阶段：定稿已提交', '2026-09-04 20:54:00'),
  (319, 75, '魏文博', 'SUBMIT_PROPOSAL', 'PROPOSAL', 47, '提交开题报告', '2026-09-09 21:59:00'),
  (320, 15, '毛梓萱', 'APPROVE_PROPOSAL', 'PROPOSAL', 47, '开题审核通过', '2026-09-11 21:59:00');

INSERT INTO `audit_log` (`id`, `actor_id`, `actor_name`, `action`, `target_type`, `target_id`, `detail`, `create_time`) VALUES
  (321, 75, '魏文博', 'SUBMIT_MIDTERM', 'MIDTERM', 37, '提交中期报告', '2026-09-20 17:14:00'),
  (322, 15, '毛梓萱', 'APPROVE_MIDTERM', 'MIDTERM', 37, '中期检查通过', '2026-09-23 17:14:00'),
  (323, 75, '魏文博', 'SUBMIT_FINAL', 'FINAL', 27, '提交论文定稿', '2026-09-26 12:59:00'),
  (324, 1, '系统管理员', 'RECORD_DEFENSE', 'DEFENSE', 1, '录入答辩成绩 77.9', '2026-06-11 09:15:00'),
  (325, 1, '系统管理员', 'RECORD_DEFENSE', 'DEFENSE', 2, '录入答辩成绩 91.1', '2026-06-11 09:30:00'),
  (326, 1, '系统管理员', 'RECORD_DEFENSE', 'DEFENSE', 3, '录入答辩成绩 90.3', '2026-06-11 09:45:00'),
  (327, 1, '系统管理员', 'RECORD_DEFENSE', 'DEFENSE', 4, '录入答辩成绩 92.5', '2026-06-11 10:00:00'),
  (328, 1, '系统管理员', 'RECORD_DEFENSE', 'DEFENSE', 5, '录入答辩成绩 76.5', '2026-06-11 10:15:00'),
  (329, 1, '系统管理员', 'RECORD_DEFENSE', 'DEFENSE', 6, '录入答辩成绩 76.0', '2026-06-11 10:30:00'),
  (330, 1, '系统管理员', 'RECORD_DEFENSE', 'DEFENSE', 7, '录入答辩成绩 84.8', '2026-06-12 09:15:00'),
  (331, 1, '系统管理员', 'RECORD_DEFENSE', 'DEFENSE', 8, '录入答辩成绩 82.6', '2026-06-12 09:30:00'),
  (332, 1, '系统管理员', 'RECORD_DEFENSE', 'DEFENSE', 9, '录入答辩成绩 86.2', '2026-06-12 09:45:00'),
  (333, 1, '系统管理员', 'RECORD_DEFENSE', 'DEFENSE', 10, '录入答辩成绩 85.6', '2026-06-12 10:00:00'),
  (334, 1, '系统管理员', 'RECORD_DEFENSE', 'DEFENSE', 11, '录入答辩成绩 84.4', '2026-06-12 10:15:00'),
  (335, 1, '系统管理员', 'RECORD_DEFENSE', 'DEFENSE', 12, '录入答辩成绩 86.3', '2026-06-12 10:30:00'),
  (336, 1, '系统管理员', 'ARCHIVE_THESIS', 'THESIS', 1, '论文材料归档完成', '2026-06-22 10:14:00'),
  (337, 1, '系统管理员', 'ARCHIVE_THESIS', 'THESIS', 3, '论文材料归档完成', '2026-06-23 08:20:00'),
  (338, 1, '系统管理员', 'ARCHIVE_THESIS', 'THESIS', 5, '论文材料归档完成', '2026-06-24 16:54:00'),
  (339, 1, '系统管理员', 'ARCHIVE_THESIS', 'THESIS', 8, '论文材料归档完成', '2026-06-25 08:13:00'),
  (340, 1, '系统管理员', 'ARCHIVE_THESIS', 'THESIS', 10, '论文材料归档完成', '2026-06-22 21:34:00');

INSERT INTO `audit_log` (`id`, `actor_id`, `actor_name`, `action`, `target_type`, `target_id`, `detail`, `create_time`) VALUES
  (341, 1, '系统管理员', 'ARCHIVE_THESIS', 'THESIS', 12, '论文材料归档完成', '2026-06-20 18:48:00');

-- 17. 站内消息（notification）
INSERT INTO `notification` (`id`, `user_id`, `title`, `content`, `link`, `type`, `is_read`, `create_time`) VALUES
  (1, 26, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-03-09 14:54:00'),
  (2, 27, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-03-11 19:37:00'),
  (3, 28, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-03-10 17:43:00'),
  (4, 29, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-03-13 08:28:00'),
  (5, 30, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-03-07 09:31:00'),
  (6, 31, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-03-10 08:02:00'),
  (7, 32, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-03-11 20:10:00'),
  (8, 33, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-03-13 09:10:00'),
  (9, 34, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-03-08 17:58:00'),
  (10, 35, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-03-11 18:17:00'),
  (11, 36, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-03-13 16:45:00'),
  (12, 37, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-03-14 20:28:00'),
  (13, 38, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-09-09 11:37:00'),
  (14, 20, '待评阅任务', '有一篇论文待你评阅：《基于深度学习的医学影像分割》', '/review/mine', 'FLOW', 0, '2026-09-28 15:55:00'),
  (15, 15, '待审核：开题报告', '邹丽 提交了《基于多模态融合的短视频内容审核》的开题报告，请及时处理。', '/proposal/review', 'FLOW', 0, '2026-09-10 08:01:00'),
  (16, 40, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-09-11 18:38:00'),
  (17, 16, '待检查：中期报告', '曹娜 提交了中期报告，请检查。', '/midterm/review', 'FLOW', 0, '2026-09-19 21:13:00'),
  (18, 17, '待审核：开题报告', '于丹 提交了《基于强化学习的动态资源调度》的开题报告，请及时处理。', '/proposal/review', 'FLOW', 0, '2026-09-08 11:57:00'),
  (19, 42, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-09-12 18:39:00'),
  (20, 18, '待检查：中期报告', '孙辉 提交了中期报告，请检查。', '/midterm/review', 'FLOW', 0, '2026-09-19 21:28:00');

INSERT INTO `notification` (`id`, `user_id`, `title`, `content`, `link`, `type`, `is_read`, `create_time`) VALUES
  (21, 43, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-09-12 14:46:00'),
  (22, 3, '待审核：开题报告', '魏宇航 提交了《基于迁移学习的小样本医学影像分类》的开题报告，请及时处理。', '/proposal/review', 'FLOW', 0, '2026-09-09 13:00:00'),
  (23, 46, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-09-13 18:21:00'),
  (24, 47, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-09-13 19:07:00'),
  (25, 5, '待检查：中期报告', '韩芳 提交了中期报告，请检查。', '/midterm/review', 'FLOW', 0, '2026-09-18 12:25:00'),
  (26, 48, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-09-09 21:25:00'),
  (27, 22, '待评阅任务', '有一篇论文待你评阅：《微服务链路追踪平台的设计与实现》', '/review/mine', 'FLOW', 0, '2026-09-28 11:07:00'),
  (28, 49, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-09-12 14:08:00'),
  (29, 50, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-09-15 18:14:00'),
  (30, 51, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-09-12 14:23:00'),
  (31, 23, '待评阅任务', '有一篇论文待你评阅：《基于机器学习的学生成绩分析》', '/review/mine', 'FLOW', 0, '2026-09-28 15:19:00'),
  (32, 52, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-09-12 15:37:00'),
  (33, 10, '待检查：中期报告', '于浩然 提交了中期报告，请检查。', '/midterm/review', 'FLOW', 0, '2026-09-21 10:04:00'),
  (34, 53, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-09-14 14:30:00'),
  (35, 54, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-09-11 10:29:00'),
  (36, 13, '待审核：开题报告', '魏峰 提交了《停车位检测系统的设计与实现》的开题报告，请及时处理。', '/proposal/review', 'FLOW', 0, '2026-09-10 19:56:00'),
  (37, 56, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-09-10 17:22:00'),
  (38, 57, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-09-09 09:50:00'),
  (39, 58, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-09-13 08:30:00'),
  (40, 59, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-09-13 10:08:00');

INSERT INTO `notification` (`id`, `user_id`, `title`, `content`, `link`, `type`, `is_read`, `create_time`) VALUES
  (41, 17, '待检查：中期报告', '韦琳 提交了中期报告，请检查。', '/midterm/review', 'FLOW', 0, '2026-09-18 11:41:00'),
  (42, 60, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-09-12 19:41:00'),
  (43, 25, '待评阅任务', '有一篇论文待你评阅：《基于大语言模型的题库自动组卷》', '/review/mine', 'FLOW', 0, '2026-09-28 20:47:00'),
  (44, 61, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-09-14 10:49:00'),
  (45, 19, '待检查：中期报告', '曾子涵 提交了中期报告，请检查。', '/midterm/review', 'FLOW', 0, '2026-09-18 12:52:00'),
  (46, 62, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-09-13 20:31:00'),
  (47, 63, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-09-10 10:40:00'),
  (48, 64, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-09-10 14:21:00'),
  (49, 65, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-09-11 14:59:00'),
  (50, 67, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-09-11 17:49:00'),
  (51, 68, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-09-10 09:18:00'),
  (52, 69, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-09-11 14:28:00'),
  (53, 21, '待评阅任务', '有一篇论文待你评阅：《基于边缘计算的无人零售结算》', '/review/mine', 'FLOW', 0, '2026-09-28 19:39:00'),
  (54, 70, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-09-10 17:53:00'),
  (55, 71, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-09-13 18:25:00'),
  (56, 72, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-09-11 17:17:00'),
  (57, 14, '待审核：开题报告', '马丹 提交了《图书馆推荐系统的设计与实现》的开题报告，请及时处理。', '/proposal/review', 'FLOW', 0, '2026-09-08 09:43:00'),
  (58, 75, '开题审核结果', '指导教师已通过你的开题报告。', '/thesis/mine', 'FLOW', 1, '2026-09-11 21:59:00'),
  (59, 26, '答辩成绩已发布', '你的答辩成绩为 77.9，总评 84.2。', '/thesis/mine', 'SCORE', 1, '2026-06-12 09:15:00'),
  (60, 27, '答辩成绩已发布', '你的答辩成绩为 91.1，总评 88.1。', '/thesis/mine', 'SCORE', 1, '2026-06-12 09:30:00');

INSERT INTO `notification` (`id`, `user_id`, `title`, `content`, `link`, `type`, `is_read`, `create_time`) VALUES
  (61, 28, '答辩成绩已发布', '你的答辩成绩为 90.3，总评 87.1。', '/thesis/mine', 'SCORE', 1, '2026-06-12 09:45:00'),
  (62, 29, '答辩成绩已发布', '你的答辩成绩为 92.5，总评 87.7。', '/thesis/mine', 'SCORE', 1, '2026-06-12 10:00:00'),
  (63, 30, '答辩成绩已发布', '你的答辩成绩为 76.5，总评 83.8。', '/thesis/mine', 'SCORE', 1, '2026-06-12 10:15:00'),
  (64, 31, '答辩成绩已发布', '你的答辩成绩为 76.0，总评 81.0。', '/thesis/mine', 'SCORE', 1, '2026-06-12 10:30:00'),
  (65, 32, '答辩成绩已发布', '你的答辩成绩为 84.8，总评 84.0。', '/thesis/mine', 'SCORE', 1, '2026-06-13 09:15:00'),
  (66, 33, '答辩成绩已发布', '你的答辩成绩为 82.6，总评 84.0。', '/thesis/mine', 'SCORE', 1, '2026-06-13 09:30:00'),
  (67, 34, '答辩成绩已发布', '你的答辩成绩为 86.2，总评 89.3。', '/thesis/mine', 'SCORE', 1, '2026-06-13 09:45:00'),
  (68, 35, '答辩成绩已发布', '你的答辩成绩为 85.6，总评 86.2。', '/thesis/mine', 'SCORE', 1, '2026-06-13 10:00:00'),
  (69, 36, '答辩成绩已发布', '你的答辩成绩为 84.4，总评 83.4。', '/thesis/mine', 'SCORE', 1, '2026-06-13 10:15:00'),
  (70, 37, '答辩成绩已发布', '你的答辩成绩为 86.3，总评 82.8。', '/thesis/mine', 'SCORE', 1, '2026-06-13 10:30:00');

-- 18. 系统配置（sys_config）
INSERT INTO `sys_config` (`id`, `config_key`, `config_value`, `remark`, `create_time`, `update_time`) VALUES
  (1, 'score.weight.proposal', '20', '开题成绩权重（%）', NOW(), NOW()),
  (2, 'score.weight.midterm', '20', '中期成绩权重（%）', NOW(), NOW()),
  (3, 'score.weight.review', '30', '评阅成绩权重（%）', NOW(), NOW()),
  (4, 'score.weight.defense', '30', '答辩成绩权重（%）', NOW(), NOW()),
  (5, 'deadline.proposal', '2026-10-15', '开题报告提交截止日期', NOW(), NOW()),
  (6, 'deadline.midterm', '2026-11-30', '中期报告提交截止日期', NOW(), NOW()),
  (7, 'deadline.final', '2026-12-31', '论文定稿提交截止日期', NOW(), NOW()),
  (8, 'review.blind.enabled', 'false', '是否默认启用盲审', NOW(), NOW()),
  (9, 'topic.max.per.teacher', '8', '每位指导教师最大在指导学生数', NOW(), NOW()),
  (10, 'current.grade', '2027', '当前默认届别', NOW(), NOW());

-- 演示数据生成完毕。
