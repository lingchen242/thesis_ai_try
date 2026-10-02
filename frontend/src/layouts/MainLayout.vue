<template>
  <el-container class="app-layout">
    <!-- 桌面端：常驻侧边栏 -->
    <el-aside
      v-if="isDesktop"
      class="app-aside"
      :width="collapsed ? 'var(--app-sidebar-collapsed)' : 'var(--app-sidebar-width)'"
    >
      <div class="logo">
        <el-icon :size="20"><Reading /></el-icon>
        <span v-show="!collapsed">毕业论文管理系统</span>
      </div>
      <el-scrollbar>
        <el-menu
          :default-active="activeMenu"
          :collapse="collapsed"
          :collapse-transition="false"
          router
          unique-opened
        >
          <template v-for="item in visibleMenu" :key="item.path || item.title">
            <el-sub-menu v-if="item.children" :index="item.title">
              <template #title>
                <el-icon><component :is="item.icon" /></el-icon>
                <span>{{ item.title }}</span>
              </template>
              <el-menu-item v-for="child in item.children" :key="child.path" :index="child.path">
                <el-icon><component :is="child.icon" /></el-icon>
                <template #title>{{ child.title }}</template>
              </el-menu-item>
            </el-sub-menu>
            <el-menu-item v-else :index="item.path">
              <el-icon><component :is="item.icon" /></el-icon>
              <template #title>{{ item.title }}</template>
            </el-menu-item>
          </template>
        </el-menu>
      </el-scrollbar>
    </el-aside>

    <!-- 小屏：抽屉菜单 -->
    <el-drawer
      v-else
      v-model="drawerVisible"
      direction="ltr"
      size="240px"
      :with-header="false"
      class="menu-drawer"
    >
      <div class="logo">
        <el-icon :size="20"><Reading /></el-icon>
        <span>毕业论文管理系统</span>
      </div>
      <el-menu :default-active="activeMenu" router unique-opened @select="drawerVisible = false">
        <template v-for="item in visibleMenu" :key="item.path || item.title">
          <el-sub-menu v-if="item.children" :index="item.title">
            <template #title>
              <el-icon><component :is="item.icon" /></el-icon>
              <span>{{ item.title }}</span>
            </template>
            <el-menu-item v-for="child in item.children" :key="child.path" :index="child.path">
              <el-icon><component :is="child.icon" /></el-icon>
              <template #title>{{ child.title }}</template>
            </el-menu-item>
          </el-sub-menu>
          <el-menu-item v-else :index="item.path">
            <el-icon><component :is="item.icon" /></el-icon>
            <template #title>{{ item.title }}</template>
          </el-menu-item>
        </template>
      </el-menu>
    </el-drawer>

    <el-container>
      <el-header class="app-header" height="56px">
        <div class="app-header-left">
          <el-button text @click="toggleMenu">
            <el-icon :size="18"><Expand v-if="collapsed || !isDesktop" /><Fold v-else /></el-icon>
          </el-button>
          <span class="page-title">{{ pageTitle }}</span>
        </div>
        <div class="app-header-right">
          <el-badge :value="userStore.unread" :hidden="!userStore.unread" :max="99">
            <el-button text @click="goNotices">
              <el-icon :size="18"><Bell /></el-icon>
            </el-button>
          </el-badge>
          <el-dropdown @command="onCommand">
            <span class="user-entry">
              <el-icon><UserFilled /></el-icon>
              <span class="name">{{ userStore.displayName }}</span>
              <el-tag size="small" effect="plain">{{ roleLabel }}</el-tag>
            </span>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="profile">个人中心</el-dropdown-item>
                <el-dropdown-item command="notices">我的消息</el-dropdown-item>
                <el-dropdown-item divided command="logout">退出登录</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </el-header>

      <el-main class="app-main">
        <router-view />
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessageBox } from 'element-plus'
import { noticeApi } from '@/api'
import { useUserStore } from '@/stores/user'
import { useResponsive } from '@/composables/useResponsive'
import { ROLE_LABEL } from '@/constants'

interface MenuItem {
  path?: string
  title: string
  icon: string
  roles?: string[]
  children?: MenuItem[]
}

const MENU: MenuItem[] = [
  { path: '/dashboard', title: '数据看板', icon: 'DataBoard' },
  { path: '/thesis/mine', title: '我的论文', icon: 'Notebook', roles: ['STUDENT'] },
  { path: '/thesis/list', title: '论文管理', icon: 'Files', roles: ['ADMIN', 'ADVISOR', 'REVIEWER'] },
  { path: '/topics', title: '课题管理', icon: 'Collection' },
  { path: '/selections', title: '选题管理', icon: 'Promotion' },
  { path: '/proposals', title: '开题管理', icon: 'Document' },
  { path: '/midterms', title: '中期检查', icon: 'Odometer' },
  { path: '/finals', title: '论文定稿', icon: 'DocumentChecked' },
  { path: '/reviews', title: '论文评阅', icon: 'EditPen' },
  { path: '/defense', title: '答辩管理', icon: 'UserFilled' },
  { path: '/scores', title: '成绩管理', icon: 'Trophy' },
  {
    title: '基础数据',
    icon: 'Grid',
    roles: ['ADMIN'],
    children: [
      { path: '/students', title: '学生管理', icon: 'User' },
      { path: '/teachers', title: '教师管理', icon: 'Avatar' }
    ]
  },
  {
    title: '系统管理',
    icon: 'Tools',
    roles: ['ADMIN'],
    children: [
      { path: '/system/users', title: '账号管理', icon: 'Key' },
      { path: '/system/dict', title: '字典管理', icon: 'Coin' },
      { path: '/system/config', title: '系统配置', icon: 'Setting' },
      { path: '/system/import', title: '批量导入', icon: 'Upload' }
    ]
  }
]

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()
const { isDesktop } = useResponsive()

const collapsed = ref(false)
const drawerVisible = ref(false)

const roleLabel = computed(() => ROLE_LABEL[userStore.role] ?? '')
const pageTitle = computed(() => (route.meta?.title as string) ?? '')
const activeMenu = computed(() => route.path)

/** 首页/详情页没有直接命中的菜单项时，兜底高亮对应父级 */
const visibleMenu = computed(() => filterByRole(MENU))

function filterByRole(items: MenuItem[]): MenuItem[] {
  return items
    .filter((item) => !item.roles || item.roles.includes(userStore.role))
    .map((item) => ({
      ...item,
      children: item.children ? filterByRole(item.children) : undefined
    }))
    .filter((item) => !item.children || item.children.length > 0)
}

function toggleMenu() {
  if (isDesktop.value) {
    collapsed.value = !collapsed.value
  } else {
    drawerVisible.value = true
  }
}

async function loadUnread() {
  if (!userStore.token) return
  try {
    userStore.unread = await noticeApi.unreadCount()
  } catch {
    // 忽略：未登录或接口异常时不影响页面
  }
}

function goNotices() {
  router.push('/notices')
}

async function onCommand(command: string) {
  if (command === 'profile') {
    router.push('/profile')
  } else if (command === 'notices') {
    router.push('/notices')
  } else if (command === 'logout') {
    await ElMessageBox.confirm('确定要退出登录吗？', '提示', { type: 'warning' })
    await userStore.logout()
    router.replace('/login')
  }
}

watch(
  () => route.path,
  () => {
    if (!isDesktop.value) {
      drawerVisible.value = false
    }
    if (route.path === '/notices') {
      userStore.unread = 0
    }
  }
)

onMounted(loadUnread)

// 每 60 秒刷新一次未读消息数
setInterval(loadUnread, 60000)
</script>

<style scoped>
.page-title {
  font-size: 15px;
  font-weight: 500;
}

.user-entry {
  display: flex;
  align-items: center;
  gap: 6px;
  cursor: pointer;
  outline: none;
}

.user-entry .name {
  font-size: 14px;
}

:deep(.el-menu) {
  border-right: none;
}

:deep(.menu-drawer .el-drawer__body) {
  padding: 0;
}

@media (max-width: 768px) {
  .user-entry .name {
    display: none;
  }
  .page-title {
    font-size: 14px;
  }
}
</style>
