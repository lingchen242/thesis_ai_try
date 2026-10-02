<template>
  <el-card shadow="never">
    <div class="search-bar">
      <el-input v-model="query.keyword" placeholder="论文题目 / 学生" clearable @keyup.enter="load" />
      <el-select v-model="query.grade" placeholder="届别" clearable>
        <el-option v-for="item in gradeOptions" :key="item.id" :label="item.itemName" :value="item.itemName" />
      </el-select>
      <el-select v-model="query.major" placeholder="专业" clearable>
        <el-option v-for="item in majorOptions" :key="item.id" :label="item.itemName" :value="item.itemName" />
      </el-select>
      <el-button type="primary" @click="load">查询</el-button>
      <el-button @click="reset">重置</el-button>
    </div>

    <el-table v-loading="loading" :data="list" border stripe>
      <el-table-column prop="studentName" label="学生" width="100" />
      <el-table-column v-if="!isMobile" prop="studentNo" label="学号" width="120" />
      <el-table-column prop="thesisTitle" label="论文题目" min-width="200" show-overflow-tooltip />
      <el-table-column v-if="!isMobile" prop="advisorName" label="指导教师" width="110" />
      <el-table-column label="开题" width="80" align="center">
        <template #default="{ row }">{{ row.proposalScore ?? '-' }}</template>
      </el-table-column>
      <el-table-column label="中期" width="80" align="center">
        <template #default="{ row }">{{ row.midtermScore ?? '-' }}</template>
      </el-table-column>
      <el-table-column label="评阅" width="80" align="center">
        <template #default="{ row }">{{ row.reviewScore ?? '-' }}</template>
      </el-table-column>
      <el-table-column label="答辩" width="80" align="center">
        <template #default="{ row }">{{ row.defenseScore ?? '-' }}</template>
      </el-table-column>
      <el-table-column label="总评" width="100" align="center">
        <template #default="{ row }">
          <span class="total-score">{{ row.totalScore ?? '-' }}</span>
        </template>
      </el-table-column>
      <el-table-column label="等级" width="90" align="center">
        <template #default="{ row }">
          <el-tag v-if="row.level" size="small" :type="levelType(row.level)" effect="plain">
            {{ row.level }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column v-if="userStore.isAdmin" label="操作" width="90" fixed="right">
        <template #default="{ row }">
          <el-button text type="primary" size="small" @click="recompute(row)">重算</el-button>
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
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { scoreApi } from '@/api'
import { useUserStore } from '@/stores/user'
import { useDictOptions, useRootDictOptions } from '@/composables/useDict'
import { useResponsive } from '@/composables/useResponsive'
import { DICT } from '@/constants'
import type { PageQuery, ThesisScore } from '@/types'

const userStore = useUserStore()
const { isMobile } = useResponsive()
const gradeOptions = useRootDictOptions(DICT.GRADE)
const majorOptions = useDictOptions(DICT.MAJOR)

const loading = ref(false)
const list = ref<ThesisScore[]>([])
const total = ref(0)
const query = reactive<PageQuery>({ pageNum: 1, pageSize: 10, keyword: '', grade: '', major: '' })

function levelType(level: string) {
  if (level === '优秀') return 'success'
  if (level === '不及格') return 'danger'
  if (level === '及格') return 'warning'
  return 'primary'
}

async function load() {
  loading.value = true
  try {
    const res = await scoreApi.page({ ...query })
    list.value = res.records
    total.value = res.total
  } finally {
    loading.value = false
  }
}

function reset() {
  query.keyword = ''
  query.grade = ''
  query.major = ''
  query.pageNum = 1
  load()
}

async function recompute(row: ThesisScore) {
  if (!row.thesisId) return
  await scoreApi.recompute(row.thesisId)
  ElMessage.success('已重算')
  load()
}

onMounted(load)
</script>

<style scoped>
.total-score {
  color: #f56c6c;
  font-weight: 600;
}
</style>
