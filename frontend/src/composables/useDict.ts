import { onMounted, ref, type Ref } from 'vue'
import { useDictStore } from '@/stores/dict'
import type { DictItem } from '@/types'

/** 加载某个字典类型的可选项（下拉框用） */
export function useDictOptions(typeCode: string): Ref<DictItem[]> {
  const store = useDictStore()
  const options = ref<DictItem[]>([])

  onMounted(async () => {
    options.value = await store.load(typeCode)
  })

  return options
}

/** 只取顶级字典项（学院、届别等） */
export function useRootDictOptions(typeCode: string): Ref<DictItem[]> {
  const store = useDictStore()
  const options = ref<DictItem[]>([])

  onMounted(async () => {
    options.value = await store.loadRoot(typeCode)
  })

  return options
}

/** 按名称反查字典项 id（级联回填） */
export async function resolveDictIdByName(typeCode: string, name?: string | null) {
  if (!name) return undefined
  const store = useDictStore()
  let items = store.cache[typeCode]
  if (!items) {
    items = await store.load(typeCode, true)
  }
  return items.find((item) => item.itemName === name)?.id
}

/** 通用字典名称到 id 的级联加载：学院 -> 专业 -> 班级 */
export function useOrgCascade() {
  const store = useDictStore()

  async function colleges() {
    return store.loadRoot('COLLEGE', true)
  }

  async function majors(collegeName: string) {
    const collegeId = await resolveDictIdByName('COLLEGE', collegeName)
    if (!collegeId) return []
    return store.loadChildren('MAJOR', collegeId)
  }

  async function classes(majorName: string) {
    const majorId = await resolveDictIdByName('MAJOR', majorName)
    if (!majorId) return []
    return store.loadChildren('CLASS', majorId)
  }

  return { colleges, majors, classes }
}
