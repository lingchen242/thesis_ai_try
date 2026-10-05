<template>
  <el-card shadow="never">
    <template #header>
      <div class="table-toolbar" style="margin-bottom: 0">
        <span>我的消息</span>
        <div>
          <el-checkbox v-model="onlyUnread" @change="load">只看未读</el-checkbox>
          <el-button text type="primary" @click="markAll">全部已读</el-button>
        </div>
      </div>
    </template>

    <el-empty v-if="!loading && !list.length" description="暂无消息" />
    <div v-else v-loading="loading" class="notice-list">
      <div
        v-for="item in list"
        :key="item.id"
        class="notice-item"
        :class="{ unread: item.isRead === 0 }"
        @click="open(item)"
      >
        <div class="notice-head">
          <span class="title">{{ item.title }}</span>
          <span class="text-muted">{{ item.createTime }}</span>
        </div>
        <div class="content">{{ item.content }}</div>
      </div>
    </div>
  </el-card>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { noticeApi } from '@/api'
import { useUserStore } from '@/stores/user'
import type { Notification } from '@/types'

const router = useRouter()
const userStore = useUserStore()
const list = ref<Notification[]>([])
const loading = ref(false)
const onlyUnread = ref(false)

async function load() {
  loading.value = true
  try {
    list.value = await noticeApi.list(onlyUnread.value)
  } finally {
    loading.value = false
  }
}

async function open(item: Notification) {
  if (item.isRead === 0 && item.id) {
    await noticeApi.markRead(item.id)
    userStore.unread = Math.max(0, userStore.unread - 1)
  }
  if (item.link) {
    router.push(item.link)
  } else {
    load()
  }
}

async function markAll() {
  await noticeApi.markAllRead()
  ElMessage.success('已全部标记为已读')
  userStore.unread = 0
  load()
}

onMounted(load)
</script>

<style scoped>
.notice-list {
  display: flex;
  flex-direction: column;
}

.notice-item {
  padding: 12px 10px;
  border-radius: 6px;
  cursor: pointer;
}

.notice-item:hover {
  background: var(--el-fill-color-light);
}

.notice-item + .notice-item {
  border-top: 1px dashed var(--el-border-color-lighter);
}

.notice-item.unread .title::before {
  content: '';
  display: inline-block;
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--el-color-danger);
  margin-right: 6px;
  vertical-align: middle;
}

.notice-head {
  display: flex;
  justify-content: space-between;
  gap: 8px;
  font-size: 14px;
}

.notice-head .title {
  font-weight: 500;
}

.content {
  margin-top: 4px;
  font-size: 13px;
  color: var(--el-text-color-regular);
  line-height: 1.6;
}
</style>
