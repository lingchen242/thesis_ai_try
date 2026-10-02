/** 后端实体与通用结构类型定义 */

export interface PageResult<T> {
  total: number
  pageNum: number
  pageSize: number
  records: T[]
}

export interface PageQuery {
  pageNum?: number
  pageSize?: number
  keyword?: string
  [key: string]: unknown
}

export type Role = 'STUDENT' | 'ADVISOR' | 'REVIEWER' | 'ADMIN'

export interface SysUser {
  id?: number
  username: string
  realName: string
  role: Role
  gender?: number
  phone?: string
  email?: string
  status?: number
  lastLoginTime?: string
  createTime?: string
}

export interface Student {
  id?: number
  userId?: number
  username?: string
  studentNo: string
  realName: string
  gender?: number
  grade: string
  college: string
  major: string
  className: string
  advisorId?: number | null
  advisorName?: string
  phone?: string
  email?: string
  thesisStatus?: string
  createTime?: string
}

export interface Teacher {
  id?: number
  userId?: number
  username?: string
  teacherNo: string
  realName: string
  gender?: number
  title?: string
  college?: string
  major?: string
  teacherType?: string
  canReview?: number
  maxQuota?: number
  phone?: string
  email?: string
  studentCount?: number
  createTime?: string
}

export interface Topic {
  id?: number
  title: string
  topicType?: string
  source?: string
  teacherId?: number
  teacherName?: string
  grade?: string
  college?: string
  major?: string
  description?: string
  requirement?: string
  capacity?: number
  selectedCount?: number
  status?: string
  applyCount?: number
  applied?: boolean
  publishTime?: string
  createTime?: string
}

export interface Selection {
  id?: number
  topicId?: number
  topicTitle?: string
  studentId?: number
  studentName?: string
  studentNo?: string
  className?: string
  teacherName?: string
  grade?: string
  status?: string
  studentRemark?: string
  teacherComment?: string
  applyTime?: string
  handleTime?: string
}

export interface Thesis {
  id?: number
  studentId?: number
  studentName?: string
  studentNo?: string
  className?: string
  topicId?: number
  advisorId?: number
  advisorName?: string
  title: string
  grade?: string
  college?: string
  major?: string
  status: string
  statusLabel?: string
  currentStage?: string
  startTime?: string
  submitTime?: string
  archiveTime?: string
}

export interface Proposal {
  id?: number
  thesisId?: number
  thesisTitle?: string
  studentName?: string
  studentNo?: string
  advisorName?: string
  reviewerName?: string
  content?: string
  attachmentIds?: string
  submitTime?: string
  reviewStatus?: string
  reviewComment?: string
  reviewTime?: string
  score?: number
}

export interface MidtermReport {
  id?: number
  thesisId?: number
  thesisTitle?: string
  studentName?: string
  studentNo?: string
  advisorName?: string
  progressPercent?: number
  content?: string
  attachmentIds?: string
  submitTime?: string
  reviewStatus?: string
  reviewComment?: string
  reviewTime?: string
  score?: number
}

export interface FinalSubmission {
  id?: number
  thesisId?: number
  thesisTitle?: string
  studentName?: string
  studentNo?: string
  fileUrl?: string
  fileName?: string
  fileSize?: number
  version?: number
  note?: string
  submitTime?: string
  statusLabel?: string
}

export interface Review {
  id?: number
  thesisId?: number
  thesisTitle?: string
  studentName?: string
  studentNo?: string
  reviewerId?: number
  reviewerName?: string
  score?: number
  comment?: string
  status?: string
  blind?: number
  grade?: string
  fileUrl?: string
  assignTime?: string
  submitTime?: string
}

export interface DefenseGroup {
  id?: number
  name: string
  grade?: string
  college?: string
  defenseDate?: string
  location?: string
  secretaryId?: number
  secretaryName?: string
  status?: string
  remark?: string
  memberCount?: number
  thesisCount?: number
}

export interface DefenseGroupMember {
  id?: number
  groupId?: number
  teacherId?: number
  teacherName?: string
  title?: string
  college?: string
  roleInGroup?: string
}

export interface DefenseRecord {
  id?: number
  thesisId?: number
  thesisTitle?: string
  studentName?: string
  studentNo?: string
  groupId?: number
  groupName?: string
  grade?: string
  score?: number
  result?: string
  comment?: string
  recordedTime?: string
}

export interface ThesisScore {
  id?: number
  thesisId?: number
  thesisTitle?: string
  studentName?: string
  studentNo?: string
  grade?: string
  college?: string
  major?: string
  advisorName?: string
  proposalScore?: number
  midtermScore?: number
  reviewScore?: number
  defenseScore?: number
  totalScore?: number
  level?: string
}

export interface Attachment {
  id?: number
  bizType?: string
  bizId?: number
  fileName?: string
  fileUrl?: string
  fileSize?: number
  mimeType?: string
  storageDriver?: string
  uploaderId?: number
  createTime?: string
}

export interface AuditLog {
  id?: number
  actorId?: number
  actorName?: string
  action?: string
  targetType?: string
  targetId?: number
  detail?: string
  createTime?: string
}

export interface Notification {
  id?: number
  userId?: number
  title: string
  content?: string
  link?: string
  type?: string
  isRead?: number
  createTime?: string
}

export interface DictType {
  id?: number
  typeCode: string
  typeName: string
  remark?: string
  itemCount?: number
}

export interface DictItem {
  id?: number
  typeCode?: string
  itemCode?: string
  itemName: string
  parentId?: number | null
  parentName?: string
  sortNo?: number
  status?: number
  remark?: string
  children?: DictItem[]
}

export interface SysConfig {
  id?: number
  configKey: string
  configValue?: string
  remark?: string
}

export interface TodoItem {
  title: string
  count: number
  link: string
}

export interface StageItem {
  status: string
  label: string
  count: number
}

export interface BucketItem {
  bucket: string
  cnt: number
}

export interface Overview {
  role: Role
  realName: string
  stageDistribution: StageItem[]
  scoreDistribution: BucketItem[]
  todos: TodoItem[]
  [key: string]: unknown
}
