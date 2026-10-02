<template>
  <div v-loading="loading">
    <el-page-header class="mb-16" @back="router.back()">
      <template #content>
        <span>论文详情</span>
      </template>
    </el-page-header>

    <template v-if="thesis">
      <el-card shadow="never" class="mb-16">
        <template #header>
          <div class="table-toolbar" style="margin-bottom: 0">
            <span>{{ thesis.title }}</span>
            <div>
              <StatusTag :status="thesis.status" />
              <el-button
                v-if="userStore.isAdmin && thesis.status === 'DEFENSE_DONE'"
                type="primary"
                size="small"
                style="margin-left: 8px"
                @click="archive"
              >
                归档
              </el-button>
            </div>
          </div>
        </template>
        <el-descriptions :column="isMobile ? 1 : 3" border size="small">
          <el-descriptions-item label="学生">
            {{ thesis.studentName }}（{{ thesis.studentNo }}）
          </el-descriptions-item>
          <el-descriptions-item label="班级">{{ thesis.className || '-' }}</el-descriptions-item>
          <el-descriptions-item label="指导教师">{{ thesis.advisorName || '-' }}</el-descriptions-item>
          <el-descriptions-item label="届别">{{ thesis.grade || '-' }}</el-descriptions-item>
          <el-descriptions-item label="学院 / 专业">
            {{ thesis.college }} / {{ thesis.major }}
          </el-descriptions-item>
          <el-descriptions-item label="当前阶段">{{ thesis.currentStage || '-' }}</el-descriptions-item>
          <el-descriptions-item label="选题时间">{{ thesis.startTime || '-' }}</el-descriptions-item>
          <el-descriptions-item label="定稿提交">{{ thesis.submitTime || '-' }}</el-descriptions-item>
          <el-descriptions-item label="归档时间">{{ thesis.archiveTime || '-' }}</el-descriptions-item>
        </el-descriptions>
      </el-card>

      <el-row :gutter="12">
        <el-col :xs="24" :sm="24" :md="14" :lg="15">
          <el-card shadow="never" class="mb-16">
            <template #header><span>开题报告</span></template>
            <template v-if="proposal">
              <div class="mb-16">
                <StatusTag :status="proposal.reviewStatus" kind="review" />
                <span class="text-muted" style="margin-left: 8px">
                  提交于 {{ proposal.submitTime || '-' }}
                </span>
              </div>
              <div class="content-block">{{ proposal.content }}</div>
              <div class="mt-16">
                <span class="text-muted">附件：</span>
                <AttachmentList :ids="proposal.attachmentIds" />
              </div>
              <el-alert
                v-if="proposal.reviewComment"
                class="mt-16"
                :title="`审核意见：${proposal.reviewComment}`"
                :type="proposal.reviewStatus === 'APPROVED' ? 'success' : 'warning'"
                :closable="false"
              />
            </template>
            <el-empty v-else description="尚未提交开题报告" :image-size="70" />
          </el-card>

          <el-card shadow="never" class="mb-16">
            <template #header><span>中期报告</span></template>
            <template v-if="midterm">
              <div class="mb-16">
                <StatusTag :status="midterm.reviewStatus" kind="review" />
                <span class="text-muted" style="margin-left: 8px">
                  进度 {{ midterm.progressPercent ?? 0 }}% · 提交于 {{ midterm.submitTime || '-' }}
                </span>
              </div>
              <div class="content-block">{{ midterm.content }}</div>
              <div class="mt-16">
                <span class="text-muted">附件：</span>
                <AttachmentList :ids="midterm.attachmentIds" />
              </div>
              <el-alert
                v-if="midterm.reviewComment"
                class="mt-16"
                :title="`检查意见：${midterm.reviewComment}`"
                :type="midterm.reviewStatus === 'APPROVED' ? 'success' : 'warning'"
                :closable="false"
              />
            </template>
            <el-empty v-else description="尚未提交中期报告" :image-size="70" />
          </el-card>

          <el-card shadow="never" class="mb-16">
            <template #header><span>定稿文件</span></template>
            <el-table v-if="finals.length" :data="finals" border size="small">
              <el-table-column prop="version" label="版本" width="70" align="center" />
              <el-table-column prop="fileName" label="文件名" min-width="160" show-overflow-tooltip />
              <el-table-column prop="submitTime" label="提交时间" width="160" />
              <el-table-column label="操作" width="80">
                <template #default="{ row }">
                  <el-link type="primary" :href="row.fileUrl" target="_blank">下载</el-link>
                </template>
              </el-table-column>
            </el-table>
            <el-empty v-else description="尚未提交定稿" :image-size="70" />
          </el-card>

          <el-card shadow="never" class="mb-16">
            <template #header><span>评阅记录</span></template>
            <el-table v-if="reviews.length" :data="reviews" border size="small">
              <el-table-column prop="reviewerName" label="评阅教师" width="110" />
              <el-table-column label="成绩" width="80" align="center">
                <template #default="{ row }">{{ row.score ?? '-' }}</template>
              </el-table-column>
              <el-table-column label="状态" width="90" align="center">
                <template #default="{ row }">
                  <StatusTag :status="row.status" kind="reviewTask" />
                </template>
              </el-table-column>
              <el-table-column prop="comment" label="评阅意见" min-width="200" show-overflow-tooltip />
            </el-table>
            <el-empty v-else description="尚未指派评阅" :image-size="70" />
          </el-card>
        </el-col>

        <el-col :xs="24" :sm="24" :md="10" :lg="9">
          <el-card shadow="never" class="mb-16">
            <template #header><span>成绩汇总</span></template>
            <template v-if="score">
              <el-descriptions :column="1" border size="small">
                <el-descriptions-item label="开题成绩">{{ score.proposalScore ?? '-' }}</el-descriptions-item>
                <el-descriptions-item label="中期成绩">{{ score.midtermScore ?? '-' }}</el-descriptions-item>
                <el-descriptions-item label="评阅成绩">{{ score.reviewScore ?? '-' }}</el-descriptions-item>
                <el-descriptions-item label="答辩成绩">{{ score.defenseScore ?? '-' }}</el-descriptions-item>
                <el-descriptions-item label="总评">
                  <span style="color: #f56c6c; font-weight: 600">{{ score.totalScore ?? '-' }}</span>
                  <el-tag size="small" style="margin-left: 6px">{{ score.level }}</el-tag>
                </el-descriptions-item>
              </el-descriptions>
            </template>
            <el-empty v-else description="尚无成绩" :image-size="70" />
          </el-card>

          <el-card shadow="never" class="mb-16">
            <template #header><span>答辩信息</span></template>
            <el-descriptions v-if="defenseRecord" :column="1" border size="small">
              <el-descriptions-item label="答辩组">{{ defenseRecord.groupName || '-' }}</el-descriptions-item>
              <el-descriptions-item label="答辩成绩">{{ defenseRecord.score ?? '待录入' }}</el-descriptions-item>
              <el-descriptions-item label="结论">
                <StatusTag v-if="defenseRecord.result" :status="defenseRecord.result" kind="defenseResult" />
                <span v-else>-</span>
              </el-descriptions-item>
              <el-descriptions-item label="答辩评语">{{ defenseRecord.comment || '-' }}</el-descriptions-item>
            </el-descriptions>
            <el-empty v-else description="尚未安排答辩" :image-size="70" />
          </el-card>

          <el-card shadow="never">
            <template #header><span>操作时间轴</span></template>
            <el-timeline v-if="timeline.length">
              <el-timeline-item
                v-for="log in timeline"
                :key="log.id"
                :timestamp="log.createTime"
                placement="top"
              >
                <div class="timeline-detail">{{ log.detail }}</div>
                <div class="text-muted">{{ log.actorName }}</div>
              </el-timeline-item>
            </el-timeline>
            <el-empty v-else description="暂无记录" :image-size="70" />
          </el-card>
        </el-col>
      </el-row>
    </template>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { thesisApi } from '@/api'
import { useUserStore } from '@/stores/user'
import { useResponsive } from '@/composables/useResponsive'
import StatusTag from '@/components/StatusTag.vue'
import AttachmentList from '@/components/AttachmentList.vue'
import type {
  AuditLog,
  DefenseRecord,
  FinalSubmission,
  MidtermReport,
  Proposal,
  Review,
  Thesis,
  ThesisScore
} from '@/types'

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()
const { isMobile } = useResponsive()

const loading = ref(false)
const thesis = ref<Thesis | null>(null)
const timeline = ref<AuditLog[]>([])
const proposal = ref<Proposal | null>(null)
const midterm = ref<MidtermReport | null>(null)
const finals = ref<FinalSubmission[]>([])
const reviews = ref<Review[]>([])
const defenseRecord = ref<DefenseRecord | null>(null)
const score = ref<ThesisScore | null>(null)

const thesisId = computed(() => Number(route.params.id))

async function load() {
  loading.value = true
  try {
    const bundle = await thesisApi.bundle(thesisId.value)
    thesis.value = bundle.thesis as Thesis
    timeline.value = (bundle.timeline as AuditLog[]) ?? []
    proposal.value = (bundle.proposal as Proposal) ?? null
    midterm.value = (bundle.midterm as MidtermReport) ?? null
    finals.value = (bundle.finals as FinalSubmission[]) ?? []
    reviews.value = (bundle.reviews as Review[]) ?? []
    defenseRecord.value = (bundle.defenseRecord as DefenseRecord) ?? null
    score.value = (bundle.score as ThesisScore) ?? null
  } finally {
    loading.value = false
  }
}

async function archive() {
  await ElMessageBox.confirm('确认将该论文归档？归档后流程结束。', '归档确认', { type: 'warning' })
  await thesisApi.transition(thesisId.value, { target: 'ARCHIVED', comment: '材料齐备，论文归档' })
  ElMessage.success('已归档')
  load()
}

onMounted(load)
</script>

<style scoped>
.content-block {
  white-space: pre-wrap;
  font-size: 13px;
  line-height: 1.8;
  color: #606266;
  background: #fafafa;
  border-radius: 6px;
  padding: 10px 12px;
}
</style>
