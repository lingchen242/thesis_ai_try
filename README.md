# 毕业论文管理系统

面向高校院系的毕业论文（设计）全过程管理系统，覆盖 **选题 → 开题 → 中期检查 → 定稿 → 评阅 → 答辩 → 归档** 完整链路，做到流程可追溯、材料可留存、进度可视化。

## 技术栈

| 层 | 选型 |
| --- | --- |
| 前端 | Vue 3 + TypeScript + Vite + Element Plus + Pinia + Vue Router + ECharts |
| 后端 | Spring Boot 3.2 + MyBatis Plus 3.5 + Spring Security 6 + JWT |
| 数据库 | MySQL 8.0（utf8mb4 / InnoDB） |
| 文件存储 | **本地静态目录** `backend/storage/uploads/`，通过 `/uploads/**` 映射访问 |
| 构建 | Maven 3.9+ / JDK 17+（已在 JDK 21 上验证） |

## 目录结构（三目录分离）

```
thesis-management/
├── backend/        后端 Spring Boot 工程（含本地静态文件存储目录 storage/）
├── frontend/       前端 Vue3 工程
├── database/       数据库脚本（建表 + 字典 + 演示数据）
├── scripts/        演示数据生成与自检脚本
└── docs/           项目计划文档
```

## 环境要求

- JDK 17 或以上（推荐 17 / 21）
- Maven 3.8 或以上
- Node.js 18 或以上（推荐 20 / 22）
- MySQL 8.0

## 快速开始

### 1. 初始化数据库

```bash
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS thesis_mgmt DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci;"
mysql -u root -p thesis_mgmt < database/01_schema.sql
mysql -u root -p thesis_mgmt < database/02_demo_data.sql
```

详见 [database/README.md](database/README.md)。

### 2. 配置数据库连接

`backend/src/main/resources/application.yml` 中的连接参数是**占位符**，需要替换：

```yaml
spring:
  datasource:
    url: jdbc:mysql://__MYSQL_HOST__:__MYSQL_PORT__/thesis_mgmt?...
    username: __MYSQL_USERNAME__
    password: __MYSQL_PASSWORD__
```

**请把真实连接信息填到 `application-local.yml`**（该文件已被 `.gitignore` 忽略，不会进入版本控制）：

```bash
cd backend/src/main/resources
cp application-local.yml.example application-local.yml
# 编辑 application-local.yml，填入真实的 host / port / username / password
```

`application.yml` 中已设置默认激活 `local` profile：

```yaml
spring:
  profiles:
    active: ${SPRING_PROFILES_ACTIVE:local}
```

因此**无需额外启动参数**，直接启动就会读取 `application-local.yml`；其它环境用环境变量覆盖即可，例如 `SPRING_PROFILES_ACTIVE=prod`。

> ⚠️ 不要把真实账号密码写进 `application.yml`。它是版本控制中的模板文件，一旦填进去就会随提交进入 git 历史。所有个人配置一律放 `application-local.yml`。

### 3. 启动后端

```bash
cd backend
mvn clean package -DskipTests
java -jar target/thesis-management.jar
# 或开发模式
mvn spring-boot:run
```

后端默认监听 `http://localhost:8080`。

### 4. 启动前端

```bash
cd frontend
npm install
npm run dev
```

前端默认监听 `http://localhost:5173`，已配置代理把 `/api` 与 `/uploads` 转发到后端。

### 5. 登录

| 角色 | 账号 | 密码 |
| --- | --- | --- |
| 管理员 | `admin` | `admin123` |
| 指导教师 | `t2001` ~ `t2018` | `123456` |
| 评阅教师 | `r3001` ~ `r3006` | `123456` |
| 学生 | `s20260001` ~ `s20270043` | `123456` |

> 演示数据里 2026 届学生已完成全部流程（答辩完成 / 已归档），2027 届学生分布在进行中的各阶段，可直接用于查看各页面效果。

## 核心设计

### 论文状态机

状态流转规则**唯一真源**在 `backend/src/main/java/com/example/thesis/domain/ThesisStatus.java`：枚举同时定义「允许的下一状态」与「允许执行该流转的角色」，所有变更必须经过 `FlowGuard.ensure()`，非法流转会被拒绝并返回可读原因。

```
DRAFT → PROPOSAL_SUBMITTED → PROPOSAL_APPROVED → MIDTERM_SUBMITTED → MIDTERM_PASSED
     → FINAL_SUBMITTED → REVIEWING → REVIEW_PASSED → DEFENSE_SCHEDULED → DEFENSE_DONE → ARCHIVED
```

其中 `PROPOSAL_SUBMITTED → DRAFT`、`MIDTERM_SUBMITTED → PROPOSAL_APPROVED`、`REVIEWING → FINAL_SUBMITTED` 为三条「退回重交」路径。

### 统一字典管理

- `sys_dict_type` 定义类型，`sys_dict_item` 通过 `parent_id` 支持**学院 → 专业 → 班级**三级树
- 管理员可在「系统管理 → 字典管理」中维护，前端通过 `useDictStore` 按类型缓存
- 业务表（学生/课题/论文）**冗余存名称**，保证归档数据不随字典调整漂移
- 新增学生时，学院/专业/班级必须命中字典，否则拒绝并提示

### 本地文件存储

- 落盘路径：`backend/storage/uploads/{业务类型}/{yyyyMM}/{uuid}.{ext}`
- 访问路径：`/uploads/{业务类型}/{yyyyMM}/{uuid}.{ext}`，由 `WebMvcConfig` 注册为静态资源
- 数据库 `attachment` 表只存相对路径，`storage_driver` 固定为 `local`
- 校验：允许 `pdf/doc/docx/xls/xlsx/zip/jpg/jpeg/png`，单文件 ≤ 20MB，服务端重命名不信任客户端文件名
- `StorageService` 是接口，将来接入云端只需新增实现类并切换 `thesis.storage.driver`，业务代码零改动

### 操作留痕与站内消息

- 每次状态流转、审核、指派、录入成绩都会写 `audit_log`，论文详情页的时间轴即读取该表
- 状态变更会向相关人推送站内消息（顶栏铃铛红点）

## API 约定

- 前缀 `/api`，统一响应体：`{ "code": 0, "message": "ok", "data": ... }`
- `code = 0` 表示成功；非 0 为业务错误，`401` 表示登录失效，`403` 表示越权
- **HTTP 状态码统一返回 200**，前端只需判断 body 中的 `code`（文件下载接口除外）
- 认证方式：请求头 `Authorization: Bearer <token>`

示例：

```bash
# 登录取 token
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'

# 带 token 调用
curl http://localhost:8080/api/dashboard/overview -H "Authorization: Bearer <token>"
```

## 主要功能模块

| 模块 | 说明 |
| --- | --- |
| 数据看板 | 按角色返回不同指标：管理员看全院统计，导师看指导学生，评阅教师看任务量，学生看个人进度 |
| 课题管理 | 教师出题（草稿/发布/关闭），学生浏览与申报 |
| 选题管理 | 导师录取/驳回，录取后自动建立论文记录并回填学生指导教师 |
| 开题管理 | 学生提交（正文 + 附件），导师审核（通过/退回 + 成绩 + 意见） |
| 中期检查 | 学生提交（进度百分比 + 正文），导师检查，超期预警名单 |
| 论文定稿 | 学生上传定稿（多版本），管理员指派评阅 |
| 论文评阅 | 指派（可自动挑任务最少的教师）/ 盲审开关 / 打分评语；全部提交后自动推进状态，平均分 < 60 退回重交 |
| 答辩管理 | 建组 → 设置成员（组长/秘书/委员）→ 编入学生 → 录入成绩，自动推进状态并重算总评 |
| 成绩管理 | 按权重计算总评（开题 20 / 中期 20 / 评阅 30 / 答辩 30，可配置），支持手动重算 |
| 基础数据 | 学生、教师档案维护 |
| 系统管理 | 账号管理、字典管理、系统配置、Excel 批量导入 |
| 个人中心 | 资料查看、修改密码 |
| 站内消息 | 全部/未读筛选、标记已读 |

## 响应式支持

| 断点 | 表现 |
| --- | --- |
| ≥ 1200px | 侧边栏常驻 + 完整表格列 |
| 992 ~ 1200px | 侧边栏常驻 + 精简列 |
| 768 ~ 992px | 侧边栏折叠为抽屉 |
| < 768px | 抽屉菜单 + 表格隐藏次要列、表单单列、抽屉全屏宽度 |

## 常见问题

**Q：启动报错 `Access denied for user` 或 `Unknown database`**
A：`application.yml` 里的占位符还没替换，或数据库未导入。见上文「快速开始」第 1、2 步。

**Q：前端请求 404 / 跨域**
A：确认后端已在 8080 端口启动；前端 `vite.config.ts` 已配置 `/api` 与 `/uploads` 代理，若改了端口需同步修改。

**Q：上传的文件在哪里？**
A：`backend/storage/uploads/`，按业务类型与年月分目录。备份时直接复制该目录即可。

**Q：想让某个教师既能指导又能评阅**
A：在「教师管理」编辑该教师，打开「可被指派评阅」开关（或在字典/数据层把 `teacher_type` 设为 `BOTH`）。

**Q：调整评分权重**
A：「系统管理 → 系统配置」修改 `score.weight.*`，未评分的环节不计入分母，不会把总分拉低。

## 相关文档

- [项目计划文档](docs/PROJECT_PLAN.md) —— 需求、数据模型、状态机、里程碑、风险
- [数据库脚本说明](database/README.md) —— 导入步骤、表结构、演示账号、数据重新生成
