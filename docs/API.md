# 后端 API 文档

毕业论文管理系统后端 REST 接口说明。文档与代码保持一致：接口清单来自 `backend/src/main/java/com/example/thesis/controller/`，权限规则来自各 Service 的实际校验逻辑。

| 项 | 值 |
| --- | --- |
| 服务地址（开发） | `http://localhost:8080` |
| 接口前缀 | `/api` |
| 数据格式 | `application/json; charset=UTF-8` |
| 认证方式 | JWT，请求头 `Authorization: Bearer <token>` |
| 接口规模 | **90 个端点**，分布在 11 个控制器中 |
| 代码位置 | `backend/src/main/java/com/example/thesis/controller/` |

---

## 一、通用约定

### 1.1 统一响应结构

```json
{
  "code": 0,
  "message": "ok",
  "data": {}
}
```

| 字段 | 说明 |
| --- | --- |
| `code` | `0` 表示成功；非 0 为业务错误码 |
| `message` | 提示文案，失败时可直接展示给用户 |
| `data` | 业务数据，无返回值时该字段不出现 |

**HTTP 状态码恒为 200**（文件下载接口除外）。这样做的好处是前端只需判断 `code`，不必同时处理两套错误通道。未登录与越权也通过 `code` 表达：

| code | 含义 | 前端建议动作 |
| --- | --- | --- |
| `0` | 成功 | 取 `data` |
| `401` | 未登录 / Token 失效 | 清除本地登录态，跳转登录页并带上 `redirect` |
| `403` | 已登录但无权访问 | 提示「无权限」，停留在当前页 |
| `404` | 资源不存在 | 提示并刷新列表 |
| `1000` | 通用业务错误 | 直接展示 `message` |
| `1001` | 参数校验失败 | 展示 `message`（含字段名） |
| `1002` | 状态流转非法 | 展示 `message`，刷新详情以同步最新状态 |
| `1003` | 文件相关错误 | 展示 `message` |
| `500` | 服务端异常 | 提示「服务异常」，上报日志 |

### 1.2 认证

登录成功后拿到 Token，后续所有需登录的接口都要带上：

```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
```

Token 有效期由 `thesis.jwt.expire-minutes` 控制（默认 720 分钟）。登出后 Token 进入内存黑名单，立即失效。

> ⚠️ **签名密钥策略（影响客户端）**：`thesis.jwt.secret` **不再提供默认值**。若未在 `application-local.yml` 或环境变量中配置，服务启动时会**随机生成**一个密钥——此时**服务每次重启都会使所有已签发的 Token 立即失效**，客户端需要重新登录。开发环境可接受；生产环境务必配置固定密钥。

> **注意**：请求头前缀必须是 `Bearer ` 加一个空格，服务端按 `thesis.jwt.prefix` 配置截取。

### 1.3 分页

**请求参数**（所有列表接口通用）：

| 参数 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `pageNum` | int | 1 | 页码，从 1 开始 |
| `pageSize` | int | 10 | 每页条数，上限 200 |
| `keyword` | string | - | 模糊搜索关键字，各接口匹配字段不同 |

**响应结构**：

```json
{
  "code": 0,
  "data": {
    "total": 55,
    "pageNum": 1,
    "pageSize": 10,
    "records": []
  }
}
```

### 1.4 时间格式

所有时间字段统一为字符串 `yyyy-MM-dd HH:mm:ss`（`LocalDate` 为 `yyyy-MM-dd`），提交时也使用同样格式。Element Plus 的日期选择器配置 `value-format="YYYY-MM-DD HH:mm:ss"` 即可直接对接。

---

## 二、数据权限规则（重要）

同一个接口对不同角色返回的数据范围不同，规则集中在 `ThesisService.applyScope()` 与各 Service 的可见性校验中。

| 角色 | 课题 | 选题 | 论文 | 开题 / 中期 | 评阅 | 答辩 |
| --- | --- | --- | --- | --- | --- | --- |
| `STUDENT` | 仅开放申报中 + 自己已申报的 | 仅自己的 | 仅自己的 | 仅自己的 | 仅自己论文的 | 只读 |
| `ADVISOR` | 仅自己出的题 | 仅自己课题收到的 | 仅自己指导的 | 仅自己指导的 | 仅自己指导的 | 只读 |
| `REVIEWER` | 全部（只读） | ⚠️ 当前未限制 | 仅被指派评阅的 | ⚠️ 当前未限制 | 仅指派给自己的 | 仅自己所在答辩组的 |
| `ADMIN` | 全部 | 全部 | 全部 | 全部 | 全部 | 全部 |

> ⚠️ **上表中两处标记为「当前未限制」的，是代码实现与设计意图不符的已知缺陷**：`GET /api/proposals`、`GET /api/midterms`、`GET /api/selections` 三个列表接口对 `REVIEWER` 没有加数据范围条件，导致评阅教师能读到全院的开题/中期报告正文与选题申请详情。
>
> **该问题截至目前尚未修复**（已确认保留）。接口的**调用方式不受影响**，无需改动前端；修复属于后端一次性改动。

> 越权访问单条资源（如学生查看他人论文）会抛出 `403`，而不是返回空数据。

---

## 三、接口清单

### 3.1 认证 `/api/auth`

| 方法 | 路径 | 权限 | 说明 |
| --- | --- | --- | --- |
| POST | `/api/auth/login` | 公开 | 登录 |
| POST | `/api/auth/logout` | 登录用户 | 登出，Token 加入黑名单 |
| GET | `/api/auth/me` | 登录用户 | 当前用户资料（含学生/教师档案） |
| PUT | `/api/auth/password` | 登录用户 | 修改本人密码 |

**POST `/api/auth/login`**

请求体：

```json
{ "username": "s20260001", "password": "123456" }
```

响应 `data`：

```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "expireIn": 43200,
  "user": { "id": 12, "username": "s20260001", "realName": "张三", "role": "STUDENT", "status": 1 },
  "student": { "id": 8, "studentNo": "20260001", "grade": "2026", "college": "计算机与人工智能学院", "major": "计算机科学与技术", "className": "计科22-1班" },
  "teacher": null
}
```

> 账号不存在与密码错误返回同一提示「账号或密码错误」，避免账号枚举。`user.password` 字段永不返回。

**PUT `/api/auth/password`**

```json
{ "currentPassword": "123456", "newPassword": "abc123456" }
```

新密码至少 6 位，且不能与当前密码相同。

---

### 3.2 账号管理 `/api/users`（写操作限 ADMIN）

| 方法 | 路径 | 权限 | 说明 |
| --- | --- | --- | --- |
| GET | `/api/users` | 登录用户 | 分页查询，可按 `role` 过滤 |
| POST | `/api/users` | ADMIN | 新建账号 |
| PUT | `/api/users/{id}` | ADMIN | 修改账号（不改密码） |
| DELETE | `/api/users/{id}` | ADMIN | 删除账号（连带删除档案） |
| PUT | `/api/users/{id}/password` | ADMIN | 重置密码 |

**GET** 查询参数：分页参数 + `role`（`STUDENT` / `ADVISOR` / `REVIEWER` / `ADMIN`）。

**POST** 请求体为账号对象，初始密码通过 **query 参数** 传递：

```
POST /api/users?password=abc123
{ "username": "t2020", "realName": "王五", "role": "ADVISOR", "phone": "13800000000" }
```

`password` 留空则使用 `thesis.import.default-password`（默认 `123456`）。

---

### 3.3 教师管理 `/api/teachers`

| 方法 | 路径 | 权限 | 说明 |
| --- | --- | --- | --- |
| GET | `/api/teachers` | 登录用户 | 分页查询，可按 `college` / `teacherType` / `canReview` 过滤 |
| POST | `/api/teachers` | ADMIN | 新建教师（同时创建账号，账号=工号） |
| PUT | `/api/teachers/{id}` | ADMIN | 修改教师 |
| DELETE | `/api/teachers/{id}` | ADMIN | 删除（名下有学生时拒绝） |
| GET | `/api/teachers/options` | 登录用户 | 指导 / 评阅教师下拉选项 |

**GET `/api/teachers/options`** 响应：

```json
{
  "advisors": [{ "id": 1, "teacherNo": "T2001", "realName": "李四", "title": "教授", "studentCount": 4 }],
  "reviewers": [{ "id": 7, "teacherNo": "T2007", "realName": "赵六", "canReview": 1 }]
}
```

> `advisors` 排除纯评阅教师；`reviewers` 返回 `teacher_type='REVIEWER'` 或 `can_review=1` 的教师。

---

### 3.4 学生管理 `/api/students`

| 方法 | 路径 | 权限 | 说明 |
| --- | --- | --- | --- |
| GET | `/api/students` | 登录用户 | 分页查询，可按 `grade` / `college` / `major` / `advisorId` 过滤 |
| POST | `/api/students` | ADMIN | 新建学生（账号=学号） |
| PUT | `/api/students/{id}` | ADMIN | 修改学生 |
| DELETE | `/api/students/{id}` | ADMIN | 删除（已有论文记录时拒绝） |

**POST** 请求体：

```json
{
  "studentNo": "20270044",
  "realName": "陈七",
  "gender": 1,
  "grade": "2027",
  "college": "软件学院",
  "major": "软件工程",
  "className": "软工23-1班",
  "advisorId": 1,
  "phone": "13700000000",
  "email": "chenqi@stu.edu.cn"
}
```

> `grade` / `college` / `major` / `className` **必须命中字典项**，否则返回 `1001` 并提示「字典中没有该××，请先在『系统管理 → 字典管理』中维护」。

---

### 3.5 字典管理 `/api/dict`

| 方法 | 路径 | 权限 | 说明 |
| --- | --- | --- | --- |
| GET | `/api/dict/types` | 登录用户 | 字典类型列表（含 `itemCount`） |
| POST | `/api/dict/types` | ADMIN | 新建类型 |
| PUT | `/api/dict/types/{id}` | ADMIN | 修改类型 |
| DELETE | `/api/dict/types/{id}` | ADMIN | 删除类型（下有字典项时拒绝） |
| GET | `/api/dict/items` | 登录用户 | 字典项查询 |
| POST | `/api/dict/items` | ADMIN | 新建字典项 |
| PUT | `/api/dict/items/{id}` | ADMIN | 修改字典项 |
| DELETE | `/api/dict/items/{id}` | ADMIN | 删除字典项（有子项时拒绝） |

**GET `/api/dict/items`** 查询参数：

| 参数 | 必填 | 说明 |
| --- | --- | --- |
| `typeCode` | 是 | 字典类型编码，如 `COLLEGE` |
| `parentId` | 否 | 父级字典项 id；传 `0` 表示**只取顶级** |
| `onlyEnabled` | 否 | `true` 时只返回启用项（下拉框用） |
| `asTree` | 否 | `true` 时返回树形结构（字典管理页用） |

**三级联动示例**（学院 → 专业 → 班级）：

```
GET /api/dict/items?typeCode=COLLEGE&parentId=0&onlyEnabled=true     → 学院列表
GET /api/dict/items?typeCode=MAJOR&parentId=1&onlyEnabled=true       → 该学院下的专业
GET /api/dict/items?typeCode=CLASS&parentId=2&onlyEnabled=true       → 该专业下的班级
```

**内置字典类型**：`COLLEGE`（学院）、`MAJOR`（专业）、`CLASS`（班级）、`GRADE`（届别）、`TOPIC_TYPE`（课题类型）、`TOPIC_SOURCE`（课题来源）、`TITLE`（职称）、`DEFENSE_RESULT`（答辩结论）。

---

### 3.6 系统配置 `/api/configs`

| 方法 | 路径 | 权限 | 说明 |
| --- | --- | --- | --- |
| GET | `/api/configs` | 登录用户 | 全部配置项 |
| PUT | `/api/configs` | ADMIN | 批量 upsert（传数组） |

**内置配置项**：

| key | 含义 | 默认值 |
| --- | --- | --- |
| `score.weight.proposal` | 开题成绩权重 | 20 |
| `score.weight.midterm` | 中期成绩权重 | 20 |
| `score.weight.review` | 评阅成绩权重 | 30 |
| `score.weight.defense` | 答辩成绩权重 | 30 |
| `deadline.proposal` | 开题截止日期 | - |
| `deadline.midterm` | 中期截止日期 | - |
| `deadline.final` | 定稿截止日期 | - |

> 截止日期用于「中期检查 → 超期预警」；留空表示不预警。

---

### 3.7 批量导入 `/api/import`（限 ADMIN）

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/api/import/template` | 下载 xlsx 模板（返回二进制，非 JSON） |
| POST | `/api/import/users` | 上传并导入，`multipart/form-data`，字段名 `file` |

**POST `/api/import/users`** 响应：

```json
{
  "total": 50,
  "successCount": 48,
  "failCount": 2,
  "imported": false,
  "message": "校验未通过，本次未导入任何数据",
  "errors": [
    { "row": 5, "message": "账号已存在；" },
    { "row": 9, "message": "学院不在字典中；专业不在字典中；" }
  ]
}
```

> **全量校验后才落库**：任一行有问题则整批不导入，`imported=false`，避免出现「导了一半」的中间状态。`row` 为 Excel 中的实际行号。

---

### 3.8 课题 `/api/topics`

| 方法 | 路径 | 权限 | 说明 |
| --- | --- | --- | --- |
| GET | `/api/topics` | 登录用户 | 分页查询，按角色自动限定范围 |
| GET | `/api/topics/{id}` | 登录用户 | 课题详情 |
| POST | `/api/topics` | ADVISOR / ADMIN | 新建课题（初始为草稿） |
| PUT | `/api/topics/{id}` | 出题教师 / ADMIN | 修改课题 |
| POST | `/api/topics/{id}/publish` | 出题教师 / ADMIN | 草稿 → 开放申报 |
| POST | `/api/topics/{id}/close` | 出题教师 / ADMIN | 关闭申报 |
| DELETE | `/api/topics/{id}` | 出题教师 / ADMIN | 删除（已有申报时拒绝） |

**GET** 查询参数：分页参数 + `status` / `grade` / `major` / `teacherId` / `onlyOpen`。

`status` 取值：`DRAFT`（草稿）、`OPEN`（开放申报）、`SELECTED`（已选满）、`CLOSED`（已关闭）。

**POST** 请求体：

```json
{
  "title": "基于深度学习的图像超分辨率重建",
  "topicType": "软件开发",
  "source": "教师命题",
  "grade": "2027",
  "capacity": 2,
  "description": "课题简介…",
  "requirement": "任务要求…"
}
```

> 指导教师创建时 `teacherId` 由服务端自动取本人档案；管理员需显式指定。

---

### 3.9 选题申请 `/api/selections`

| 方法 | 路径 | 权限 | 说明 |
| --- | --- | --- | --- |
| GET | `/api/selections` | 登录用户 | 分页查询，按角色限定范围 |
| GET | `/api/selections/mine` | STUDENT | 我的选题申请（无则返回 `null`） |
| POST | `/api/selections` | STUDENT | 申报课题 |
| POST | `/api/selections/{id}/approve` | 出题教师 / ADMIN | 录取 |
| POST | `/api/selections/{id}/reject` | 出题教师 / ADMIN | 驳回 |

**POST `/api/selections`**

```json
{ "topicId": 15, "remark": "我对该方向有相关项目经验" }
```

申报前置校验：已确定课题则拒绝；已有待审/已通过申请则拒绝；课题须为 `OPEN` 且名额未满。

**录取的连带效果**（在一个事务内完成）：

1. 申请状态置 `APPROVED`
2. 课题 `selected_count + 1`，满员则课题状态置 `SELECTED`
3. **自动创建论文记录**，状态 `DRAFT`，并写入指导教师
4. 回填学生档案的 `advisor_id`
5. 该学生其它待审申请自动置 `REJECTED`
6. 写入操作留痕 + 发送站内消息

**请求体**（审核意见，可省略）：

```json
{ "comment": "同意，注意数据集的选取" }
```

---

### 3.10 论文主流程 `/api/theses`

| 方法 | 路径 | 权限 | 说明 |
| --- | --- | --- | --- |
| GET | `/api/theses` | 登录用户 | 分页查询，按角色限定范围 |
| GET | `/api/theses/mine` | STUDENT | 我的论文 |
| GET | `/api/theses/{id}` | 可见者 | 论文详情 |
| GET | `/api/theses/{id}/detail` | 可见者 | **详情页聚合数据** |
| GET | `/api/theses/{id}/timeline` | 可见者 | 操作时间轴 |
| POST | `/api/theses/{id}/transition` | 见状态机 | 通用状态流转 |

**GET** 查询参数：分页参数 + `status` / `grade` / `college` / `advisorId` / `studentId`。

**GET `/api/theses/{id}/detail`** 一次返回详情页所需全部数据，避免前端发 6 个请求：

```json
{
  "thesis":     { "id": 3, "title": "…", "status": "REVIEWING", "statusLabel": "评阅中" },
  "timeline":   [{ "actorName": "李四", "detail": "指派 赵六 评阅论文", "createTime": "2026-09-20 10:12:00" }],
  "proposal":   { "reviewStatus": "APPROVED", "score": 88, "content": "…" },
  "midterm":    { "reviewStatus": "APPROVED", "progressPercent": 90, "score": 85 },
  "finals":     [{ "version": 1, "fileName": "论文定稿.pdf", "fileUrl": "/uploads/final/202609/xxx.pdf" }],
  "reviews":    [{ "reviewerName": "赵六", "score": 87, "status": "SUBMITTED", "comment": "…" }],
  "defenseRecord": null,
  "score":      { "proposalScore": 88, "midtermScore": 85, "reviewScore": 87, "totalScore": 86.2, "level": "良好" }
}
```

**POST `/api/theses/{id}/transition`**

```json
{ "target": "ARCHIVED", "comment": "材料齐备，论文归档", "score": null }
```

`target` 必须是当前状态允许的下一状态，且当前角色有权执行，否则返回 `1002` 并给出可读原因：

```json
{
  "code": 1002,
  "message": "当前状态「待提交开题」不能流转到「评阅中」，允许的下一步：开题待审核"
}
```

---

### 3.11 开题报告 `/api/proposals`

| 方法 | 路径 | 权限 | 说明 |
| --- | --- | --- | --- |
| GET | `/api/proposals` | 登录用户 | 分页查询，可按 `thesisId` / `reviewStatus` 过滤 |
| GET | `/api/proposals/mine` | STUDENT | 我的开题报告 |
| POST | `/api/proposals` | STUDENT | 提交开题报告 |
| POST | `/api/proposals/{id}/review` | 指导教师 / ADMIN | 审核 |

**POST `/api/proposals`**

```json
{ "content": "研究背景、内容、技术路线、进度安排…", "attachmentIds": "12,13" }
```

`attachmentIds` 为附件 id 的逗号分隔字符串（先去 `/api/files/upload` 上传拿到 id）。

**POST `/api/proposals/{id}/review`**

```json
{ "decision": "APPROVED", "comment": "开题合理，同意进入下一阶段", "score": 88 }
```

`decision` 取值 `APPROVED`（→ `PROPOSAL_APPROVED`）或 `REJECTED`（→ 退回 `DRAFT` 供学生重交）。

---

### 3.12 中期检查 `/api/midterms`

| 方法 | 路径 | 权限 | 说明 |
| --- | --- | --- | --- |
| GET | `/api/midterms` | 登录用户 | 分页查询 |
| GET | `/api/midterms/mine` | STUDENT | 我的中期报告 |
| GET | `/api/midterms/alerts` | 登录用户 | **超期预警名单**（按角色限定范围） |
| POST | `/api/midterms` | STUDENT | 提交中期报告 |
| POST | `/api/midterms/{id}/review` | 指导教师 / ADMIN | 检查 |

**POST `/api/midterms`**

```json
{ "progressPercent": 85, "content": "已完成…存在问题…后续计划…", "attachmentIds": "20" }
```

**GET `/api/midterms/alerts`** 响应：列出处于「等待学生提交」状态且已过截止日期的论文：

```json
[
  {
    "thesisId": 27,
    "title": "基于知识图谱的推荐系统",
    "statusLabel": "开题已通过",
    "task": "中期报告",
    "deadline": "2026-09-30 23:59:59",
    "overdueDays": 5,
    "studentName": "张三",
    "studentNo": "20270003",
    "advisorName": "李四"
  }
]
```

第 1 位是超期最久的。

---

### 3.13 论文定稿 `/api/finals`

| 方法 | 路径 | 权限 | 说明 |
| --- | --- | --- | --- |
| GET | `/api/finals` | 登录用户 | 分页查询，可按 `grade` 过滤 |
| POST | `/api/finals` | STUDENT | 提交定稿（自动递增版本号） |

**POST `/api/finals`**

```json
{
  "fileUrl": "/uploads/final/202609/a1b2c3.pdf",
  "fileName": "论文定稿.pdf",
  "fileSize": 2048576,
  "note": "第 1 版定稿"
}
```

只有当前状态为 `MIDTERM_PASSED`（中期通过）或 `REVIEWING`（评阅被退回重交）时允许提交，提交后状态置 `FINAL_SUBMITTED`。

---

### 3.14 论文评阅 `/api/reviews`

| 方法 | 路径 | 权限 | 说明 |
| --- | --- | --- | --- |
| GET | `/api/reviews` | 登录用户 | 分页查询，按角色限定范围 |
| GET | `/api/reviews/mine` | REVIEWER | 我的评阅任务，`onlyPending=true` 只看待办 |
| POST | `/api/reviews/assign` | ADMIN | 指派评阅 |
| POST | `/api/reviews/{id}/submit` | 被指派人 / ADMIN | 提交评阅意见 |

**POST `/api/reviews/assign`**

```json
{ "thesisId": 3, "reviewerId": null, "blind": true }
```

| 字段 | 说明 |
| --- | --- |
| `reviewerId` | **留空则自动指派**：从可评阅教师中挑选当前待办最少的一位 |
| `blind` | 是否盲审 |

首次指派会把论文状态从 `FINAL_SUBMITTED` 推进到 `REVIEWING`；论文已处于 `REVIEWING` 时可继续追加评阅人。

**POST `/api/reviews/{id}/submit`**

```json
{ "score": 87, "comment": "论文结构完整，实验充分，建议通过" }
```

成绩需在 0~100；成绩和意见至少填一项。**全部评阅人提交后自动结算**：

| 条件 | 结果 |
| --- | --- |
| 评阅平均分 ≥ 60 | 论文置 `REVIEW_PASSED`，进入待答辩 |
| 评阅平均分 < 60 | 论文退回 `FINAL_SUBMITTED`，通知学生修改后重交 |

---

### 3.15 答辩管理 `/api/defense`

| 方法 | 路径 | 权限 | 说明 |
| --- | --- | --- | --- |
| GET | `/api/defense/groups` | 登录用户 | 答辩组分页查询 |
| GET | `/api/defense/groups/{id}` | 登录用户 | 答辩组详情（组 + 成员 + 学生） |
| POST | `/api/defense/groups` | ADMIN | 新建答辩组 |
| PUT | `/api/defense/groups/{id}` | ADMIN | 修改答辩组 |
| DELETE | `/api/defense/groups/{id}` | ADMIN | 删除（组内有学生时拒绝） |
| POST | `/api/defense/groups/{id}/members` | ADMIN | 设置成员 |
| GET | `/api/defense/candidates` | ADMIN | 可编入的学生（`REVIEW_PASSED`） |
| GET | `/api/defense/groups/{id}/theses` | 登录用户 | 组内学生 |
| POST | `/api/defense/groups/{id}/schedule` | ADMIN | 编入答辩组 |
| DELETE | `/api/defense/groups/theses/{thesisId}` | ADMIN | 移出答辩组 |
| GET | `/api/defense/records` | 登录用户 | 答辩成绩列表 |
| POST | `/api/defense/records` | ADMIN / 组内 REVIEWER | 录入答辩成绩 |

**POST `/api/defense/groups/{id}/members`**

```json
{ "memberIds": [1, 7, 9], "chairId": 1, "secretaryId": 9 }
```

`chairId` / `secretaryId` 应在 `memberIds` 中，服务端据此写入成员角色（`CHAIR` / `SECRETARY` / `MEMBER`），其余为 `MEMBER`。

**POST `/api/defense/groups/{id}/schedule`** —— 请求体是 **JSON 数组**：

```json
[3, 4, 5]
```

把论文编入答辩组，状态从 `REVIEW_PASSED` 推进到 `DEFENSE_SCHEDULED`。

**POST `/api/defense/records`**

```json
{
  "thesisId": 3,
  "groupId": 1,
  "score": 88,
  "result": "PASS",
  "comment": "表达清晰，回答问题准确"
}
```

| 字段 | 说明 |
| --- | --- |
| `result` | `PASS` / `DEFER` / `FAIL`，**留空则按成绩自动判定**（≥75 通过，≥60 暂缓，否则不通过） |

录入后论文状态推进到 `DEFENSE_DONE`，并**自动重算总评**、向学生推送成绩通知。

---

### 3.16 成绩 `/api/scores`

| 方法 | 路径 | 权限 | 说明 |
| --- | --- | --- | --- |
| GET | `/api/scores` | 登录用户 | 分页查询，可按 `grade` / `college` / `major` 过滤 |
| GET | `/api/scores/{thesisId}` | 登录用户 | 单篇论文成绩 |
| POST | `/api/scores/{thesisId}/recompute` | ADMIN | 重算总评（调整权重后用） |

**响应示例**：

```json
{
  "thesisId": 3,
  "proposalScore": 88,
  "midtermScore": 85,
  "reviewScore": 87,
  "defenseScore": 90,
  "totalScore": 87.7,
  "level": "良好",
  "studentName": "张三",
  "thesisTitle": "基于深度学习的图像超分辨率重建"
}
```

**总评规则**：按权重加权平均，**未评分的环节不计入分母**（不会因为还没答辩就把总分拉低）。权重取自 `sys_config`。

```
总评 = Σ(已评分环节成绩 × 该环节权重) / Σ(已评分环节权重)
```

等级：≥90 优秀 / ≥80 良好 / ≥70 中等 / ≥60 及格 / <60 不及格。

---

### 3.17 附件 `/api/files`

文件保存到后端本地静态目录，数据库只登记相对路径。

| 方法 | 路径 | 权限 | 说明 |
| --- | --- | --- | --- |
| POST | `/api/files/upload` | 登录用户 | 上传，`multipart/form-data` + query `bizType` |
| POST | `/api/files/bind` | 登录用户 | 把已上传的附件绑定到业务记录 |
| GET | `/api/files` | 登录用户 | 按 `bizType` + `bizId` 查询 |
| GET | `/api/files/by-ids` | 登录用户 | 按 id 批量查询，`ids` 逗号分隔 |
| DELETE | `/api/files/{id}` | 登录用户 | 删除（同时删除磁盘文件） |

**上传**：

```
POST /api/files/upload?bizType=PROPOSAL     (form-data: file=@论文.pdf)
```

响应：

```json
{
  "id": 12,
  "bizType": "PROPOSAL",
  "bizId": 0,
  "fileName": "开题报告.pdf",
  "fileUrl": "/uploads/proposal/202610/9f8e7d6c.pdf",
  "fileSize": 1024000,
  "storageDriver": "local"
}
```

`bizType` 取值：`PROPOSAL` / `MIDTERM` / `FINAL` / `OTHER`，决定落盘子目录。

**绑定**（材料保存后调用，把附件挂到具体记录）：

```json
{ "bizType": "PROPOSAL", "bizId": 25, "ids": [12, 13] }
```

**限制**：允许 `pdf/doc/docx/xls/xlsx/zip/jpg/jpeg/png`，单文件 ≤ 20MB，服务端用 UUID 重命名，不信任客户端文件名。

**访问**：`fileUrl` 是相对路径，浏览器可直接访问 `http://localhost:8080/uploads/proposal/202610/9f8e7d6c.pdf`（开发环境前端已配置 `/uploads` 代理）。

---

### 3.18 数据看板 `/api/dashboard`

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/api/dashboard/overview` | 角色化总览（指标 + 阶段分布 + 成绩分布 + 待办） |
| GET | `/api/dashboard/stages` | 各阶段论文数量 |
| GET | `/api/dashboard/todos` | 当前角色的待办清单 |

**GET `/api/dashboard/overview`** 返回内容随角色变化：

| 角色 | 额外返回的指标 |
| --- | --- |
| `ADMIN` | `studentCount`、`teacherCount`、`thesisCount`、`finishedCount`、`completionRate`、`avgScore`、`pendingProposal`、`pendingMidterm`、`pendingAssignReview`、`pendingSchedule`、`pendingArchive`、`pendingReview`、`alerts` |
| `ADVISOR` | `myStudentCount`、`myThesisCount`、`pendingSelection`、`pendingProposal`、`pendingMidterm`、`finishedCount` |
| `REVIEWER` | `pendingCount`、`submittedCount`、`avgScore` |
| `STUDENT` | `thesis`、`statusLabel`、`progress`（0~100）、`score`、`hasThesis` |

所有角色都会返回：

```json
{
  "role": "ADMIN",
  "realName": "系统管理员",
  "stageDistribution": [{ "status": "DRAFT", "label": "待提交开题", "count": 3 }],
  "scoreDistribution": [{ "bucket": "80-89", "cnt": 12 }],
  "todos": [{ "title": "待指派评阅", "count": 5, "link": "/review/assign" }]
}
```

> `todos` 中 `count` 为 0 的项会被自动省略。

---

### 3.19 站内消息 `/api/notifications`

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/api/notifications` | 我的消息，`onlyUnread=true` 只看未读（最多返回 200 条） |
| GET | `/api/notifications/unread-count` | 未读数量（顶栏红点） |
| PUT | `/api/notifications/{id}/read` | 标记已读（只能操作自己的消息） |
| PUT | `/api/notifications/read-all` | 全部已读 |

消息类型：`SYSTEM`（系统）、`FLOW`（流程流转）、`SCORE`（成绩）。

---

## 四、完整业务时序（跑通一篇论文）

```
POST /api/auth/login                          student 登录
GET  /api/topics?onlyOpen=true                student 浏览课题
POST /api/selections                          student 申报课题
POST /api/selections/{id}/approve             advisor 录取 → 系统创建论文(DRAFT)
POST /api/proposals                           student 提交开题
POST /api/proposals/{id}/review {APPROVED}    advisor 审核通过 → PROPOSAL_APPROVED
POST /api/midterms                            student 提交中期
POST /api/midterms/{id}/review {APPROVED}     advisor 检查通过 → MIDTERM_PASSED
POST /api/files/upload?bizType=FINAL          student 上传定稿文件
POST /api/finals                              student 提交定稿 → FINAL_SUBMITTED
POST /api/reviews/assign                      admin 指派评阅 → REVIEWING
POST /api/reviews/{id}/submit {score:87}      reviewer 提交评阅 → 全部提交后 REVIEW_PASSED
POST /api/defense/groups/{id}/schedule [3]    admin 编入答辩组 → DEFENSE_SCHEDULED
POST /api/defense/records {score:88}          admin/reviewer 录入成绩 → DEFENSE_DONE + 重算总评
POST /api/theses/{id}/transition {ARCHIVED}   admin 归档 → ARCHIVED
GET  /api/theses/{id}/detail                  任意可见角色查看完整档案与时间轴
```

---

## 五、cURL 快速验证

```bash
# 1. 登录并取出 Token
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' \
  | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')

# 2. 带 Token 调用
curl -s http://localhost:8080/api/dashboard/overview -H "Authorization: Bearer $TOKEN"

# 3. 字典三级联动
curl -s "http://localhost:8080/api/dict/items?typeCode=COLLEGE&parentId=0" -H "Authorization: Bearer $TOKEN"

# 4. 上传附件
curl -s -X POST "http://localhost:8080/api/files/upload?bizType=PROPOSAL" \
  -H "Authorization: Bearer $TOKEN" -F "file=@./开题报告.pdf"
```

---

## 六、前端调用方式

前端所有接口集中在 `frontend/src/api/index.ts`，按业务域分组（`authApi` / `topicApi` / `thesisApi` …），通过 `frontend/src/api/request.ts` 统一处理 Token 注入与错误提示：

```ts
import { topicApi } from '@/api'

const page = await topicApi.page({ pageNum: 1, pageSize: 10, keyword: '深度学习' })
// page 即为响应中的 data 字段，无需再手动解包
```

`request.ts` 已统一处理：自动附加 `Authorization` 头；`code = 401` 时清除登录态并跳转登录页；其它非 0 码自动弹出 `message` 提示。因此业务代码里通常**不需要写 try/catch 去提示错误**。

---

## 七、已知限制与后续优化

本节只列**与接口行为直接相关**的限制。

| 项 | 现状 | 状态 |
| --- | --- | --- |
| **开题/中期/选题列表的数据范围** | `REVIEWER` 未加限制，可读到非本人评阅的数据 | ⏸ **未修复**（已知缺陷，待处理） |
| 附件删除 / 绑定 | 仅上传者本人或管理员可操作 | ✅ 已修复 |
| 登录接口 | 无失败次数限制 | ⏸ 未修复（若仅内网使用可接受） |
| 模板下载失败响应 | 前端已识别 JSON 错误体并提示，不再存成坏文件 | ✅ 已修复 |
| 学号 / 工号 | 创建后不可修改（与登录账号绑定） | ✅ 已修复 |
| Token 黑名单 | 内存实现，多实例部署会不一致 | 换 Redis 存储即可，接口无需改动 |
| `GET /api/theses/{id}/detail` | 一次返回 8 类数据，字段多 | 数据量增大后可拆分为按需加载 |
| 查重 | 未实现 | 状态机已在 `FINAL_SUBMITTED` 前预留扩展点 |
| 接口文档化 | 本文档为手工维护 | 可引入 springdoc-openapi 自动生成并与本文档对齐 |
