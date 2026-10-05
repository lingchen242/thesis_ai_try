# 毕业论文管理系统

面向高校院系的毕业论文（设计）全过程管理系统，覆盖 **选题 → 开题 → 中期检查 → 定稿 → 评阅 → 答辩 → 归档** 完整链路。

> 📖 **完整文档见 [docs/](docs/README.md)** —— 本文只保留仓库入口信息。

| 层 | 选型 |
| --- | --- |
| 前端 | Vue 3 + TypeScript + Vite + Element Plus + Pinia |
| 后端 | Spring Boot 3.2 + MyBatis Plus 3.5 + Spring Security 6 + JWT |
| 数据库 | MySQL 8.0 |
| 文件存储 | 本地静态目录 `backend/storage/uploads/`（经 `/uploads/**` 访问） |

## 目录

```
backend/    后端 Spring Boot 工程
frontend/   前端 Vue3 工程
database/   数据库脚本（建表 + 字典 + 演示数据）
scripts/    演示数据生成与自检脚本
docs/       全部项目文档
```

## 快速开始

```bash
# 1. 初始化数据库
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS thesis_mgmt DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci;"
mysql -u root -p thesis_mgmt < database/01_schema.sql
mysql -u root -p thesis_mgmt < database/02_demo_data.sql

# 2. 配置连接信息（放到被 gitignore 的 application-local.yml，勿改 application.yml）
cd backend/src/main/resources && cp application-local.yml.example application-local.yml
#    编辑 application-local.yml 填入真实 host / port / username / password

# 3. 启动后端（默认激活 local profile，无需额外参数）
cd backend && mvn spring-boot:run

# 4. 启动前端
cd frontend && npm install && npm run dev
```

前端访问 `http://localhost:5173`。

| 角色 | 账号 | 密码 |
| --- | --- | --- |
| 管理员 | `admin` | `admin123` |
| 指导教师 | `t2001` ~ `t2018` | `123456` |
| 评阅教师 | `r3001` ~ `r3006` | `123456` |
| 学生 | `s20260001` ~ `s20270043` | `123456` |

## 文档

| 文档 | 内容 |
| --- | --- |
| [docs/README.md](docs/README.md) | **项目介绍主文档**：快速开始、核心设计、功能模块、常见问题 |
| [docs/PROJECT_PLAN.md](docs/PROJECT_PLAN.md) | 项目计划：需求、权限矩阵、数据模型、状态机、里程碑、风险 |
| [docs/BACKEND.md](docs/BACKEND.md) | 后端架构与代码导读 |
| [docs/BACKEND_REVIEW.md](docs/BACKEND_REVIEW.md) | 后端代码审查报告（分级问题 + 修复建议） |
| [docs/API.md](docs/API.md) | 后端 REST 接口文档（90 个端点） |
| [docs/DATABASE.md](docs/DATABASE.md) | 数据库设计说明 |
| [docs/FRONTEND_SPEC.md](docs/FRONTEND_SPEC.md) | 前端开发规范与自查清单 |
