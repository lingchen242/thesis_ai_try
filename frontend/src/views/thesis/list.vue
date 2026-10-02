<template>
  <el-card shadow="never">
    <div class="search-bar">
      <el-input v-model="query.keyword" placeholder="论文题目" clearable @keyup.enter="load" />
      <el-select v-model="query.status" placeholder="阶段" clearable>
        <el-option
          v-for="item in THESIS_STATUS_OPTIONS"
          :key="item.value"
          :label="item.label"
          :value="item.value"
        />
      </el-select>
      <el-select v-model="query.grade" placeholder="届别" clearable>
        <el-option v-for="item in gradeOptions" :key="item.id" :label="item.itemName" :value="item.itemName" />
      </el-select>
      <el-button type="primary" @click="load">查询</el-button>
      <el-button @click="reset">重置</el-button>
    </div>

    <div class="table-toolbar">
      <span class="text-muted">共 {{ total }} 篇</span>
    </div>

    <el-table v-loading="loading" :data="list" border stripe>
      <el-table-column prop="studentName" label="学生" width="100" />
      <el-table-column v-if="!isMobile" prop="studentNo" label="学号" width="120" />
      <el-table-column prop="title" label="论文题目" min-width="220" show-overflow-tooltip />
      <el-table-column v-if="!isMobile" prop="advisorName" label="指导教师" width="110" />
      <el-table-column v-if="!isMobile" prop="grade" label="届别" width="80" align="center" />
      <el-table-column label="当前阶段" width="120" align="center">
        <template #default="{ row }">
          <StatusTag :status="row.status" />
        </template>
      </el-table-column>
      <el-table-column label="操作" width="90" fixed="right">
        <template #default="{ row }">
          <el-button text type="primary" size="small" @click="goDetail(row)">详情</el-button>
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
import { useRouter } from 'vue-router'
import { thesisApi } from '@/api'
import { useRootDictOptions } from '@/composables/useDict'
import { useResponsive } from '@/composables/useResponsive'
import { DICT, THESIS_STATUS_OPTIONS } from '@/constants'
import StatusTag from '@/components/StatusTag.vue'
import type { PageQuery, Thesis } from '@/types'

const router = useRouter()
const { isMobile } = useResponsive()
const gradeOptions = useRootDictOptions(DICT.GRADE)

const loading = ref(false)
const list = ref<Thesis[]>([])
const total = ref(0)
const query = reactive<PageQuery>({ pageNum: 1, pageSize: 10, keyword: '', status: '', grade: '' })

async function load() {
  loading.value = true
  try {
    const res = await thesisApi.page({ ...query })
    list.value = res.records
    total.value = res.total
  } finally {
    loading.value = false
  }
}

function reset() {
  query.keyword = ''
  query.status = ''
  query.grade = ''
  query.pageNum = 1
  load()
}

function goDetail(row: Thesis) {
  router.push(`/thesis/detail/${row.id}`)
}

onMounted(load)
</script>
