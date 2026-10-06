# 毕业论文管理系统

面向高校院系的毕业论文（设计）全过程管理系统，覆盖 **选题 → 开题 → 中期检查 → 定稿 → 评阅 → 答辩 → 归档** 完整链路，做到流程可追溯、材料可留存、进度可视化。

本文件是项目介绍主文档，包含核心设计与配置说明。**只想先把系统跑起来**的话，看仓库根目录的 [README.md](../README.md) 即可。

## 文档索引

| 文档 | 内容 |
| --- | --- |
| [USER_GUIDE.md](USER_GUIDE.md) | 使用说明：四类角色各自的操作流程 |
| [PROJECT_PLAN.md](PROJECT_PLAN.md) | 需求、角色权限矩阵、数据模型、状态机、里程碑、风险 |
| [BACKEND.md](BACKEND.md) | 后端架构与代码导读：分层、请求生命周期、业务规则位置、扩展点 |
| [API.md](API.md) | 后端 REST 接口：约定、数据权限、90 个端点、时序、cURL 示例 |
| [DATABASE.md](DATABASE.md) | 数据库设计：20 张表、实体关系、索引、设计取舍、演示数据 |
| [FRONTEND_SPEC.md](FRONTEND_SPEC.md) | 前端开发规范与合规自查清单 |

---

## 技术栈

| 层 | 选型 |
| --- | --- |
| 前端 | Vue 3（组合式 API）+ TypeScript + Vite + Element Plus + Pinia + Vue Router + ECharts |
| 后端 | Spring Boot 3.2 + MyBatis Plus 3.5 + Spring Security 6 + JJWT 0.11.5 |
| 数据库 | MySQL 8.0（utf8mb4 / InnoDB，20 张表） |
| 文件存储 | 本地静态目录 `backend/storage/uploads/`，经 `/uploads/**` 访问 |
| 构建 | Maven 3.8+ / JDK 17+（已在 JDK 21 验证）；Node 18+ |

## 目录结构（三目录分离）

```
.
├── backend/        后端 Spring Boot 工程（含本地文件存储目录 storage/）
├── frontend/       前端 Vue3 工程
├── database/       数据库脚本（建表 + 字典 + 演示数据）
├── scripts/        演示数据生成与自检脚本
└── docs/           全部项目文档
```

---

## 快速开始

### 1. 初始化数据库

```bash
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS thesis_mgmt DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci;"
mysql -u root -p thesis_mgmt < database/01_schema.sql
mysql -u root -p thesis_mgmt < database/02_demo_data.sql
```

详见 [DATABASE.md](DATABASE.md)。

### 2. 配置数据库连接

真实连接信息**不要写进 `application.yml`**（那是版本控制中的模板，只含占位符），而是放到被 gitignore 的 `application-local.yml`：

```bash
cd backend/src/main/resources
cp application-local.yml.example application-local.yml
# 编辑 application-local.yml，填入真实的 host / port / username / password
```

`application.yml` 中已设置默认激活 `local` profile：

```yaml
spring:
  profiles:
    active: "${SPRING_PROFILES_ACTIVE:local}"
```

因此**无需额外启动参数**，直接启动即可。其它环境用环境变量覆盖：`SPRING_PROFILES_ACTIVE=prod`。

### 3. 启动后端

```bash
cd backend
mvn clean package -DskipTests
java -jar target/thesis-management.jar
# 或开发模式
mvn spring-boot:run
```

后端监听 `http://localhost:8080`。

### 4. 启动前端

```bash
cd frontend
npm install
npm run dev
```

前端监听 `http://localhost:5173`，已配置代理把 `/api` 与 `/uploads` 转发到后端。

### 5. 登录

| 角色 | 账号 | 密码 |
| --- | --- | --- |
| 管理员 | `admin` | `admin123` |
| 指导教师 | `t2001` ~ `t2018` | `123456` |
| 评阅教师 | `r3001` ~ `r3006` | `123456` |
| 学生 | `s20260001` ~ `s20270043` | `123456` |

> 演示数据由脚本生成，**姓名、学号、联系方式均为虚构**，仅用于功能演示。密码仅为演示便利，请勿在生产环境沿用。
>
> 数据中 2026 届学生已完成全流程（答辩完成 / 已归档），2027 届学生分布在进行中的各阶段，可以直接查看各类页面的实际效果。

各角色具体怎么操作，见 [USER_GUIDE.md](USER_GUIDE.md)。

---

## 核心设计

### 论文状态机

流转规则的**唯一真源**是 `backend/src/main/java/com/example/thesis/domain/ThesisStatus.java`：枚举同时定义「允许的下一状态」与「允许执行该流转的角色」，所有变更必须经过 `FlowGuard.ensure()`，非法流转会被拒绝并返回可读原因。

```
DRAFT → PROPOSAL_SUBMITTED → PROPOSAL_APPROVED → MIDTERM_SUBMITTED → MIDTERM_PASSED
     → FINAL_SUBMITTED → REVIEWING → REVIEW_PASSED → DEFENSE_SCHEDULED → DEFENSE_DONE → ARCHIVED
```

三条「退回重交」路径：`PROPOSAL_SUBMITTED → DRAFT`、`MIDTERM_SUBMITTED → PROPOSAL_APPROVED`、`REVIEWING → FINAL_SUBMITTED`。

各服务不重复写状态判断，这也保证了通过任何入口触发的流转都受同一套规则约束。

### 统一字典管理

- `sys_dict_type` 定义类型，`sys_dict_item` 通过 `parent_id` 支持**学院 → 专业 → 班级**三级树
- 管理员在「系统管理 → 字典管理」维护，前端按类型缓存，避免每个下拉框重复请求
- 业务表**冗余存名称**，保证归档数据不随字典调整漂移（详见 [DATABASE.md](DATABASE.md#62-业务表为什么冗余存名称)）
- 新增学生 / 课题时，相关字段必须命中字典项，否则拒绝并提示

### 本地文件存储

- 落盘：`backend/storage/uploads/{业务类型}/{yyyyMM}/{uuid}.{ext}`
- 访问：`/uploads/{业务类型}/{yyyyMM}/{uuid}.{ext}`，由 `WebMvcConfig` 注册为静态资源
- 数据库 `attachment` 表只存相对路径，`storage_driver` 固定为 `local`
- 校验：允许 `pdf/doc/docx/xls/xlsx/zip/jpg/jpeg/png`，单文件 ≤ 20MB，服务端 UUID 重命名
- `StorageService` 是接口，将来接入云端只需新增实现类并切换 `thesis.storage.driver`，业务代码零改动

### 操作留痕与站内消息

- 状态流转、审核、指派、录入成绩都会写 `audit_log`，论文详情页时间轴即读该表
- 状态变更向相关人推送站内消息（顶栏铃铛红点）
- 留痕与业务写操作在同一事务内，业务回滚时留痕一起回滚，不会出现「操作没成功但有记录」

### 认证方式

无状态 JWT：登录时把用户 ID 用固定密钥签成一个有效期 12 小时的凭证，之后每次请求验签并**回查数据库**取最新状态。这样账号被禁用、被删除、角色被调整都会立即生效，代价是每个请求多一次主键查询。

详细逻辑见 [BACKEND.md](BACKEND.md)，接口约定见 [API.md](API.md)。

---

## 功能模块

| 模块 | 说明 |
| --- | --- |
| 数据看板 | 按角色返回不同指标：管理员看全院统计，导师看指导学生，评阅教师看任务量，学生看个人进度 |
| 课题管理 | 教师出题（草稿 / 发布 / 关闭），学生浏览与申报 |
| 选题管理 | 导师录取 / 驳回，录取后自动创建论文记录并回填学生指导教师 |
| 开题管理 | 学生提交（正文 + 附件），导师审核（通过 / 退回 + 成绩 + 意见） |
| 中期检查 | 学生提交（进度百分比 + 正文），导师检查，超期预警名单 |
| 论文定稿 | 学生上传定稿（多版本），管理员指派评阅 |
| 论文评阅 | 指派（可自动挑任务最少的教师）/ 盲审开关 / 打分评语；全部提交后自动推进，平均分 < 60 退回重交 |
| 答辩管理 | 建组 → 设置成员（组长 / 秘书 / 委员）→ 编入学生 → 录入成绩，自动推进并重算总评 |
| 成绩管理 | 按权重计算总评（开题 20 / 中期 20 / 评阅 30 / 答辩 30，可配置），未评分环节不计入分母 |
| 基础数据 | 学生、教师档案维护 |
| 系统管理 | 账号管理、字典管理、系统配置、Excel 批量导入 |
| 个人中心 | 资料查看、修改密码 |
| 站内消息 | 全部 / 未读筛选、标记已读 |

---

## 响应式支持

| 断点 | 表现 |
| --- | --- |
| ≥ 1200px | 侧边栏常驻 + 完整表格列 |
| 992 ~ 1200px | 侧边栏常驻 + 精简列 |
| 768 ~ 992px | 侧边栏折叠为抽屉 |
| < 768px | 抽屉菜单 + 表格隐藏次要列、表单单列、抽屉全屏宽度 |

---

## 常见问题

**Q：启动报 `Access denied for user` 或 `Unknown database`**
A：`application-local.yml` 没建或没填对，或数据库未导入。见「快速开始」第 1、2 步。

**Q：前端请求 404 / 跨域**
A：确认后端已在 8080 端口启动；`vite.config.ts` 已配置 `/api` 与 `/uploads` 代理，改端口需同步修改。

**Q：登录成功后立刻提示「登录状态已失效」**
A：确认后端与前端都已是最新代码。排查时看浏览器 Network 中请求是否带 `Authorization: Bearer ...` 头，即可定位是前端未带还是后端未认。

**Q：重启后端后，已登录的用户全部掉线**
A：正常情况下不会。只有在没有配置 JWT 签名密钥时才会——此时服务每次启动都会随机生成密钥，重启后旧 Token 自然失效。要避免就在 `application-local.yml` 中配置一个固定的随机字符串（≥ 32 字节）：

```yaml
thesis:
  jwt:
    secret: "用 openssl rand -base64 48 生成的随机串"
```

**Q：上传的文件在哪里？**
A：`backend/storage/uploads/`，按业务类型与年月分目录。备份时直接复制该目录。

**Q：想让某教师既能指导又能评阅**
A：在「教师管理」编辑该教师，打开「可被指派评阅」开关。

**Q：调整评分权重**
A：「系统管理 → 系统配置」修改 `score.weight.*`，未评分环节不计入分母。

---

## 已知限制

用于正式场景前请了解：

| 项 | 现状 |
| --- | --- |
| 开题 / 中期 / 选题列表的数据范围 | 评阅教师未被限制，可读到全院数据。**已知缺陷，尚未修复** |
| 登录接口 | 无失败次数限制 |
| Token 黑名单 | 内存实现，多实例部署需替换为 Redis |
| Token 有效期 | 无滑动续期，默认 12 小时，到点需重新登录 |
| 论文查重 | 未实现 |
| 演示数据密码 | 较简单，仅供本地体验 |

---

## 验证状态

| 项 | 结果 |
| --- | --- |
| 后端 `mvn clean package -DskipTests` | 通过，产出 `target/thesis-management.jar` |
| 前端 `vue-tsc --noEmit` | 0 错误 |
| 前端 `vite build` | 通过 |
| 数据库脚本 `scripts/check_sql.py` | 结构 / 唯一键 / 引用完整性 / 字典一致性 / 状态分布 全部通过 |
| 前端规范自查（9 项） | 全部通过，见 [FRONTEND_SPEC.md](FRONTEND_SPEC.md#十五合规现状) |
