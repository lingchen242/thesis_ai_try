<template>
  <el-card shadow="never">
    <div class="search-bar">
      <el-input v-model="query.keyword" placeholder="姓名 / 学号" clearable @keyup.enter="load" />
      <el-select v-model="query.grade" placeholder="届别" clearable>
        <el-option v-for="item in gradeOptions" :key="item.id" :label="item.itemName" :value="item.itemName" />
      </el-select>
      <el-select v-model="query.college" placeholder="学院" clearable @change="onCollegeChange">
        <el-option v-for="item in collegeOptions" :key="item.id" :label="item.itemName" :value="item.itemName" />
      </el-select>
      <el-select v-model="query.major" placeholder="专业" clearable>
        <el-option v-for="item in majorOptions" :key="item.id" :label="item.itemName" :value="item.itemName" />
      </el-select>
      <el-button type="primary" @click="load">查询</el-button>
      <el-button @click="reset">重置</el-button>
    </div>

    <div class="table-toolbar">
      <span class="text-muted">共 {{ total }} 名学生</span>
      <el-button type="primary" @click="openForm()">
        <el-icon><Plus /></el-icon>新增学生
      </el-button>
    </div>

    <el-table v-loading="loading" :data="list" border stripe>
      <el-table-column prop="studentNo" label="学号" width="120" />
      <el-table-column prop="realName" label="姓名" width="100" />
      <el-table-column prop="grade" label="届别" width="80" align="center" />
      <el-table-column v-if="!isMobile" prop="college" label="学院" min-width="170" show-overflow-tooltip />
      <el-table-column v-if="!isMobile" prop="major" label="专业" min-width="150" show-overflow-tooltip />
      <el-table-column v-if="!isMobile" prop="className" label="班级" width="130" />
      <el-table-column prop="advisorName" label="指导教师" width="110" />
      <el-table-column v-if="!isMobile" label="论文阶段" width="120" align="center">
        <template #default="{ row }">
          <StatusTag v-if="row.thesisStatus" :status="row.thesisStatus" />
          <span v-else class="text-muted">未选题</span>
        </template>
      </el-table-column>
      <el-table-column label="操作" :width="isMobile ? 90 : 200" fixed="right">
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

  <el-drawer v-model="formVisible" :title="form.id ? '编辑学生' : '新增学生'" size="min(560px, 94%)">
    <el-form ref="formRef" :model="form" :rules="rules" label-width="90px">
      <el-form-item label="学号" prop="studentNo">
        <el-input v-model="form.studentNo" maxlength="32" placeholder="同时作为登录账号" />
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
      <el-form-item label="届别" prop="grade">
        <el-select v-model="form.grade" style="width: 100%" @change="onGradeChange">
          <el-option v-for="item in gradeOptions" :key="item.id" :label="item.itemName" :value="item.itemName" />
        </el-select>
      </el-form-item>
      <el-form-item label="学院" prop="college">
        <el-select v-model="form.college" style="width: 100%" @change="onFormCollegeChange">
          <el-option v-for="item in collegeOptions" :key="item.id" :label="item.itemName" :value="item.itemName" />
        </el-select>
      </el-form-item>
      <el-form-item label="专业" prop="major">
        <el-select v-model="form.major" style="width: 100%" :disabled="!form.college" @change="onFormMajorChange">
          <el-option v-for="item in formMajorOptions" :key="item.id" :label="item.itemName" :value="item.itemName" />
        </el-select>
      </el-form-item>
      <el-form-item label="班级" prop="className">
        <el-select v-model="form.className" style="width: 100%" :disabled="!form.major">
          <el-option v-for="item in formClassOptions" :key="item.id" :label="item.itemName" :value="item.itemName" />
        </el-select>
      </el-form-item>
      <el-form-item label="指导教师">
        <el-select v-model="form.advisorId" clearable filterable style="width: 100%">
          <el-option
            v-for="item in advisors"
            :key="item.id"
            :label="`${item.realName}（${item.teacherNo}）`"
            :value="item.id as number"
          />
        </el-select>
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
import { onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox, type FormInstance, type FormRules } from 'element-plus'
import { userApi } from '@/api'
import { useUserStore } from '@/stores/user'
import { useDictStore } from '@/stores/dict'
import { useResponsive } from '@/composables/useResponsive'
import { DICT, SEARCH_PLACEHOLDER } from '@/constants'
import StatusTag from '@/components/StatusTag.vue'
import type { DictItem, PageQuery, Student, Teacher } from '@/types'

const dictStore = useDictStore()
const { isMobile } = useResponsive()

const loading = ref(false)
const saving = ref(false)
const list = ref<Student[]>([])
const total = ref(0)
const advisors = ref<Teacher[]>([])

const gradeOptions = ref<DictItem[]>([])
const collegeOptions = ref<DictItem[]>([])
const majorOptions = ref<DictItem[]>([])
const formMajorOptions = ref<DictItem[]>([])
const formClassOptions = ref<DictItem[]>([])

const query = reactive<PageQuery>({ pageNum: 1, pageSize: 10, keyword: '', grade: '', college: '', major: '' })

const formVisible = ref(false)
const formRef = ref<FormInstance>()
const form = reactive<Student>(emptyForm())
const password = ref('')

const rules: FormRules = {
  studentNo: [{ required: true, message: '请输入学号', trigger: 'blur' }],
  realName: [{ required: true, message: '请输入姓名', trigger: 'blur' }],
  grade: [{ required: true, message: '请选择届别', trigger: 'change' }],
  college: [{ required: true, message: '请选择学院', trigger: 'change' }],
  major: [{ required: true, message: '请选择专业', trigger: 'change' }],
  className: [{ required: true, message: '请选择班级', trigger: 'change' }]
}

function emptyForm(): Student {
  return {
    studentNo: '',
    realName: '',
    gender: 0,
    grade: '',
    college: '',
    major: '',
    className: '',
    advisorId: undefined,
    phone: '',
    email: ''
  }
}

async function loadDicts() {
  gradeOptions.value = await dictStore.loadRoot(DICT.GRADE, true)
  collegeOptions.value = await dictStore.loadRoot(DICT.COLLEGE, true)
  majorOptions.value = await dictStore.load(DICT.MAJOR, true)
}

async function onCollegeChange(college: string) {
  query.major = ''
  majorOptions.value = college ? await dictStore.loadChildren(DICT.MAJOR, dictStore.idByName(DICT.COLLEGE, college) as number) : []
}

async function onGradeChange() {
  // 届别变化时班级选项需要刷新
  form.className = ''
  if (form.college && form.major) {
    await onFormMajorChange(form.major)
  }
}

async function onFormCollegeChange(college: string) {
  form.major = ''
  form.className = ''
  formClassOptions.value = []
  const collegeId = dictStore.idByName(DICT.COLLEGE, college)
  formMajorOptions.value = collegeId ? await dictStore.loadChildren(DICT.MAJOR, collegeId) : []
}

async function onFormMajorChange(major: string) {
  form.className = ''
  const majorId = dictStore.idByName(DICT.MAJOR, major)
  formClassOptions.value = majorId ? await dictStore.loadChildren(DICT.CLASS, majorId) : []
}

async function load() {
  loading.value = true
  try {
    const res = await userApi.pageStudents({ ...query })
    list.value = res.records
    total.value = res.total
  } finally {
    loading.value = false
  }
}

function reset() {
  query.keyword = ''
  query.grade = ''
  query.college = ''
  query.major = ''
  query.pageNum = 1
  load()
}

async function openForm(row?: Student) {
  if (!advisors.value.length) {
    const options = await userApi.teacherOptions()
    advisors.value = options.advisors
  }
  Object.assign(form, row ? { ...row } : emptyForm())
  password.value = ''
  if (row) {
    onFormCollegeChange(row.college)
    const majorId = dictStore.idByName(DICT.MAJOR, row.major)
    formClassOptions.value = majorId ? await dictStore.loadChildren(DICT.CLASS, majorId) : []
  } else {
    formMajorOptions.value = []
    formClassOptions.value = []
  }
  formVisible.value = true
}

async function save() {
  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid) return
  saving.value = true
  try {
    if (form.id) {
      await userApi.updateStudent(form.id, form)
    } else {
      await userApi.createStudent(form, password.value || undefined)
    }
    ElMessage.success('保存成功')
    formVisible.value = false
    load()
  } finally {
    saving.value = false
  }
}

async function resetPassword(row: Student) {
  const { value } = await ElMessageBox.prompt(`为「${row.realName}」设置新密码（留空使用默认密码）`, '重置密码', {
    inputPlaceholder: '新密码',
    inputValue: ''
  }).catch(() => ({ value: undefined as string | undefined }))
  if (value === undefined) return
  await userApi.resetPassword(row.userId as number, value || undefined)
  ElMessage.success('密码已重置')
}

async function remove(row: Student) {
  await ElMessageBox.confirm(`确定删除学生「${row.realName}」？`, '提示', { type: 'warning' })
  await userApi.deleteStudent(row.id as number)
  ElMessage.success('已删除')
  load()
}

onMounted(async () => {
  await loadDicts()
  load()
})
</script>
