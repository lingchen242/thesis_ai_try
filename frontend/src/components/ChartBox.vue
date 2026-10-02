<template>
  <div class="chart-box" :style="{ height: typeof height === 'number' ? `${height}px` : height }">
    <v-chart v-if="hasData" :option="option" autoresize />
    <el-empty v-else description="暂无数据" :image-size="70" />
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { use } from 'echarts/core'
import { CanvasRenderer } from 'echarts/renderers'
import { BarChart, FunnelChart, LineChart, PieChart } from 'echarts/charts'
import {
  GridComponent,
  LegendComponent,
  TitleComponent,
  TooltipComponent
} from 'echarts/components'
import VChart from 'vue-echarts'

use([
  CanvasRenderer,
  BarChart,
  LineChart,
  PieChart,
  FunnelChart,
  GridComponent,
  TooltipComponent,
  LegendComponent,
  TitleComponent
])

const props = withDefaults(
  defineProps<{
    option: Record<string, unknown>
    height?: number | string
  }>(),
  { height: 300 }
)

/** 简单判断是否有数据，避免图表区域出现空白 */
const hasData = computed(() => {
  const series = (props.option as { series?: unknown[] }).series
  if (!series || !Array.isArray(series) || series.length === 0) {
    return false
  }
  return series.some((item) => {
    const data = (item as { data?: unknown[] }).data
    return Array.isArray(data) && data.length > 0
  })
})
</script>

<style scoped>
.chart-box {
  width: 100%;
}
</style>
