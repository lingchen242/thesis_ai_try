<template>
  <el-card shadow="never">
    <template #header>
      <div class="table-toolbar" style="margin-bottom: 0">
        <span>系统配置</span>
        <div>
          <el-button @click="load">刷新</el-button>
          <el-button type="primary" :loading="saving" @click="save">保存全部</el-button>
        </div>
      </div>
    </template>

    <el-alert
      class="mb-16"
      type="info"
      :closable="false"
      show-icon
      title="评分权重用于计算总评；截止日期用于中期检查的超期预警。修改后立即生效，无需重启服务。"
    />

    <el-table v-loading="loading" :data="list" border stripe>
      <el-table-column prop="configKey" label="配置项" width="240" />
      <el-table-column prop="remark" label="说明" min-width="220" show-overflow-tooltip />
      <el-table-column label="值" :width="isMobile ? 180 : 280">
        <template #default="{ row }">
          <el-date-picker
            v-if="row.configKey.startsWith('deadline.')"
            v-model="row.configValue"
            type="date"
            value-format="YYYY-MM-DD"
            style="width: 100%"
          />
          <el-input v-else v-model="row.configValue" />
        </template>
      </el-table-column>
      <el-table-column label="操作" width="100" fixed="right">
        <template #default="{ row }">
          <el-button text type="primary" size="small" @click="saveOne(row)">保存</el-button>
        </template>
      </el-table-column>
    </el-table>
  </el-card>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { configApi } from '@/api'
import { useResponsive } from '@/composables/useResponsive'
import type { SysConfig } from '@/types'

const { isMobile } = useResponsive()

const loading = ref(false)
const saving = ref(false)
const list = ref<SysConfig[]>([])

async function load() {
  loading.value = true
  try {
    list.value = await configApi.list()
  } finally {
    loading.value = false
  }
}

async function save() {
  saving.value = true
  try {
    await configApi.update(list.value)
    ElMessage.success('配置已保存')
    load()
  } finally {
    saving.value = false
  }
}

async function saveOne(row: SysConfig) {
  await configApi.update([row])
  ElMessage.success('已保存')
}

onMounted(load)
</script>
