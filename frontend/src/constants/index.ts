/** 前端共享常量与文案映射 */

export const THESIS_STATUS: Record<string, { label: string; type: string; step: number }> = {
  DRAFT: { label: '待提交开题', type: 'info', step: 1 },
  PROPOSAL_SUBMITTED: { label: '开题待审核', type: 'warning', step: 2 },
  PROPOSAL_APPROVED: { label: '开题已通过', type: 'primary', step: 3 },
  MIDTERM_SUBMITTED: { label: '中期待检查', type: 'warning', step: 4 },
  MIDTERM_PASSED: { label: '中期已通过', type: 'primary', step: 5 },
  FINAL_SUBMITTED: { label: '定稿已提交', type: 'primary', step: 6 },
  REVIEWING: { label: '评阅中', type: 'warning', step: 7 },
  REVIEW_PASSED: { label: '评阅已通过', type: 'success', step: 8 },
  DEFENSE_SCHEDULED: { label: '待答辩', type: 'warning', step: 9 },
  DEFENSE_DONE: { label: '答辩完成', type: 'success', step: 10 },
  ARCHIVED: { label: '已归档', type: 'success', step: 11 }
}

export const THESIS_STATUS_OPTIONS = Object.entries(THESIS_STATUS).map(([value, item]) => ({
  value,
  label: item.label
}))

export const REVIEW_STATUS: Record<string, { label: string; type: string }> = {
  PENDING: { label: '待审核', type: 'warning' },
  APPROVED: { label: '已通过', type: 'success' },
  REJECTED: { label: '已驳回', type: 'danger' }
}

export const SELECTION_STATUS: Record<string, { label: string; type: string }> = {
  PENDING: { label: '待审核', type: 'warning' },
  APPROVED: { label: '已录取', type: 'success' },
  REJECTED: { label: '未通过', type: 'danger' }
}

export const TOPIC_STATUS: Record<string, { label: string; type: string }> = {
  DRAFT: { label: '草稿', type: 'info' },
  OPEN: { label: '开放申报', type: 'success' },
  SELECTED: { label: '已选满', type: 'primary' },
  CLOSED: { label: '已关闭', type: 'info' }
}

export const REVIEW_TASK_STATUS: Record<string, { label: string; type: string }> = {
  PENDING: { label: '待评阅', type: 'warning' },
  SUBMITTED: { label: '已提交', type: 'success' }
}

export const DEFENSE_RESULT: Record<string, { label: string; type: string }> = {
  PASS: { label: '通过', type: 'success' },
  DEFER: { label: '暂缓', type: 'warning' },
  FAIL: { label: '不通过', type: 'danger' }
}

export const DEFENSE_GROUP_STATUS: Record<string, { label: string; type: string }> = {
  PLANNED: { label: '待进行', type: 'warning' },
  FINISHED: { label: '已结束', type: 'success' }
}

export const ROLE_LABEL: Record<string, string> = {
  STUDENT: '学生',
  ADVISOR: '指导教师',
  REVIEWER: '评阅教师',
  ADMIN: '管理员'
}

export const ROLE_OPTIONS = Object.entries(ROLE_LABEL).map(([value, label]) => ({ value, label }))

export const TEACHER_TYPE: Record<string, string> = {
  ADVISOR: '指导教师',
  REVIEWER: '评阅教师',
  BOTH: '指导兼评阅'
}

export const BIZ_TYPE: Record<string, string> = {
  PROPOSAL: '开题报告',
  MIDTERM: '中期报告',
  FINAL: '论文定稿',
  OTHER: '其它附件'
}

/** 字典类型编码 */
export const DICT = {
  COLLEGE: 'COLLEGE',
  MAJOR: 'MAJOR',
  CLASS: 'CLASS',
  GRADE: 'GRADE',
  TOPIC_TYPE: 'TOPIC_TYPE',
  TOPIC_SOURCE: 'TOPIC_SOURCE',
  TITLE: 'TITLE',
  DEFENSE_RESULT: 'DEFENSE_RESULT'
} as const

/** 通用查询关键字占位文案 */
export const SEARCH_PLACEHOLDER = '输入关键字搜索'

export function statusMeta(map: Record<string, { label: string; type: string }>, code?: string) {
  if (!code) return { label: '-', type: 'info' }
  return map[code] ?? { label: code, type: 'info' }
}
