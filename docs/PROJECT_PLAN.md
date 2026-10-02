# 毕业论文管理系统 · 项目计划文档

> 版本：v2.0（技术栈修订版）
> 日期：2026-10-02
> 状态：**待确认** —— 确认后进入编码阶段
> 变更记录：v1.0 采用 Node/Express + SQLite；v2.0 按用户要求改为 **Spring Boot 3 + MyBatis Plus + MySQL 8.0**，角色调整为四类，初始账号改为批量导入。

---

## 一、项目目标

面向高校院系的毕业论文（设计）全过程管理系统：把「选题 → 开题 → 中期检查 → 定稿 → 评阅 → 答辩 → 归档」这条主线从线下表格和微信群搬到系统上，做到**流程可追溯、材料可留存、进度可视化**。

用户原始要求与落地方案对照：

| 要求 | 落地方案 |
| --- | --- |
| 登录认证 | 账号密码 + Spring Security + JWT，角色路由守卫 + 接口级鉴权 |
| 数据看板 | 首页 Dashboard，按角色展示不同指标与图表（ECharts） |
| 列表管理 | 统一表格页：筛选 / 搜索 / 排序 / 分页 / 批量操作 / 导出 |
| 表单编辑 | 抽屉 / 弹窗表单，校验、草稿、附件上传 |
| 论文审查过程功能 | 状态机驱动的流转引擎 + 各阶段审核表单 + 操作留痕 |
| 数据使用本地数据库 | MySQL 8.0（本机或内网实例），库名 `thesis_mgmt` |
| 文件使用云端存储 | WorkBuddy 云端存储（前端直传），DB 只存 URL；含本地磁盘驱动回退 |
| 响应式布局 | Element Plus 栅格 + 断点适配，支持桌面 / 平板 / 手机 |
| 初始账号批量导入 | 提供 Excel 模板 + 后端导入接口；首次数据由演示 SQL 灌入 |

---

## 二、技术选型

### 2.1 已确认

| 层 | 选型 |
| --- | --- |
| 前端 | Vue 3 + TypeScript + Vite + Element Plus + Pinia + Vue Router 4 |
| 图表 | ECharts + vue-echarts |
| 后端 | **Spring Boot 3.2（JDK 17）** |
| ORM | **MyBatis Plus 3.5** |
| 数据库 | **MySQL 8.0**（utf8mb4 / InnoDB） |
| 安全 | Spring Security 6 + JWT（jjwt）+ BCrypt |
| 校验 | Jakarta Validation + 全局异常处理 |
| 构建 | Maven（单模块起步） |

### 2.2 角色定义（四类）

| 角色 | 编码 | 说明 |
| --- | --- | --- |
| 学生 | `STUDENT` | 选题、提交各阶段材料、查看本人进度与成绩 |
| 指导教师 | `ADVISOR` | 发布课题、录取选题、审核开题/中期、查看指导学生 |
| 评阅教师 | `REVIEWER` | 被指派后对论文定稿评阅打分 |
| 管理员 | `ADMIN` | 用户与基础数据管理、指派评阅、答辩分组、流程监控、系统配置 |

> 一名教师可同时具备指导与评阅能力，由管理员在教师档案中勾选「可评阅」；登录角色决定菜单与接口权限范围。

### 2.3 我做的假设（如与预期不符请在审核时指出）

1. 「【管理内容】」按**毕业论文（设计）全流程**理解，管理对象：课题、学生、教师、论文、阶段材料、成绩、附件。
2. 流程范围（v1.0 已确认）：选题与开题、中期检查、评阅与答辩；**不含查重模块**，状态机预留扩展点。
3. 数据规模：单届 ≤ 2000 学生、≤ 500 教师，MySQL 单机足够。
4. 不开放自助注册，账号由管理员批量导入或手动创建。
5. 系统配置（评分权重、各阶段截止时间）存 `sys_config`，改配置不改代码。

---

## 三、角色权限矩阵

| 能力 | 学生 | 指导教师 | 评阅教师 | 管理员 |
| --- | :-: | :-: | :-: | :-: |
| 浏览 / 申报课题 | ✅ | 出题 | — | ✅ 全量 |
| 审核选题申请 | — | ✅ 自己的课题 | — | ✅ 调配 |
| 提交 / 审核开题报告 | 提交 | ✅ 审核 | — | 查看 |
| 提交 / 检查中期报告 | 提交 | ✅ 检查 | — | 查看 |
| 提交论文定稿 | ✅ | — | — | 查看 |
| 指派评阅 | — | — | — | ✅ |
| 评阅打分 | — | — | ✅ | 查看 |
| 答辩分组 / 成绩录入 | 查看 | 查看 | ✅ 录入 | ✅ 建组 |
| 用户 / 班级 / 届别管理 | — | — | — | ✅ |
| 数据看板 | 个人进度 | 指导学生 | 评阅任务 | 全院统计 |
| 系统配置 | — | — | — | ✅ |

---

## 四、功能模块清单

### M1 · 登录认证
- 登录页（账号 + 密码，记住我）；密码 BCrypt 加盐
- JWT 签发与刷新，登出加入黑名单
- 前端路由守卫 + 后端接口鉴权；越权返回 403
- 个人中心：改密码、查看资料
- **批量导入**：Excel 模板下载 → 上传 → 校验（学号/工号重复、必填缺失）→ 预览 → 确认导入 → 失败行可下载

### M2 · 数据看板
- **管理员**：学生/教师/论文总数、完成率、各阶段分布漏斗、超期预警数、成绩分布柱图、近 30 天提交趋势、待办卡片（待审开题/中期/评阅/答辩）
- **指导教师**：指导学生数、待审清单、进度环形图
- **评阅教师**：待评阅数、已评阅数、平均分
- **学生**：我的进度时间轴、下一待办、截止提醒
- ECharts 图表容器随断点自适应

### M3 · 列表管理
覆盖：用户、学生、教师、课题、选题申请、论文、答辩分组、附件、操作日志
- 关键字搜索 + 多条件筛选（届别 / 学院 / 专业 / 状态 / 教师）
- 排序、分页、列显隐、密度切换
- 批量审核 / 批量指派 / 批量导出
- 导出 Excel（EasyExcel）

### M4 · 表单编辑
- 抽屉（大表单）/ 弹窗（小表单）两种形态
- 统一校验、字段级错误提示、未保存离开拦截
- 长文本（研究内容、审核意见）用轻量 Markdown 编辑
- 附件上传：多文件、进度条、类型/大小校验、可预览可删除

### M5 · 论文审查过程（核心）
- **状态机引擎**：流转规则集中在 `ThesisStatus` 枚举与 `FlowGuard`，非法流转直接拒绝并给出原因
- **选题**：教师发布课题（含容量上限）→ 学生申报 → 教师录取/驳回 → 管理员调配
- **开题**：学生提交开题报告（正文 + 附件）→ 导师审核（通过 / 修改后重交 / 不通过 + 意见）
- **中期**：提交中期报告 + 进度百分比 → 导师检查 → 超期未提交进预警名单
- **定稿**：上传定稿 PDF/Word，支持多版本
- **评阅**：管理员指派评阅教师（可设盲审）→ 按评分项打分 + 评语
- **答辩**：建答辩组（成员/时间/地点）→ 学生入组 → 录入答辩成绩 → 按权重算总评
- **归档**：材料齐备后归档，状态置 `ARCHIVED`
- **留痕**：`audit_log` 记录 谁 / 何时 / 对哪条记录 / 做了什么；详情页时间轴展示
- **通知**：状态变更生成站内消息（不做邮件短信）

### M6 · 文件云端存储
- `StorageService` 抽象，双驱动：`cloud`（WorkBuddy 云端存储）/ `local`（`uploads/` 目录）
- 默认 `cloud`，配置项 `thesis.storage.driver` 切换
- 前端直传：拿到云端 URL 后回调后端登记 `attachment` 记录
- 校验：允许 `pdf/doc/docx/zip/jpg/png`，单文件 ≤ 20MB
- 数据库只存 URL + 元信息，不存二进制

### M7 · 响应式布局
- 断点：`xs<768`（手机）`sm 768~992` `md 992~1200` `lg>1200`
- `≥992px`：左侧固定菜单 + 顶栏 + 内容区
- `<992px`：菜单折叠为抽屉
- 表格在 `<768px` 自动切卡片流
- 表单单列/双列随断点切换，手机端抽屉全屏

---

## 五、数据库设计（MySQL 8.0）

库名 `thesis_mgmt`，字符集 `utf8mb4`，排序规则 `utf8mb4_0900_ai_ci`，引擎 InnoDB。
建表脚本见 **`sql/01_schema.sql`**，演示数据见 **`sql/02_demo_data.sql`**。

| 表 | 说明 | 关键字段 |
| --- | --- | --- |
| `sys_user` | 账号 | username / password / real_name / role / status |
| `student` | 学生档案 | user_id / student_no / grade / college / major / class_name / advisor_id |
| `teacher` | 教师档案 | user_id / teacher_no / title / college / max_quota / can_review |
| `topic` | 课题 | title / type / teacher_id / capacity / selected_count / status / grade |
| `selection` | 选题申请 | topic_id / student_id / status / remark / teacher_comment |
| `thesis` | 论文主表 | student_id / topic_id / advisor_id / status / grade |
| `proposal` | 开题报告 | thesis_id / content / review_status / review_comment / score |
| `midterm_report` | 中期报告 | thesis_id / progress_percent / review_status / score |
| `final_submission` | 定稿 | thesis_id / file_url / version |
| `review` | 评阅 | thesis_id / reviewer_id / score / comment / status |
| `defense_group` | 答辩组 | name / grade / defense_date / location |
| `defense_group_member` | 答辩组成员 | group_id / teacher_id / role_in_group |
| `defense_record` | 答辩成绩 | thesis_id / group_id / score / result / comment |
| `thesis_score` | 总评 | proposal_score / midterm_score / review_score / defense_score / total_score |
| `attachment` | 附件 | biz_type / biz_id / file_name / file_url / file_size / storage_driver |
| `audit_log` | 操作留痕 | actor_id / action / target_type / target_id / detail |
| `notification` | 站内消息 | user_id / title / content / link / is_read |
| `sys_config` | 系统配置 | config_key / config_value / remark |

**索引**：`thesis(status, grade)`、`thesis(advisor_id)`、`selection(topic_id, status)`、`attachment(biz_type, biz_id)`、`audit_log(target_type, target_id)`、`review(reviewer_id, status)`。

---

## 六、论文状态机

```
DRAFT                 （已录取选题，待提交开题）
  ↓ 提交开题
PROPOSAL_SUBMITTED ──导师审核──┬→ PROPOSAL_APPROVED
                               └→ PROPOSAL_REJECTED → 回到 DRAFT
PROPOSAL_APPROVED
  ↓ 提交中期
MIDTERM_SUBMITTED ──导师检查──┬→ MIDTERM_PASSED
                              └→ MIDTERM_REJECTED → 回到 PROPOSAL_APPROVED
MIDTERM_PASSED
  ↓ 提交定稿
FINAL_SUBMITTED
  ↓ 指派评阅
REVIEWING ──专家评阅──┬→ REVIEW_PASSED
                      └→ REVIEW_FAILED → 回到 FINAL_SUBMITTED
REVIEW_PASSED
  ↓ 编入答辩组
DEFENSE_SCHEDULED
  ↓ 录入成绩
DEFENSE_DONE
  ↓ 归档
ARCHIVED
```

规则集中在 `domain.ThesisStatus`（枚举 + 允许的下一状态 + 允许操作的角色），所有变更经 `FlowGuard.canTransition()` 校验并写 `audit_log`。

---

## 七、工程结构

```
thesis-management/
├── docs/                     # 计划文档、API、部署说明
├── sql/
│   ├── 01_schema.sql         # 建表 DDL
│   └── 02_demo_data.sql      # 演示数据（可独立导入）
├── backend/                  # Spring Boot 3
│   └── src/main/java/com/example/thesis/
│       ├── ThesisApplication.java
│       ├── common/           # R 统一响应、异常、分页、常量
│       ├── config/           # Security / MyBatisPlus / Cors / WebMvc / Storage
│       ├── security/         # JwtFilter、UserDetails、权限处理
│       ├── domain/           # 状态机 ThesisStatus、评分规则 ScoreRule（纯逻辑，可单测）
│       ├── entity/           # 与表一一对应
│       ├── mapper/           # MyBatis Plus Mapper + XML（复杂联表）
│       ├── service/          # 业务层
│       ├── controller/       # REST 接口
│       └── storage/          # StorageService（cloud / local）
│   └── src/main/resources/
│       ├── application.yml
│       └── mapper/*.xml
├── web/                      # Vue3 前端
│   └── src/{api,router,stores,layouts,components,views,composables,styles}
├── scripts/                  # 备份、导入模板生成
├── .gitignore
└── README.md
```

**关键依赖**
- 后端：`spring-boot-starter-web` `spring-boot-starter-security` `mybatis-plus-spring-boot3-starter` `mysql-connector-j` `jjwt` `easyexcel` `lombok` `spring-boot-starter-validation`
- 前端：`vue@3` `typescript` `vite` `element-plus` `pinia` `vue-router@4` `axios` `echarts` `vue-echarts` `dayjs` `xlsx`
- 工程：ESLint / Prettier、JUnit5 + Mockito（domain 层单测）

---

## 八、API 设计（前缀 `/api`）

| 分组 | 方法与路径 |
| --- | --- |
| 认证 | `POST /auth/login` `POST /auth/logout` `GET /auth/me` `PUT /auth/password` |
| 用户 | `GET/POST /users` `GET/PUT/DELETE /users/:id` `POST /users/import` `GET /users/template` |
| 教师/学生 | `GET/POST /teachers` `GET/PUT /teachers/:id` `GET/POST /students` `GET/PUT /students/:id` |
| 课题 | `GET/POST /topics` `GET/PUT/DELETE /topics/:id` `POST /topics/:id/publish` |
| 选题 | `POST /selections` `GET /selections` `POST /selections/:id/approve\|reject` |
| 论文 | `GET /theses` `GET /theses/:id` `POST /theses/:id/transition` `GET /theses/:id/timeline` |
| 开题 | `POST /proposals` `POST /proposals/:id/review` |
| 中期 | `POST /midterm` `POST /midterm/:id/review` `GET /midterm/alerts` |
| 定稿 | `POST /final-submissions` `GET /final-submissions/:thesisId` |
| 评阅 | `POST /reviews/assign` `GET /reviews/mine` `POST /reviews/:id/submit` |
| 答辩 | `GET/POST /defense-groups` `POST /defense-groups/:id/members` `POST /defense-records` |
| 成绩 | `GET /scores/:thesisId` `POST /scores/:thesisId/recompute` |
| 文件 | `POST /files/register` `GET /files` `DELETE /files/:id` |
| 看板 | `GET /dashboard/stats` `GET /dashboard/stage-distribution` `GET /dashboard/todos` |
| 配置 | `GET/PUT /configs` |

统一响应：`{ "code": 0, "data": ..., "message": "ok" }`；业务异常走 `@RestControllerAdvice`，HTTP 401/403/404/500 统一封装。

---

## 九、开发里程碑（每个里程碑一个分支 + 提交）

| # | 里程碑 | 主要交付 |
| --- | --- | --- |
| M0 | 工程初始化 | git 分支规范、Maven 工程、Vite 工程、README、`.gitignore`、一键启动脚本 |
| M1 | 数据库就绪 | 执行 `01_schema.sql`；Entity/Mapper；MyBatis Plus 分页与逻辑删除配置 |
| M2 | 认证与骨架 | Spring Security + JWT、登录接口/页面、路由守卫、主布局、权限指令、批量导入 |
| M3 | 基础 CRUD | 用户 / 学生 / 教师 / 班级管理列表与表单 |
| M4 | 选题与开题 | 课题发布、选题申请与审核、开题提交与审核 |
| M5 | 中期检查 | 中期报告提交、检查、超期预警 |
| M6 | 定稿 + 评阅 + 答辩 | 定稿上传、评阅指派与打分、答辩分组、成绩录入与总评 |
| M7 | 数据看板 | 四类角色看板、ECharts、待办卡片 |
| M8 | 云端文件存储 | StorageService 双驱动、上传组件、附件管理 |
| M9 | 响应式与体验 | 断点适配、表格转卡片、空状态/加载态 |
| M10 | 测试与文档 | domain 单测、冒烟自测、API 文档、部署说明 |

**Git 规范**：主干 `main`，开发分支 `feat/xxx`、`fix/xxx`；Conventional Commits（`feat:` `fix:` `docs:` `refactor:` `test:` `chore:`）；里程碑结束合并回 `main` 并打标签 `v0.1`…`v1.0`。`.gitignore` 排除 `target/`、`node_modules/`、`uploads/`、`.env*`、`*.log`。

---

## 十、演示数据 SQL 说明

文件：`sql/01_schema.sql`（建表）、`sql/02_demo_data.sql`（数据），由你本地执行导入，我这边不连数据库。

导入顺序：
```bash
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS thesis_mgmt DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci;"
mysql -u root -p thesis_mgmt < sql/01_schema.sql
mysql -u root -p thesis_mgmt < sql/02_demo_data.sql
```

数据规模与分布（详见 SQL 文件头注释）：

| 项目 | 数量 |
| --- | --- |
| 管理员 | 1 |
| 指导教师 | 18 |
| 评阅教师 | 6 |
| 学生 | 55（2026 届 12 / 2027 届 43） |
| 课题 | 60（已选 50 / 开放 10） |
| 选题申请 | 55（通过 50 / 待审 3 / 驳回 2） |
| 论文 | 50，覆盖 11 种状态全部取值 |
| 答辩组 | 3 |
| 开题报告 / 中期报告 / 定稿 | 47 / 37 / 27 |
| 评阅 / 答辩组 / 答辩成绩 | 22 / 3 / 12 |
| 附件 / 操作日志 / 站内消息 | 111 / 341 / 70 |

**演示账号**（学生与教师密码统一 `123456`，管理员 `admin123`）。

| 角色 | 账号 | 说明 |
| --- | --- | --- |
| 管理员 | `admin` | 全部权限 |
| 指导教师 | `t2001` ~ `t2018` | 每人 2~3 名指导学生 |
| 评阅教师 | `r3001` ~ `r3006` | 各有待评阅/已评阅任务 |
| 学生 | `s20260001` … `s20270043` | 2026 届已走完全流程，2027 届覆盖进行中各阶段 |

生成与校验脚本：
```bash
python scripts/gen_demo_sql.py   # 重新生成（固定随机种子，结果可复现）
python scripts/check_sql.py      # 自检：语法 / 唯一键 / 引用完整性 / 状态分布
```
已通过自检：80 个账号的 BCrypt 哈希逐一验证可登录，10 组唯一键无冲突，25 组外键引用无悬空。

---

## 十一、风险与待确认事项

1. **云端存储 Origin 校验**：WorkBuddy 云端存储按应用发布域名做同源校验，`localhost` 直连可能被拒 → 保留 `local` 驱动作开发期与降级方案，配置项 `thesis.storage.driver` 一键切换，上线前切回 `cloud` 并验证。
2. **MySQL 连接参数**：`application.yml` 中库名/账号/密码留占位符，你本地填；默认 `jdbc:mysql://localhost:3306/thesis_mgmt?useUnicode=true&characterEncoding=utf8mb4&serverTimezone=Asia/Shanghai`。
3. **查重模块未纳入**：`FINAL_SUBMITTED` 前预留扩展点，后续可插入 `PLAGIARISM_CHECK` 状态而不动主流程。
4. **批量导入并发**：导入 2000 行用批处理 + 事务，失败行回滚并导出错误报告，不做部分提交。
5. **评分权重**：默认 开题 20 / 中期 20 / 评阅 30 / 答辩 30，存 `sys_config`，可在线改。
6. **待确认**：① 学院/专业/班级是否需要独立字典表（当前按字符串冗余存，够用但无法级联管理）；② 是否需要「专业负责人」这一中间审批角色；③ 演示数据规模是否合适。

---

## 十二、验收标准

- [ ] 四类角色均能登录，越权访问被拦截（前端菜单 + 后端接口双重）
- [ ] 完整跑通：教师出题 → 学生选题 → 导师录取 → 开题审核 → 中期检查 → 定稿 → 评阅 → 答辩 → 归档
- [ ] 非法状态流转被拒绝并提示原因
- [ ] 每步操作在详情页时间轴可见
- [ ] 附件能上传 / 下载预览 / 删除，DB 只存 URL
- [ ] 看板数据在演示数据下正确，图表随窗口自适应
- [ ] 1440 / 1024 / 768 / 375 四种宽度下无横向滚动、可操作
- [ ] 批量导入可导入 Excel 并给出失败行报告
- [ ] `mvn spring-boot:run` + `npm run dev` 一键启动；`npm run build` 产出可部署包
- [ ] git 历史清晰，每个里程碑可追溯

---

## 十三、审核确认

请确认：
1. 第五节表结构与第六节状态机是否符合你们院系的实际流程
2. 里程碑划分与优先级是否 OK
3. 第十一节三个待确认项

**回复「同意」即按本文档进入编码**；有调整请直接指出条目编号。
