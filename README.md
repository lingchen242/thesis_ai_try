# 毕业论文管理系统

面向高校院系的毕业论文（设计）全过程管理系统，覆盖 **选题 → 开题 → 中期检查 → 定稿 → 评阅 → 答辩 → 归档** 完整链路。

把论文流程从「微信群 + Excel + 邮件附件」搬进一套可追溯的系统：每一步流转都有规则约束、有操作留痕、有材料留档，进度对各方可见。

## 特性

**流程闭环**

- 11 个论文状态的完整状态机，允许的流转与可操作角色集中定义在单一枚举里，非法流转会被拒绝并返回可读原因
- 三条「退回重交」路径：开题被退回、中期被退回、评阅不合格退回，学生可就地修改重提
- 选题录取时自动建立论文记录并回填学生指导教师；评阅全部提交后自动结算推进

**权限与数据范围**

- 四类角色：学生、指导教师、评阅教师、管理员
- 三级权限：路由级（哪些接口免登录）、方法级（哪些接口限管理员）、数据级（只能看到与自己相关的数据）
- 账号被禁用或删除后，已签发的 Token 立即失效

**材料与留痕**

- 附件走本地静态目录，服务端 UUID 重命名、扩展名白名单、大小上限校验
- 每次状态流转、审核、指派、录入成绩都写操作留痕，论文详情页的时间轴即读该表
- 状态变更自动推送站内消息，顶栏红点提示

**避免人工算错**

- 总评按权重加权，且**未评分的环节不计入分母**——不会因为还没答辩就把总分拉到 0
- 超期未提交自动预警，列出超期最久的优先处理
- 评阅指派可自动挑选当前待办最少的教师
- 答辩成绩留空时按分数自动判定结论

**易维护**

- 统一字典管理，学院 → 专业 → 班级三级树，业务表冗余存名称以保证归档数据稳定
- Excel 批量导入账号，全量校验通过才落库，不会出现「导了一半」
- 自适应布局：1440 / 1024 / 768 / 375 宽度下均无横向滚动

## 技术栈

| 层 | 选型 |
| --- | --- |
| 前端 | Vue 3（组合式 API）+ TypeScript + Vite + Element Plus + Pinia + Vue Router + ECharts |
| 后端 | Spring Boot 3.2 + MyBatis Plus 3.5 + Spring Security 6 + JJWT 0.11.5 |
| 数据库 | MySQL 8.0（utf8mb4 / InnoDB，20 张表） |
| 文件存储 | 本地静态目录，经 `/uploads/**` 访问（存储层为接口，可替换为云端） |
| 构建 | Maven 3.8+ / JDK 17+（已在 JDK 21 验证）；Node 18+ |

## 快速开始

### 1. 初始化数据库

```bash
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS thesis_mgmt DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci;"
mysql -u root -p thesis_mgmt < database/01_schema.sql
mysql -u root -p thesis_mgmt < database/02_demo_data.sql
```

### 2. 配置数据库连接

不要改 `application.yml`（那是版本控制中的模板，只含占位符），而是：

```bash
cd backend/src/main/resources
cp application-local.yml.example application-local.yml
# 编辑 application-local.yml，填入真实的 host / port / username / password
```

`application.yml` 已设置默认激活 `local` profile，**直接启动即可，无需额外参数**。`application-local.yml` 已被 `.gitignore` 忽略，不会提交。

### 3. 启动

```bash
# 后端（默认 http://localhost:8080）
cd backend
mvn clean package -DskipTests
java -jar target/thesis-management.jar

# 前端（默认 http://localhost:5173，已配置 /api 与 /uploads 代理）
cd frontend
npm install
npm run dev
```

## 演示账号

| 角色 | 账号 | 密码 |
| --- | --- | --- |
| 管理员 | `admin` | `admin123` |
| 指导教师 | `t2001` ~ `t2018` | `123456` |
| 评阅教师 | `r3001` ~ `r3006` | `123456` |
| 学生 | `s20260001` ~ `s20270043` | `123456` |

> 演示数据由脚本生成，**姓名、学号、联系方式均为虚构**，仅用于功能演示。密码仅为演示便利，请勿在生产环境沿用。数据中 2026 届学生已走完全流程，2027 届分布在进行中的各阶段，方便查看各类页面。

## 目录结构

```
.
├── backend/       后端 Spring Boot 工程（含本地文件存储目录 storage/）
├── frontend/      前端 Vue3 工程
├── database/      数据库脚本（建表 + 字典 + 演示数据）
├── scripts/       演示数据生成与自检脚本
└── docs/          全部项目文档
```

## 文档

| 文档 | 内容 |
| --- | --- |
| [docs/README.md](docs/README.md) | **项目介绍主文档**：核心设计、功能模块、配置说明、常见问题 |
| [docs/USER_GUIDE.md](docs/USER_GUIDE.md) | 使用说明：四类角色各自的操作流程 |
| [docs/PROJECT_PLAN.md](docs/PROJECT_PLAN.md) | 项目计划：需求、权限矩阵、数据模型、状态机、里程碑、风险 |
| [docs/BACKEND.md](docs/BACKEND.md) | 后端架构与代码导读：分层、请求生命周期、扩展点 |
| [docs/API.md](docs/API.md) | 后端 REST 接口文档（90 个端点、数据权限、调用时序） |
| [docs/DATABASE.md](docs/DATABASE.md) | 数据库设计：20 张表、实体关系、索引、设计取舍 |
| [docs/FRONTEND_SPEC.md](docs/FRONTEND_SPEC.md) | 前端开发规范与合规自查清单 |
| [docs/BACKEND_REVIEW.md](docs/BACKEND_REVIEW.md) | 后端代码审查报告：分级问题清单与修复建议 |

## 已知限制

在用于正式场景前，请了解以下几点：

- **开题 / 中期 / 选题三个列表接口对评阅教师未做数据范围限制**，评阅教师可读到全院数据。这是已知缺陷且尚未修复，详见 [BACKEND_REVIEW.md 的 P1-1](docs/BACKEND_REVIEW.md#p1-1-数据权限不一致reviewer-可越权读取全部开题--中期--选题数据)
- 登录接口无失败次数限制
- Token 黑名单为内存实现，多实例部署需替换为 Redis
- 无 Token 滑动续期，有效期默认 12 小时，到点需重新登录
- 未实现论文查重
- 演示数据的密码较简单，仅供本地体验

## 许可

本仓库暂未指定开源许可证。如需他人自由使用、修改与分发，请补充 `LICENSE` 文件（如 MIT、Apache-2.0）；未指定时默认保留全部权利。
