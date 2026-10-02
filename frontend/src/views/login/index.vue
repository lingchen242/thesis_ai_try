<template>
  <div class="login-page">
    <div class="login-card">
      <h2>毕业论文管理系统</h2>
      <div class="subtitle">Graduation Thesis Management</div>

      <el-form ref="formRef" :model="form" :rules="rules" size="large" @keyup.enter="submit">
        <el-form-item prop="username">
          <el-input v-model="form.username" placeholder="账号（学号 / 工号）" clearable>
            <template #prefix>
              <el-icon><User /></el-icon>
            </template>
          </el-input>
        </el-form-item>
        <el-form-item prop="password">
          <el-input v-model="form.password" type="password" placeholder="密码" show-password clearable>
            <template #prefix>
              <el-icon><Lock /></el-icon>
            </template>
          </el-input>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="loading" style="width: 100%" @click="submit">
            登 录
          </el-button>
        </el-form-item>
      </el-form>

      <div class="login-tips">
        <div>演示账号（来自 database/02_demo_data.sql）：</div>
        <div>管理员 admin / admin123</div>
        <div>指导教师 t2001 / 123456</div>
        <div>评阅教师 r3001 / 123456</div>
        <div>学生 s20260001 / 123456</div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, type FormInstance, type FormRules } from 'element-plus'
import { useUserStore } from '@/stores/user'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()

const formRef = ref<FormInstance>()
const loading = ref(false)
const form = reactive({ username: '', password: '' })

const rules: FormRules = {
  username: [{ required: true, message: '请输入账号', trigger: 'blur' }],
  password: [{ required: true, message: '请输入密码', trigger: 'blur' }]
}

async function submit() {
  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid) return
  loading.value = true
  try {
    const res = await userStore.login(form.username.trim(), form.password)
    ElMessage.success(`欢迎回来，${res.user.realName}`)
    const redirect = (route.query.redirect as string) || '/dashboard'
    router.replace(redirect)
  } catch {
    // 错误提示已由请求层处理
  } finally {
    loading.value = false
  }
}
</script>
