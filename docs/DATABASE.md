# 数据库设计说明

毕业论文管理系统的 MySQL 8.0 数据模型。脚本放在 `database/` 目录，**由使用者本地导入**。

| 项 | 值 |
| --- | --- |
| 数据库 | MySQL 8.0 |
| 库名 | `thesis_mgmt` |
| 字符集 / 排序规则 | `utf8mb4` / `utf8mb4_0900_ai_ci` |
| 存储引擎 | InnoDB |
| 表数量 | 20（18 张业务表 + 2 张字典表） |
| 脚本位置 | `database/01_schema.sql`、`database/02_demo_data.sql` |

---

## 一、目录内容

| 文件 | 说明 |
| --- | --- |
| `01_schema.sql` | 建表 DDL。重复执行安全（先 `DROP` 后 `CREATE`，会清空数据） |
| `02_demo_data.sql` | 字典基础数据 + 演示数据。文件头含 20 条 `TRUNCATE`，可反复导入 |
| `README.md` | 目录指引（详细说明见本文档） |

## 二、导入步骤

```bash
# 1. 建库
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS thesis_mgmt DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci;"

# 2. 建表
mysql -u root -p thesis_mgmt < database/01_schema.sql

# 3. 灌入字典与演示数据
mysql -u root -p thesis_mgmt < database/02_demo_data.sql
```

> Windows CMD 下如遇中文乱码，先执行 `chcp 65001`，或改用 Git Bash / PowerShell 导入。

---

## 三、表结构概览

### 3.1 字典表（统一字典管理）

| 表 | 说明 | 关键字段 |
| --- | --- | --- |
| `sys_dict_type` | 字典类型 | `type_code`(唯一) / `type_name` / `remark` |
| `sys_dict_item` | 字典项，支持树形 | `type_code` / `item_code` / `item_name` / `parent_id` / `sort_no` / `status` |

`sys_dict_item.parent_id` 指向同表 `id`，据此构成 **学院 → 专业 → 班级** 三级树。

**内置字典类型**

| type_code | 类型名 | 层级 | 说明 |
| --- | --- | --- | --- |
| `COLLEGE` | 学院 | 一级（`parent_id` 为 NULL） | 3 项 |
| `MAJOR` | 专业 | 二级（父级为学院） | 7 项 |
| `CLASS` | 班级 | 三级（父级为专业） | 28 项 |
| `GRADE` | 届别 | 一级 | 2026 / 2027 |
| `TOPIC_TYPE` | 课题类型 | 一级 | 理论研究 / 工程设计 / 软件开发 / 实验研究 / 调研报告 |
| `TOPIC_SOURCE` | 课题来源 | 一级 | 教师命题 / 企业真题 / 学生自拟 |
| `TITLE` | 教师职称 | 一级 | 教授 / 副教授 / 讲师 / 助教 |
| `DEFENSE_RESULT` | 答辩结论 | 一级 | 通过 / 暂缓 / 不通过 |

### 3.2 账号与档案

| 表 | 说明 | 关键字段 |
| --- | --- | --- |
| `sys_user` | 登录账号 | `username` / `password`(BCrypt) / `real_name` / `role` / `status` |
| `teacher` | 教师档案 | `user_id` / `teacher_no` / `title` / `college` / `max_quota` / `can_review` |
| `student` | 学生档案 | `user_id` / `student_no` / `grade` / `college` / `major` / `class_name` / `advisor_id` |

`sys_user.role` 取值：`STUDENT` / `ADVISOR` / `REVIEWER` / `ADMIN`。

### 3.3 流程业务表

| 表 | 说明 | 关键字段 |
| --- | --- | --- |
| `topic` | 课题 | `title` / `teacher_id` / `capacity` / `selected_count` / `status` / `grade` |
| `selection` | 选题申请 | `topic_id` / `student_id` / `status` / `student_remark` / `teacher_comment` |
| `thesis` | 论文主表 | `student_id` / `topic_id` / `advisor_id` / `status` / `current_stage` |
| `proposal` | 开题报告 | `thesis_id` / `content` / `review_status` / `review_comment` / `score` |
| `midterm_report` | 中期报告 | `thesis_id` / `progress_percent` / `review_status` / `score` |
| `final_submission` | 定稿（多版本） | `thesis_id` / `file_url` / `version` / `submit_time` |
| `review` | 评阅 | `thesis_id` / `reviewer_id` / `score` / `comment` / `status` / `blind` |
| `defense_group` | 答辩组 | `name` / `grade` / `defense_date` / `location` / `secretary_id` |
| `defense_group_member` | 答辩组成员 | `group_id` / `teacher_id` / `role_in_group` |
| `defense_record` | 答辩成绩与编组 | `thesis_id` / `group_id` / `score` / `result` |
| `thesis_score` | 总评 | `proposal_score` / `midterm_score` / `review_score` / `defense_score` / `total_score` |

### 3.4 支撑表

| 表 | 说明 | 关键字段 |
| --- | --- | --- |
| `attachment` | 附件登记 | `biz_type` / `biz_id` / `file_name` / `file_url` / `storage_driver` |
| `audit_log` | 操作留痕 | `actor_id` / `actor_name` / `action` / `target_type` / `target_id` / `detail` |
| `notification` | 站内消息 | `user_id` / `title` / `content` / `link` / `type` / `is_read` |
| `sys_config` | 系统配置 | `config_key` / `config_value` / `remark` |

---

## 四、实体关系

```
sys_user 1───1 teacher ──┐
   │                     │
   │                     ├──< topic >──┐
   └───1 student ────────┘             │
            │  advisor_id ──> teacher │
            │                          │
            └──< selection >────────────┘   (topic_id)
                    │
                    │ 录取后自动创建
                    ▼
                 thesis ────┬── proposal        (1:1，可多次提交保留最新)
                    │       ├── midterm_report   (1:1)
                    │       ├── final_submission (1:N，多版本)
                    │       ├── review           (1:N，多评阅人)
                    │       ├── defense_record   (1:1，同时承载编组关系)
                    │       └── thesis_score     (1:1)
                    │
                    └──< attachment >   (通过 biz_type + biz_id 关联)
                    └──< audit_log >    (通过 target_type + target_id 关联)
```

**几个关键关系说明**

| 关系 | 实现方式 | 说明 |
| --- | --- | --- |
| 学生 → 指导教师 | `student.advisor_id` | 选题录取时自动回填 |
| 选题 → 论文 | `selection` 录取时由服务端创建 `thesis` | 一名学生仅一篇论文 |
| 论文 → 答辩组 | `defense_record`（一题一条） | **不单独建关联表**：成绩为空即表示「已编组待答辩」，避免多一张表 |
| 附件 → 业务 | `attachment.biz_type` + `biz_id` | 通用附件表，不随业务表增加而扩展 |
| 留痕 → 业务 | `audit_log.target_type` + `target_id` | 论文详情页时间轴即按此查询 |

---

## 五、索引设计

| 表 | 索引 | 用途 |
| --- | --- | --- |
| `sys_dict_item` | `(type_code, parent_id)` | 字典三级联动的核心查询路径 |
| `sys_dict_item` | `uk(type_code, item_code)` | 同类型下编码唯一 |
| `thesis` | `(status, grade)` | 看板按阶段 / 届别统计 |
| `thesis` | `(advisor_id)` | 指导教师查看自己指导的论文 |
| `selection` | `(topic_id, status)` | 课题的待审申请列表 |
| `review` | `(reviewer_id, status)` | 评阅教师待办清单 |
| `attachment` | `(biz_type, biz_id)` | 按业务记录取附件 |
| `audit_log` | `(target_type, target_id)` | 时间轴查询 |

统计类查询（`GROUP BY status`、`GROUP BY grade`）直接走 `thesis` 上的复合索引。

---

## 六、设计取舍（重要）

### 6.1 为什么不建物理外键

所有表**只建索引，不建 `FOREIGN KEY` 约束**。原因：

- 便于数据维护、分批导入与表重建，不会被外键顺序卡住
- 演示数据生成脚本可自由控制插入顺序
- 引用完整性由**应用层 + 脚本自检**保证，而非数据库

> `scripts/check_sql.py` 会校验全部引用关系（含 `sys_dict_item.parent_id` 自引用），导入前即可发现问题。

### 6.2 业务表为什么冗余存名称

`student.college / major / class_name`、`topic.grade`、`thesis.major` 等字段存的是**名称而非字典 id**。

| 好处 | 代价 |
| --- | --- |
| 历史归档数据不随字典调整而漂移 | 字典改名不回溯历史记录 |
| 列表查询无需 join 字典表，简单高效 | 存储轻微冗余 |

对「毕业设计归档」这个场景，**数据稳定性比实时一致性更重要**——若干年后学院改名，当年毕业生的档案里应当仍是当年那个学院名。

代价是：新增学生 / 课题时，这些字段必须命中字典项，否则接口直接拒绝并提示去字典管理维护（见 `UserService.checkDict()`）。

### 6.3 为什么用逻辑删除

`sys_user` / `teacher` / `student` / `topic` / `thesis` 等表带 `deleted` 字段（MyBatis Plus `@TableLogic`）。删除即置 `deleted = 1`，查询自动过滤。

- 字典表、日志表（`audit_log`）、消息表（`notification`）、`defense_group_member` **不需要**逻辑删除，物理删除即可。
- 关联数据未清理时，服务层会**主动拒绝删除**（如「该教师名下还有 4 名学生，无法删除」），而不是靠数据库报错。

### 6.4 时间字段

所有表统一 `create_time` / `update_time`，由 DDL 的 `DEFAULT CURRENT_TIMESTAMP` 与 `ON UPDATE CURRENT_TIMESTAMP` 维护，应用层不需要显式赋值（MyBatis Plus 默认忽略 null 字段，不会覆盖默认值）。

---

## 七、演示数据

### 7.1 数据规模

| 项目 | 数量 |
| --- | --- |
| 字典类型 / 字典项 | 8 / 55（学院 3、专业 7、班级 28） |
| 管理员 / 指导教师 / 评阅教师 | 1 / 18 / 6 |
| 学生 | 55（2026 届 12、2027 届 43） |
| 课题 | 60（已选 50、开放 10） |
| 选题申请 | 55（通过 50、待审 3、驳回 2） |
| 论文 | 50，覆盖 **11 种状态全部取值** |
| 开题 / 中期 / 定稿 | 47 / 37 / 27 |
| 评阅 / 答辩组 / 答辩成绩 | 22 / 3 / 12 |
| 附件 / 操作日志 / 站内消息 | 111 / 341 / 70 |

> 2026 届按 2026-01~06 的真实节奏排布，已完成全流程；2027 届各环节集中在 2026-08~09（压缩时间线），用于演示进行中的各阶段页面。

### 7.2 演示账号

密码统一 `123456`（管理员 `admin123`），均为 BCrypt（`$2a$10$`）哈希，可直接登录。

| 角色 | 账号 |
| --- | --- |
| 管理员 | `admin` |
| 指导教师 | `t2001` ~ `t2018` |
| 评阅教师 | `r3001` ~ `r3006` |
| 学生 | `s20260001` ~ `s20270043` |

### 7.3 重新生成

演示数据由脚本生成，固定随机种子（`SEED=20261002`），结果可复现。

```bash
pip install bcrypt

# 调整 scripts/gen_demo_sql.py 顶部的 N_ADVISOR / N_STUDENT_2027 / N_OPEN_TOPIC 等常量后：
python scripts/gen_demo_sql.py

# 自检：语法结构、唯一键冲突、引用完整性、字典一致性、状态分布
python scripts/check_sql.py
```

**自检项**：

| 检查 | 内容 |
| --- | --- |
| 结构 | 每张表都有 `CREATE TABLE`、主键、`ENGINE=InnoDB` |
| 唯一键 | 按 DDL 中的唯一键校验无重复 |
| 引用完整性 | 全部外键引用（含字典自引用）均指向存在的记录 |
| **字典一致性** | `student.college/major/class_name`、`topic.topic_type/source`、`teacher.title` 等字段的值必须命中对应字典项 |
| 状态分布 | 确认 11 种论文状态均有数据 |

---

## 八、相关文档

- [API 文档](API.md) —— 接口与字段含义
- [项目计划文档](PROJECT_PLAN.md) —— 数据模型的设计背景与里程碑
- [前端开发规范](FRONTEND_SPEC.md)
