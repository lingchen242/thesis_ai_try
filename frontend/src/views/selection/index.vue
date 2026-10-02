<template>
  <div>
    <!-- 学生视角：我的选题申请 -->
    <el-card v-if="userStore.isStudent" shadow="never" class="mb-16">
      <template #header><span>我的选题申请</span></template>
      <div v-if="mySelection">
        <el-descriptions :column="isMobile ? 1 : 2" border size="small">
          <el-descriptions-item label="课题名称">{{ mySelection.topicTitle }}</el-descriptions-item>
          <el-descriptions-item label="指导教师">{{ mySelection.teacherName || '-' }}</el-descriptions-item>
          <el-descriptions-item label="申报时间">{{ mySelection.applyTime || '-' }}</el-descriptions-item>
          <el-descriptions-item label="状态">
            <StatusTag :status="mySelection.status" kind="selection" />
          </el-descriptions-item>
          <el-descriptions-item label="申请说明">{{ mySelection.studentRemark || '-' }}</el-descriptions-item>
          <el-descriptions-item label="教师意见">{{ mySelection.teacherComment || '-' }}</el-descriptions-item>
        </el-descriptions>
      </div>
      <el-empty v-else description="还没有申报课题，请到「课题管理」中挑选" />
    </el-card>

    <!-- 教师 / 管理员视角：审核列表 -->
    <el-card shadow="never">
      <div class="search-bar">
        <el-input v-model="query.keyword" placeholder="学生姓名 / 学号" clearable @keyup.enter="load" />
        <el-select v-model="query.status" placeholder="状态" clearable>
          <el-option v-for="item in statusOptions" :key="item.value" :label="item.label" :value="item.value" />
        </el-select>
        <el-button type="primary" @click="load">查询</el-button>
        <el-button @click="reset">重置</el-button>
      </div>

      <el-table v-loading="loading" :data="list" border stripe>
        <el-table-column prop="studentName" label="学生" width="100" />
        <el-table-column v-if="!isMobile" prop="studentNo" label="学号" width="120" />
        <el-table-column v-if="!isMobile" prop="className" label="班级" width="130" />
        <el-table-column prop="topicTitle" label="申报课题" min-width="200" show-overflow-tooltip />
        <el-table-column v-if="!isMobile" prop="applyTime" label="申报时间" width="160" />
        <el-table-column label="状态" width="100" align="center">
          <template #default="{ row }">
            <StatusTag :status="row.status" kind="selection" />
          </template>
        </el-table-column>
        <el-table-column label="操作" width="170" fixed="right">
          <template #default="{ row }">
            <template v-if="row.status === 'PENDING'">
              <el-button text type="success" size="small" @click="decide(row, true)">录取</el-button>
              <el-button text type="danger" size="small" @click="decide(row, false)">驳回</el-button>
            </template>
            <el-button v-else text size="small" @click="showDetail(row)">查看</el-button>
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

    <el-dialog v-model="detailVisible" title="选题申请详情" width="min(560px, 92vw)">
      <el-descriptions v-if="current" :column="1" border size="small">
        <el-descriptions-item label="学生">
          {{ current.studentName }}（{{ current.studentNo }}）
        </el-descriptions-item>
        <el-descriptions-item label="班级">{{ current.className || '-' }}</el-descriptions-item>
        <el-descriptions-item label="课题">{{ current.topicTitle }}</el-descriptions-item>
        <el-descriptions-item label="申请说明">{{ current.studentRemark || '-' }}</el-descriptions-item>
        <el-descriptions-item label="教师意见">{{ current.teacherComment || '-' }}</el-descriptions-item>
      </el-descriptions>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { selectionApi } from '@/api'
import { useUserStore } from '@/stores/user'
import { useResponsive } from '@/composables/useResponsive'
import { SELECTION_STATUS } from '@/constants'
import StatusTag from '@/components/StatusTag.vue'
import type { PageQuery, Selection } from '@/types'

const userStore = useUserStore()
const { isMobile } = useResponsive()

const statusOptions = Object.entries(SELECTION_STATUS).map(([value, item]) => ({
  value,
  label: item.label
}))

const loading = ref(false)
const list = ref<Selection[]>([])
const total = ref(0)
const mySelection = ref<Selection | null>(null)
const detailVisible = ref(false)
const current = ref<Selection | null>(null)

const query = reactive<PageQuery>({ pageNum: 1, pageSize: 10, keyword: '', status: '' })

async function load() {
  if (userStore.isStudent) {
    mySelection.value = await selectionApi.mine()
    return
  }
  loading.value = true
  try {
    const res = await selectionApi.page({ ...query })
    list.value = res.records
    total.value = res.total
  } finally {
    loading.value = false
  }
}

function reset() {
  query.keyword = ''
  query.status = ''
  query.pageNum = 1
  load()
}

async function decide(row: Selection, approved: boolean) {
  const action = approved ? '录取' : '驳回'
  const { value } = await ElMessageBox.prompt(
    `确定${action} ${row.studentName} 对该课题的申报？`,
    `${action}选题申请`,
    {
      inputType: 'textarea',
      inputPlaceholder: `请填写${action}意见（选填）`,
      confirmButtonText: action,
      type: approved ? 'success' : 'warning'
    }
  ).catch(() => ({ value: undefined as string | undefined }))
  if (value === undefined) return
  if (approved) {
    await selectionApi.approve(row.id as number, value)
  } else {
    await selectionApi.reject(row.id as number, value)
  }
  ElMessage.success(`${action}成功`)
  load()
}

function showDetail(row: Selection) {
  current.value = row
  detailVisible.value = true
}

onMounted(load)
</script>
