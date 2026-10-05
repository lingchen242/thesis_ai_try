import type { Student, SysUser, Teacher } from '@/types'

/**
 * 认证信息本地存储。
 *
 * 唯一职责：持有 localStorage 的键名与读写逻辑。
 * 请求层（api/request.ts）与状态层（stores/user.ts）都从这里取，避免两边各写一份键名导致不一致。
 */

const TOKEN_KEY = 'thesis_token'
const PROFILE_KEY = 'thesis_profile'

export interface StoredProfile {
  user: SysUser
  student?: Student | null
  teacher?: Teacher | null
}

export function getToken(): string {
  return localStorage.getItem(TOKEN_KEY) || ''
}

export function setToken(token: string): void {
  if (token) {
    localStorage.setItem(TOKEN_KEY, token)
  } else {
    localStorage.removeItem(TOKEN_KEY)
  }
}

export function getProfile(): StoredProfile | null {
  const raw = localStorage.getItem(PROFILE_KEY)
  if (!raw) return null
  try {
    return JSON.parse(raw) as StoredProfile
  } catch {
    localStorage.removeItem(PROFILE_KEY)
    return null
  }
}

export function setProfile(profile: StoredProfile): void {
  localStorage.setItem(PROFILE_KEY, JSON.stringify(profile))
}

export function clearAuth(): void {
  localStorage.removeItem(TOKEN_KEY)
  localStorage.removeItem(PROFILE_KEY)
}
