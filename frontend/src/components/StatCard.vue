<template>
  <div class="stat-card">
    <div class="label">
      <el-icon v-if="icon" :size="14"><component :is="icon" /></el-icon>
      <span>{{ label }}</span>
    </div>
    <div class="value" :class="color">
      <slot>{{ value }}</slot>
      <span v-if="suffix" class="suffix">{{ suffix }}</span>
    </div>
  </div>
</template>

<script setup lang="ts">
withDefaults(
  defineProps<{
    label: string
    value?: string | number | null
    color?: 'primary' | 'success' | 'warning' | 'danger' | ''
    suffix?: string
    icon?: string
  }>(),
  { color: '', value: 0 }
)
</script>

<style scoped>
.stat-card .label {
  display: flex;
  align-items: center;
  gap: 4px;
}

.stat-card .suffix {
  font-size: 13px;
  margin-left: 2px;
  color: var(--el-text-color-secondary);
}
</style>
