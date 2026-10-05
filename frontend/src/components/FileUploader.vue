<template>
  <div class="file-uploader">
    <el-upload
      :auto-upload="false"
      :show-file-list="false"
      :multiple="multiple"
      :accept="accept"
      :on-change="onFileChange"
      drag
    >
      <el-icon class="upload-icon"><UploadFilled /></el-icon>
      <div class="upload-text">
        将文件拖到此处，或<em>点击选择</em>
      </div>
      <template #tip>
        <div class="text-muted">
          支持 {{ accept.replace(/\./g, '').toUpperCase() }}，单个文件不超过 {{ maxSize }}MB
        </div>
      </template>
    </el-upload>

    <ul v-if="modelValue.length" class="file-list">
      <li v-for="item in modelValue" :key="item.id">
        <el-icon><Document /></el-icon>
        <span class="file-name" :title="item.fileName">{{ item.fileName }}</span>
        <span class="text-muted">{{ prettySize(item.fileSize) }}</span>
        <el-link type="primary" :href="item.fileUrl" target="_blank">预览</el-link>
        <el-link type="danger" @click="remove(item)">删除</el-link>
      </li>
    </ul>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { ElMessage, type UploadFile } from 'element-plus'
import { fileApi } from '@/api'
import type { Attachment } from '@/types'

const props = withDefaults(
  defineProps<{
    modelValue: Attachment[]
    bizType: string
    multiple?: boolean
    maxSize?: number
    accept?: string
  }>(),
  {
    multiple: false,
    maxSize: 20,
    accept: '.pdf,.doc,.docx,.zip,.jpg,.jpeg,.png'
  }
)

const emit = defineEmits<{
  (e: 'update:modelValue', value: Attachment[]): void
}>()

const uploading = ref(false)

function prettySize(size?: number) {
  if (!size) return '-'
  if (size < 1024) return `${size} B`
  if (size < 1024 * 1024) return `${(size / 1024).toFixed(1)} KB`
  return `${(size / 1024 / 1024).toFixed(2)} MB`
}

function allowed(fileName: string) {
  const ext = `.${fileName.split('.').pop()?.toLowerCase() ?? ''}`
  return props.accept.split(',').includes(ext)
}

async function onFileChange(uploadFile: UploadFile) {
  const raw = uploadFile.raw
  if (!raw) return
  if (!allowed(raw.name)) {
    ElMessage.error(`不支持的文件类型：${raw.name}`)
    return
  }
  if (raw.size > props.maxSize * 1024 * 1024) {
    ElMessage.error(`文件超过 ${props.maxSize}MB 限制`)
    return
  }
  uploading.value = true
  try {
    const attachment = await fileApi.upload(raw, props.bizType)
    const next = props.multiple ? [...props.modelValue, attachment] : [attachment]
    emit('update:modelValue', next)
    ElMessage.success('上传成功')
  } catch {
    // 错误提示已由请求层统一处理
  } finally {
    uploading.value = false
  }
}

async function remove(item: Attachment) {
  if (item.id) {
    try {
      await fileApi.remove(item.id)
    } catch {
      return
    }
  }
  emit(
    'update:modelValue',
    props.modelValue.filter((it) => it.id !== item.id)
  )
}
</script>

<style scoped>
.file-list {
  margin: 12px 0 0;
  padding: 0;
  list-style: none;
}

.file-list li {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 0;
  border-bottom: 1px dashed var(--el-border-color-lighter);
  font-size: 13px;
}

.file-list .file-name {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

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
