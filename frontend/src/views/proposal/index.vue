<template>
  <div>
    <!-- 学生：提交 / 查看开题报告 -->
    <el-card v-if="userStore.isStudent" shadow="never">
      <template #header>
        <div class="table-toolbar" style="margin-bottom: 0">
          <span>开题报告</span>
          <StatusTag v-if="mine" :status="mine.reviewStatus" kind="review" />
        </div>
      </template>

      <el-alert
        v-if="!canSubmit && mine"
        class="mb-16"
        :type="mine.reviewStatus === 'APPROVED' ? 'success' : 'warning'"
        :title="
          mine.reviewStatus === 'APPROVED'
            ? '开题已通过，如需修改请联系指导教师'
            : mine.reviewStatus === 'REJECTED'
              ? '开题被退回，请修改后重新提交'
              : '开题报告已提交，等待指导教师审核'
        "
        :description="mine.reviewComment || ''"
        :closable="false"
        show-icon
      />

      <el-form ref="formRef" :model="form" :rules="rules" label-width="90px">
        <el-form-item label="报告正文" prop="content">
          <el-input
            v-model="form.content"
            type="textarea"
            :rows="12"
            maxlength="8000"
            show-word-limit
            placeholder="请填写研究背景、研究内容、技术路线、进度安排等"
          />
        </el-form-item>
        <el-form-item label="附件">
          <FileUploader v-model="attachments" biz-type="PROPOSAL" multiple />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="saving" :disabled="!canSubmit" @click="submit">
            {{ mine ? '重新提交' : '提交开题报告' }}
          </el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 教师 / 管理员：审核列表 -->
    <el-card v-else shadow="never">
      <div class="search-bar">
        <el-input v-model="query.keyword" placeholder="学生姓名 / 论文题目" clearable @keyup.enter="load" />
        <el-select v-model="query.reviewStatus" placeholder="审核状态" clearable>
          <el-option label="待审核" value="PENDING" />
          <el-option label="已通过" value="APPROVED" />
          <el-option label="已驳回" value="REJECTED" />
        </el-select>
        <el-button type="primary" @click="load">查询</el-button>
        <el-button @click="load">刷新</el-button>
      </div>

      <el-table v-loading="loading" :data="list" border stripe>
        <el-table-column prop="studentName" label="学生" width="100" />
        <el-table-column v-if="!isMobile" prop="studentNo" label="学号" width="120" />
        <el-table-column prop="thesisTitle" label="论文题目" min-width="200" show-overflow-tooltip />
        <el-table-column v-if="!isMobile" prop="submitTime" label="提交时间" width="160" />
        <el-table-column label="状态" width="100" align="center">
          <template #default="{ row }">
            <StatusTag :status="row.reviewStatus" kind="review" />
          </template>
        </el-table-column>
        <el-table-column v-if="!isMobile" prop="score" label="成绩" width="80" align="center" />
        <el-table-column label="操作" width="190" fixed="right">
          <template #default="{ row }">
            <el-button text type="primary" size="small" @click="openReview(row)">查看</el-button>
            <template v-if="row.reviewStatus === 'PENDING' && canReview">
              <el-button text type="success" size="small" @click="openReview(row, true)">
                审核
              </el-button>
            </template>
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
    </el-card>

    <!-- 审核弹窗 -->
    <el-dialog v-model="reviewVisible" title="开题报告审核" width="min(680px, 94vw)">
      <template v-if="current">
        <el-descriptions :column="1" border size="small" class="mb-16">
          <el-descriptions-item label="学生">
            {{ current.studentName }}（{{ current.studentNo }}）
          </el-descriptions-item>
          <el-descriptions-item label="论文题目">{{ current.thesisTitle }}</el-descriptions-item>
          <el-descriptions-item label="提交时间">{{ current.submitTime }}</el-descriptions-item>
        </el-descriptions>
        <div class="content-block mb-16">{{ current.content }}</div>
        <div class="mb-16">
          <span class="text-muted">附件：</span>
          <AttachmentList :ids="current.attachmentIds" />
        </div>

        <template v-if="current.reviewStatus === 'PENDING' && canReview">
          <el-form label-width="80px">
            <el-form-item label="审核结论">
              <el-radio-group v-model="reviewForm.decision">
                <el-radio value="APPROVED">通过</el-radio>
                <el-radio value="REJECTED">退回修改</el-radio>
              </el-radio-group>
            </el-form-item>
            <el-form-item label="开题成绩">
              <el-input-number v-model="reviewForm.score" :min="0" :max="100" :precision="1" />
            </el-form-item>
            <el-form-item label="审核意见">
              <el-input v-model="reviewForm.comment" type="textarea" :rows="3" maxlength="1000" />
            </el-form-item>
          </el-form>
        </template>
        <el-alert
          v-else-if="current.reviewComment"
          :title="`审核意见：${current.reviewComment}`"
          :type="current.reviewStatus === 'APPROVED' ? 'success' : 'warning'"
          :closable="false"
        />
      </template>
      <template #footer>
        <el-button @click="reviewVisible = false">关闭</el-button>
        <el-button
          v-if="current?.reviewStatus === 'PENDING' && canReview"
          type="primary"
          :loading="saving"
          @click="submitReview"
        >
          提交审核
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage, type FormInstance, type FormRules } from 'element-plus'
import { fileApi, proposalApi } from '@/api'
import { useUserStore } from '@/stores/user'
import { useResponsive } from '@/composables/useResponsive'
import StatusTag from '@/components/StatusTag.vue'
import FileUploader from '@/components/FileUploader.vue'
import AttachmentList from '@/components/AttachmentList.vue'
import type { Attachment, PageQuery, Proposal } from '@/types'

const userStore = useUserStore()
const { isMobile } = useResponsive()

const canReview = computed(() => userStore.isAdvisor || userStore.isAdmin)

const loading = ref(false)
const saving = ref(false)
const list = ref<Proposal[]>([])
const total = ref(0)
const mine = ref<Proposal | null>(null)

const query = reactive<PageQuery>({ pageNum: 1, pageSize: 10, keyword: '', reviewStatus: '' })

const formRef = ref<FormInstance>()
const form = reactive({ content: '' })
const attachments = ref<Attachment[]>([])

const canSubmit = computed(
  () => !mine.value || ['REJECTED', 'PENDING'].includes(mine.value.reviewStatus ?? '')
)

const rules: FormRules = {
  content: [{ required: true, message: '请填写开题报告正文', trigger: 'blur' }]
}

const reviewVisible = ref(false)
const current = ref<Proposal | null>(null)
const reviewForm = reactive({ decision: 'APPROVED', score: 85 as number | undefined, comment: '' })

async function load() {
  if (userStore.isStudent) {
    mine.value = await proposalApi.mine()
    if (mine.value) {
      form.content = mine.value.content ?? ''
      if (mine.value.attachmentIds) {
        attachments.value = await fileApi.listByIds(mine.value.attachmentIds)
      }
    }
    return
  }
  loading.value = true
  try {
    const res = await proposalApi.page({ ...query })
    list.value = res.records
    total.value = res.total
  } finally {
    loading.value = false
  }
}

async function submit() {
  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid) return
  saving.value = true
  try {
    const ids = attachments.value.map((item) => item.id as number)
    const saved = await proposalApi.submit({ content: form.content })
    if (saved.id && ids.length) {
      await fileApi.bind({ bizType: 'PROPOSAL', bizId: saved.id, ids })
    }
    ElMessage.success('开题报告已提交，等待指导教师审核')
    load()
  } finally {
    saving.value = false
  }
}

function openReview(row: Proposal, editable = false) {
  current.value = row
  reviewForm.decision = 'APPROVED'
  reviewForm.score = 85
  reviewForm.comment = ''
  reviewVisible.value = true
  if (!editable) {
    reviewForm.decision = row.reviewStatus === 'REJECTED' ? 'REJECTED' : 'APPROVED'
  }
}

async function submitReview() {
  if (!current.value?.id) return
  saving.value = true
  try {
    await proposalApi.review(current.value.id, {
      decision: reviewForm.decision,
      comment: reviewForm.comment,
      score: reviewForm.score
    })
    ElMessage.success('审核已提交')
    reviewVisible.value = false
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
