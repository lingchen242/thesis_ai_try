import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import { authApi } from '@/api'
import type { Role, Student, SysUser, Teacher } from '@/types'

const TOKEN_KEY = 'thesis_token'
const USER_KEY = 'thesis_user'

interface StoredUser {
  user: SysUser
  student?: Student
  teacher?: Teacher
}

export const useUserStore = defineStore('user', () => {
  const token = ref<string>(localStorage.getItem(TOKEN_KEY) || '')
  const user = ref<SysUser | null>(null)
  const student = ref<Student | null>(null)
  const teacher = ref<Teacher | null>(null)
  const unread = ref<number>(0)

  const cached = localStorage.getItem(USER_KEY)
  if (cached) {
    try {
      const parsed = JSON.parse(cached) as StoredUser
      user.value = parsed.user
      student.value = parsed.student ?? null
      teacher.value = parsed.teacher ?? null
    } catch {
      localStorage.removeItem(USER_KEY)
    }
  }

  const role = computed<Role>(() => (user.value?.role ?? 'STUDENT') as Role)
  const isAdmin = computed(() => role.value === 'ADMIN')
  const isStudent = computed(() => role.value === 'STUDENT')
  const isAdvisor = computed(() => role.value === 'ADVISOR')
  const isReviewer = computed(() => role.value === 'REVIEWER')
  const displayName = computed(() => user.value?.realName || user.value?.username || '')
  /** 学生/教师档案 ID（业务接口常用） */
  const profileId = computed(() => student.value?.id ?? teacher.value?.id ?? null)

  function persist() {
    localStorage.setItem(TOKEN_KEY, token.value)
    if (user.value) {
      localStorage.setItem(
        USER_KEY,
        JSON.stringify({ user: user.value, student: student.value, teacher: teacher.value })
      )
    }
  }

  function apply(payload: StoredUser) {
    user.value = payload.user
    student.value = payload.student ?? null
    teacher.value = payload.teacher ?? null
    persist()
  }

  async function login(username: string, password: string) {
    const res = await authApi.login({ username, password })
    token.value = res.token
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
    localStorage.removeItem(TOKEN_KEY)
    localStorage.removeItem(USER_KEY)
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
