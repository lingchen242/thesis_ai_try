<template>
  <el-card shadow="never">
    <div class="search-bar">
      <el-input v-model="query.keyword" placeholder="账号 / 姓名" clearable @keyup.enter="load" />
      <el-select v-model="query.role" placeholder="角色" clearable>
        <el-option v-for="item in ROLE_OPTIONS" :key="item.value" :label="item.label" :value="item.value" />
      </el-select>
      <el-button type="primary" @click="load">查询</el-button>
      <el-button @click="reset">重置</el-button>
    </div>

    <div class="table-toolbar">
      <span class="text-muted">共 {{ total }} 个账号</span>
      <el-button type="primary" @click="openForm()">
        <el-icon><Plus /></el-icon>新增账号
      </el-button>
    </div>

    <el-table v-loading="loading" :data="list" border stripe>
      <el-table-column prop="username" label="账号" width="140" />
      <el-table-column prop="realName" label="姓名" width="110" />
      <el-table-column label="角色" width="110" align="center">
        <template #default="{ row }">
          <el-tag size="small" effect="plain">{{ ROLE_LABEL[row.role] }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column v-if="!isMobile" prop="phone" label="手机号" width="130" />
      <el-table-column v-if="!isMobile" prop="email" label="邮箱" min-width="180" show-overflow-tooltip />
      <el-table-column label="状态" width="90" align="center">
        <template #default="{ row }">
          <el-tag :type="row.status === 1 ? 'success' : 'info'" size="small" effect="plain">
            {{ row.status === 1 ? '启用' : '禁用' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column v-if="!isMobile" prop="lastLoginTime" label="最近登录" width="160" />
      <el-table-column label="操作" :width="isMobile ? 90 : 220" fixed="right">
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

  <el-drawer v-model="formVisible" :title="form.id ? '编辑账号' : '新增账号'" size="min(480px, 94%)">
    <el-form ref="formRef" :model="form" :rules="rules" label-width="90px">
      <el-form-item label="账号" prop="username">
        <el-input v-model="form.username" maxlength="50" />
      </el-form-item>
      <el-form-item label="姓名" prop="realName">
        <el-input v-model="form.realName" maxlength="50" />
      </el-form-item>
      <el-form-item label="角色" prop="role">
        <el-select v-model="form.role" style="width: 100%">
          <el-option v-for="item in ROLE_OPTIONS" :key="item.value" :label="item.label" :value="item.value" />
        </el-select>
      </el-form-item>
      <el-form-item label="手机号">
        <el-input v-model="form.phone" maxlength="20" />
      </el-form-item>
      <el-form-item label="邮箱">
        <el-input v-model="form.email" maxlength="100" />
      </el-form-item>
      <el-form-item label="状态">
        <el-switch v-model="statusSwitch" />
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
import { useResponsive } from '@/composables/useResponsive'
import { ROLE_LABEL, ROLE_OPTIONS } from '@/constants'
import type { PageQuery, SysUser } from '@/types'

const { isMobile } = useResponsive()

const loading = ref(false)
const saving = ref(false)
const list = ref<SysUser[]>([])
const total = ref(0)
const query = reactive<PageQuery>({ pageNum: 1, pageSize: 10, keyword: '', role: '' })

const formVisible = ref(false)
const formRef = ref<FormInstance>()
const form = reactive<SysUser>(emptyForm())
const password = ref('')

const statusSwitch = computed({
  get: () => form.status === 1,
  set: (value: boolean) => {
    form.status = value ? 1 : 0
  }
})

const rules: FormRules = {
  username: [{ required: true, message: '请输入账号', trigger: 'blur' }],
  realName: [{ required: true, message: '请输入姓名', trigger: 'blur' }],
  role: [{ required: true, message: '请选择角色', trigger: 'change' }]
}

function emptyForm(): SysUser {
  return { username: '', realName: '', role: 'ADMIN', status: 1, phone: '', email: '' }
}

async function load() {
  loading.value = true
  try {
    const res = await userApi.pageUsers({ ...query })
    list.value = res.records
    total.value = res.total
  } finally {
    loading.value = false
  }
}

function reset() {
  query.keyword = ''
  query.role = ''
  query.pageNum = 1
  load()
}

function openForm(row?: SysUser) {
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
      await userApi.updateUser(form.id, form)
    } else {
      await userApi.createUser(form, password.value || undefined)
    }
    ElMessage.success('保存成功')
    formVisible.value = false
    load()
  } finally {
    saving.value = false
  }
}

async function resetPassword(row: SysUser) {
  const { value } = await ElMessageBox.prompt(`为「${row.realName}」设置新密码（留空使用默认密码）`, '重置密码', {
    inputValue: ''
  }).catch(() => ({ value: undefined as string | undefined }))
  if (value === undefined) return
  await userApi.resetPassword(row.id as number, value || undefined)
  ElMessage.success('密码已重置')
}

async function remove(row: SysUser) {
  await ElMessageBox.confirm(`确定删除账号「${row.username}」？`, '提示', { type: 'warning' })
  await userApi.deleteUser(row.id as number)
  ElMessage.success('已删除')
  load()
}

onMounted(load)
</script>
