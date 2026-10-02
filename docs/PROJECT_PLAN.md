# 毕业论文管理系统 · 项目计划文档

> 版本：v1.0（待审核）
> 日期：2026-10-02
> 状态：**待确认** —— 确认后进入编码阶段

---

## 一、项目目标

面向高校院系的毕业论文（设计）全过程管理系统：把「选题 → 开题 → 中期检查 → 定稿 → 评阅 → 答辩 → 归档」这条主线从线下表格/微信群里搬到系统上，做到**流程可追溯、材料可留存、进度可视化**。

核心诉求（用户原始要求）对应关系：

| 要求 | 落地方案 |
| --- | --- |
| 登录认证 | 账号密码 + JWT，角色路由守卫 + 按钮级权限 |
| 数据看板 | 首页 Dashboard，按角色展示不同指标与图表 |
| 列表管理 | 统一表格页：筛选 / 搜索 / 排序 / 分页 / 批量操作 / 导出 |
| 表单编辑 | 弹窗 / 抽屉表单，校验、草稿、附件上传 |
| 论文审查过程功能 | 状态机驱动的流转引擎 + 各阶段审核表单 + 操作留痕 |
| 数据使用本地数据库 | SQLite（better-sqlite3），文件落盘 `data/thesis.db` |
| 文件使用云端存储 | WorkBuddy 云端存储（前端直传），DB 只存 URL；含本地磁盘驱动回退 |
| 响应式布局 | Element Plus 栅格 + 断点适配，支持桌面 / 平板 / 手机 |

---

## 二、已确认的选型与假设

### 2.1 已确认（用户选择）

- **技术栈**：Vue 3 + TypeScript + Vite + Element Plus（前端）｜ Node.js + Express + TypeScript（后端）
- **流程范围**：选题与开题、中期检查、评阅与答辩
- **不含**：查重 / 学术不端检测模块（本次明确排除，后续可作为插件追加）

### 2.2 我做的假设（如与预期不符请在审核时指出）

1. 需求中的「【管理内容】」未填写，我按**毕业论文（设计）全流程**理解，管理对象包括：课题、学生、教师、论文、各阶段材料、成绩。
2. 角色设计为四类：**学生、指导教师、评阅专家、院系管理员**（评阅专家由管理员从教师库指派，不单独建账号表）。
3. 数据规模假设：单届 ≤ 2000 名学生、≤ 500 名教师。SQLite 在此规模下单机完全够用。
4. 不内置账号自助注册；账号由管理员导入或手动创建（避免任意注册风险）。
5. 语言与时区：中文界面，`Asia/Shanghai`。

---

## 三、角色与权限矩阵

| 能力 | 学生 | 指导教师 | 评阅专家 | 院系管理员 |
| --- | :-: | :-: | :-: | :-: |
| 浏览 / 申请课题 | ✅ | 出课题 | — | ✅ 全量 |
| 审核选题申请 | — | ✅（自己的课题） | — | ✅ |
| 提交开题报告 | ✅ | — | — | — |
| 审核开题报告 | — | ✅（自己的学生） | — | ✅ 查看 |
| 提交中期报告 | ✅ | — | — | — |
| 中期检查 | — | ✅ | — | ✅ |
| 提交论文定稿 | ✅ | — | — | — |
| 评阅打分 | — | — | ✅ | ✅ 指派 |
| 答辩分组 / 成绩录入 | — | 查看 | ✅ | ✅ |
| 用户 / 班级 / 届别管理 | — | — | — | ✅ |
| 数据看板 | 个人进度 | 指导学生 | 评阅任务 | 全院统计 |
| 系统配置（时间节点等） | — | — | — | ✅ |

---

## 四、功能模块清单

### M1 · 登录认证
- 登录页（账号 + 密码，记住我，图形验证码预留开关）
- JWT 签发与刷新；密码 `bcrypt` 加盐哈希
- 路由守卫：未登录跳登录页；越权跳 403
- 按钮级权限指令 `v-permission`
- 个人中心：改密码、查看个人信息

### M2 · 数据看板（Dashboard）
- **管理员**：学生数 / 教师数 / 论文总数 / 完成率；各阶段分布漏斗图；各阶段超期预警数；成绩分布柱状图；近 30 天提交量折线图；待办事项卡片（待审开题 N、待评阅 N、待答辩 N）
- **教师**：我指导的学生数、待我审核清单、进度分布环形图
- **学生**：我的论文进度时间轴、下一待办、 deadlines 提醒
- 技术：ECharts（vue-echarts），图表容器随断点自适应

### M3 · 列表管理
统一列表页能力，覆盖 8 个实体：用户、学生、教师、课题、选题申请、论文、答辩分组、附件
- 关键字搜索 + 多条件筛选（届别 / 专业 / 状态 / 教师）
- 排序、分页、列显隐、密度切换
- 批量操作：批量审核、批量导出、批量指派
- 导出 CSV / Excel（前端 `xlsx` 生成，不依赖后端）

### M4 · 表单编辑
- 抽屉（大表单）/ 弹窗（小表单）两种形态
- 统一校验规则、字段级错误提示、未保存离开拦截
- 富文本字段（研究内容、教师意见）用轻量 Markdown 编辑器
- 附件上传：多文件、进度条、类型/大小校验、可预览可删除

### M5 · 论文审查过程（核心）
- **状态机引擎**：`thesis_status` 集中定义流转规则，非法流转直接拒绝并给出原因
- **选题阶段**：教师发布课题（含容量上限）→ 学生申报 → 教师择优录取 → 管理员可强制调配
- **开题阶段**：学生提交开题报告（正文 + 附件）→ 导师审核（通过 / 修改后重交 / 不通过 + 意见）
- **中期阶段**：学生提交中期报告 + 进度百分比 → 导师检查 → 超期未提交自动进入预警名单
- **定稿阶段**：学生上传定稿 PDF/Word
- **评阅阶段**：管理员指派评阅专家（可设盲审开关）→ 专家按评分项打分 + 评语
- **答辩阶段**：建答辩组（成员 / 时间 / 地点）→ 学生入组 → 录入答辩成绩 → 计算总评（开题 20% + 中期 20% + 评阅 30% + 答辩 30%，权重可配置）
- **归档**：定稿 + 全部材料打包记录，状态置为已归档
- **全流程留痕**：`audit_logs` 记录谁在什么时候对哪条记录做了什么；详情页展示时间轴
- **消息通知**：状态变更时生成站内消息（不做邮件/短信，避免过度设计）

### M6 · 文件云端存储
- 抽象 `storageService`，两个驱动：`cloud`（WorkBuddy 云端存储）/ `local`（`uploads/` 目录）
- 默认 `cloud`，通过环境变量 `STORAGE_DRIVER` 切换
- 前端直传：浏览器拿到云端 URL 后回调后端登记 `attachments` 记录
- 校验：允许 `pdf/doc/docx/zip/jpg/png`，单文件 ≤ 20MB
- 数据库只存 `file_url` + 元信息，不存二进制

### M7 · 响应式布局
- 断点：`xs < 768`（手机）`sm 768~992`（平板竖）`md 992~1200` `lg > 1200`
- `≥992px`：左侧固定菜单 + 顶部栏 + 内容区
- `<992px`：菜单折叠为抽屉，顶部汉堡按钮唤出
- 表格在 `<768px` 自动切换为卡片流（每行一张卡）
- 表单：单列 / 双列随断点切换；抽屉在手机端全屏

---

## 五、数据模型（SQLite）

```
users(id, username, password_hash, real_name, role, college, major, title,
      phone, email, status, last_login_at, created_at, updated_at)
students(id, user_id→users, student_no UK, grade, class_name, major, college, advisor_id→teachers)
teachers(id, user_id→users, teacher_no UK, title, college, max_quota, is_reviewer)
topics(id, title, type, source, description, requirement, teacher_id→teachers,
       capacity, selected_count, status, grade, created_at)
selections(id, topic_id, student_id, status, student_remark, teacher_comment, applied_at, handled_at)
theses(id, student_id UK, topic_id, advisor_id, title, status, current_stage,
       grade, created_at, updated_at)
proposals(id, thesis_id, content, attachment_ids, submit_at,
          review_status, review_comment, review_at, reviewer_id)
midterm_reports(id, thesis_id, progress_percent, content, attachment_ids,
                submit_at, review_status, review_comment, review_at)
final_submissions(id, thesis_id, file_url, version, submit_at, note)
reviews(id, thesis_id, reviewer_id, assigned_by, score, comment, status, submitted_at)
defense_groups(id, name, grade, defense_date, location, secretary_id, members_json, status)
defense_records(id, thesis_id, group_id, score, result, comment, recorded_by, recorded_at)
thesis_scores(id, thesis_id UK, proposal_score, midterm_score, review_score,
              defense_score, total_score, computed_at)
attachments(id, biz_type, biz_id, file_name, file_url, file_size, mime_type,
            uploader_id, storage_driver, created_at)
audit_logs(id, actor_id, action, target_type, target_id, detail_json, created_at)
notifications(id, user_id, title, content, link, is_read, created_at)
system_configs(key PK, value, description, updated_at)
```

**索引**：`theses(status)`、`theses(advisor_id)`、`selections(topic_id,status)`、`attachments(biz_type,biz_id)`、`audit_logs(target_type,target_id)`。

---

## 六、论文状态机

```
DRAFT                （已选题，待提交开题）
  ↓ 提交
PROPOSAL_SUBMITTED   ──导师审核──┬→ PROPOSAL_APPROVED
                                 └→ PROPOSAL_REJECTED → 回到 DRAFT
PROPOSAL_APPROVED
  ↓ 提交中期
MIDTERM_SUBMITTED    ──导师检查──┬→ MIDTERM_PASSED
                                 └→ MIDTERM_REJECTED → 回到 PROPOSAL_APPROVED
MIDTERM_PASSED
  ↓ 提交定稿
FINAL_SUBMITTED
  ↓ 指派评阅
REVIEWING            ──专家评阅──→ REVIEW_PASSED / REVIEW_FAILED(→FINAL_SUBMITTED)
REVIEW_PASSED
  ↓ 编入答辩组
DEFENSE_SCHEDULED
  ↓ 录入成绩
DEFENSE_DONE
  ↓ 归档
ARCHIVED
```

规则集中写在 `server/src/domain/thesisFlow.ts`，任何状态变更必须经过 `canTransition(from, to, role)` 校验 + 写 `audit_logs`。

---

## 七、技术架构与目录结构

```
thesis-management/
├── docs/                          # 文档（本文件、API、部署）
├── server/                        # 后端
│   ├── src/
│   │   ├── index.ts               # 入口
│   │   ├── app.ts                 # Express 装配
│   │   ├── config/                # 环境变量、常量
│   │   ├── db/                    # better-sqlite3 连接 + migrations + seeds
│   │   ├── domain/                # 状态机、评分规则、业务校验（纯函数，可单测）
│   │   ├── middleware/            # auth、rbac、validate、errorHandler
│   │   ├── modules/               # auth/users/topics/selections/theses/
│   │   │                          # proposals/midterm/reviews/defense/dashboard/files
│   │   └── utils/
│   ├── data/thesis.db             # SQLite 数据文件（gitignore）
│   └── package.json
├── web/                           # 前端
│   ├── src/
│   │   ├── api/                   # axios 封装 + 各模块请求
│   │   ├── router/                # 路由 + 守卫
│   │   ├── stores/                # Pinia（user / app / dict）
│   │   ├── layouts/               # 主框架（侧边栏/顶栏/面包屑/响应式）
│   │   ├── components/            # 通用组件：ProTable / FormDrawer / Uploader /
│   │   │                          # StatusTag / TimelineCard / StatCard
│   │   ├── views/                 # login / dashboard / topic / proposal /
│   │   │                          # midterm / review / defense / user / profile
│   │   ├── composables/           # useResponsive / useTable / usePermission
│   │   └── styles/                # 变量、断点、暗色预留
│   └── package.json
├── scripts/                       # 初始化、种子数据、备份
├── .gitignore
└── README.md
```

**关键依赖**
- 前端：`vue@3` `typescript` `vite` `element-plus` `pinia` `vue-router@4` `axios` `echarts` `vue-echarts` `dayjs`
- 后端：`express@4` `better-sqlite3` `bcryptjs` `jsonwebtoken` `zod`（入参校验）`multer`（本地驱动上传）`cors` `helmet`
- 工程：`eslint` `prettier` `vitest`（domain 层单测）`concurrently`（一键起前后端）

---

## 八、API 设计（REST，前缀 `/api`）

| 分组 | 方法与路径 |
| --- | --- |
| 认证 | `POST /auth/login` `POST /auth/logout` `GET /auth/me` `PUT /auth/password` |
| 用户 | `GET/POST /users` `GET/PUT/DELETE /users/:id` `POST /users/import` |
| 课题 | `GET/POST /topics` `GET/PUT/DELETE /topics/:id` `POST /topics/:id/publish` |
| 选题 | `POST /selections` `GET /selections` `POST /selections/:id/approve\|reject` |
| 论文 | `GET /theses` `GET /theses/:id` `POST /theses/:id/transition` `GET /theses/:id/timeline` |
| 开题 | `POST /proposals` `POST /proposals/:id/review` |
| 中期 | `POST /midterm` `POST /midterm/:id/review` `GET /midterm/alerts` |
| 定稿 | `POST /final-submissions` `GET /final-submissions/:thesisId` |
| 评阅 | `POST /reviews/assign` `GET /reviews/mine` `POST /reviews/:id/submit` |
| 答辩 | `GET/POST /defense-groups` `POST /defense-groups/:id/members` `POST /defense-records` |
| 成绩 | `GET /scores/:thesisId` `POST /scores/:thesisId/recompute` |
| 文件 | `POST /files/register` `GET /files?bizType=&bizId=` `DELETE /files/:id` |
| 看板 | `GET /dashboard/stats` `GET /dashboard/stage-distribution` `GET /dashboard/todos` |
| 配置 | `GET/PUT /configs` |

统一响应体：`{ code: 0, data, message }`，非 0 为业务错误；HTTP 401/403/404/500 走统一错误中间件。

---

## 九、开发里程碑（每个里程碑一个 commit / 分支）

| # | 里程碑 | 主要交付 | 预估 |
| --- | --- | --- | --- |
| M0 | 工程初始化 | git 仓库、目录骨架、依赖安装、ESLint/Prettier、README、`.gitignore`、一键启动脚本 | 小 |
| M1 | 数据库与种子数据 | 建表 migration、索引、演示账号/数据的 seed 脚本 | 小 |
| M2 | 认证与骨架 | 登录接口/页面、JWT、路由守卫、主布局、权限指令 | 中 |
| M3 | 基础 CRUD | 用户 / 学生 / 教师 / 班级管理列表与表单 | 中 |
| M4 | 选题与开题 | 课题发布、选题申请与审核、开题提交与审核 | 中 |
| M5 | 中期检查 | 中期报告提交、检查、超期预警 | 中 |
| M6 | 定稿 + 评阅 + 答辩 | 定稿上传、评阅指派与打分、答辩分组、成绩录入与总评 | 大 |
| M7 | 数据看板 | 三类角色看板、ECharts 图表、待办卡片 | 中 |
| M8 | 云端文件存储 | storageService 双驱动、上传组件、附件管理页 | 中 |
| M9 | 响应式与体验 | 断点适配、表格转卡片、抽屉全屏、空状态/加载态 | 中 |
| M10 | 测试与文档 | domain 层单测、冒烟自测、API 文档、部署说明 | 小 |

**Git 规范**：主干 `main`；开发分支 `feat/xxx`、`fix/xxx`；提交信息用 Conventional Commits（`feat:` `fix:` `docs:` `refactor:` `test:` `chore:`）；每个里程碑结束合并回 `main` 并打轻量标签 `v0.1`…`v1.0`。`.gitignore` 排除 `node_modules`、`data/*.db`、`uploads/`、`.env*`、日志。

---

## 十、风险与待确认事项

1. **云端存储的 Origin 校验**：WorkBuddy 云端存储依赖应用发布域名做同源校验，本地 `localhost` 直连可能被拒。因此保留 `local` 驱动作为开发期与降级方案，`STORAGE_DRIVER=local` 一键切换。上线前再切回 `cloud` 并验证。
2. **SQLite 并发写入**：单写者模型，高并发写入会 `SQLITE_BUSY`。本系统写操作分散且低频，风险低；已开启 WAL 模式缓解。若未来需要多人同时批量导入，再评估迁移 PostgreSQL。
3. **查重模块未纳入**：本次不含，但状态机已预留 `FINAL_SUBMITTED` 前的扩展点，后续可插入 `PLAGIARISM_CHECK` 状态而不改动主流程。
4. **评分权重**：默认 开题 20 / 中期 20 / 评阅 30 / 答辩 30，写进 `system_configs`，院系可自行调整，不必改代码。
5. **数据备份**：SQLite 是单文件，提供 `scripts/backup.ts` 定期复制到 `backups/`，后续可接云端存储做异地备份。
6. **待确认**：初始账号是管理员手动建还是批量导入？演示数据（seed）是否需要我造 50 名学生 + 20 名教师的样例？

---

## 十一、验收标准

- [ ] 四类角色均能登录，越权访问被拦截
- [ ] 完整跑通一条链路：教师出题 → 学生选题 → 导师录取 → 开题审核 → 中期检查 → 定稿 → 评阅 → 答辩 → 归档
- [ ] 非法状态流转被拒绝并提示原因
- [ ] 每一步操作在详情页时间轴可见
- [ ] 附件能上传、能下载/预览、能删除，DB 中只存 URL
- [ ] 看板数据在真实数据下正确，图表随窗口缩放自适应
- [ ] 1440 / 1024 / 768 / 375 四种宽度下无横向滚动、无错位、可操作
- [ ] `npm run dev` 一键启动前后端；`npm run build` 产出可部署静态包
- [ ] git 历史清晰，每个里程碑可追溯

---

## 十二、审核确认

请确认以下三点后我开始编码：

1. 功能范围与角色权限是否符合预期（第二节的假设尤其需要过一眼）
2. 里程碑划分与优先级是否 OK，有无需要提前/砍掉的模块
3. 第十节「待确认」的两个问题（初始账号方式、是否造演示数据）

**回复「同意」即视为按本文档执行**；如有调整请直接指出条目编号。
