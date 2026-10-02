import { computed, onBeforeUnmount, onMounted, ref } from 'vue'

/**
 * 响应式断点。
 * xs < 768（手机）/ sm 768~992（平板竖）/ md 992~1200 / lg >= 1200
 */
export function useResponsive() {
  const width = ref(typeof window === 'undefined' ? 1440 : window.innerWidth)

  function update() {
    width.value = window.innerWidth
  }

  onMounted(() => window.addEventListener('resize', update, { passive: true }))
  onBeforeUnmount(() => window.removeEventListener('resize', update))

  const isMobile = computed(() => width.value < 768)
  const isTablet = computed(() => width.value >= 768 && width.value < 992)
  /** 侧边栏常驻的阈值 */
  const isDesktop = computed(() => width.value >= 992)
  /** 表格需要转卡片流的阈值 */
  const useCardList = computed(() => width.value < 768)

  return { width, isMobile, isTablet, isDesktop, useCardList }
}
