<template>
  <div v-loading="loading">
    <el-empty
      v-if="!thesis"
      description="你还没有论文记录，请先到「课题管理」中申报课题"
    >
      <el-button type="primary" @click="router.push('/topics')">去选题</el-button>
    </el-empty>

    <template v-else>
      <el-card shadow="never" class="mb-16">
        <template #header>
          <div class="table-toolbar" style="margin-bottom: 0">
            <span>我的论文</span>
            <StatusTag :status="thesis.status" />
          </div>
        </template>
        <el-descriptions :column="isMobile ? 1 : 2" border size="small">
          <el-descriptions-item label="论文题目" :span="isMobile ? 1 : 2">
            {{ thesis.title }}
          </el-descriptions-item>
          <el-descriptions-item label="指导教师">{{ thesis.advisorName || '-' }}</el-descriptions-item>
          <el-descriptions-item label="届别 / 专业">
            {{ thesis.grade }} / {{ thesis.major }}
          </el-descriptions-item>
          <el-descriptions-item label="选题时间">{{ thesis.startTime || '-' }}</el-descriptions-item>
          <el-descriptions-item label="定稿提交">{{ thesis.submitTime || '-' }}</el-descriptions-item>
          <el-descriptions-item v-if="score" label="总评成绩">
            <span style="color: #f56c6c; font-weight: 600">{{ score.totalScore ?? '-' }}</span>
            <el-tag size="small" class="mt-8" style="margin-left: 6px">{{ score.level }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item v-if="thesis.archiveTime" label="归档时间">
            {{ thesis.archiveTime }}
          </el-descriptions-item>
        </el-descriptions>
      </el-card>

      <el-card shadow="never" class="mb-16">
        <template #header><span>流程进度</span></template>
        <el-steps :active="activeStep" align-center :simple="isMobile" finish-status="success">
          <el-step v-for="step in steps" :key="step" :title="step" />
        </el-steps>
        <div class="next-action mt-16">
          <el-alert :title="nextTip" type="info" :closable="false" show-icon />
          <div class="mt-16">
            <el-button
              v-if="thesis.status === 'DRAFT'"
              type="primary"
              @click="router.push('/proposals')"
            >
              提交开题报告
            </el-button>
            <el-button
              v-if="thesis.status === 'PROPOSAL_APPROVED'"
              type="primary"
              @click="router.push('/midterms')"
            >
              提交中期报告
            </el-button>
            <el-button
              v-if="['MIDTERM_PASSED', 'REVIEWING'].includes(thesis.status)"
              type="primary"
              @click="router.push('/finals')"
            >
              提交论文定稿
            </el-button>
            <el-button @click="router.push('/proposals')">查看开题</el-button>
            <el-button @click="router.push('/midterms')">查看中期</el-button>
            <el-button @click="router.push('/scores')">查看成绩</el-button>
          </div>
        </div>
      </el-card>

      <el-card shadow="never">
        <template #header><span>操作记录</span></template>
        <el-timeline v-if="timeline.length">
          <el-timeline-item
            v-for="log in timeline"
            :key="log.id"
            :timestamp="log.createTime"
            placement="top"
          >
            <div>{{ log.detail }}</div>
            <div class="text-muted">{{ log.actorName }}</div>
          </el-timeline-item>
        </el-timeline>
        <el-empty v-else description="暂无记录" :image-size="70" />
      </el-card>
    </template>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { scoreApi, thesisApi } from '@/api'
import { useResponsive } from '@/composables/useResponsive'
import { THESIS_STATUS } from '@/constants'
import StatusTag from '@/components/StatusTag.vue'
import type { AuditLog, Thesis, ThesisScore } from '@/types'

const router = useRouter()
const { isMobile } = useResponsive()

const loading = ref(false)
const thesis = ref<Thesis | null>(null)
const timeline = ref<AuditLog[]>([])
const score = ref<ThesisScore | null>(null)

const steps = [
  '选题',
  '开题提交',
  '开题通过',
  '中期提交',
  '中期通过',
  '定稿提交',
  '评阅中',
  '评阅通过',
  '答辩安排',
  '答辩完成',
  '归档'
]

const activeStep = computed(() => {
  if (!thesis.value) return 0
  return (THESIS_STATUS[thesis.value.status]?.step ?? 1) - 1
})

const NEXT_TIP: Record<string, string> = {
  DRAFT: '下一步：撰写并提交开题报告，提交后由指导教师审核。',
  PROPOSAL_SUBMITTED: '开题报告已提交，等待指导教师审核。',
  PROPOSAL_APPROVED: '开题已通过，请按计划开展研究并在中期检查前提交中期报告。',
  MIDTERM_SUBMITTED: '中期报告已提交，等待指导教师检查。',
  MIDTERM_PASSED: '中期已通过，请完成论文定稿后提交。',
  FINAL_SUBMITTED: '定稿已提交，等待管理员指派评阅教师。',
  REVIEWING: '评阅进行中，请耐心等待评阅结果。',
  REVIEW_PASSED: '评阅已通过，等待安排答辩。',
  DEFENSE_SCHEDULED: '已安排答辩，请按通知时间地点参加。',
  DEFENSE_DONE: '答辩已完成，等待成绩归档。',
  ARCHIVED: '全流程已结束，论文已归档。'
}

const nextTip = computed(() => (thesis.value ? NEXT_TIP[thesis.value.status] ?? '' : ''))

async function load() {
  loading.value = true
  try {
    thesis.value = await thesisApi.mine()
    if (thesis.value?.id) {
      timeline.value = await thesisApi.timeline(thesis.value.id)
      score.value = await scoreApi.getByThesis(thesis.value.id)
    }
  } finally {
    loading.value = false
  }
}

onMounted(load)
</script>

<style scoped>
.next-action {
  text-align: center;
}
</style>
