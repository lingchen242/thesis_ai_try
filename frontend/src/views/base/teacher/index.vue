<template>
  <el-card shadow="never">
    <div class="search-bar">
      <el-input v-model="query.keyword" placeholder="姓名 / 工号" clearable @keyup.enter="load" />
      <el-select v-model="query.college" placeholder="学院" clearable>
        <el-option v-for="item in collegeOptions" :key="item.id" :label="item.itemName" :value="item.itemName" />
      </el-select>
      <el-select v-model="query.teacherType" placeholder="教师类型" clearable>
        <el-option label="指导教师" value="ADVISOR" />
        <el-option label="评阅教师" value="REVIEWER" />
      </el-select>
      <el-button type="primary" @click="load">查询</el-button>
      <el-button @click="reset">重置</el-button>
    </div>

    <div class="table-toolbar">
      <span class="text-muted">共 {{ total }} 名教师</span>
      <el-button type="primary" @click="openForm()">
        <el-icon><Plus /></el-icon>新增教师
      </el-button>
    </div>

    <el-table v-loading="loading" :data="list" border stripe>
      <el-table-column prop="teacherNo" label="工号" width="110" />
      <el-table-column prop="realName" label="姓名" width="100" />
      <el-table-column prop="title" label="职称" width="100" />
      <el-table-column v-if="!isMobile" prop="college" label="学院" min-width="170" show-overflow-tooltip />
      <el-table-column v-if="!isMobile" prop="major" label="专业" min-width="140" show-overflow-tooltip />
      <el-table-column label="类型" width="120" align="center">
        <template #default="{ row }">
          <el-tag size="small" effect="plain">{{ TEACHER_TYPE[row.teacherType] ?? row.teacherType }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="指导学生" width="90" align="center">
        <template #default="{ row }">{{ row.studentCount ?? 0 }} / {{ row.maxQuota ?? '-' }}</template>
      </el-table-column>
      <el-table-column label="可评阅" width="80" align="center">
        <template #default="{ row }">
          <el-tag v-if="row.canReview" size="small" type="success" effect="plain">是</el-tag>
          <span v-else class="text-muted">否</span>
        </template>
      </el-table-column>
      <el-table-column label="操作" :width="isMobile ? 90 : 210" fixed="right">
        <template #default="{ row }">
          <el-button text type="primary" size="small" @click="openForm(row)">编辑</el-button>
          <el-button text type="warning" size="small" @click="resetPassword(row)">重置密码</el-button>
          <el-button v-if="!isMobile" text type="danger" size="small" @click="remove(row)">删除</el-button>
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

  <el-drawer v-model="formVisible" :title="form.id ? '编辑教师' : '新增教师'" size="min(560px, 94%)">
    <el-form ref="formRef" :model="form" :rules="rules" label-width="100px">
      <el-form-item label="工号" prop="teacherNo">
        <el-input v-model="form.teacherNo" maxlength="32" placeholder="同时作为登录账号" />
      </el-form-item>
      <el-form-item label="姓名" prop="realName">
        <el-input v-model="form.realName" maxlength="50" />
      </el-form-item>
      <el-form-item label="性别">
        <el-radio-group v-model="form.gender">
          <el-radio :value="1">男</el-radio>
          <el-radio :value="2">女</el-radio>
          <el-radio :value="0">未知</el-radio>
        </el-radio-group>
      </el-form-item>
      <el-form-item label="教师类型" prop="teacherType">
        <el-radio-group v-model="form.teacherType">
          <el-radio value="ADVISOR">指导教师</el-radio>
          <el-radio value="REVIEWER">评阅教师</el-radio>
        </el-radio-group>
      </el-form-item>
      <el-form-item label="职称">
        <el-select v-model="form.title" clearable style="width: 100%">
          <el-option v-for="item in titleOptions" :key="item.id" :label="item.itemName" :value="item.itemName" />
        </el-select>
      </el-form-item>
      <el-form-item label="学院">
        <el-select v-model="form.college" clearable style="width: 100%">
          <el-option v-for="item in collegeOptions" :key="item.id" :label="item.itemName" :value="item.itemName" />
        </el-select>
      </el-form-item>
      <el-form-item label="专业">
        <el-select v-model="form.major" clearable style="width: 100%">
          <el-option v-for="item in majorOptions" :key="item.id" :label="item.itemName" :value="item.itemName" />
        </el-select>
      </el-form-item>
      <el-form-item label="最大指导学生数">
        <el-input-number v-model="form.maxQuota" :min="0" :max="50" />
      </el-form-item>
      <el-form-item label="可被指派评阅">
        <el-switch v-model="canReviewSwitch" />
      </el-form-item>
      <el-form-item label="手机号">
        <el-input v-model="form.phone" maxlength="20" />
      </el-form-item>
      <el-form-item label="邮箱">
        <el-input v-model="form.email" maxlength="100" />
      </el-form-item>
      <el-form-item v-if="!form.id" label="初始密码">
        <el-input v-model="password" placeholder="留空则使用系统默认密码" />
      </el-form-item>
      <el-form-item>
        <el-button type="primary" :loading="saving" @click="save">保存</el-button>
        <el-button @click="formVisible = false">取消</el-button>
      </el-form-item>
    </el-form>
  </el-drawer>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox, type FormInstance, type FormRules } from 'element-plus'
import { userApi } from '@/api'
import { useDictStore } from '@/stores/dict'
import { useResponsive } from '@/composables/useResponsive'
import { DICT, TEACHER_TYPE } from '@/constants'
import type { DictItem, PageQuery, Teacher } from '@/types'

const dictStore = useDictStore()
const { isMobile } = useResponsive()

const loading = ref(false)
const saving = ref(false)
const list = ref<Teacher[]>([])
const total = ref(0)

const collegeOptions = ref<DictItem[]>([])
const majorOptions = ref<DictItem[]>([])
const titleOptions = ref<DictItem[]>([])

const query = reactive<PageQuery>({ pageNum: 1, pageSize: 10, keyword: '', college: '', teacherType: '' })

const formVisible = ref(false)
const formRef = ref<FormInstance>()
const form = reactive<Teacher>(emptyForm())
const password = ref('')

const canReviewSwitch = computed({
  get: () => form.canReview === 1,
  set: (value: boolean) => {
    form.canReview = value ? 1 : 0
  }
})

const rules: FormRules = {
  teacherNo: [{ required: true, message: '请输入工号', trigger: 'blur' }],
  realName: [{ required: true, message: '请输入姓名', trigger: 'blur' }],
  teacherType: [{ required: true, message: '请选择教师类型', trigger: 'change' }]
}

function emptyForm(): Teacher {
  return {
    teacherNo: '',
    realName: '',
    gender: 0,
    teacherType: 'ADVISOR',
    title: '',
    college: '',
    major: '',
    maxQuota: 8,
    canReview: 0,
    phone: '',
    email: ''
  }
}

async function load() {
  loading.value = true
  try {
    const res = await userApi.pageTeachers({ ...query })
    list.value = res.records
    total.value = res.total
  } finally {
    loading.value = false
  }
}

function reset() {
  query.keyword = ''
  query.college = ''
  query.teacherType = ''
  query.pageNum = 1
  load()
}

function openForm(row?: Teacher) {
  Object.assign(form, row ? { ...row } : emptyForm())
  password.value = ''
  formVisible.value = true
}

async function save() {
  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid) return
  saving.value = true
  try {
    if (form.id) {
      await userApi.updateTeacher(form.id, form)
    } else {
      await userApi.createTeacher(form, password.value || undefined)
    }
    ElMessage.success('保存成功')
    formVisible.value = false
    load()
  } finally {
    saving.value = false
  }
}

async function resetPassword(row: Teacher) {
  const { value } = await ElMessageBox.prompt(`为「${row.realName}」设置新密码（留空使用默认密码）`, '重置密码', {
    inputValue: ''
  }).catch(() => ({ value: undefined as string | undefined }))
  if (value === undefined) return
  await userApi.resetPassword(row.userId as number, value || undefined)
  ElMessage.success('密码已重置')
}

async function remove(row: Teacher) {
  await ElMessageBox.confirm(`确定删除教师「${row.realName}」？`, '提示', { type: 'warning' })
  await userApi.deleteTeacher(row.id as number)
  ElMessage.success('已删除')
  load()
}

onMounted(async () => {
  collegeOptions.value = await dictStore.loadRoot(DICT.COLLEGE, true)
  majorOptions.value = await dictStore.load(DICT.MAJOR, true)
  titleOptions.value = await dictStore.loadRoot(DICT.TITLE, true)
  load()
})
</script>
