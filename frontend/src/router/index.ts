import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router'
import { ElMessage } from 'element-plus'
import { useUserStore } from '@/stores/user'
import type { Role } from '@/types'

/**
 * meta 约定：
 *   title   菜单标题（同时用于面包屑与页签标题）
 *   icon    Element Plus 图标组件名
 *   roles   可见 / 可访问的角色，缺省表示所有登录用户
 *   hidden  不在侧边菜单中显示（如详情页）
 *   group   菜单分组标题，渲染时按顺序插入分组标题
 */
const routes: RouteRecordRaw[] = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/login/index.vue'),
    meta: { title: '登录', hidden: true }
  },
  {
    path: '/',
    component: () => import('@/layouts/MainLayout.vue'),
    redirect: '/dashboard',
    children: [
      {
        path: 'dashboard',
        name: 'Dashboard',
        component: () => import('@/views/dashboard/index.vue'),
        meta: { title: '数据看板', icon: 'DataBoard' }
      },
      {
        path: 'thesis/mine',
        name: 'MyThesis',
        component: () => import('@/views/thesis/mine.vue'),
        meta: { title: '我的论文', icon: 'Notebook', roles: ['STUDENT'] }
      },
      {
        path: 'thesis/list',
        name: 'ThesisList',
        component: () => import('@/views/thesis/list.vue'),
        meta: { title: '论文管理', icon: 'Files', roles: ['ADMIN', 'ADVISOR', 'REVIEWER'] }
      },
      {
        path: 'thesis/detail/:id',
        name: 'ThesisDetail',
        component: () => import('@/views/thesis/detail.vue'),
        meta: { title: '论文详情', hidden: true }
      },
      {
        path: 'topics',
        name: 'Topics',
        component: () => import('@/views/topic/index.vue'),
        meta: { title: '课题管理', icon: 'Collection' }
      },
      {
        path: 'selections',
        name: 'Selections',
        component: () => import('@/views/selection/index.vue'),
        meta: { title: '选题管理', icon: 'Promotion' }
      },
      {
        path: 'proposals',
        name: 'Proposals',
        component: () => import('@/views/proposal/index.vue'),
        meta: { title: '开题管理', icon: 'Document' }
      },
      {
        path: 'midterms',
        name: 'Midterms',
        component: () => import('@/views/midterm/index.vue'),
        meta: { title: '中期检查', icon: 'Odometer' }
      },
      {
        path: 'finals',
        name: 'Finals',
        component: () => import('@/views/final/index.vue'),
        meta: { title: '论文定稿', icon: 'DocumentChecked' }
      },
      {
        path: 'reviews',
        name: 'Reviews',
        component: () => import('@/views/review/index.vue'),
        meta: { title: '论文评阅', icon: 'EditPen' }
      },
      {
        path: 'defense',
        name: 'Defense',
        component: () => import('@/views/defense/index.vue'),
        meta: { title: '答辩管理', icon: 'UserFilled' }
      },
      {
        path: 'scores',
        name: 'Scores',
        component: () => import('@/views/score/index.vue'),
        meta: { title: '成绩管理', icon: 'Trophy' }
      },
      {
        path: 'students',
        name: 'Students',
        component: () => import('@/views/base/student/index.vue'),
        meta: { title: '学生管理', icon: 'User', roles: ['ADMIN'] }
      },
      {
        path: 'teachers',
        name: 'Teachers',
        component: () => import('@/views/base/teacher/index.vue'),
        meta: { title: '教师管理', icon: 'Avatar', roles: ['ADMIN'] }
      },
      {
        path: 'system/users',
        name: 'SystemUsers',
        component: () => import('@/views/system/user/index.vue'),
        meta: { title: '账号管理', icon: 'Key', roles: ['ADMIN'] }
      },
      {
        path: 'system/dict',
        name: 'SystemDict',
        component: () => import('@/views/system/dict/index.vue'),
        meta: { title: '字典管理', icon: 'Coin', roles: ['ADMIN'] }
      },
      {
        path: 'system/config',
        name: 'SystemConfig',
        component: () => import('@/views/system/config/index.vue'),
        meta: { title: '系统配置', icon: 'Setting', roles: ['ADMIN'] }
      },
      {
        path: 'system/import',
        name: 'SystemImport',
        component: () => import('@/views/system/import/index.vue'),
        meta: { title: '批量导入', icon: 'Upload', roles: ['ADMIN'] }
      },
      {
        path: 'notices',
        name: 'Notices',
        component: () => import('@/views/notice/index.vue'),
        meta: { title: '我的消息', icon: 'Bell', hidden: true }
      },
      {
        path: 'profile',
        name: 'Profile',
        component: () => import('@/views/profile/index.vue'),
        meta: { title: '个人中心', icon: 'User', hidden: true }
      }
    ]
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'NotFound',
    component: () => import('@/views/error/404.vue'),
    meta: { title: '页面不存在', hidden: true }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior: () => ({ top: 0 })
})

const WHITE_LIST = ['/login']

router.beforeEach(async (to) => {
  const userStore = useUserStore()
  document.title = to.meta?.title ? `${to.meta.title} · 毕业论文管理系统` : '毕业论文管理系统'

  if (WHITE_LIST.includes(to.path)) {
    return true
  }
  if (!userStore.token) {
    return { path: '/login', query: { redirect: to.fullPath } }
  }
  // 刷新后恢复用户资料
  if (!userStore.user) {
    try {
      await userStore.loadProfile()
    } catch {
      userStore.clear()
      return { path: '/login', query: { redirect: to.fullPath } }
    }
  }
  // 角色校验
  const roles = to.meta?.roles as Role[] | undefined
  if (roles && roles.length > 0 && !roles.includes(userStore.role)) {
    ElMessage.error('当前角色无权访问该页面')
    return { path: '/dashboard' }
  }
  return true
})

export default router
