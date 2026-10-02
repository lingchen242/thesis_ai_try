import http from './request'
import type {
  Attachment,
  AuditLog,
  DefenseGroup,
  DefenseGroupMember,
  DefenseRecord,
  DictItem,
  DictType,
  FinalSubmission,
  MidtermReport,
  Notification,
  Overview,
  PageQuery,
  PageResult,
  Proposal,
  Review,
  Selection,
  Student,
  SysConfig,
  SysUser,
  Teacher,
  Thesis,
  ThesisScore,
  Topic
} from '@/types'

/** 认证 */
export const authApi = {
  login: (data: { username: string; password: string }) =>
    http.post<{ token: string; expireIn: number; user: SysUser; student?: Student; teacher?: Teacher }>(
      '/auth/login',
      data
    ),
  logout: () => http.post<void>('/auth/logout'),
  me: () => http.get<{ user: SysUser; student?: Student; teacher?: Teacher }>('/auth/me'),
  changePassword: (data: { currentPassword: string; newPassword: string }) =>
    http.put<void>('/auth/password', data)
}

/** 账号 / 教师 / 学生 */
export const userApi = {
  pageUsers: (params: PageQuery) => http.get<PageResult<SysUser>>('/users', params),
  createUser: (data: SysUser, password?: string) =>
    http.post<SysUser>('/users', data, password ? { password } : undefined),
  updateUser: (id: number, data: SysUser) => http.put<SysUser>(`/users/${id}`, data),
  deleteUser: (id: number) => http.delete<void>(`/users/${id}`),
  resetPassword: (id: number, password?: string) =>
    http.put<void>(`/users/${id}/password`, { password }),

  pageTeachers: (params: PageQuery) => http.get<PageResult<Teacher>>('/teachers', params),
  createTeacher: (data: Teacher, password?: string) =>
    http.post<Teacher>('/teachers', data, password ? { password } : undefined),
  updateTeacher: (id: number, data: Teacher) => http.put<Teacher>(`/teachers/${id}`, data),
  deleteTeacher: (id: number) => http.delete<void>(`/teachers/${id}`),
  teacherOptions: () => http.get<{ advisors: Teacher[]; reviewers: Teacher[] }>('/teachers/options'),

  pageStudents: (params: PageQuery) => http.get<PageResult<Student>>('/students', params),
  createStudent: (data: Student, password?: string) =>
    http.post<Student>('/students', data, password ? { password } : undefined),
  updateStudent: (id: number, data: Student) => http.put<Student>(`/students/${id}`, data),
  deleteStudent: (id: number) => http.delete<void>(`/students/${id}`)
}

/** 字典与配置 */
export const dictApi = {
  listTypes: () => http.get<DictType[]>('/dict/types'),
  createType: (data: DictType) => http.post<DictType>('/dict/types', data),
  updateType: (id: number, data: DictType) => http.put<DictType>(`/dict/types/${id}`, data),
  deleteType: (id: number) => http.delete<void>(`/dict/types/${id}`),

  listItems: (params: { typeCode: string; parentId?: number; onlyEnabled?: boolean; asTree?: boolean }) =>
    http.get<DictItem[]>('/dict/items', params),
  createItem: (data: DictItem) => http.post<DictItem>('/dict/items', data),
  updateItem: (id: number, data: DictItem) => http.put<DictItem>(`/dict/items/${id}`, data),
  deleteItem: (id: number) => http.delete<void>(`/dict/items/${id}`)
}

export const configApi = {
  list: () => http.get<SysConfig[]>('/configs'),
  update: (data: SysConfig[]) => http.put<void>('/configs', data)
}

export const importApi = {
  template: () => http.download('/import/template', undefined, '账号导入模板.xlsx'),
  users: (file: File) => http.upload<Record<string, unknown>>('/import/users', file)
}

/** 课题与选题 */
export const topicApi = {
  page: (params: PageQuery) => http.get<PageResult<Topic>>('/topics', params),
  detail: (id: number) => http.get<Topic>(`/topics/${id}`),
  create: (data: Topic) => http.post<Topic>('/topics', data),
  update: (id: number, data: Topic) => http.put<Topic>(`/topics/${id}`, data),
  publish: (id: number) => http.post<void>(`/topics/${id}/publish`),
  close: (id: number) => http.post<void>(`/topics/${id}/close`),
  remove: (id: number) => http.delete<void>(`/topics/${id}`)
}

export const selectionApi = {
  page: (params: PageQuery) => http.get<PageResult<Selection>>('/selections', params),
  mine: () => http.get<Selection | null>('/selections/mine'),
  apply: (data: { topicId: number; remark?: string }) => http.post<Selection>('/selections', data),
  approve: (id: number, comment?: string) =>
    http.post<void>(`/selections/${id}/approve`, { comment }),
  reject: (id: number, comment?: string) => http.post<void>(`/selections/${id}/reject`, { comment })
}

/** 论文主流程 */
export const thesisApi = {
  page: (params: PageQuery) => http.get<PageResult<Thesis>>('/theses', params),
  mine: () => http.get<Thesis | null>('/theses/mine'),
  detail: (id: number) => http.get<Thesis>(`/theses/${id}`),
  bundle: (id: number) => http.get<Record<string, unknown>>(`/theses/${id}/detail`),
  timeline: (id: number) => http.get<AuditLog[]>(`/theses/${id}/timeline`),
  transition: (id: number, data: { target: string; comment?: string; score?: number }) =>
    http.post<Thesis>(`/theses/${id}/transition`, data),
  pageFinals: (params: PageQuery) => http.get<PageResult<FinalSubmission>>('/finals', params),
  submitFinal: (data: FinalSubmission) => http.post<FinalSubmission>('/finals', data)
}

export const proposalApi = {
  page: (params: PageQuery) => http.get<PageResult<Proposal>>('/proposals', params),
  mine: () => http.get<Proposal | null>('/proposals/mine'),
  submit: (data: Proposal) => http.post<Proposal>('/proposals', data),
  review: (id: number, data: { decision: string; comment?: string; score?: number }) =>
    http.post<Proposal>(`/proposals/${id}/review`, data)
}

export const midtermApi = {
  page: (params: PageQuery) => http.get<PageResult<MidtermReport>>('/midterms', params),
  mine: () => http.get<MidtermReport | null>('/midterms/mine'),
  submit: (data: MidtermReport) => http.post<MidtermReport>('/midterms', data),
  review: (id: number, data: { decision: string; comment?: string; score?: number }) =>
    http.post<MidtermReport>(`/midterms/${id}/review`, data),
  alerts: (grade?: string) => http.get<Record<string, unknown>[]>('/midterms/alerts', { grade })
}

/** 评阅 */
export const reviewApi = {
  page: (params: PageQuery) => http.get<PageResult<Review>>('/reviews', params),
  mine: (onlyPending?: boolean) => http.get<Review[]>('/reviews/mine', { onlyPending }),
  assign: (data: { thesisId: number; reviewerId?: number; blind?: boolean }) =>
    http.post<Review>('/reviews/assign', data),
  submit: (id: number, data: { score?: number; comment?: string }) =>
    http.post<Review>(`/reviews/${id}/submit`, data)
}

/** 答辩 */
export const defenseApi = {
  pageGroups: (params: PageQuery) => http.get<PageResult<DefenseGroup>>('/defense/groups', params),
  groupDetail: (id: number) =>
    http.get<{ group: DefenseGroup; members: DefenseGroupMember[]; theses: Thesis[] }>(
      `/defense/groups/${id}`
    ),
  createGroup: (data: DefenseGroup) => http.post<DefenseGroup>('/defense/groups', data),
  updateGroup: (id: number, data: DefenseGroup) =>
    http.put<DefenseGroup>(`/defense/groups/${id}`, data),
  deleteGroup: (id: number) => http.delete<void>(`/defense/groups/${id}`),
  setMembers: (id: number, data: { memberIds: number[]; chairId?: number; secretaryId?: number }) =>
    http.post<void>(`/defense/groups/${id}/members`, data),
  candidates: (groupId?: number) => http.get<Thesis[]>('/defense/candidates', { groupId }),
  groupTheses: (id: number) => http.get<Thesis[]>(`/defense/groups/${id}/theses`),
  schedule: (id: number, thesisIds: number[]) =>
    http.post<void>(`/defense/groups/${id}/schedule`, thesisIds),
  removeThesis: (thesisId: number) => http.delete<void>(`/defense/groups/theses/${thesisId}`),
  pageRecords: (params: PageQuery) => http.get<PageResult<DefenseRecord>>('/defense/records', params),
  record: (data: { thesisId: number; groupId: number; score?: number; result?: string; comment?: string }) =>
    http.post<DefenseRecord>('/defense/records', data)
}

/** 成绩 */
export const scoreApi = {
  page: (params: PageQuery) => http.get<PageResult<ThesisScore>>('/scores', params),
  getByThesis: (thesisId: number) => http.get<ThesisScore | null>(`/scores/${thesisId}`),
  recompute: (thesisId: number) => http.post<ThesisScore>(`/scores/${thesisId}/recompute`)
}

/** 看板 */
export const dashboardApi = {
  overview: () => http.get<Overview>('/dashboard/overview'),
  stages: () => http.get<{ status: string; label: string; count: number }[]>('/dashboard/stages'),
  todos: () => http.get<{ title: string; count: number; link: string }[]>('/dashboard/todos')
}

/** 附件 */
export const fileApi = {
  upload: (file: File, bizType: string) =>
    http.upload<Attachment>('/files/upload', file, { bizType }),
  bind: (data: { bizType: string; bizId: number; ids: number[] }) =>
    http.post<void>('/files/bind', data),
  list: (bizType: string, bizId: number) => http.get<Attachment[]>('/files', { bizType, bizId }),
  listByIds: (ids: string) => http.get<Attachment[]>('/files/by-ids', { ids }),
  remove: (id: number) => http.delete<void>(`/files/${id}`)
}

/** 站内消息 */
export const noticeApi = {
  list: (onlyUnread?: boolean) => http.get<Notification[]>('/notifications', { onlyUnread }),
  unreadCount: () => http.get<number>('/notifications/unread-count'),
  markRead: (id: number) => http.put<void>(`/notifications/${id}/read`),
  markAllRead: () => http.put<void>('/notifications/read-all')
}
