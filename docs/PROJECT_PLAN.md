# 毕业论文管理系统 · 项目计划文档

> 版本：v3.0（定稿版 · 编码依据）
> 日期：2026-10-02
> 状态：**已确认，进入编码**
> 变更记录：
> - v1.0 初版：Node/Express + SQLite
> - v2.0：改为 Spring Boot 3 + MyBatis Plus + MySQL 8.0，四类角色，初始账号批量导入
> - v3.0：**取消云端存储改用本地静态目录**；MySQL 连接参数使用占位符；**新增学院/专业/班级独立字典表与统一字典管理**；移除「专业负责人」角色；目录结构调整为 **frontend / backend / database 三目录分离**

---

## 一、项目目标

面向高校院系的毕业论文（设计）全过程管理系统：把「选题 → 开题 → 中期检查 → 定稿 → 评阅 → 答辩 → 归档」这条主线从线下表格和微信群搬到系统上，做到**流程可追溯、材料可留存、进度可视化**。

用户要求与落地方案对照：

| 要求 | 落地方案 |
| --- | --- |
| 登录认证 | 账号密码 + Spring Security + JWT，角色路由守卫 + 接口级鉴权 |
| 数据看板 | 首页 Dashboard，按角色展示不同指标与图表（ECharts） |
| 列表管理 | 统一表格页：筛选 / 搜索 / 排序 / 分页 / 批量操作 / 导出 |
| 表单编辑 | 抽屉 / 弹窗表单，校验、草稿、附件上传 |
| 论文审查过程功能 | 状态机驱动的流转引擎 + 各阶段审核表单 + 操作留痕 |
| 数据使用本地数据库 | MySQL 8.0（本机或内网实例），库名 `thesis_mgmt` |
| 文件使用本地存储 | 后端本地静态目录 `backend/storage/uploads/{业务类型}/`，通过 `/uploads/**` 静态映射访问；数据库只存相对路径。`StorageService` 抽象保留，后续可无侵入接入云端 |
| 响应式布局 | Element Plus 栅格 + 断点适配，支持桌面 / 平板 / 手机 |
| 初始账号批量导入 | Excel 模板 + 后端导入接口；首次数据由演示 SQL 灌入 |
| 统一字典管理 | 独立 `sys_dict_type` + `sys_dict_item` 表，学院/专业/班级三级树，管理员可维护 |
| 目录分离 | 根目录下 `frontend/`（前端）、`backend/`（后端）、`database/`（数据库脚本）各司其职 |

---

## 二、技术选型

### 2.1 已确认

| 层 | 选型 |
| --- | --- |
| 前端 | Vue 3 + TypeScript + Vite + Element Plus + Pinia + Vue Router 4 |
| 图表 | ECharts + vue-echarts |
| 后端 | **Spring Boot 3.2（JDK 17 目标，本机 JDK 21 可编译运行）** |
| ORM | **MyBatis Plus 3.5** |
| 数据库 | **MySQL 8.0**（utf8mb4 / InnoDB） |
| 安全 | Spring Security 6 + JWT（jjwt）+ BCrypt |
| 文件存储 | **本地静态目录**（`backend/storage/uploads`），通过 `/uploads/**` 映射为静态资源 |
| 校验 | Jakarta Validation + 全局异常处理 |
| 构建 | Maven；前端 Vite |

### 2.2 角色定义（四类）

| 角色 | 编码 | 说明 |
| --- | --- | --- |
| 学生 | `STUDENT` | 选题、提交各阶段材料、查看本人进度与成绩 |
| 指导教师 | `ADVISOR` | 发布课题、录取选题、审核开题/中期、查看指导学生 |
| 评阅教师 | `REVIEWER` | 被指派后对论文定稿评阅打分 |
| 管理员 | `ADMIN` | 用户与基础数据管理、字典维护、指派评阅、答辩分组、流程监控、系统配置 |

> 已明确**不设「专业负责人」中间审批角色**：选题录取由指导教师完成，跨专业调配与最终审批归管理员。

### 2.3 假设与边界

1. 「【管理内容】」按**毕业论文（设计）全流程**理解，管理对象：课题、学生、教师、论文、阶段材料、成绩、附件、字典。
2. 流程范围（已确认）：选题与开题、中期检查、评阅与答辩；**不含查重模块**，状态机预留扩展点。
3. 数据规模：单届 ≤ 2000 学生、≤ 500 教师，MySQL 单机足够。
4. 不开放自助注册，账号由管理员批量导入或手动创建。
5. **字典与业务表的关系**：学院/专业/班级等可选项统一由 `sys_dict_item` 维护，业务表（学生、课题、论文）冗余存**名称**。这样历史数据不随字典调整而漂移，代价是改名不回溯——对毕业设计归档场景是更稳妥的取舍。
6. 系统配置（评分权重、各阶段截止时间）存 `sys_config`，改配置不改代码。

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
| **字典维护** | — | — | — | ✅ |
| 数据看板 | 个人进度 | 指导学生 | 评阅任务 | 全院统计 |
| 系统配置 | — | — | — | ✅ |

---

## 四、功能模块清单

### M1 · 登录认证
- 登录页（账号 + 密码，记住我）；密码 BCrypt 加盐
- JWT 签发，登出加入黑名单
- 前端路由守卫 + 后端接口鉴权；越权返回 403
- 个人中心：改密码、查看资料
- **批量导入**：Excel 模板下载 → 上传 → 校验（学号/工号重复、必填缺失、字典项存在性）→ 预览 → 确认导入 → 失败行可下载

### M2 · 数据看板
- **管理员**：学生/教师/论文总数、完成率、各阶段分布漏斗、超期预警数、成绩分布柱图、近 30 天提交趋势、待办卡片（待审开题/中期/评阅/答辩）
- **指导教师**：指导学生数、待审清单、进度环形图
- **评阅教师**：待评阅数、已评阅数、平均分
- **学生**：我的进度时间轴、下一待办、截止提醒
- ECharts 图表容器随断点自适应

### M3 · 列表管理
覆盖：用户、学生、教师、课题、选题申请、论文、答辩分组、附件、操作日志、字典
- 关键字搜索 + 多条件筛选（届别 / 学院 / 专业 / 状态 / 教师）
- 排序、分页、列显隐、密度切换
- 批量审核 / 批量指派 / 批量导出

### M4 · 表单编辑
- 抽屉（大表单）/ 弹窗（小表单）两种形态
- 统一校验、字段级错误提示、未保存离开拦截
- 长文本（研究内容、审核意见）用多行文本
- 附件上传：多文件、进度条、类型/大小校验、可预览可删除

### M5 · 论文审查过程（核心）
- **状态机引擎**：流转规则集中在 `ThesisStatus` 枚举与 `FlowGuard`，非法流转直接拒绝并给出原因
- **选题**：教师发布课题（含容量上限）→ 学生申报 → 教师录取/驳回 → 管理员调配
- **开题**：学生提交开题报告（正文 + 附件）→ 导师审核（通过 / 驳回 + 意见）
- **中期**：提交中期报告 + 进度百分比 → 导师检查 → 超期未提交进预警名单
- **定稿**：上传定稿 PDF/Word，支持多版本
- **评阅**：管理员指派评阅教师（可设盲审）→ 打分 + 评语
- **答辩**：建答辩组（成员/时间/地点）→ 学生入组 → 录入答辩成绩 → 按权重算总评
- **归档**：材料齐备后归档，状态置 `ARCHIVED`
- **留痕**：`audit_log` 记录 谁 / 何时 / 对哪条记录 / 做了什么；详情页时间轴展示
- **通知**：状态变更生成站内消息

### M6 · 本地文件存储
- `StorageService` 接口 + `LocalStorageService` 实现（云端实现类留扩展位，当前不启用）
- 落盘路径：`backend/storage/uploads/{bizType}/{yyyyMM}/{uuid}.{ext}`
- 访问路径：`/uploads/{bizType}/{yyyyMM}/{uuid}.{ext}`，由 `WebMvcConfig` 映射为静态资源
- 校验：允许 `pdf/doc/docx/zip/jpg/png`，单文件 ≤ 20MB；服务端重命名，不信任客户端文件名
- 数据库 `attachment.file_url` 存**相对路径**，`storage_driver` 固定为 `local`

### M7 · 响应式布局
- 断点：`xs<768`（手机）`sm 768~992` `md 992~1200` `lg>1200`
- `≥992px`：左侧固定菜单 + 顶栏 + 内容区
- `<992px`：菜单折叠为抽屉
- 表格在 `<768px` 自动切卡片流
- 表单单列/双列随断点切换，手机端抽屉全屏

---

## 五、数据库设计（MySQL 8.0）

库名 `thesis_mgmt`，字符集 `utf8mb4`，排序规则 `utf8mb4_0900_ai_ci`，引擎 InnoDB。
建表脚本 `database/01_schema.sql`，字典与演示数据 `database/02_demo_data.sql`。

### 5.1 基础字典（新增）

| 表 | 说明 | 关键字段 |
| --- | --- | --- |
| `sys_dict_type` | 字典类型 | `type_code`(UK) / `type_name` / `remark` |
| `sys_dict_item` | 字典项（支持树形） | `type_code` / `item_code` / `item_name` / `parent_id` / `sort_no` / `status` |

内置字典类型：

| type_code | 类型名 | 层级 | 示例 |
| --- | --- | --- | --- |
| `COLLEGE` | 学院 | 一级（parent_id 为空） | 计算机与人工智能学院 |
| `MAJOR` | 专业 | 二级（parent_id = 学院项 id） | 人工智能 |
| `CLASS` | 班级 | 三级（parent_id = 专业项 id） | 24计算机A班 |
| `GRADE` | 届别 | 一级 | 2026、2027 |
| `TOPIC_TYPE` | 课题类型 | 一级 | 理论研究 / 工程设计 / 软件开发 |
| `TOPIC_SOURCE` | 课题来源 | 一级 | 教师命题 / 企业真题 / 学生自拟 |
| `TITLE` | 教师职称 | 一级 | 教授 / 副教授 / 讲师 / 助教 |
| `DEFENSE_RESULT` | 答辩结论 | 一级 | 通过 / 暂缓 / 不通过 |

### 5.2 业务表

| 表 | 说明 | 关键字段 |
| --- | --- | --- |
| `sys_user` | 账号 | username / password / real_name / role / status |
| `student` | 学生档案 | user_id / student_no / grade / college / major / class_name / advisor_id |
| `teacher` | 教师档案 | user_id / teacher_no / title / college / max_quota / can_review |
| `topic` | 课题 | title / teacher_id / capacity / selected_count / status / grade |
| `selection` | 选题申请 | topic_id / student_id / status / remark / teacher_comment |
| `thesis` | 论文主表 | student_id / topic_id / advisor_id / status / grade |
| `proposal` | 开题报告 | thesis_id / content / review_status / review_comment / score |
| `midterm_report` | 中期报告 | thesis_id / progress_percent / review_status / score |
| `final_submission` | 定稿 | thesis_id / file_url / version |
| `review` | 评阅 | thesis_id / reviewer_id / score / comment / status |
| `defense_group` | 答辩组 | name / grade / defense_date / location |
| `defense_group_member` | 答辩组成员 | group_id / teacher_id / role_in_group |
| `defense_record` | 答辩成绩 | thesis_id / group_id / score / result |
| `thesis_score` | 总评 | proposal_score / midterm_score / review_score / defense_score / total_score |
| `attachment` | 附件 | biz_type / biz_id / file_name / file_url / storage_driver |
| `audit_log` | 操作留痕 | actor_id / action / target_type / target_id / detail |
| `notification` | 站内消息 | user_id / title / content / link / is_read |
| `sys_config` | 系统配置 | config_key / config_value / remark |

**索引**：`thesis(status, grade)`、`thesis(advisor_id)`、`selection(topic_id, status)`、`attachment(biz_type, biz_id)`、`audit_log(target_type, target_id)`、`review(reviewer_id, status)`、`sys_dict_item(type_code, parent_id)`。

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

规则集中在 `domain/ThesisStatus.java`（枚举 + 允许的下一状态 + 允许操作的角色），所有变更经 `FlowGuard.canTransition()` 校验并写 `audit_log`。

---

## 七、工程结构（三目录分离）

```
thesis-management/
├── backend/                              # ① 后端（Spring Boot 3）
│   ├── pom.xml
│   ├── storage/                          #    本地静态文件存储根目录
│   │   └── uploads/{proposal,midterm,final,other}/
│   └── src/main/
│       ├── java/com/example/thesis/
│       │   ├── ThesisApplication.java
│       │   ├── common/                   #    R 统一响应、PageResult、异常、常量
│       │   ├── config/                   #    Security/MyBatisPlus/WebMvc/Jwt/Storage 配置
│       │   ├── security/                 #    JwtUtil、JwtFilter、LoginUser、SecurityUtils
│       │   ├── domain/                   #    ThesisStatus 状态机、FlowGuard、ScoreRule
│       │   ├── entity/                   #    20 个实体，与表一一对应
│       │   ├── mapper/                   #    MyBatis Plus Mapper
│       │   ├── dto/                      #    请求/响应对象
│       │   ├── vo/                       #    列表展示对象
│       │   ├── service/                  #    业务层
│       │   ├── controller/               #    REST 接口
│       │   └── storage/                  #    StorageService + LocalStorageService
│       └── resources/
│           └── application.yml           #    MySQL 连接参数为占位符
│
├── frontend/                             # ② 前端（Vue3 + Vite + Element Plus）
│   ├── package.json / vite.config.ts / tsconfig.json / index.html
│   └── src/
│       ├── api/                          #    axios 封装 + 各模块接口
│       ├── router/                       #    路由 + 守卫
│       ├── stores/                       #    Pinia：user / dict
│       ├── layouts/                      #    MainLayout 主框架（响应式）
│       ├── components/                   #    PageTable / StatusTag / FileUpload 等
│       ├── composables/                  #    useResponsive / useTable / useDict
│       ├── views/                        #    各业务页面
│       ├── styles/                       #    全局样式与断点
│       └── types/                        #    TS 类型
│
├── database/                             # ③ 数据库（脚本）
│   ├── 01_schema.sql                     #    建表 DDL（含字典表）
│   ├── 02_demo_data.sql                  #    字典数据 + 演示数据
│   └── README.md                         #    导入步骤说明
│
├── scripts/                              # 辅助脚本（生成/校验演示数据）
├── docs/                                 # 项目文档
├── .gitignore
└── README.md
```

**关键依赖**
- 后端：`spring-boot-starter-web` / `-security` / `-validation`、`mybatis-plus-spring-boot3-starter`、`mysql-connector-j`、`jjwt`、`easyexcel`、`lombok`
- 前端：`vue@3`、`typescript`、`vite`、`element-plus`、`pinia`、`vue-router@4`、`axios`、`echarts`、`vue-echarts`、`dayjs`

---

## 八、API 设计（前缀 `/api`）

| 分组 | 方法与路径 |
| --- | --- |
| 认证 | `POST /auth/login`、`POST /auth/logout`、`GET /auth/me`、`PUT /auth/password` |
| 用户 | `GET/POST /users`、`GET/PUT/DELETE /users/{id}`、`POST /users/import`、`GET /users/template` |
| 教师/学生 | `GET/POST /teachers`、`PUT /teachers/{id}`、`GET/POST /students`、`PUT /students/{id}` |
| 字典 | `GET /dict/types`、`POST/PUT/DELETE /dict/types`、`GET /dict/items`、`POST/PUT/DELETE /dict/items` |
| 课题 | `GET/POST /topics`、`GET/PUT/DELETE /topics/{id}`、`POST /topics/{id}/publish` |
| 选题 | `POST /selections`、`GET /selections`、`POST /selections/{id}/approve`、`POST /selections/{id}/reject` |
| 论文 | `GET /theses`、`GET /theses/{id}`、`POST /theses/{id}/transition`、`GET /theses/{id}/timeline` |
| 开题 | `POST /proposals`、`GET /proposals`、`POST /proposals/{id}/review` |
| 中期 | `POST /midterms`、`GET /midterms`、`POST /midterms/{id}/review`、`GET /midterms/alerts` |
| 定稿 | `POST /finals`、`GET /finals` |
| 评阅 | `POST /reviews/assign`、`GET /reviews`、`POST /reviews/{id}/submit` |
| 答辩 | `GET/POST /defense/groups`、`POST /defense/groups/{id}/members`、`POST /defense/records` |
| 成绩 | `GET /scores`、`GET /scores/{thesisId}`、`POST /scores/{thesisId}/recompute` |
| 文件 | `POST /files/upload`、`GET /files/biz`、`GET /files/{id}/download`、`DELETE /files/{id}` |
| 看板 | `GET /dashboard/stats`、`GET /dashboard/stage-distribution`、`GET /dashboard/todos` |
| 配置 | `GET/PUT /configs` |

统一响应：`{ "code": 0, "data": ..., "message": "ok" }`；`code != 0` 为业务错误，由 `GlobalExceptionHandler` 统一封装。

---

## 九、开发里程碑（每个里程碑一个分支 + 提交）

| # | 里程碑 | 主要交付 | 状态 |
| --- | --- | --- | --- |
| M0 | 工程初始化 | 三目录骨架、`.gitignore`、README、Maven 与 Vite 工程 | ✅ 本次完成 |
| M1 | 数据库与后端骨架 | `database/` 建表与演示数据、20 实体、Mapper、MyBatis Plus 配置 | ✅ 本次完成 |
| M2 | 认证与字典 | Spring Security + JWT、登录接口/页面、路由守卫、主布局、字典 CRUD | ✅ 本次完成 |
| M3 | 基础 CRUD | 用户 / 学生 / 教师管理列表与表单、批量导入 | ✅ 本次完成 |
| M4 | 选题与开题 | 课题发布、选题申请与审核、开题提交与审核 | ✅ 本次完成 |
| M5 | 中期检查 | 中期报告提交、检查、超期预警 | ✅ 本次完成 |
| M6 | 定稿 + 评阅 + 答辩 | 定稿上传、评阅指派与打分、答辩分组、成绩录入与总评 | ✅ 本次完成 |
| M7 | 数据看板 | 四类角色看板、ECharts、待办卡片 | ✅ 本次完成 |
| M8 | 本地文件存储 | StorageService、上传接口与组件、附件管理、静态目录映射 | ✅ 本次完成 |
| M9 | 响应式与体验 | 断点适配、表格转卡片、空状态/加载态 | ✅ 本次完成 |
| M10 | 文档与自测 | README 启动说明、编译校验、冒烟清单 | ✅ 本次完成 |

**Git 规范**：主干 `main`，开发分支 `feat/xxx`、`fix/xxx`；Conventional Commits（`feat:` `fix:` `docs:` `refactor:` `test:` `chore:`）；里程碑合并后打标签。

---

## 十、数据库脚本与演示数据

### 10.1 导入步骤

```bash
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS thesis_mgmt DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci;"
mysql -u root -p thesis_mgmt < database/01_schema.sql
mysql -u root -p thesis_mgmt < database/02_demo_data.sql
```

### 10.2 数据规模

| 项目 | 数量 |
| --- | --- |
| 字典类型 / 字典项 | 8 / 约 70 |
| 管理员 | 1 |
| 指导教师 | 18 |
| 评阅教师 | 6 |
| 学生 | 55（2026 届 12 / 2027 届 43） |
| 课题 | 60（已选 50 / 开放 10） |
| 选题申请 | 55（通过 50 / 待审 3 / 驳回 2） |
| 论文 | 50，覆盖 11 种状态全部取值 |
| 开题 / 中期 / 定稿 | 47 / 37 / 27 |
| 评阅 / 答辩组 / 答辩成绩 | 22 / 3 / 12 |
| 附件 / 操作日志 / 站内消息 | 111 / 341 / 70 |

### 10.3 演示账号

学生与教师密码统一 `123456`，管理员 `admin123`，均为 BCrypt（`$2a$10$`）哈希。

| 角色 | 账号 |
| --- | --- |
| 管理员 | `admin` |
| 指导教师 | `t2001` ~ `t2018` |
| 评阅教师 | `r3001` ~ `r3006` |
| 学生 | `s20260001` ~ `s20270043` |

### 10.4 生成与校验脚本

```bash
python scripts/gen_demo_sql.py   # 重新生成（固定随机种子，结果可复现）
python scripts/check_sql.py      # 自检：语法 / 唯一键 / 引用完整性 / 状态分布
```

---

## 十一、风险与处理（已按用户意见修订）

1. ~~云端存储 Origin 校验~~ → **已取消云端存储**。全部改为本地静态目录：文件落盘 `backend/storage/uploads/{业务类型}/{yyyyMM}/`，经 `/uploads/**` 静态映射对外提供访问。`StorageService` 抽象与 `storage_driver` 字段保留，将来接入云端只需新增一个实现类，业务代码零改动。
2. ~~MySQL 连接参数~~ → **使用占位符**。`application.yml` 中为 `__MYSQL_HOST__` / `__MYSQL_PORT__` / `__MYSQL_USERNAME__` / `__MYSQL_PASSWORD__`，由使用者自行替换；同时提供 `application-local.yml.example` 作为可复制的示例。
3. **字典表** → 已采用**独立字典表统一管理**：`sys_dict_type`（类型）+ `sys_dict_item`（项目，含 `parent_id` 支持学院→专业→班级三级）。管理员在「系统管理 → 字典管理」中维护，业务表冗余存名称以保证归档数据稳定。
4. **专业负责人角色** → **不设**。选题录取由指导教师完成，跨专业调配与最终审批归管理员，审批链条缩短为两级。
5. 查重模块未纳入：`FINAL_SUBMITTED` 前预留扩展点，后续可插入 `PLAGIARISM_CHECK` 状态而不动主流程。
6. 批量导入并发：批处理 + 事务，失败行回滚并导出错误报告，不做部分提交。
7. 评分权重：默认 开题 20 / 中期 20 / 评阅 30 / 答辩 30，存 `sys_config`，可在线改。
8. 本地文件存储的容量与备份需运维关注：建议定期备份 `storage/uploads` 目录；磁盘写满会导致上传失败，接口已统一返回可读错误。

---

## 十二、验收标准

- [ ] 四类角色均能登录，越权访问被拦截（前端菜单 + 后端接口双重）
- [ ] 完整跑通：教师出题 → 学生选题 → 导师录取 → 开题审核 → 中期检查 → 定稿 → 评阅 → 答辩 → 归档
- [ ] 非法状态流转被拒绝并提示原因
- [ ] 每步操作在详情页时间轴可见
- [ ] 附件能上传 / 下载 / 删除，文件落在 `backend/storage/uploads` 下，DB 只存相对路径
- [ ] 字典管理可增删改学院/专业/班级，三级联动在选择器中生效
- [ ] 看板数据在演示数据下正确，图表随窗口自适应
- [ ] 1440 / 1024 / 768 / 375 四种宽度下无横向滚动、可操作
- [ ] 批量导入可导入 Excel 并给出失败行报告
- [ ] 后端 `mvn -f backend/pom.xml clean package` 通过；前端 `npm run build` 产出可部署包
- [ ] git 历史清晰，每个里程碑可追溯
