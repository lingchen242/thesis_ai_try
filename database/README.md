# 数据库脚本说明

本目录存放毕业论文管理系统的 MySQL 8.0 建表与演示数据脚本，**由使用者本地导入**。

## 目录内容

| 文件 | 说明 |
| --- | --- |
| `01_schema.sql` | 建表 DDL，共 20 张表（18 张业务表 + 2 张字典表）。重复执行安全 |
| `02_demo_data.sql` | 字典基础数据 + 演示数据，可反复导入（文件头含 20 条 `TRUNCATE`） |

## 导入步骤

```bash
# 1. 建库
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS thesis_mgmt DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci;"

# 2. 建表
mysql -u root -p thesis_mgmt < database/01_schema.sql

# 3. 灌入字典与演示数据
mysql -u root -p thesis_mgmt < database/02_demo_data.sql
```

> Windows CMD 下如果中文乱码，请先执行 `chcp 65001`，或改用 Git Bash / PowerShell。

## 表结构概览

### 字典表（统一字典管理）

- `sys_dict_type` — 字典类型（COLLEGE / MAJOR / CLASS / GRADE / TOPIC_TYPE / TOPIC_SOURCE / TITLE / DEFENSE_RESULT）
- `sys_dict_item` — 字典项，通过 `parent_id` 支持**学院 → 专业 → 班级**三级树

> 设计说明：学院/专业/班级等可选项统一由字典维护，业务表（学生、课题、论文）**冗余存名称**。
> 这样历史归档数据不会随字典调整而漂移，代价是字典改名不回溯历史记录。

### 业务表

`sys_user`、`student`、`teacher`、`topic`、`selection`、`thesis`、`proposal`、
`midterm_report`、`final_submission`、`review`、`defense_group`、`defense_group_member`、
`defense_record`、`thesis_score`、`attachment`、`audit_log`、`notification`、`sys_config`

## 演示数据规模

| 项目 | 数量 |
| --- | --- |
| 字典类型 / 字典项 | 8 / 55（学院 3、专业 7、班级 28） |
| 管理员 / 指导教师 / 评阅教师 | 1 / 18 / 6 |
| 学生 | 55（2026 届 12、2027 届 43） |
| 课题 | 60（已选 50、开放 10） |
| 选题申请 | 55（通过 50、待审 3、驳回 2） |
| 论文 | 50，覆盖 11 种状态全部取值 |
| 开题 / 中期 / 定稿 | 47 / 37 / 27 |
| 评阅 / 答辩组 / 答辩成绩 | 22 / 3 / 12 |
| 附件 / 操作日志 / 站内消息 | 111 / 341 / 70 |

## 演示账号

密码统一为 `123456`（管理员为 `admin123`），均为 BCrypt（`$2a$10$`）哈希，可直接登录。

| 角色 | 账号 |
| --- | --- |
| 管理员 | `admin` |
| 指导教师 | `t2001` ~ `t2018` |
| 评阅教师 | `r3001` ~ `r3006` |
| 学生 | `s20260001` ~ `s20270043` |

## 重新生成演示数据

演示数据由脚本生成，可调整规模后重新生成（结果可复现，固定随机种子）。

```bash
# 依赖 bcrypt
pip install bcrypt

# 修改 scripts/gen_demo_sql.py 顶部的 N_ADVISOR / N_STUDENT_2027 / N_OPEN_TOPIC 等常量后：
python scripts/gen_demo_sql.py

# 自检：语法结构、唯一键冲突、引用完整性、字典一致性、状态分布
python scripts/check_sql.py
```
