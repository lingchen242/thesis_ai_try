<template>
  <el-tag :type="meta.type as never" size="small" effect="light">{{ meta.label }}</el-tag>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import {
  DEFENSE_GROUP_STATUS,
  DEFENSE_RESULT,
  REVIEW_STATUS,
  REVIEW_TASK_STATUS,
  SELECTION_STATUS,
  THESIS_STATUS,
  TOPIC_STATUS
} from '@/constants'

type Kind = 'thesis' | 'review' | 'selection' | 'topic' | 'reviewTask' | 'defenseResult' | 'defenseGroup'

const props = withDefaults(defineProps<{ status?: string; kind?: Kind }>(), {
  kind: 'thesis'
})

const MAPS: Record<Kind, Record<string, { label: string; type: string }>> = {
  thesis: THESIS_STATUS,
  review: REVIEW_STATUS,
  selection: SELECTION_STATUS,
  topic: TOPIC_STATUS,
  reviewTask: REVIEW_TASK_STATUS,
  defenseResult: DEFENSE_RESULT,
  defenseGroup: DEFENSE_GROUP_STATUS
}

const meta = computed(() => {
  const map = MAPS[props.kind] ?? THESIS_STATUS
  if (!props.status) {
    return { label: '-', type: 'info' }
  }
  return map[props.status] ?? { label: props.status, type: 'info' }
})
</script>
