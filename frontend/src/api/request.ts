import axios, { type AxiosInstance, type AxiosRequestConfig } from 'axios'
import { ElMessage } from 'element-plus'
import { useUserStore } from '@/stores/user'
import { getToken } from '@/utils/auth-storage'
import router from '@/router'

/** 后端统一响应体 */
interface ApiResult<T = unknown> {
  code: number
  message: string
  data: T
}

const instance: AxiosInstance = axios.create({
  baseURL: '/api',
  timeout: 30000
})

instance.interceptors.request.use((config) => {
  const token = getToken()
  if (token) {
    config.headers = config.headers ?? {}
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

function redirectToLogin(message: string) {
  ElMessage.error(message)
  const userStore = useUserStore()
  userStore.clear()
  const current = router.currentRoute.value.fullPath
  if (!current.startsWith('/login')) {
    router.replace({ path: '/login', query: { redirect: current } })
  }
}

instance.interceptors.response.use(
  (response) => {
    // 文件下载类请求直接返回原始响应
    if (response.config.responseType === 'blob' || response.config.responseType === 'arraybuffer') {
      return response
    }
    const result = response.data as ApiResult
    if (result.code === 0) {
      return response
    }
    if (result.code === 401) {
      redirectToLogin(result.message || '登录状态已失效，请重新登录')
    } else {
      ElMessage.error(result.message || '操作失败')
    }
    return Promise.reject(new Error(result.message || '操作失败'))
  },
  (error) => {
    const status = error?.response?.status
    if (status === 401) {
      redirectToLogin('登录状态已失效，请重新登录')
    } else if (status === 403) {
      ElMessage.error('无权限访问该资源')
    } else if (status === 404) {
      ElMessage.error('接口不存在，请确认后端服务已启动')
    } else {
      ElMessage.error(error?.message || '网络异常，请稍后重试')
    }
    return Promise.reject(error)
  }
)

/** 泛型请求封装：直接拿到后端 data 字段 */
async function request<T>(config: AxiosRequestConfig): Promise<T> {
  const response = await instance.request<ApiResult<T>>(config)
  return (response.data as ApiResult<T>).data
}

export const http = {
  get: <T>(url: string, params?: Record<string, unknown>) =>
    request<T>({ url, method: 'GET', params }),
  post: <T>(url: string, data?: unknown, params?: Record<string, unknown>) =>
    request<T>({ url, method: 'POST', data, params }),
  put: <T>(url: string, data?: unknown) => request<T>({ url, method: 'PUT', data }),
  delete: <T>(url: string, params?: Record<string, unknown>) =>
    request<T>({ url, method: 'DELETE', params }),
  /** 上传文件 */
  upload: <T>(url: string, file: File, params?: Record<string, unknown>) => {
    const form = new FormData()
    form.append('file', file)
    return request<T>({
      url,
      method: 'POST',
      data: form,
      params,
      headers: { 'Content-Type': 'multipart/form-data' }
    })
  },
  /** 下载二进制（用于 Excel 模板导出） */
  download: async (url: string, params?: Record<string, unknown>, filename?: string) => {
    const response = await instance.request<Blob>({
      url,
      method: 'GET',
      params,
      responseType: 'blob'
    })
    const blob = response.data as unknown as Blob
    const link = document.createElement('a')
    link.href = URL.createObjectURL(blob)
    link.download = filename || 'download.xlsx'
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    URL.revokeObjectURL(link.href)
  }
}

export default http
