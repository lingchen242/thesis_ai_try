<template>
  <el-row :gutter="12">
    <el-col :xs="24" :sm="24" :md="10" :lg="9">
      <el-card shadow="never" class="mb-16">
        <template #header><span>基本信息</span></template>
        <el-descriptions :column="1" border size="small">
          <el-descriptions-item label="账号">{{ user?.username }}</el-descriptions-item>
          <el-descriptions-item label="姓名">{{ user?.realName }}</el-descriptions-item>
          <el-descriptions-item label="角色">
            <el-tag size="small">{{ ROLE_LABEL[user?.role ?? ''] }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="手机号">{{ user?.phone || '-' }}</el-descriptions-item>
          <el-descriptions-item label="邮箱">{{ user?.email || '-' }}</el-descriptions-item>
          <template v-if="student">
            <el-descriptions-item label="学号">{{ student.studentNo }}</el-descriptions-item>
            <el-descriptions-item label="届别">{{ student.grade }}</el-descriptions-item>
            <el-descriptions-item label="学院">{{ student.college }}</el-descriptions-item>
            <el-descriptions-item label="专业">{{ student.major }}</el-descriptions-item>
            <el-descriptions-item label="班级">{{ student.className }}</el-descriptions-item>
          </template>
          <template v-if="teacher">
            <el-descriptions-item label="工号">{{ teacher.teacherNo }}</el-descriptions-item>
            <el-descriptions-item label="职称">{{ teacher.title || '-' }}</el-descriptions-item>
            <el-descriptions-item label="学院">{{ teacher.college || '-' }}</el-descriptions-item>
            <el-descriptions-item label="最大指导学生数">
              {{ teacher.maxQuota ?? '-' }}
            </el-descriptions-item>
          </template>
        </el-descriptions>
      </el-card>
    </el-col>

    <el-col :xs="24" :sm="24" :md="14" :lg="15">
      <el-card shadow="never" class="mb-16">
        <template #header><span>修改密码</span></template>
        <el-form
          ref="formRef"
          :model="form"
          :rules="rules"
          label-width="100px"
          style="max-width: 460px"
        >
          <el-form-item label="当前密码" prop="currentPassword">
            <el-input v-model="form.currentPassword" type="password" show-password />
          </el-form-item>
          <el-form-item label="新密码" prop="newPassword">
            <el-input v-model="form.newPassword" type="password" show-password />
          </el-form-item>
          <el-form-item label="确认新密码" prop="confirmPassword">
            <el-input v-model="form.confirmPassword" type="password" show-password />
          </el-form-item>
          <el-form-item>
            <el-button type="primary" :loading="saving" @click="submit">保存</el-button>
            <el-button @click="reset">重置</el-button>
          </el-form-item>
        </el-form>
      </el-card>
    </el-col>
  </el-row>
</template>

<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import { ElMessage, type FormInstance, type FormRules } from 'element-plus'
import { authApi } from '@/api'
import { useUserStore } from '@/stores/user'
import { ROLE_LABEL } from '@/constants'

const userStore = useUserStore()
const formRef = ref<FormInstance>()
const saving = ref(false)

const user = computed(() => userStore.user)
const student = computed(() => userStore.student)
const teacher = computed(() => userStore.teacher)

const form = reactive({ currentPassword: '', newPassword: '', confirmPassword: '' })

const rules: FormRules = {
  currentPassword: [{ required: true, message: '请输入当前密码', trigger: 'blur' }],
  newPassword: [
    { required: true, message: '请输入新密码', trigger: 'blur' },
    { min: 6, message: '新密码至少 6 位', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, message: '请再次输入新密码', trigger: 'blur' },
    {
      validator: (_rule, value, callback) => {
        if (value !== form.newPassword) {
          callback(new Error('两次输入的密码不一致'))
        } else {
          callback()
        }
      },
      trigger: 'blur'
    }
  ]
}

function reset() {
  form.currentPassword = ''
  form.newPassword = ''
  form.confirmPassword = ''
}

async function submit() {
  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid) return
  saving.value = true
  try {
    await authApi.changePassword({
      currentPassword: form.currentPassword,
      newPassword: form.newPassword
    })
    ElMessage.success('密码修改成功，请重新登录')
    reset()
    setTimeout(async () => {
      await userStore.logout()
      window.location.href = '/login'
    }, 800)
  } finally {
    saving.value = false
  }
}
</script>
