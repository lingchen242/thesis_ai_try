<template>
  <el-card shadow="never">
    <div class="search-bar">
      <el-input v-model="query.keyword" placeholder="课题名称 / 简介" clearable @keyup.enter="load" />
      <el-select v-model="query.status" placeholder="状态" clearable>
        <el-option v-for="item in statusOptions" :key="item.value" :label="item.label" :value="item.value" />
      </el-select>
      <el-select v-model="query.grade" placeholder="届别" clearable>
        <el-option v-for="item in gradeOptions" :key="item.id" :label="item.itemName" :value="item.itemName" />
      </el-select>
      <el-button type="primary" @click="load">查询</el-button>
      <el-button @click="reset">重置</el-button>
    </div>

    <div class="table-toolbar">
      <span class="text-muted">
        共 {{ total }} 条{{ userStore.isStudent ? '（仅显示开放申报的课题）' : '' }}
      </span>
      <el-button v-if="!userStore.isStudent" type="primary" @click="openForm()">
        <el-icon><Plus /></el-icon>新建课题
      </el-button>
    </div>

    <el-table v-loading="loading" :data="list" border stripe>
      <el-table-column prop="title" label="课题名称" min-width="220" show-overflow-tooltip />
      <el-table-column prop="topicType" label="类型" width="110" />
      <el-table-column v-if="!isMobile" prop="source" label="来源" width="110" />
      <el-table-column v-if="!isMobile" prop="teacherName" label="出题教师" width="110" />
      <el-table-column v-if="!isMobile" prop="grade" label="届别" width="80" align="center" />
      <el-table-column label="容量" width="90" align="center">
        <template #default="{ row }">{{ row.selectedCount ?? 0 }} / {{ row.capacity ?? 1 }}</template>
      </el-table-column>
      <el-table-column v-if="!isMobile" label="申报数" width="80" align="center">
        <template #default="{ row }">{{ row.applyCount ?? 0 }}</template>
      </el-table-column>
      <el-table-column label="状态" width="100" align="center">
        <template #default="{ row }">
          <StatusTag :status="row.status" kind="topic" />
        </template>
      </el-table-column>
      <el-table-column label="操作" :width="isMobile ? 110 : 240" fixed="right">
        <template #default="{ row }">
          <template v-if="userStore.isStudent">
            <el-tag v-if="row.applied" size="small" type="success" effect="plain">已申报</el-tag>
            <el-button
              v-else
              text
              type="primary"
              size="small"
              :disabled="row.status !== 'OPEN'"
              @click="apply(row)"
            >
              申报
            </el-button>
            <el-button text size="small" @click="showDetail(row)">详情</el-button>
          </template>
          <template v-else>
            <el-button text type="primary" size="small" @click="openForm(row)">编辑</el-button>
            <el-button
              v-if="row.status === 'DRAFT'"
              text
              type="success"
              size="small"
              @click="publish(row)"
            >
              发布
            </el-button>
            <el-button
              v-else-if="row.status !== 'CLOSED'"
              text
              type="warning"
              size="small"
              @click="close(row)"
            >
              关闭
            </el-button>
            <el-button text type="danger" size="small" @click="remove(row)">删除</el-button>
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

  <!-- 新建 / 编辑 -->
  <el-drawer v-model="formVisible" :title="form.id ? '编辑课题' : '新建课题'" :size="drawerSize">
    <el-form ref="formRef" :model="form" :rules="rules" label-width="90px">
      <el-form-item label="课题名称" prop="title">
        <el-input v-model="form.title" maxlength="200" show-word-limit />
      </el-form-item>
      <el-form-item label="类型" prop="topicType">
        <el-select v-model="form.topicType" placeholder="请选择" style="width: 100%">
          <el-option v-for="item in typeOptions" :key="item.id" :label="item.itemName" :value="item.itemName" />
        </el-select>
      </el-form-item>
      <el-form-item label="来源" prop="source">
        <el-select v-model="form.source" placeholder="请选择" style="width: 100%">
          <el-option v-for="item in sourceOptions" :key="item.id" :label="item.itemName" :value="item.itemName" />
        </el-select>
      </el-form-item>
      <el-form-item label="届别" prop="grade">
        <el-select v-model="form.grade" placeholder="请选择" style="width: 100%">
          <el-option v-for="item in gradeOptions" :key="item.id" :label="item.itemName" :value="item.itemName" />
        </el-select>
      </el-form-item>
      <el-form-item label="可选人数" prop="capacity">
        <el-input-number v-model="form.capacity" :min="1" :max="20" />
      </el-form-item>
      <el-form-item v-if="userStore.isAdmin" label="出题教师" prop="teacherId">
        <el-select v-model="form.teacherId" placeholder="请选择" filterable style="width: 100%">
          <el-option
            v-for="item in advisors"
            :key="item.id"
            :label="`${item.realName}（${item.teacherNo}）`"
            :value="item.id as number"
          />
        </el-select>
      </el-form-item>
      <el-form-item label="课题简介">
        <el-input v-model="form.description" type="textarea" :rows="4" maxlength="1000" show-word-limit />
      </el-form-item>
      <el-form-item label="任务要求">
        <el-input v-model="form.requirement" type="textarea" :rows="4" maxlength="1000" show-word-limit />
      </el-form-item>
      <el-form-item>
        <el-button type="primary" :loading="saving" @click="save">保存</el-button>
        <el-button @click="formVisible = false">取消</el-button>
      </el-form-item>
    </el-form>
  </el-drawer>

  <!-- 申报 -->
  <el-dialog v-model="applyVisible" title="申报课题" width="min(520px, 92vw)">
    <div class="mb-16">
      <div style="font-weight: 600">{{ current?.title }}</div>
      <div class="text-muted mt-8">
        出题教师：{{ current?.teacherName }} · 容量 {{ current?.selectedCount ?? 0 }}/{{ current?.capacity ?? 1 }}
      </div>
    </div>
    <el-input v-model="applyRemark" type="textarea" :rows="4" maxlength="500" show-word-limit placeholder="申请说明（选填）" />
    <template #footer>
      <el-button @click="applyVisible = false">取消</el-button>
      <el-button type="primary" :loading="saving" @click="submitApply">提交申报</el-button>
    </template>
  </el-dialog>

  <!-- 详情 -->
  <el-dialog v-model="detailVisible" title="课题详情" width="min(620px, 92vw)">
    <el-descriptions v-if="current" :column="1" border size="small">
      <el-descriptions-item label="课题名称">{{ current.title }}</el-descriptions-item>
      <el-descriptions-item label="类型 / 来源">
        {{ current.topicType || '-' }} / {{ current.source || '-' }}
      </el-descriptions-item>
      <el-descriptions-item label="出题教师">{{ current.teacherName || '-' }}</el-descriptions-item>
      <el-descriptions-item label="届别">{{ current.grade || '-' }}</el-descriptions-item>
      <el-descriptions-item label="容量">
        {{ current.selectedCount ?? 0 }} / {{ current.capacity ?? 1 }}
      </el-descriptions-item>
      <el-descriptions-item label="课题简介">{{ current.description || '-' }}</el-descriptions-item>
      <el-descriptions-item label="任务要求">{{ current.requirement || '-' }}</el-descriptions-item>
    </el-descriptions>
  </el-dialog>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox, type FormInstance, type FormRules } from 'element-plus'
import { selectionApi, topicApi, userApi } from '@/api'
import { useUserStore } from '@/stores/user'
import { useDictOptions, useRootDictOptions } from '@/composables/useDict'
import { useResponsive } from '@/composables/useResponsive'
import { DICT, TOPIC_STATUS } from '@/constants'
import StatusTag from '@/components/StatusTag.vue'
import type { PageQuery, Teacher, Topic } from '@/types'

const userStore = useUserStore()
const { isMobile, isDesktop } = useResponsive()

const typeOptions = useDictOptions(DICT.TOPIC_TYPE)
const sourceOptions = useDictOptions(DICT.TOPIC_SOURCE)
const gradeOptions = useRootDictOptions(DICT.GRADE)

const statusOptions = Object.entries(TOPIC_STATUS).map(([value, item]) => ({ value, label: item.label }))

const loading = ref(false)
const saving = ref(false)
const list = ref<Topic[]>([])
const total = ref(0)
const advisors = ref<Teacher[]>([])

const query = reactive<PageQuery>({ pageNum: 1, pageSize: 10, keyword: '', status: '', grade: '' })

const drawerSize = computed(() => (isDesktop.value ? '520px' : '92%'))

const formVisible = ref(false)
const formRef = ref<FormInstance>()
const form = reactive<Topic>(emptyForm())

const applyVisible = ref(false)
const applyRemark = ref('')
const detailVisible = ref(false)
const current = ref<Topic | null>(null)

const rules: FormRules = {
  title: [{ required: true, message: '请输入课题名称', trigger: 'blur' }],
  topicType: [{ required: true, message: '请选择课题类型', trigger: 'change' }],
  capacity: [{ required: true, message: '请输入可选人数', trigger: 'blur' }]
}

function emptyForm(): Topic {
  return {
    title: '',
    topicType: '',
    source: '',
    grade: '',
    capacity: 1,
    description: '',
    requirement: '',
    teacherId: undefined
  }
}

async function load() {
  loading.value = true
  try {
    const res = await topicApi.page({ ...query })
    list.value = res.records
    total.value = res.total
  } finally {
    loading.value = false
  }
}

function reset() {
  query.keyword = ''
  query.status = ''
  query.grade = ''
  query.pageNum = 1
  load()
}

function openForm(row?: Topic) {
  Object.assign(form, row ? { ...row } : emptyForm())
  formVisible.value = true
  if (userStore.isAdmin && !advisors.value.length) {
    userApi.teacherOptions().then((res) => {
      advisors.value = res.advisors
    })
  }
}

async function save() {
  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid) return
  saving.value = true
  try {
    if (form.id) {
      await topicApi.update(form.id, form)
    } else {
      await topicApi.create(form)
    }
    ElMessage.success('保存成功')
    formVisible.value = false
    load()
  } finally {
    saving.value = false
  }
}

async function publish(row: Topic) {
  await topicApi.publish(row.id as number)
  ElMessage.success('课题已发布')
  load()
}

async function close(row: Topic) {
  await topicApi.close(row.id as number)
  ElMessage.success('课题已关闭')
  load()
}

async function remove(row: Topic) {
  await ElMessageBox.confirm(`确定删除课题「${row.title}」？`, '提示', { type: 'warning' })
  await topicApi.remove(row.id as number)
  ElMessage.success('已删除')
  load()
}

function apply(row: Topic) {
  current.value = row
  applyRemark.value = ''
  applyVisible.value = true
}

async function submitApply() {
  if (!current.value?.id) return
  saving.value = true
  try {
    await selectionApi.apply({ topicId: current.value.id, remark: applyRemark.value })
    ElMessage.success('申报已提交，请等待指导教师审核')
    applyVisible.value = false
    load()
  } finally {
    saving.value = false
  }
}

function showDetail(row: Topic) {
  current.value = row
  detailVisible.value = true
}

onMounted(load)
</script>
