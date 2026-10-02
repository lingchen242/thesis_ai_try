<template>
  <div class="attachment-list">
    <template v-if="attachments.length">
      <el-tag
        v-for="item in attachments"
        :key="item.id"
        class="attachment-item"
        effect="plain"
        closable
        @close="removeFile(item)"
      >
        <el-link :href="item.fileUrl" target="_blank" :underline="false">
          <el-icon><Paperclip /></el-icon>
          {{ item.fileName }}
        </el-link>
      </el-tag>
    </template>
    <span v-else class="text-muted">无附件</span>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref, watch } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { fileApi } from '@/api'
import type { Attachment } from '@/types'

const props = defineProps<{
  /** 逗号分隔的附件 id */
  ids?: string | null
  /** 是否允许删除 */
  editable?: boolean
}>()

const attachments = ref<Attachment[]>([])

async function load() {
  if (!props.ids) {
    attachments.value = []
    return
  }
  try {
    attachments.value = await fileApi.listByIds(props.ids)
  } catch {
    attachments.value = []
  }
}

async function removeFile(item: Attachment) {
  if (!props.editable || !item.id) return
  await ElMessageBox.confirm(`确定删除附件「${item.fileName}」？`, '提示', { type: 'warning' })
  await fileApi.remove(item.id)
  ElMessage.success('已删除')
  load()
}

onMounted(load)
watch(() => props.ids, load)
</script>

<style scoped>
.attachment-item {
  margin: 0 8px 8px 0;
}
</style>
