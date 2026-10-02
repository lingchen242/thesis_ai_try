import { defineStore } from 'pinia'
import { ref } from 'vue'
import { dictApi } from '@/api'
import type { DictItem } from '@/types'

/**
 * 字典缓存。字典数据变化不频繁，前端按 typeCode 缓存，避免每个下拉框都请求一次。
 */
export const useDictStore = defineStore('dict', () => {
  const cache = ref<Record<string, DictItem[]>>({})
  const loading = ref<Record<string, boolean>>({})

  async function load(typeCode: string, force = false): Promise<DictItem[]> {
    if (!force && cache.value[typeCode]) {
      return cache.value[typeCode]
    }
    if (loading.value[typeCode]) {
      // 简单轮询等待，避免并发重复请求
      await new Promise((resolve) => setTimeout(resolve, 120))
      if (cache.value[typeCode]) {
        return cache.value[typeCode]
      }
    }
    loading.value[typeCode] = true
    try {
      const items = await dictApi.listItems({ typeCode, onlyEnabled: true })
      cache.value[typeCode] = items ?? []
      return cache.value[typeCode]
    } finally {
      loading.value[typeCode] = false
    }
  }

  /** 只取顶级项（学院、届别等） */
  async function loadRoot(typeCode: string, force = false): Promise<DictItem[]> {
    const key = `${typeCode}#root`
    if (!force && cache.value[key]) {
      return cache.value[key]
    }
    const items = await dictApi.listItems({ typeCode, parentId: 0, onlyEnabled: true })
    cache.value[key] = items ?? []
    return cache.value[key]
  }

  /** 取某父级下的子项（专业、班级级联） */
  async function loadChildren(typeCode: string, parentId: number): Promise<DictItem[]> {
    const key = `${typeCode}#${parentId}`
    if (cache.value[key]) {
      return cache.value[key]
    }
    const items = await dictApi.listItems({ typeCode, parentId, onlyEnabled: true })
    cache.value[key] = items ?? []
    return cache.value[key]
  }

  function clear(typeCode?: string) {
    if (!typeCode) {
      cache.value = {}
      return
    }
    Object.keys(cache.value)
      .filter((key) => key.startsWith(typeCode))
      .forEach((key) => delete cache.value[key])
  }

  /** 由名称反查字典项（编辑回填用） */
  function idByName(typeCode: string, name?: string | null): number | undefined {
    if (!name) return undefined
    return cache.value[typeCode]?.find((item) => item.itemName === name)?.id
  }

  return { cache, load, loadRoot, loadChildren, clear, idByName }
})
