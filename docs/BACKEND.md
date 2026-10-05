# 后端架构与代码导读

本文帮助你在最短时间内看懂 `backend/` 的组织方式、一次请求怎么走、业务规则写在哪里、以及要扩展时该动哪几个文件。

| 项 | 值 |
| --- | --- |
| 技术栈 | Spring Boot 3.2 + MyBatis Plus 3.5 + Spring Security 6 + JJWT 0.11.5 |
| 构建 | Maven 3.8+ / JDK 17+（已在 JDK 21 验证） |
| 规模 | 92 个 Java 文件 / 7524 行 / 90 个 REST 端点 / 20 张表 |
| 包根 | `com.example.thesis` |
| 启动类 | `ThesisApplication`（带 `@MapperScan` 与 `@ConfigurationPropertiesScan`） |

---

## 一、分层与包职责

```
backend/src/main/java/com/example/thesis/
├── ThesisApplication.java     启动类
├── common/                    与业务无关的公共设施（6 个文件）
│   ├── R.java                 统一响应体 { code, message, data }
│   ├── PageResult.java        分页结果，3 个静态工厂 of()
│   ├── PageQuery.java         分页入参基类
│   ├── BizException.java      业务异常
│   ├── ErrorCode.java         错误码常量
│   └── GlobalExceptionHandler.java  @RestControllerAdvice 全局异常处理
├── config/                    配置类（7 个）
│   ├── SecurityConfig         Security 过滤链 + CORS + PasswordEncoder
│   ├── JwtAuthenticationFilter JWT 认证过滤器（在 security/ 包）
│   ├── MybatisPlusConfig      分页插件
│   ├── WebMvcConfig           本地静态资源映射 /uploads/**
│   ├── JacksonConfig          时间格式统一
│   └── *Properties            @ConfigurationProperties 绑定
├── security/                  JWT 与登录上下文（5 个）
│   ├── JwtUtil                签发与解析
│   ├── JwtAuthenticationFilter 每个请求解析 Token 并回查用户
│   ├── TokenBlacklist         登出黑名单（内存）
│   ├── LoginUser              UserDetails 实现
│   └── SecurityUtils          取当前用户 / requireRole
├── domain/                    纯业务规则，无框架依赖（3 个）
│   ├── ThesisStatus           论文状态机（唯一真源）
│   ├── FlowGuard              流转守卫
│   └── ScoreRule              总评加权算法与等级
├── dto/                       请求体（2 个）
│   ├── Requests.java          嵌套 record 集中管理
│   └── PageQuery.java
├── entity/                    20 张表一一对应（20 个）
├── mapper/                    MyBatis Plus BaseMapper（20 个）
├── service/                   业务逻辑与事务边界（15 个）
├── controller/                REST 接口（11 个）
└── storage/                   文件存储抽象（2 个）
```

**分层约定**

| 层 | 可以做 | 不可以做 |
| --- | --- | --- |
| Controller | 参数接收、`@Valid` 校验、调 Service、返回 `R` | 写业务逻辑、try-catch 吞异常、直接调 Mapper |
| Service | 业务规则、权限与数据范围、事务（`@Transactional`）、写留痕/消息 | 处理 `HttpServletRequest` |
| Mapper | 数据访问；自定义查询用 `#{}` 参数化 | 写业务判断 |
| domain | 纯规则计算（状态机、成绩） | 依赖 Mapper / Service |

---

## 二、一次请求的完整生命周期

以 `GET /api/theses/3/detail`（导师查看论文详情）为例：

```
1. Tomcat 接收请求
2. Spring Security 过滤链
   ├─ CorsFilter            处理跨域
   └─ JwtAuthenticationFilter（security/JwtAuthenticationFilter.java）
        · resolveToken()     从 Authorization 头截取 Bearer 后的 Token
        · jwtUtil.parse()    校验签名与有效期
        · sysUserMapper.selectById(uid)  回查用户，校验 status=1
        · 放入 SecurityContext（LoginUser）
      ↓ 未通过则 SecurityConfig 的 authenticationEntryPoint 返回 {code:401}
3. DispatcherServlet 路由到 ThesisController.detail()
4. Service 层
   ├─ ThesisService.requireVisible(3)
   │    · 查论文
   │    · 按角色校验可见性（学生须是本人 / 导师须是自己指导 / 评阅须被指派）
   │    · 不通过 → BizException(403)
   └─ 组装聚合数据（thesis + timeline + proposal + midterm + finals + reviews + 成绩）
5. 返回 R.ok(bundle) → Jackson 序列化为 {"code":0,"message":"ok","data":{...}}
   · LocalDateTime 由 JacksonConfig 格式化为 yyyy-MM-dd HH:mm:ss
   · SysUser.password 由 @JsonIgnore 屏蔽
6. 若中途抛异常 → GlobalExceptionHandler 统一转换成 R.fail(code, message)
```

> **注意**：业务异常也会返回 HTTP 200，错误码在 body 的 `code` 里。前端只需判断 `code`。

---

## 三、业务规则写在哪里

这是本项目最需要先记住的一点：**规则集中，不散落**。

### 3.1 论文状态机 —— `domain/ThesisStatus.java`

枚举同时定义三件事：

1. 每个状态的**中文标签**（`getLabel()`）
2. 允许的**下一状态**（`TRANSITIONS` + `canTransitTo()`）
3. 每个目标状态允许的**操作角色**（`TARGET_ROLES` + `roleAllowed()`）

```
DRAFT → PROPOSAL_SUBMITTED → PROPOSAL_APPROVED → MIDTERM_SUBMITTED → MIDTERM_PASSED
     → FINAL_SUBMITTED → REVIEWING → REVIEW_PASSED → DEFENSE_SCHEDULED → DEFENSE_DONE → ARCHIVED

三条退回路径：
  PROPOSAL_SUBMITTED → DRAFT
  MIDTERM_SUBMITTED  → PROPOSAL_APPROVED
  REVIEWING          → FINAL_SUBMITTED
```

所有流转必须经过 `domain/FlowGuard.ensure(from, to, role)`，非法流转抛出 `BizException.flow(...)` 并附带可读原因（含「允许的下一步」列表）。

**各 Service 不重复写状态判断**，这是刻意设计——保证无论从哪个入口触发，规则都一致。

### 3.2 数据范围 —— 分散在各 Service 的可见性方法

| 方法 | 位置 | 职责 |
| --- | --- | --- |
| `ThesisService.applyScope()` | `service/ThesisService.java` | 论文列表按角色限定范围（四角色全覆盖） |
| `ThesisService.requireVisible()` | 同上 | 单条论文的可见性校验，不通过抛 403 |
| `TopicService.requireOwned()` | `service/TopicService.java` | 课题只能由出题教师或管理员操作 |
| `ThesisService.requireAdvisorThesis()` | `service/ThesisService.java` | 开题/中期审核必须是自己指导的论文 |
| `ProposalService.visibleThesisIds()` | `service/ProposalService.java` | 开题列表范围 ⚠️ 见审查报告 P1-1 |
| `MidtermService.visibleThesisIds()` | `service/MidtermService.java` | 中期列表范围 ⚠️ 见审查报告 P1-1 |
| `SelectionService.page()` | `service/SelectionService.java` | 选题列表范围 ⚠️ 见审查报告 P1-1 |

> ⚠️ 标记的三处对 `REVIEWER` 角色没有限定分支，会导致越权读取，详见 [BACKEND_REVIEW.md](BACKEND_REVIEW.md#p1-1-数据权限不一致reviewer-可越权读取全部开题--中期--选题数据)。

### 3.3 成绩计算 —— `domain/ScoreRule.java`

```
总评 = Σ(已评分环节成绩 × 该环节权重) / Σ(已评分环节权重)
```

未评分的环节**不计入分母**，避免「还没答辩就把总分拉到 0」。权重从 `sys_config` 读取（`score.weight.*`），可用管理员在线调整。

等级：≥90 优秀 / ≥80 良好 / ≥70 中等 / ≥60 及格 / <60 不及格（阈值见审查报告 P3-1）。

### 3.4 留痕与通知 —— `service/AuditService.java`

- `log(action, targetType, targetId, detail)` 写 `audit_log`
- `notify(userId, title, content, link, type)` 写 `notification`
- 论文详情页的时间轴就是 `auditService.timeline("THESIS", thesisId)`

由于留痕与业务写操作在**同一事务**内，业务回滚时留痕也会一起回滚，不会出现「操作没成功但有记录」。

---

## 四、15 个 Service 的职责分工

| Service | 行数 | 职责 |
| --- | --- | --- |
| `AuthService` | 101 | 登录、登出、当前用户资料、修改密码 |
| `UserService` | 373 | 账号 / 教师 / 学生 CRUD、下拉选项、展示字段装配 |
| `SystemService` | 231 | 字典类型与字典项、系统配置 upsert |
| `ImportService` | 328 | Excel 模板生成与批量导入（全量校验后落库） |
| `AuditService` | 122 | 操作留痕、站内消息读写 |
| `TopicService` | 214 | 课题 CRUD、发布/关闭、数据范围 |
| `SelectionService` | 296 | 申报、录取、驳回；录取时创建论文并回填导师 |
| `ThesisService` | 351 | 论文列表/详情/时间轴/流转/定稿提交、数据范围 |
| `ProposalService` | 211 | 开题提交与审核 |
| `MidtermService` | 294 | 中期提交与检查、超期预警 |
| `ReviewService` | 299 | 指派（可自动挑任务最少者）、提交评阅、结算推进 |
| `DefenseService` | 422 | 答辩组、成员、编组、成绩录入 |
| `ScoreService` | 189 | 总评重算与查询 |
| `DashboardService` | 276 | 角色化看板指标与待办 |
| `FileService` | 101 | 附件上传、绑定、查询、删除 |

**事务分布**：`DefenseService`(6) / `UserService`(6) / `TopicService`(4) / `SelectionService`(3) / `SystemService`(3) / `ProposalService`·`MidtermService`·`ReviewService`·`ThesisService`(各 2) / `ImportService`·`ScoreService`(各 1)。`AuthService`、`AuditService`、`DashboardService`、`FileService` 无 `@Transactional`——它们的方法只做单次写操作，无需事务。

---

## 五、认证与安全

```
登录:  POST /api/auth/login  (唯一 permitAll 的业务端点)
       ↓ 校验 BCrypt 密码
       ↓ JwtUtil.generate(userId, username, role)  → HS256 签名
       ↓ 返回 token / expireIn / user / student / teacher

后续:  Authorization: Bearer <token>
       ↓ JwtAuthenticationFilter 解析 → 回查 sys_user 校验 status
       ↓ 放入 SecurityContext

登出:  POST /api/auth/logout → Token 进入 TokenBlacklist（内存），立即失效
```

| 机制 | 位置 | 说明 |
| --- | --- | --- |
| 无状态会话 | `SecurityConfig` | `SessionCreationPolicy.STATELESS`，不用 Cookie |
| 密码加密 | `SecurityConfig.passwordEncoder()` | BCrypt |
| 角色级权限 | 20 处 `@PreAuthorize("hasRole('ADMIN')")` | 集中在管理类接口 |
| 数据级权限 | 各 Service 的可见性方法 | 注解无法表达「只能操作自己的」 |
| 账号禁用即时生效 | `JwtAuthenticationFilter` | 每请求回查 `status`，禁用后已签发 Token 立即失效 |
| 登出失效 | `TokenBlacklist` | 内存实现，多实例需换 Redis |
| 上传校验 | `LocalStorageService` | 扩展名白名单 + 大小上限 + UUID 重命名 |

---

## 六、扩展点：常见改动该动哪里

### 6.1 新增一个论文状态

1. `domain/ThesisStatus` 加枚举值 + 标签
2. 在 `static` 块里补 `allow(前置状态, 新状态)` 与 `role(新状态, 角色...)`
3. `frontend/src/constants/index.ts` 的 `THESIS_STATUS` 补标签与标签色 + `step`
4. 如需新页面，`views/` 加页面并挂路由

> 状态机是唯一真源，所以服务层**不需要改**。

### 6.2 新增一个审批环节

1. 建表 + Entity + Mapper（参照 `proposal` 三件套）
2. `domain/ThesisStatus` 加状态与流转
3. 新建 Service（参照 `ProposalService`：`page` / `mine` / `submit` / `review` + 数据范围）
4. Controller 挂接口（参照 `ThesisController` 里的开题分组）
5. 前端加页面与 API 分组

### 6.3 新增一个字典类型

**不需要改代码**。在「系统管理 → 字典管理」新建类型与字典项即可；业务表按需冗余存名称。

### 6.4 把文件存储换成云端

实现 `storage/StorageService` 接口，然后切换配置：

```yaml
thesis:
  storage:
    driver: cloud   # 当前 LocalStorageService 实现 driver() 返回 "local"
```

注意：现在 `LocalStorageService` 是唯一实现且被直接注入，若要支持切换需引入 `@ConditionalOnProperty` 或工厂选择。见审查报告 P3 说明。

### 6.5 新增一个角色

1. `Constants` 加 `ROLE_XXX`
2. `domain/ThesisStatus.TARGET_ROLES` 里给相关目标状态加上该角色
3. 各 Service 的数据范围方法补分支（**重点检查这一步**，漏了就会出现 P1-1 那类越权）
4. 前端路由 `meta.roles` 与菜单配置补上

---

## 七、本地调试速查

```bash
cd backend

# 编译
mvn -q compile

# 打包（含依赖，产出可独立运行的 jar）
mvn clean package -DskipTests
java -jar target/thesis-management.jar

# 开发模式启动（改代码自动重启需自行加 devtools）
mvn spring-boot:run

# 只看某个类的编译错误
mvn -q compile 2>&1 | grep -A3 "ERROR"
```

**配置文件优先级**（后者覆盖前者）：

```
application.yml            仓库中的模板，只含占位符
application-local.yml      本地真实连接信息，已被 .gitignore 忽略
环境变量                     SPRING_PROFILES_ACTIVE=prod 可切换 profile
```

**日志位置**：控制台 + `logging.file.name` 配置的文件（默认 `logs/thesis-management.log`）。

**上传文件目录**：`backend/storage/uploads/{业务类型}/{yyyyMM}/`，启动时自动创建。

---

## 八、相关文档

| 文档 | 内容 |
| --- | --- |
| [BACKEND_REVIEW.md](BACKEND_REVIEW.md) | **代码审查报告**：分级问题清单与修复建议（本次交付重点） |
| [API.md](API.md) | 接口文档：90 个端点、数据权限、时序、cURL |
| [DATABASE.md](DATABASE.md) | 20 张表、实体关系、索引、设计取舍 |
| [PROJECT_PLAN.md](PROJECT_PLAN.md) | 项目计划与里程碑 |
