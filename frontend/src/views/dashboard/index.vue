<template>
  <div v-loading="loading">
    <!-- 欢迎条 -->
    <el-card shadow="never" class="mb-16">
      <div class="welcome">
        <div>
          <div class="hello">{{ greeting }}，{{ overview?.realName || userStore.displayName }}</div>
          <div class="text-muted">
            当前角色：{{ ROLE_LABEL[userStore.role] }} ·
            {{ today }}
          </div>
        </div>
        <el-tag v-if="overview?.role === 'ADMIN'" type="primary" effect="plain">
          全院数据视图
        </el-tag>
      </div>
    </el-card>

    <!-- 指标卡片（按角色不同） -->
    <el-row :gutter="12" class="mb-16">
      <el-col v-for="card in statCards" :key="card.label" :xs="12" :sm="12" :md="6" :lg="6">
        <div class="mb-16">
          <StatCard
            :label="card.label"
            :value="card.value"
            :color="card.color"
            :suffix="card.suffix"
            :icon="card.icon"
          />
        </div>
      </el-col>
    </el-row>

    <el-row :gutter="12">
      <!-- 待办 -->
      <el-col :xs="24" :sm="24" :md="10" :lg="9">
        <el-card shadow="never" class="mb-16">
          <template #header>
            <span>待办事项</span>
          </template>
          <div v-if="overview?.todos?.length" class="todo-list">
            <div
              v-for="todo in overview.todos"
              :key="todo.title"
              class="todo-item"
              @click="router.push(todo.link)"
            >
              <span class="todo-title">{{ todo.title }}</span>
              <el-tag type="warning" effect="plain" size="small">{{ todo.count }}</el-tag>
            </div>
          </div>
          <el-empty v-else description="暂无待办" :image-size="70" />
        </el-card>

        <!-- 学生进度 -->
        <el-card v-if="userStore.isStudent" shadow="never" class="mb-16">
          <template #header>
            <span>我的进度</span>
          </template>
          <el-progress
            type="dashboard"
            :percentage="Number(overview?.progress ?? 0)"
            :color="progressColor"
          />
          <div class="mt-16" style="text-align: center">
            <StatusTag :status="(overview?.thesis as Thesis)?.status" />
            <div class="text-muted mt-8">
              {{ (overview?.thesis as Thesis)?.title || '尚未选题' }}
            </div>
          </div>
        </el-card>
      </el-col>

      <!-- 图表 -->
      <el-col :xs="24" :sm="24" :md="14" :lg="15">
        <el-card shadow="never" class="mb-16">
          <template #header>
            <span>各阶段论文分布</span>
          </template>
          <ChartBox :option="stageOption" :height="320" />
        </el-card>
        <el-card shadow="never" class="mb-16">
          <template #header>
            <span>总评分段分布</span>
          </template>
          <ChartBox :option="scoreOption" :height="280" />
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import dayjs from 'dayjs'
import { dashboardApi } from '@/api'
import { useUserStore } from '@/stores/user'
import { ROLE_LABEL } from '@/constants'
import StatCard from '@/components/StatCard.vue'
import ChartBox from '@/components/ChartBox.vue'
import StatusTag from '@/components/StatusTag.vue'
import type { Overview, Thesis } from '@/types'

const router = useRouter()
const userStore = useUserStore()
const loading = ref(false)
const overview = ref<Overview | null>(null)

const today = dayjs().format('YYYY年MM月DD日 dddd').replace('dddd', '')
const greeting = computed(() => {
  const hour = dayjs().hour()
  if (hour < 6) return '凌晨好'
  if (hour < 12) return '上午好'
  if (hour < 14) return '中午好'
  if (hour < 18) return '下午好'
  return '晚上好'
})

const progressColor = [
  { color: '#f56c6c', percentage: 20 },
  { color: '#e6a23c', percentage: 60 },
  { color: '#409eff', percentage: 85 },
  { color: '#67c23a', percentage: 100 }
]

interface Card {
  label: string
  value: string | number
  color: 'primary' | 'success' | 'warning' | 'danger' | ''
  suffix?: string
  icon: string
}

const statCards = computed<Card[]>(() => {
  const o = overview.value
  if (!o) return []
  const num = (key: string) => Number(o[key] ?? 0)
  switch (o.role) {
    case 'ADMIN':
      return [
        { label: '学生总数', value: num('studentCount'), color: 'primary', icon: 'User' },
        { label: '教师总数', value: num('teacherCount'), color: 'primary', icon: 'Avatar' },
        { label: '论文总数', value: num('thesisCount'), color: 'primary', icon: 'Files' },
        {
          label: '完成率',
          value: num('completionRate'),
          color: 'success',
          suffix: '%',
          icon: 'TrendCharts'
        },
        { label: '待审开题', value: num('pendingProposal'), color: 'warning', icon: 'Document' },
        { label: '待查中期', value: num('pendingMidterm'), color: 'warning', icon: 'Odometer' },
        { label: '待指派评阅', value: num('pendingAssignReview'), color: 'warning', icon: 'EditPen' },
        { label: '平均总评', value: num('avgScore'), color: 'success', icon: 'Trophy' }
      ]
    case 'ADVISOR':
      return [
        { label: '指导学生', value: num('myStudentCount'), color: 'primary', icon: 'User' },
        { label: '在带论文', value: num('myThesisCount'), color: 'primary', icon: 'Files' },
        { label: '待审选题', value: num('pendingSelection'), color: 'warning', icon: 'Promotion' },
        { label: '待审开题', value: num('pendingProposal'), color: 'warning', icon: 'Document' },
        { label: '待查中期', value: num('pendingMidterm'), color: 'warning', icon: 'Odometer' },
        { label: '已完成', value: num('finishedCount'), color: 'success', icon: 'CircleCheck' }
      ]
    case 'REVIEWER':
      return [
        { label: '待评阅', value: num('pendingCount'), color: 'warning', icon: 'EditPen' },
        { label: '已提交', value: num('submittedCount'), color: 'success', icon: 'CircleCheck' },
        { label: '平均给分', value: num('avgScore'), color: 'primary', icon: 'Trophy' }
      ]
    default:
      return [
        { label: '当前阶段', value: String(o.statusLabel ?? '未开始'), color: 'primary', icon: 'Odometer' },
        { label: '流程进度', value: num('progress'), color: 'success', suffix: '%', icon: 'TrendCharts' },
        {
          label: '总评成绩',
          value: (o.score as { totalScore?: number } | null)?.totalScore ?? '-',
          color: 'warning',
          icon: 'Trophy'
        }
      ]
  }
})

const stageOption = computed(() => {
  const list = overview.value?.stageDistribution ?? []
  return {
    tooltip: { trigger: 'axis' },
    grid: { left: 40, right: 20, top: 20, bottom: 60 },
    xAxis: {
      type: 'category',
      data: list.map((item) => item.label),
      axisLabel: { interval: 0, rotate: 35, fontSize: 11 }
    },
    yAxis: { type: 'value', minInterval: 1 },
    series: [
      {
        type: 'bar',
        barMaxWidth: 34,
        itemStyle: { color: '#409eff', borderRadius: [4, 4, 0, 0] },
        data: list.map((item) => item.count)
      }
    ]
  }
})

const scoreOption = computed(() => {
  const list = overview.value?.scoreDistribution ?? []
  const order = ['不及格', '60-69', '70-79', '80-89', '90-100']
  const map = new Map(list.map((item) => [item.bucket, Number(item.cnt)]))
  const data = order.map((key) => map.get(key) ?? 0)
  return {
    tooltip: { trigger: 'axis' },
    grid: { left: 40, right: 20, top: 20, bottom: 30 },
    xAxis: { type: 'category', data: order },
    yAxis: { type: 'value', minInterval: 1 },
    series: [
      {
        type: 'bar',
        barMaxWidth: 46,
        itemStyle: { color: '#67c23a', borderRadius: [4, 4, 0, 0] },
        data
      }
    ]
  }
})

async function load() {
  loading.value = true
  try {
    overview.value = await dashboardApi.overview()
  } finally {
    loading.value = false
  }
}

onMounted(load)
</script>

<style scoped>
.welcome {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  flex-wrap: wrap;
}

.hello {
  font-size: 17px;
  font-weight: 600;
  margin-bottom: 4px;
}

.todo-list {
  display: flex;
  flex-direction: column;
}

.todo-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 8px;
  border-radius: 6px;
  cursor: pointer;
  transition: background 0.2s;
}

.todo-item:hover {
  background: #f5f7fa;
}

.todo-item + .todo-item {
  border-top: 1px dashed #ebeef5;
}

.todo-title {
  font-size: 14px;
}
</style>
