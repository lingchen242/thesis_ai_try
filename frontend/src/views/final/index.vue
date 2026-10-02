<template>
  <div>
    <!-- 学生：提交定稿 -->
    <el-card v-if="userStore.isStudent" shadow="never">
      <template #header><span>论文定稿</span></template>

      <el-alert
        v-if="thesis"
        class="mb-16"
        :closable="false"
        show-icon
        :type="canSubmit ? 'info' : 'success'"
        :title="
          canSubmit
            ? '中期检查通过后即可提交定稿，评阅被退回时也可以重新提交'
            : `当前阶段「${thesis.statusLabel}」，暂不需要提交定稿`
        "
      />

      <el-form label-width="90px">
        <el-form-item label="定稿文件" required>
          <FileUploader
            v-model="files"
            biz-type="FINAL"
            :multiple="false"
            accept=".pdf,.doc,.docx,.zip"
          />
        </el-form-item>
        <el-form-item label="提交说明">
          <el-input v-model="note" type="textarea" :rows="3" maxlength="500" show-char />
        </el-form-item>
        <el-form-item>
          <el-button
            type="primary"
            :loading="saving"
            :disabled="!canSubmit || !currentFileId"
            @click="submit"
          >
            提交定稿
          </el-button>
        </el-form-item>
      </el-form>

      <el-divider content-position="left">历史提交</el-divider>
      <el-table v-if="history.length" :data="history" border size="small">
        <el-table-column prop="version" label="版本" width="70" align="center" />
        <el-table-column prop="fileName" label="文件名" min-width="180" show-overflow-tooltip />
        <el-table-column prop="submitTime" label="提交时间" width="170" />
        <el-table-column prop="note" label="说明" min-width="140" show-overflow-tooltip />
        <el-table-column label="操作" width="80">
          <template #default="{ row }">
            <el-link type="primary" :href="row.fileUrl" target="_blank">下载</el-link>
          </template>
        </el-table-column>
      </el-table>
      <el-empty v-else description="暂无提交记录" :image-size="70" />
    </el-card>

    <!-- 教师 / 管理员：定稿列表 -->
    <el-card v-else shadow="never">
      <div class="search-bar">
        <el-input v-model="query.grade" placeholder="届别" clearable @keyup.enter="load" />
        <el-button type="primary" @click="load">查询</el-button>
      </div>
      <el-table v-loading="loading" :data="list" border stripe>
        <el-table-column prop="studentName" label="学生" width="100" />
        <el-table-column v-if="!isMobile" prop="studentNo" label="学号" width="120" />
        <el-table-column prop="thesisTitle" label="论文题目" min-width="200" show-overflow-tooltip />
        <el-table-column prop="fileName" label="文件" min-width="160" show-overflow-tooltip />
        <el-table-column label="版本" width="70" align="center">
          <template #default="{ row }">v{{ row.version }}</template>
        </el-table-column>
        <el-table-column v-if="!isMobile" prop="submitTime" label="提交时间" width="170" />
        <el-table-column label="当前阶段" width="120" align="center">
          <template #default="{ row }">
            <el-tag size="small" effect="plain">{{ row.statusLabel }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="90" fixed="right">
          <template #default="{ row }">
            <el-link type="primary" :href="row.fileUrl" target="_blank">下载</el-link>
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
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { fileApi, thesisApi } from '@/api'
import { useUserStore } from '@/stores/user'
import { useResponsive } from '@/composables/useResponsive'
import FileUploader from '@/components/FileUploader.vue'
import type { Attachment, FinalSubmission, PageQuery, Thesis } from '@/types'

const userStore = useUserStore()
const { isMobile } = useResponsive()

const loading = ref(false)
const saving = ref(false)
const thesis = ref<Thesis | null>(null)
const history = ref<FinalSubmission[]>([])
const list = ref<FinalSubmission[]>([])
const total = ref(0)
const files = ref<Attachment[]>([])
const note = ref('')

const query = reactive<PageQuery>({ pageNum: 1, pageSize: 10, grade: '' })

const canSubmit = computed(() =>
  ['MIDTERM_PASSED', 'REVIEWING'].includes(thesis.value?.status ?? '')
)

const currentFileId = computed(() => files.value[0]?.id)

async function load() {
  if (userStore.isStudent) {
    thesis.value = await thesisApi.mine()
    const res = await thesisApi.pageFinals({ pageNum: 1, pageSize: 50 })
    // 学生只能查到自己名下的定稿
    history.value = res.records.filter((item) => item.thesisId === thesis.value?.id)
    return
  }
  loading.value = true
  try {
    const res = await thesisApi.pageFinals({ ...query })
    list.value = res.records
    total.value = res.total
  } finally {
    loading.value = false
  }
}

async function submit() {
  const file = files.value[0]
  if (!file) {
    ElMessage.warning('请先上传定稿文件')
    return
  }
  saving.value = true
  try {
    const saved = await thesisApi.submitFinal({
      fileUrl: file.fileUrl,
      fileName: file.fileName,
      fileSize: file.fileSize,
      note: note.value
    })
    if (saved.id && file.id) {
      await fileApi.bind({ bizType: 'FINAL', bizId: saved.id, ids: [file.id] })
    }
    ElMessage.success('定稿已提交，等待指派评阅')
    files.value = []
    note.value = ''
    load()
  } finally {
    saving.value = false
  }
}

onMounted(load)
</script>
