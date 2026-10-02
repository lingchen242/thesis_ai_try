<template>
  <div>
    <!-- 学生：提交中期报告 -->
    <el-card v-if="userStore.isStudent" shadow="never">
      <template #header>
        <div class="table-toolbar" style="margin-bottom: 0">
          <span>中期报告</span>
          <StatusTag v-if="mine" :status="mine.reviewStatus" kind="review" />
        </div>
      </template>

      <el-alert
        v-if="!canSubmit && mine"
        class="mb-16"
        :type="mine.reviewStatus === 'APPROVED' ? 'success' : 'warning'"
        :title="
          mine.reviewStatus === 'APPROVED'
            ? '中期检查已通过，请继续完成论文定稿'
            : mine.reviewStatus === 'REJECTED'
              ? '中期报告被退回，请修改后重新提交'
              : '中期报告已提交，等待指导教师检查'
        "
        :description="mine.reviewComment || ''"
        :closable="false"
        show-icon
      />

      <el-form ref="formRef" :model="form" :rules="rules" label-width="90px">
        <el-form-item label="完成进度" prop="progressPercent">
          <el-slider v-model="form.progressPercent" :min="0" :max="100" show-input style="max-width: 460px" />
        </el-form-item>
        <el-form-item label="报告正文" prop="content">
          <el-input
            v-model="form.content"
            type="textarea"
            :rows="10"
            maxlength="8000"
            show-word-limit
            placeholder="已完成工作、存在问题、后续计划"
          />
        </el-form-item>
        <el-form-item label="附件">
          <FileUploader v-model="attachments" biz-type="MIDTERM" multiple />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="saving" :disabled="!canSubmit" @click="submit">
            {{ mine ? '重新提交' : '提交中期报告' }}
          </el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 教师 / 管理员 -->
    <el-card v-else shadow="never">
      <el-tabs v-model="activeTab" @tab-change="onTabChange">
        <el-tab-pane label="报告列表" name="list" />
        <el-tab-pane label="超期预警" name="alerts" />
      </el-tabs>

      <template v-if="activeTab === 'list'">
        <div class="search-bar">
          <el-input v-model="query.keyword" placeholder="学生姓名 / 论文题目" clearable @keyup.enter="load" />
          <el-select v-model="query.reviewStatus" placeholder="检查状态" clearable>
            <el-option label="待检查" value="PENDING" />
            <el-option label="已通过" value="APPROVED" />
            <el-option label="已驳回" value="REJECTED" />
          </el-select>
          <el-button type="primary" @click="load">查询</el-button>
        </div>

        <el-table v-loading="loading" :data="list" border stripe>
          <el-table-column prop="studentName" label="学生" width="100" />
          <el-table-column v-if="!isMobile" prop="studentNo" label="学号" width="120" />
          <el-table-column prop="thesisTitle" label="论文题目" min-width="200" show-overflow-tooltip />
          <el-table-column label="进度" width="120" align="center">
            <template #default="{ row }">
              <el-progress :percentage="Number(row.progressPercent ?? 0)" :stroke-width="10" />
            </template>
          </el-table-column>
          <el-table-column v-if="!isMobile" prop="submitTime" label="提交时间" width="160" />
          <el-table-column label="状态" width="100" align="center">
            <template #default="{ row }">
              <StatusTag :status="row.reviewStatus" kind="review" />
            </template>
          </el-table-column>
          <el-table-column label="操作" width="160" fixed="right">
            <template #default="{ row }">
              <el-button text type="primary" size="small" @click="openDetail(row)">查看</el-button>
              <el-button
                v-if="row.reviewStatus === 'PENDING' && canReview"
                text
                type="success"
                size="small"
                @click="openDetail(row, true)"
              >
                检查
              </el-button>
            </template>
          </el-table-column>
        </el-table>

        <div class="pagination-wrap">
          <el-pagination
            v-model:current-page="query.pageNum"
            v-model:page-size="query.pageSize"
            :total="total"
            :page-sizes="[10, 20, 50]"
            layout="total, sizes, prev, pager, next"
            background
            @change="load"
          />
        </div>
      </template>

      <template v-else>
        <el-alert
          class="mb-16"
          type="warning"
          :closable="false"
          show-icon
          title="以下几种情况会被列入超期预警：待提交开题、待提交中期、待提交定稿，且已过系统配置中的截止日期。"
        />
        <el-table v-loading="alertsLoading" :data="alerts" border stripe>
          <el-table-column prop="studentName" label="学生" width="100" />
          <el-table-column v-if="!isMobile" prop="studentNo" label="学号" width="120" />
          <el-table-column prop="title" label="论文题目" min-width="200" show-overflow-tooltip />
          <el-table-column prop="statusLabel" label="当前阶段" width="120" />
          <el-table-column prop="task" label="待提交" width="100" align="center" />
          <el-table-column prop="advisorName" label="指导教师" width="110" />
          <el-table-column prop="deadline" label="截止日期" width="160" />
          <el-table-column label="超期天数" width="100" align="center">
            <template #default="{ row }">
              <el-tag type="danger" effect="plain" size="small">{{ row.overdueDays }} 天</el-tag>
            </template>
          </el-table-column>
        </el-table>
      </template>
    </el-card>

    <!-- 检查弹窗 -->
    <el-dialog v-model="detailVisible" title="中期报告" width="min(680px, 94vw)">
      <template v-if="current">
        <el-descriptions :column="1" border size="small" class="mb-16">
          <el-descriptions-item label="学生">
            {{ current.studentName }}（{{ current.studentNo }}）
          </el-descriptions-item>
          <el-descriptions-item label="论文题目">{{ current.thesisTitle }}</el-descriptions-item>
          <el-descriptions-item label="完成进度">{{ current.progressPercent ?? 0 }}%</el-descriptions-item>
          <el-descriptions-item label="提交时间">{{ current.submitTime }}</el-descriptions-item>
        </el-descriptions>
        <div class="content-block mb-16">{{ current.content }}</div>
        <div class="mb-16">
          <span class="text-muted">附件：</span>
          <AttachmentList :ids="current.attachmentIds" />
        </div>

        <template v-if="current.reviewStatus === 'PENDING' && canReview">
          <el-form label-width="80px">
            <el-form-item label="检查结论">
              <el-radio-group v-model="reviewForm.decision">
                <el-radio value="APPROVED">通过</el-radio>
                <el-radio value="REJECTED">退回修改</el-radio>
              </el-radio-group>
            </el-form-item>
            <el-form-item label="中期成绩">
              <el-input-number v-model="reviewForm.score" :min="0" :max="100" :precision="1" />
            </el-form-item>
            <el-form-item label="检查意见">
              <el-input v-model="reviewForm.comment" type="textarea" :rows="3" maxlength="1000" />
            </el-form-item>
          </el-form>
        </template>
        <el-alert
          v-else-if="current.reviewComment"
          :title="`检查意见：${current.reviewComment}`"
          :type="current.reviewStatus === 'APPROVED' ? 'success' : 'warning'"
          :closable="false"
        />
      </template>
      <template #footer>
        <el-button @click="detailVisible = false">关闭</el-button>
        <el-button
          v-if="current?.reviewStatus === 'PENDING' && canReview"
          type="primary"
          :loading="saving"
          @click="submitReview"
        >
          提交检查
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage, type FormInstance, type FormRules } from 'element-plus'
import { fileApi, midtermApi } from '@/api'
import { useUserStore } from '@/stores/user'
import { useResponsive } from '@/composables/useResponsive'
import StatusTag from '@/components/StatusTag.vue'
import FileUploader from '@/components/FileUploader.vue'
import AttachmentList from '@/components/AttachmentList.vue'
import type { Attachment, MidtermReport, PageQuery } from '@/types'

const userStore = useUserStore()
const { isMobile } = useResponsive()

const canReview = computed(() => userStore.isAdvisor || userStore.isAdmin)

const loading = ref(false)
const alertsLoading = ref(false)
const saving = ref(false)
const list = ref<MidtermReport[]>([])
const total = ref(0)
const mine = ref<MidtermReport | null>(null)
const alerts = ref<Record<string, unknown>[]>([])
const activeTab = ref('list')

const query = reactive<PageQuery>({ pageNum: 1, pageSize: 10, keyword: '', reviewStatus: '' })

const formRef = ref<FormInstance>()
const form = reactive({ content: '', progressPercent: 50 })
const attachments = ref<Attachment[]>([])

const canSubmit = computed(
  () => !mine.value || ['REJECTED', 'PENDING'].includes(mine.value.reviewStatus ?? '')
)

const rules: FormRules = {
  content: [{ required: true, message: '请填写中期报告正文', trigger: 'blur' }]
}

const detailVisible = ref(false)
const current = ref<MidtermReport | null>(null)
const reviewForm = reactive({ decision: 'APPROVED', score: 85 as number | undefined, comment: '' })

async function load() {
  if (userStore.isStudent) {
    mine.value = await midtermApi.mine()
    if (mine.value) {
      form.content = mine.value.content ?? ''
      form.progressPercent = mine.value.progressPercent ?? 50
      if (mine.value.attachmentIds) {
        attachments.value = await fileApi.listByIds(mine.value.attachmentIds)
      }
    }
    return
  }
  loading.value = true
  try {
    const res = await midtermApi.page({ ...query })
    list.value = res.records
    total.value = res.total
  } finally {
    loading.value = false
  }
}

async function loadAlerts() {
  alertsLoading.value = true
  try {
    alerts.value = await midtermApi.alerts()
  } finally {
    alertsLoading.value = false
  }
}

function onTabChange(name: string | number) {
  if (name === 'alerts') {
    loadAlerts()
  }
}

async function submit() {
  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid) return
  saving.value = true
  try {
    const ids = attachments.value.map((item) => item.id as number)
    const saved = await midtermApi.submit({
      content: form.content,
      progressPercent: form.progressPercent
    })
    if (saved.id && ids.length) {
      await fileApi.bind({ bizType: 'MIDTERM', bizId: saved.id, ids })
    }
    ElMessage.success('中期报告已提交，等待指导教师检查')
    load()
  } finally {
    saving.value = false
  }
}

function openDetail(row: MidtermReport, editable = false) {
  current.value = row
  reviewForm.decision = editable ? 'APPROVED' : row.reviewStatus === 'REJECTED' ? 'REJECTED' : 'APPROVED'
  reviewForm.score = 85
  reviewForm.comment = ''
  detailVisible.value = true
}

async function submitReview() {
  if (!current.value?.id) return
  saving.value = true
  try {
    await midtermApi.review(current.value.id, {
      decision: reviewForm.decision,
      comment: reviewForm.comment,
      score: reviewForm.score
    })
    ElMessage.success('检查已提交')
    detailVisible.value = false
    load()
  } finally {
    saving.value = false
  }
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
  max-height: 320px;
  overflow-y: auto;
}
</style>
