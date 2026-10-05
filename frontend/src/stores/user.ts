import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import { authApi } from '@/api'
import { clearAuth, getProfile, getToken, setProfile, setToken } from '@/utils/auth-storage'
import type { Role, Student, SysUser, Teacher } from '@/types'

export interface StoredProfile {
  user: SysUser
  student?: Student
  teacher?: Teacher
}

export const useUserStore = defineStore('user', () => {
  const token = ref<string>(getToken())
  const user = ref<SysUser | null>(null)
  const student = ref<Student | null>(null)
  const teacher = ref<Teacher | null>(null)
  const unread = ref<number>(0)

  // 刷新页面后先从本地缓存恢复，避免菜单与身份校验出现闪烁
  const cached = getProfile()
  if (cached?.user) {
    user.value = cached.user
    student.value = cached.student ?? null
    teacher.value = cached.teacher ?? null
  }

  const role = computed<Role>(() => (user.value?.role ?? 'STUDENT') as Role)
  const isAdmin = computed(() => role.value === 'ADMIN')
  const isStudent = computed(() => role.value === 'STUDENT')
  const isAdvisor = computed(() => role.value === 'ADVISOR')
  const isReviewer = computed(() => role.value === 'REVIEWER')
  const displayName = computed(() => user.value?.realName || user.value?.username || '')
  /** 学生/教师档案 ID（业务接口常用） */
  const profileId = computed(() => student.value?.id ?? teacher.value?.id ?? null)

  function apply(payload: StoredProfile) {
    user.value = payload.user
    student.value = payload.student ?? null
    teacher.value = payload.teacher ?? null
    setProfile({ user: user.value, student: student.value, teacher: teacher.value })
  }

  async function login(username: string, password: string) {
    const res = await authApi.login({ username, password })
    // 必须先落盘 Token，再去拉取其它数据，否则并发请求会因缺少 Authorization 头被判定为未登录
    token.value = res.token
    setToken(res.token)
    apply({ user: res.user, student: res.student, teacher: res.teacher })
    return res
  }

  async function loadProfile() {
    const res = await authApi.me()
    apply(res)
    return res
  }

  function clear() {
    token.value = ''
    user.value = null
    student.value = null
    teacher.value = null
    unread.value = 0
    clearAuth()
  }

  async function logout() {
    try {
      await authApi.logout()
    } catch {
      // 忽略登出接口异常，本地状态照常清理
    }
    clear()
  }

  return {
    token,
    user,
    student,
    teacher,
    unread,
    role,
    isAdmin,
    isStudent,
    isAdvisor,
    isReviewer,
    displayName,
    profileId,
    login,
    loadProfile,
    logout,
    clear,
    apply
  }
})
