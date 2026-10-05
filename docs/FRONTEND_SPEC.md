# 前端开发规范

本文档是企业级前端规范在**本项目**的落地版本。规范依据见文末，凡与通用规范不一致的地方，都在「[与通用规范的差异及理由](#十六与通用规范的差异及理由)」中给出了理由。

| 项 | 值 |
| --- | --- |
| 适用范围 | `frontend/` 目录下的全部代码 |
| 技术栈 | Vue 3（组合式 API）+ TypeScript + Vite + Element Plus + Pinia + Vue Router |
| 格式基线 | 2 空格缩进 · 单引号 · 无分号 · LF · 文件末尾空行 |
| 强制工具 | `.editorconfig`（根目录）、`frontend/.prettierrc.json` |
| 代码位置 | `frontend/src/` |

---

## 一、目录结构

```
frontend/
├── .prettierrc.json          # 格式化配置（单一真源）
├── .prettierignore
├── vite.config.ts
├── index.html
└── src/
    ├── main.ts               # 应用入口：注册 Pinia / Router / Element Plus / 全局图标
    ├── App.vue               # 根组件，只放 <router-view />
    ├── api/                  # 接口层
    │   ├── request.ts        # axios 实例、拦截器、泛型请求封装
    │   └── index.ts          # 按业务域分组的接口集合
    ├── components/           # 跨页面复用的公共组件
    ├── composables/          # 组合式函数（响应式、字典等）
    ├── constants/            # 常量与文案映射表
    ├── layouts/              # 布局组件
    ├── router/               # 路由表与导航守卫
    ├── stores/               # Pinia 状态
    ├── styles/               # 全局样式
    │   ├── variables.css     # 设计令牌（颜色 / 尺寸）—— 唯一允许出现色值的文件
    │   └── index.css         # 全局基础样式与断点规则
    ├── types/                # 全局 TypeScript 类型
    ├── utils/                # 与框架无关的工具模块
    └── views/                # 页面，按业务模块建目录
        ├── login/index.vue
        ├── dashboard/index.vue
        ├── topic/index.vue
        ├── thesis/{list,mine,detail}.vue
        └── system/{user,dict,config,import}/index.vue
```

**分层依赖方向**（禁止反向依赖，避免循环引用）：

```
views → components / composables / stores / api → utils / constants / types
```

- `utils/`、`constants/`、`types/` 是**叶子层**，只能依赖彼此，不得依赖 `stores/`、`api/`、`views/`。
- 页面特有逻辑写在 `views/<模块>/` 内，通用后才上提到 `components/` 或 `composables/`。

---

## 二、文件命名

| 类型 | 规则 | 示例 |
| --- | --- | --- |
| Vue 组件 | 大驼峰 PascalCase | `StatusTag.vue`、`FileUploader.vue`、`MainLayout.vue` |
| 页面入口 | 固定 `index.vue` | `views/topic/index.vue` |
| 页面目录 | 小写短横线（多单词时） | `views/system/config/index.vue` |
| TS 模块 | 小驼峰 camelCase | `auth-storage.ts`、`useResponsive.ts` |
| 组合式函数 | `use` 前缀 + 大驼峰（文件名小写短横线） | `useResponsive.ts`、`useDict.ts` |
| 样式文件 | 小写短横线 | `variables.css`、`index.css` |

> 组合式函数导出 `useXxx`，文件名 `use-xxx.ts` 或 `useXxx.ts` 均可，本项目统一用 `useXxx.ts`（如 `useResponsive.ts`）。

---

## 三、命名规范

| 对象 | 规则 | 示例 |
| --- | --- | --- |
| 变量 | 小驼峰 | `topicList`、`activeTab` |
| 常量（模块级、不可变） | 全大写下划线 | `TOKEN_KEY`、`THESIS_STATUS`、`BIZ_TYPE` |
| 布尔变量 | `is` / `has` / `should` / `can` 开头 | `isMobile`、`hasThesis`、`canSubmit`、`canReview` |
| 函数 | 动词开头 | `load()`、`saveTopic()`、`openForm()`、`resetPassword()` |
| 事件处理 | `handle` / `on` 前缀 | `onCommand()`、`onFileChange()`、`onTabChange()` |
| 计算属性 | 名词或形容词，不带动词 | `statCards`、`activeStep`、`canReview` |
| 模板引用 | 名词 + `Ref` 后缀 | `formRef`、`tableRef` |
| 类型 / 接口 | 大驼峰 | `Topic`、`PageResult<T>`、`DictItem` |
| CSS 类 | 小写短横线 | `app-header`、`stat-card`、`page-card` |
| CSS 变量 | `--app-*`（本项目自定义）/ `--el-*`（Element Plus） | `--app-bg`、`--el-color-primary` |

**魔法值必须抽为常量**。例如论文状态中文名不写在模板里，而由 `constants/index.ts` 的 `THESIS_STATUS` 映射 + `<StatusTag>` 组件统一渲染。

---

## 四、TypeScript 规范

1. **禁止 `any`**：不确定类型用 `unknown`，或定义明确的接口。当前全仓 `any` 数量为 **0**。
2. **所有接口报文必须有类型**，集中定义在 `src/types/index.ts`。
3. **函数参数与返回值标注类型**；有返回值的工具函数不省略返回类型。
4. **优先使用 `type` / `interface` 复用类型**，不重复声明结构相同的类型。
5. **避免非空断言 `!`**：优先用可选链 `?.` 与空值合并 `??`。

```ts
// ✅ 推荐
interface PageQuery {
  pageNum?: number
  pageSize?: number
  keyword?: string
  [key: string]: unknown
}

async function load(): Promise<void> {
  const res = await topicApi.page({ ...query })
  list.value = res.records
  total.value = res.total
}

// ❌ 禁止
const data: any = await http.get('/topics')
list.value = data.records!
```

---

## 五、Vue 组件规范

### 5.1 统一使用组合式 API + `<script setup lang="ts">`

```vue
<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import type { Topic } from '@/types'

const props = defineProps<{ status?: string }>()
const emit = defineEmits<{ (e: 'update:modelValue', value: Topic[]): void }>()
</script>
```

### 5.2 组件名必须多单词

避免与 HTML 元素重名。<br>
✅ `StatusTag`、`FileUploader`、`MainLayout`　❌ `Header`、`Table`、`Button`

### 5.3 props 必须定义类型与默认值

```ts
const props = withDefaults(
  defineProps<{ modelValue: Attachment[]; bizType: string; multiple?: boolean; maxSize?: number }>(),
  { multiple: false, maxSize: 20 }
)
```

### 5.4 指令使用缩写

`v-bind` → `:`，`v-on` → `@`，`v-slot` → `#`

```vue
<el-table-column #default="{ row }">…</el-table-column>
```

### 5.5 `computed` 与 `watch`

- **优先 `computed`**：计算属性里**禁止副作用**（不得发请求、改外部状态）。
- `watch` 只用于「响应变化触发副作用」，需明确写出 `immediate` / `deep` 的意图。

```ts
// ✅ 派生状态用 computed
const activeStep = computed(() => (THESIS_STATUS[thesis.value?.status ?? '']?.step ?? 1) - 1)

// ✅ 副作用用 watch
watch(() => route.path, () => { if (!isDesktop.value) drawerVisible.value = false })
```

### 5.6 列表渲染必须有稳定的 `key`

使用业务主键，禁止用索引：

```vue
<div v-for="item in list" :key="item.id">
```

### 5.7 权限控制写在模板条件里，而不是靠隐藏菜单

菜单隐藏只是体验优化，**真正的权限由后端接口裁决**（返回 `403`）。前端通过 `userStore.isAdmin` 等计算属性控制按钮显隐：

```vue
<el-button v-if="userStore.isAdmin" @click="archive">归档</el-button>
```

---

## 六、样式规范

### 6.1 颜色必须使用变量，禁止硬编码（强制）

| 场景 | 用法 |
| --- | --- |
| 与 Element Plus 调色板一致的色值 | 直接引用 `var(--el-*)` |
| Element Plus 未覆盖的自定义色 | 在 `styles/variables.css` 定义 `--app-*` 后再引用 |

```css
/* ✅ 推荐 */
.stat-card .value.primary { color: var(--el-color-primary); }
.mobile-card { background: var(--el-bg-color); border-radius: var(--app-card-radius); }

/* ❌ 禁止 */
.stat-card .value.primary { color: #409eff; }
```

**唯一的例外**：`src/styles/variables.css` 中的令牌定义本身就是色值出现的地方。

常用对照表：

| 语义 | 变量 |
| --- | --- |
| 主色 / 成功 / 警告 / 危险 | `--el-color-primary` / `--el-color-success` / `--el-color-warning` / `--el-color-danger` |
| 一级 / 常规 / 次要 / 禁用文字 | `--el-text-color-primary` / `-regular` / `-secondary` / `-disabled` |
| 常规 / 浅 / 更浅描边 | `--el-border-color-light` / `-lighter` |
| 卡片底色 / 页面底色 | `--el-bg-color` / `--el-fill-color-light` |
| 主色浅底（选中态） | `--el-color-primary-light-9` |

### 6.2 禁止行内样式

```vue
<!-- ✅ 推荐 -->
<span class="total-score">{{ score.totalScore }}</span>

<!-- ❌ 禁止 -->
<span style="color: #f56c6c; font-weight: 600">{{ score.totalScore }}</span>
```

> `style` 只允许用于**运行时动态计算且无法用类表达**的值，例如 `:style="{ height: chartHeight }"`。

### 6.3 选择器嵌套不超过 3 层

```css
/* ✅ */
.notice-item .title { font-weight: 500; }

/* ❌ 超过 3 层 */
.app-layout .app-main .notice-item .title span { … }
```

### 6.4 组件样式一律加 `scoped`

```vue
<style scoped>
.total-score { … }
</style>
```

需要穿透 Element Plus 内部样式时使用 `:deep()`，并写清注释说明原因。

### 6.5 通用样式抽到全局

同一个类在 ≥2 处出现，就应上提到 `styles/index.css`（如 `.text-muted`、`.page-card`、`.total-score`）。

### 6.6 响应式断点（与 `composables/useResponsive.ts` 保持一致）

| 断点 | 宽度 | 表现 |
| --- | --- | --- |
| xs | `< 768px` | 抽屉菜单；表格隐藏次要列；表单单列；抽屉全屏 |
| sm | `768 ~ 992px` | 抽屉菜单；表格精简列 |
| md | `992 ~ 1200px` | 侧边栏常驻；完整列 |
| lg | `> 1200px` | 侧边栏常驻；完整列 |

断点判断统一走 `useResponsive()`，**不要在组件里手写 `window.innerWidth` 比较**：

```ts
const { isMobile, isDesktop } = useResponsive()
```

```vue
<el-table-column v-if="!isMobile" prop="studentNo" label="学号" width="120" />
```

---

## 七、接口层规范

### 7.1 业务代码不直接使用 axios

所有请求经 `api/index.ts` 暴露的领域方法：

```ts
import { topicApi, thesisApi } from '@/api'

const page = await topicApi.page({ pageNum: 1, pageSize: 10 })
const saved = await topicApi.create(form)
```

### 7.2 `request.ts` 统一处理横切关注点

| 关注点 | 实现 |
| --- | --- |
| Token 注入 | 请求拦截器读取 `utils/auth-storage.ts` 的 `getToken()` |
| 响应解包 | 泛型 `request<T>()` 直接返回 `data` 字段 |
| 业务错误提示 | `code !== 0` 时自动 `ElMessage.error(message)` |
| 登录失效 | `code === 401` 时清登录态并跳登录页，带 `redirect` |
| 文件上传 | `http.upload(url, file, params)` 自动组装 `FormData` |
| 文件下载 | `http.download(url, params, filename)` 触发浏览器下载；并识别服务端返回的 JSON 错误体，避免把错误信息存成打不开的文件 |

**因此业务代码通常不需要 try/catch 提示错误**；只有需要「失败后阻止后续逻辑」时才捕获（如 `formRef.validate().catch(() => false)`）。

### 7.3 认证数据的读写必须经过 `utils/auth-storage.ts`

Token 与用户资料的 localStorage 键名由该模块**唯一持有**，禁止在任何其它文件里直接写 `localStorage.getItem('xxx')`。

> 这条规范来自一次真实事故：请求层读 `'token'`、状态层写 `'thesis_token'`，导致登录成功后所有请求都因缺少 `Authorization` 头被判未登录。收敛到单一模块后，此类问题从结构上不可能再发生。

### 7.4 接口分组命名

`<业务域>Api`，方法名用动词：`page` / `detail` / `create` / `update` / `remove` / `submit` / `review`。

---

## 八、状态管理规范（Pinia）

1. **按领域拆分 store**，当前仅两个：`stores/user.ts`（登录态与身份）、`stores/dict.ts`（字典缓存）。
2. **一律使用 setup 语法**（`defineStore('name', () => { … })`）。
3. **需要持久化的状态显式落盘**，通过 `utils/auth-storage.ts`，不做全量自动持久化。
4. **字典按 `typeCode` 缓存**，避免每个下拉框重复请求；字典变更后调用 `dictStore.clear()` 失效缓存。
5. **不在 store 里写业务提示**，只维护状态与数据获取。

```ts
const store = useDictStore()
const colleges = await store.loadRoot('COLLEGE')      // 顶级
const majors = await store.loadChildren('MAJOR', id)  // 级联子级
store.clear('CLASS')                                  // 变更后失效缓存
```

---

## 九、路由规范

1. **所有页面组件懒加载**：`component: () => import('@/views/xxx/index.vue')`。
2. **路由元信息承载权限与菜单**：

```ts
{
  path: 'system/dict',
  name: 'SystemDict',
  component: () => import('@/views/system/dict/index.vue'),
  meta: { title: '字典管理', icon: 'Coin', roles: ['ADMIN'] }
}
```

| meta 字段 | 说明 |
| --- | --- |
| `title` | 菜单标题 + 浏览器标题 |
| `icon` | Element Plus 图标组件名 |
| `roles` | 可访问角色；缺省表示所有登录用户 |
| `hidden` | 不在侧边菜单显示（详情页等） |

3. **守卫只做三件事**：未登录跳登录页、刷新后恢复用户资料、角色不匹配时拦截。

---

## 十、Git 提交规范

```
type(scope): 简洁描述
```

| type | 含义 |
| --- | --- |
| `feat` | 新功能 |
| `fix` | 修复缺陷 |
| `docs` | 文档 |
| `style` | 格式调整（不影响逻辑） |
| `refactor` | 重构 |
| `perf` | 性能优化 |
| `test` | 测试 |
| `chore` | 构建 / 工具 / 依赖 |

- `scope` 用模块名：`fix(frontend)`、`feat(backend)`、`docs(api)`
- 描述用**祈使句、不带句号**，中文可直接书写
- 一个提交只做一件事；破坏性变更在正文中说明

实例（本项目真实提交）：

```
fix: 修复登录成功后立即提示「登录状态已失效」
feat(frontend): Vue3 + Vite + Element Plus 前端完整实现
chore(config): 数据库连接信息迁移到 local profile，避免真实凭据进入版本控制
```

---

## 十一、代码格式与工具链

### 11.1 格式基线

| 项 | 值 |
| --- | --- |
| 缩进 | 2 空格（Java 为 4 空格） |
| 引号 | 单引号 |
| 分号 | **不写**（见「与通用规范的差异」） |
| 行宽 | 100 |
| 换行符 | LF |
| 行尾空格 | 去除（Markdown 除外） |
| 文件末尾 | 保留一个空行 |

由 `.editorconfig`（根目录）与 `frontend/.prettierrc.json` 声明，主流编辑器与 IDE 均会自动识别。

### 11.2 ESLint（可选启用）

当前项目**未安装 ESLint**，避免给已通过验证的构建引入额外依赖。若需强制校验，执行：

```bash
cd frontend
npm i -D eslint @eslint/js typescript-eslint eslint-plugin-vue globals
```

并新建 `frontend/eslint.config.js`：

```js
import js from '@eslint/js'
import globals from 'globals'
import tseslint from 'typescript-eslint'
import pluginVue from 'eslint-plugin-vue'

export default tseslint.config(
  { ignores: ['dist', 'node_modules'] },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  ...pluginVue.configs['flat/recommended'],
  {
    languageOptions: {
      globals: { ...globals.browser },
      parserOptions: { parser: tseslint.parser }
    },
    rules: {
      '@typescript-eslint/no-explicit-any': 'error',
      'no-console': ['error', { allow: ['warn', 'error'] }],
      'no-var': 'error',
      'prefer-const': 'error',
      'vue/multi-word-component-names': 'error',
      'vue/require-default-prop': 'off'
    }
  }
)
```

---

## 十二、性能规范

| 措施 | 本项目做法 |
| --- | --- |
| 路由懒加载 | 全部页面 `() => import(...)`，构建后按页拆包 |
| 图表按需引入 | `ChartBox.vue` 只注册用到的 ECharts 模块与 Canvas 渲染器 |
| 图标按需注册 | `main.ts` 中一次性注册 Element Plus 图标，模板直接用组件名 |
| 字典缓存 | `useDictStore` 按 `typeCode` 缓存，避免重复请求 |
| 详情页请求合并 | `GET /theses/{id}/detail` 一次返回详情页全部数据，替代 6 次请求 |
| 大列表分页 | 统一分页，`pageSize` 上限 200；未读消息限制 200 条 |
| 高频事件 | `resize` 监听带 `{ passive: true }`；未读轮询间隔 60 秒 |

**未做**（数据量仍小的场景，暂不引入）：虚拟滚动、图片懒加载、WebP 转换。数据量增长到千级列表时再补。

---

## 十三、安全规范

| 要求 | 落地方式 |
| --- | --- |
| XSS 防护 | 全部使用 Vue 模板插值（自动转义），**禁止 `v-html`**；当前全仓 `v-html` 数量为 0 |
| CSRF | 后端为无状态 JWT，不使用 Cookie 会话，天然免疫；请求头携带 Token |
| 敏感信息 | **真实数据库凭据放 `application-local.yml`（已 gitignore）**，仓库里只有占位符 |
| Token 存储 | 存 localStorage（内部管理系统的常规取舍）；不在 URL、日志、控制台中输出 |
| 权限控制 | 菜单按角色渲染 + 后端接口二次裁决，前端隐藏不等于越权 |
| 附件上传 | 前端做类型与大小预校验，后端用 UUID 重命名并校验扩展名，不信任客户端文件名 |
| 生产构建 | 不输出 `console`（当前全仓 `console` 数量为 0） |

---

## 十四、规范自查清单

提交前可执行以下命令自检，全部通过即视为符合本规范：

```bash
cd frontend

# 1. 类型检查（必须 0 错误）
npx vue-tsc --noEmit

# 2. 生产构建
npm run build

# 3. 禁止 any
grep -rn ": any\b\|as any" src/ || echo "无 any ✓"

# 4. 禁止 console
grep -rn "console\." src/ || echo "无 console ✓"

# 5. 禁止 var
grep -rnE "\bvar\b\s+[a-zA-Z_$]" src/ || echo "无 var ✓"

# 6. 禁止 v-html
grep -rn "v-html" src/ || echo "无 v-html ✓"

# 7. 禁止硬编码颜色（\b 用于排除 #default 模板语法误报）
grep -rnoE "#[0-9a-fA-F]{3,6}\b" src/ --include=*.vue --include=*.css \
  | grep -v "src/styles/variables.css" || echo "无硬编码颜色 ✓"

# 8. 禁止行内颜色样式
grep -rnE 'style="[^"]*(color|background)' src/ --include=*.vue || echo "无行内颜色 ✓"

# 9. localStorage 只能出现在 auth-storage.ts
grep -rn "localStorage" src/ | grep -v "utils/auth-storage.ts" || echo "读写已收敛 ✓"
```

---

## 十五、合规现状

以下为**实际执行结果**，非目标值：

| 检查项 | 结果 |
| --- | --- |
| `vue-tsc --noEmit` | ✅ 0 错误 |
| `vite build` | ✅ 通过（约 6s） |
| `any` | ✅ 0 处 |
| `console` | ✅ 0 处 |
| `var` | ✅ 0 处 |
| `v-html` | ✅ 0 处 |
| 硬编码颜色 | ✅ 0 处（色值仅存在于 `styles/variables.css` 的 3 个令牌定义） |
| 行内颜色样式 | ✅ 0 处 |
| `localStorage` 直读 | ✅ 0 处（仅 `utils/auth-storage.ts`） |
| 组件命名 PascalCase | ✅ 全部符合 |
| 路由懒加载 | ✅ 全部页面 |

> 颜色令牌化改造已完成并通过**视觉回归验证**：改造前后生产构建产物的颜色集合完全一致（80 个色值，diff 为空），即样式无任何视觉变化。

---

## 十六、与通用规范的差异及理由

| 通用规范 | 本项目 | 理由 |
| --- | --- | --- |
| 语句末尾加分号 | **不写分号** | 全项目统一为无分号风格，由 Prettier 固化。规范的核心目标是团队一致，二者取其一即可；中途全量加分会造成大量无意义 diff，且与现有已交付代码冲突。若团队决定改为加分号，只需把 `.prettierrc.json` 的 `semi` 改为 `true` 后统一格式化一次。 |
| 页面目录名为 `pages/` | 使用 `views/` | `views/` 更贴近管理后台的习惯叫法，且项目已按此落地；两者含义等价，改名收益低于改动成本。 |
| 状态目录名为 `store/` | 使用 `stores/` | 与 Pinia 官方文档示例一致（`defineStore` → `stores/`）。 |
| 颜色令牌集中在 `variables/` + `mixins/` | 单一 `styles/variables.css` | 项目未使用 Sass，纯 CSS 变量即可满足；引入预处理器会增加构建依赖而无明显收益。 |
| 单位优先 `rem` / `vh` / `%` | 以 `px` 为主 | 内部管理系统不需要基于根字号的整体缩放；断点适配已由 `useResponsive()` 与媒体查询覆盖，用 `px` 更直观可控。 |
| 强制 ESLint + Prettier | **仅启用 Prettier 与 EditorConfig，ESLint 可选** | 不引入未验证的依赖，保证 `npm run build` 的稳定性；ESLint 配置已在 §11.2 备好，需要时可直接启用。 |

---

## 附：规范依据

本规范基于企业级前端开发规范整理，覆盖项目结构、文件命名、HTML、CSS/SCSS、JavaScript、TypeScript、Vue、Git、ESLint/Prettier、构建与性能、安全共 11 个方面，并结合本项目的实际技术栈与已交付代码做了落地裁剪。
