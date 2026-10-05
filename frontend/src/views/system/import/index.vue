<template>
  <el-row :gutter="12">
    <el-col :xs="24" :sm="24" :md="10" :lg="9">
      <el-card shadow="never" class="mb-16">
        <template #header><span>第一步：下载模板</span></template>
        <p class="text-muted" style="line-height: 1.9; margin: 0 0 12px">
          模板包含「账号导入」与「填写说明」两个工作表。请按说明填写：
          角色、姓名、学号/工号必填；学生的届别/学院/专业/班级必须与字典管理中维护的名称完全一致；
          教师的职称同样需要命中字典。填写完成后请删除示例行。
        </p>
        <el-button type="primary" @click="downloadTemplate">
          <el-icon><Download /></el-icon>下载导入模板
        </el-button>
      </el-card>

      <el-card shadow="never">
        <template #header><span>第二步：上传并导入</span></template>
        <el-upload
          :auto-upload="false"
          :show-file-list="false"
          accept=".xlsx"
          :on-change="onFileChange"
          drag
        >
          <el-icon class="upload-icon"><UploadFilled /></el-icon>
          <div class="upload-text">将填好的 .xlsx 文件拖到此处，或<em>点击选择</em></div>
        </el-upload>
        <el-button
          class="mt-16"
          type="primary"
          :loading="importing"
          :disabled="!file"
          style="width: 100%"
          @click="doImport"
        >
          开始导入
        </el-button>
        <div v-if="file" class="text-muted mt-8">已选择：{{ file.name }}</div>
      </el-card>
    </el-col>

    <el-col :xs="24" :sm="24" :md="14" :lg="15">
      <el-card shadow="never">
        <template #header><span>导入结果</span></template>

        <el-empty v-if="!result" description="尚未执行导入" :image-size="80" />

        <template v-else>
          <el-descriptions :column="isMobile ? 1 : 3" border size="small" class="mb-16">
            <el-descriptions-item label="总行数">{{ result.total }}</el-descriptions-item>
            <el-descriptions-item label="成功">{{ result.successCount }}</el-descriptions-item>
            <el-descriptions-item label="失败">{{ result.failCount }}</el-descriptions-item>
          </el-descriptions>

          <el-alert
            :type="result.imported ? 'success' : 'error'"
            :title="String(result.message ?? '')"
            :closable="false"
            show-icon
            class="mb-16"
          />

          <el-table v-if="errors.length" :data="errors" border stripe size="small">
            <el-table-column prop="row" label="行号" width="90" align="center" />
            <el-table-column prop="message" label="错误原因" min-width="260" />
          </el-table>
        </template>
      </el-card>
    </el-col>
  </el-row>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { ElMessage, type UploadFile } from 'element-plus'
import { importApi } from '@/api'
import { useResponsive } from '@/composables/useResponsive'

const { isMobile } = useResponsive()

const file = ref<File | null>(null)
const importing = ref(false)
const result = ref<Record<string, unknown> | null>(null)

const errors = computed(
  () => (result.value?.errors as { row: number; message: string }[] | undefined) ?? []
)

function onFileChange(uploadFile: UploadFile) {
  if (uploadFile.raw) {
    file.value = uploadFile.raw
    result.value = null
  }
}

async function downloadTemplate() {
  await importApi.template()
  ElMessage.success('模板已开始下载')
}

async function doImport() {
  if (!file.value) return
  importing.value = true
  try {
    result.value = await importApi.users(file.value)
    if (result.value.imported) {
      ElMessage.success('导入成功')
    } else {
      ElMessage.error('校验未通过，本次未导入任何数据')
    }
  } finally {
    importing.value = false
  }
}
</script>

<style scoped>
.upload-icon {
  font-size: 36px;
  color: var(--el-text-color-disabled);
  margin-top: 12px;
}

.upload-text {
  font-size: 13px;
  color: var(--el-text-color-regular);
}

.upload-text em {
  color: var(--el-color-primary);
  font-style: normal;
}
</style>
