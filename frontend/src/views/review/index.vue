<template>
  <el-card shadow="never">
    <el-tabs v-model="activeTab" @tab-change="onTabChange">
      <el-tab-pane v-if="userStore.isReviewer" label="待我评阅" name="mine" />
      <el-tab-pane v-if="canAssign" label="评阅指派" name="assign" />
      <el-tab-pane label="评阅记录" name="all" />
    </el-tabs>

    <!-- 评阅教师任务 -->
    <template v-if="activeTab === 'mine'">
      <el-table v-loading="loading" :data="mine" border stripe>
        <el-table-column prop="studentName" label="学生" width="100" />
        <el-table-column v-if="!isMobile" prop="studentNo" label="学号" width="120" />
        <el-table-column prop="thesisTitle" label="论文题目" min-width="200" show-overflow-tooltip />
        <el-table-column label="盲审" width="70" align="center">
          <template #default="{ row }">
            <el-tag v-if="row.blind" size="small" type="warning" effect="plain">是</el-tag>
            <span v-else>-</span>
          </template>
        </el-table-column>
        <el-table-column v-if="!isMobile" prop="assignTime" label="指派时间" width="160" />
        <el-table-column label="状态" width="90" align="center">
          <template #default="{ row }">
            <StatusTag :status="row.status" kind="reviewTask" />
          </template>
        </el-table-column>
        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-link v-if="row.fileUrl" type="primary" :href="row.fileUrl" target="_blank" class="mr-8">
              定稿
            </el-link>
            <el-button
              v-if="row.status === 'PENDING'"
              text
              type="primary"
              size="small"
              @click="openSubmit(row)"
            >
              评阅
            </el-button>
            <el-button v-else text size="small" @click="openSubmit(row)">查看</el-button>
          </template>
        </el-table-column>
      </el-table>
    </template>

    <!-- 管理员指派 -->
    <template v-else-if="activeTab === 'assign'">
      <el-alert
        class="mb-16"
        type="info"
        :closable="false"
        show-icon
        title="以下论文已提交定稿，尚未指派评阅教师。不选择评阅教师时系统会自动指派当前任务最少的教师。"
      />
      <el-table v-loading="loading" :data="pending" border stripe>
        <el-table-column prop="studentName" label="学生" width="100" />
        <el-table-column v-if="!isMobile" prop="studentNo" label="学号" width="120" />
        <el-table-column prop="title" label="论文题目" min-width="200" show-overflow-tooltip />
        <el-table-column v-if="!isMobile" prop="advisorName" label="指导教师" width="110" />
        <el-table-column v-if="!isMobile" prop="submitTime" label="定稿提交" width="160" />
        <el-table-column label="操作" width="110" fixed="right">
          <template #default="{ row }">
            <el-button text type="primary" size="small" @click="openAssign(row)">指派评阅</el-button>
          </template>
        </el-table-column>
      </el-table>
    </template>

    <!-- 全部记录 -->
    <template v-else>
      <div class="search-bar">
        <el-select v-model="query.status" placeholder="评阅状态" clearable>
          <el-option label="待评阅" value="PENDING" />
          <el-option label="已提交" value="SUBMITTED" />
        </el-select>
        <el-input v-model="query.grade" placeholder="届别" clearable />
        <el-button type="primary" @click="load">查询</el-button>
      </div>
      <el-table v-loading="loading" :data="list" border stripe>
        <el-table-column prop="studentName" label="学生" width="100" />
        <el-table-column prop="thesisTitle" label="论文题目" min-width="200" show-overflow-tooltip />
        <el-table-column v-if="!isMobile" prop="reviewerName" label="评阅教师" width="110" />
        <el-table-column prop="score" label="成绩" width="80" align="center" />
        <el-table-column v-if="!isMobile" prop="submitTime" label="提交时间" width="160" />
        <el-table-column label="状态" width="90" align="center">
          <template #default="{ row }">
            <StatusTag :status="row.status" kind="reviewTask" />
          </template>
        </el-table-column>
        <el-table-column prop="comment" label="评阅意见" min-width="200" show-overflow-tooltip />
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
  </el-card>

  <!-- 指派 -->
  <el-dialog v-model="assignVisible" title="指派评阅教师" width="min(480px, 92vw)">
    <div class="mb-16">
      <div style="font-weight: 600">{{ current?.title }}</div>
      <div class="text-muted mt-8">{{ current?.studentName }}（{{ current?.studentNo }}）</div>
    </div>
    <el-form label-width="90px">
      <el-form-item label="评阅教师">
        <el-select v-model="assignForm.reviewerId" placeholder="留空则自动指派" clearable style="width: 100%">
          <el-option
            v-for="item in reviewers"
            :key="item.id"
            :label="`${item.realName}（${item.teacherNo}）`"
            :value="item.id as number"
          />
        </el-select>
      </el-form-item>
      <el-form-item label="盲审">
        <el-switch v-model="assignForm.blind" />
      </el-form-item>
    </el-form>
    <template #footer>
      <el-button @click="assignVisible = false">取消</el-button>
      <el-button type="primary" :loading="saving" @click="submitAssign">确认指派</el-button>
    </template>
  </el-dialog>

  <!-- 评阅 -->
  <el-dialog v-model="submitVisible" :title="currentReview?.status === 'PENDING' ? '提交评阅意见' : '评阅详情'" width="min(600px, 94vw)">
    <template v-if="currentReview">
      <el-descriptions :column="1" border size="small" class="mb-16">
        <el-descriptions-item label="学生">
          {{ currentReview.studentName }}（{{ currentReview.studentNo }}）
        </el-descriptions-item>
        <el-descriptions-item label="论文题目">{{ currentReview.thesisTitle }}</el-descriptions-item>
        <el-descriptions-item label="指派时间">{{ currentReview.assignTime }}</el-descriptions-item>
      </el-descriptions>

      <el-form v-if="currentReview.status === 'PENDING'" label-width="90px">
        <el-form-item label="评阅成绩">
          <el-input-number v-model="submitForm.score" :min="0" :max="100" :precision="1" />
          <span class="text-muted" style="margin-left: 8px">低于 60 分将退回学生重交</span>
        </el-form-item>
        <el-form-item label="评阅意见">
          <el-input v-model="submitForm.comment" type="textarea" :rows="5" maxlength="2000" show-word-limit />
        </el-form-item>
      </el-form>
      <template v-else>
        <el-descriptions :column="1" border size="small">
          <el-descriptions-item label="评阅成绩">{{ currentReview.score ?? '-' }}</el-descriptions-item>
          <el-descriptions-item label="评阅意见">{{ currentReview.comment || '-' }}</el-descriptions-item>
          <el-descriptions-item label="提交时间">{{ currentReview.submitTime }}</el-descriptions-item>
        </el-descriptions>
      </template>
    </template>
    <template #footer>
      <el-button @click="submitVisible = false">关闭</el-button>
      <el-button
        v-if="currentReview?.status === 'PENDING'"
        type="primary"
        :loading="saving"
        @click="submitReview"
      >
        提交
      </el-button>
    </template>
  </el-dialog>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { reviewApi, thesisApi, userApi } from '@/api'
import { useUserStore } from '@/stores/user'
import { useResponsive } from '@/composables/useResponsive'
import StatusTag from '@/components/StatusTag.vue'
import type { PageQuery, Review, Teacher, Thesis } from '@/types'

const userStore = useUserStore()
const { isMobile } = useResponsive()

const canAssign = computed(() => userStore.isAdmin)

const activeTab = ref(userStore.isReviewer ? 'mine' : canAssign.value ? 'assign' : 'all')
const loading = ref(false)
const saving = ref(false)
const mine = ref<Review[]>([])
const pending = ref<Thesis[]>([])
const list = ref<Review[]>([])
const total = ref(0)
const reviewers = ref<Teacher[]>([])

const query = reactive<PageQuery>({ pageNum: 1, pageSize: 10, status: '', grade: '' })

const assignVisible = ref(false)
const current = ref<Thesis | null>(null)
const assignForm = reactive<{ reviewerId?: number; blind: boolean }>({ reviewerId: undefined, blind: false })

const submitVisible = ref(false)
const currentReview = ref<Review | null>(null)
const submitForm = reactive<{ score?: number; comment: string }>({ score: 85, comment: '' })

async function load() {
  loading.value = true
  try {
    if (activeTab.value === 'mine') {
      mine.value = await reviewApi.mine()
    } else if (activeTab.value === 'assign') {
      const res = await thesisApi.page({ pageNum: 1, pageSize: 100, status: 'FINAL_SUBMITTED' })
      pending.value = res.records
      if (!reviewers.value.length) {
        const options = await userApi.teacherOptions()
        reviewers.value = options.reviewers
      }
    } else {
      const res = await reviewApi.page({ ...query })
      list.value = res.records
      total.value = res.total
    }
  } finally {
    loading.value = false
  }
}

function onTabChange() {
  load()
}

function openAssign(row: Thesis) {
  current.value = row
  assignForm.reviewerId = undefined
  assignForm.blind = false
  assignVisible.value = true
}

async function submitAssign() {
  if (!current.value?.id) return
  saving.value = true
  try {
    await reviewApi.assign({
      thesisId: current.value.id,
      reviewerId: assignForm.reviewerId,
      blind: assignForm.blind
    })
    ElMessage.success('指派成功')
    assignVisible.value = false
    load()
  } finally {
    saving.value = false
  }
}

function openSubmit(row: Review) {
  currentReview.value = row
  submitForm.score = row.score ?? 85
  submitForm.comment = row.comment ?? ''
  submitVisible.value = true
}

async function submitReview() {
  if (!currentReview.value?.id) return
  saving.value = true
  try {
    await reviewApi.submit(currentReview.value.id, {
      score: submitForm.score,
      comment: submitForm.comment
    })
    ElMessage.success('评阅已提交')
    submitVisible.value = false
    load()
  } finally {
    saving.value = false
  }
}

onMounted(load)
</script>

<style scoped>
.mr-8 {
  margin-right: 8px;
}
</style>
