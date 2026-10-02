<template>
  <el-row :gutter="12">
    <!-- 字典类型 -->
    <el-col :xs="24" :sm="24" :md="8" :lg="7">
      <el-card shadow="never" class="mb-16">
        <template #header>
          <div class="table-toolbar" style="margin-bottom: 0">
            <span>字典类型</span>
            <el-button type="primary" size="small" @click="openTypeForm()">新增</el-button>
          </div>
        </template>
        <div v-loading="typeLoading" class="type-list">
          <div
            v-for="item in types"
            :key="item.typeCode"
            class="type-item"
            :class="{ active: item.typeCode === activeType }"
            @click="selectType(item.typeCode)"
          >
            <div>
              <div class="type-name">{{ item.typeName }}</div>
              <div class="text-muted">{{ item.typeCode }}</div>
            </div>
            <div class="type-actions">
              <el-tag size="small" effect="plain">{{ item.itemCount ?? 0 }}</el-tag>
              <el-button text size="small" @click.stop="openTypeForm(item)">编辑</el-button>
              <el-button text type="danger" size="small" @click.stop="removeType(item)">删除</el-button>
            </div>
          </div>
        </div>
      </el-card>
    </el-col>

    <!-- 字典项 -->
    <el-col :xs="24" :sm="24" :md="16" :lg="17">
      <el-card shadow="never" class="mb-16">
        <template #header>
          <div class="table-toolbar" style="margin-bottom: 0">
            <span>
              字典项
              <span class="text-muted">
                {{ currentType?.typeName }}（{{ activeType }}）
              </span>
            </span>
            <div>
              <el-button size="small" @click="expandAll = !expandAll">
                {{ expandAll ? '折叠全部' : '展开全部' }}
              </el-button>
              <el-button type="primary" size="small" @click="openItemForm()">新增顶级项</el-button>
            </div>
          </div>
        </template>

        <el-alert
          v-if="activeType === 'COLLEGE'"
          class="mb-16"
          type="info"
          :closable="false"
          show-icon
          title="学院 → 专业 → 班级 为三级树结构。新增专业时请选择上级学院，新增班级时请选择上级专业。"
        />

        <el-table
          v-loading="itemLoading"
          :data="tree"
          row-key="id"
          border
          :default-expand-all="expandAll"
          :tree-props="{ children: 'children' }"
        >
          <el-table-column prop="itemName" label="名称" min-width="200" />
          <el-table-column v-if="!isMobile" prop="itemCode" label="编码" width="150" />
          <el-table-column v-if="!isMobile" prop="sortNo" label="排序" width="80" align="center" />
          <el-table-column label="状态" width="90" align="center">
            <template #default="{ row }">
              <el-tag :type="row.status === 1 ? 'success' : 'info'" size="small" effect="plain">
                {{ row.status === 1 ? '启用' : '停用' }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column label="操作" :width="isMobile ? 130 : 200" fixed="right">
            <template #default="{ row }">
              <el-button text type="primary" size="small" @click="openItemForm(undefined, row)">
                加子项
              </el-button>
              <el-button text size="small" @click="openItemForm(row)">编辑</el-button>
              <el-button v-if="!isMobile" text type="danger" size="small" @click="removeItem(row)">
                删除
              </el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-card>
    </el-col>
  </el-row>

  <!-- 类型表单 -->
  <el-dialog v-model="typeFormVisible" :title="typeForm.id ? '编辑字典类型' : '新增字典类型'" width="min(460px, 92vw)">
    <el-form :model="typeForm" label-width="90px">
      <el-form-item label="类型编码" required>
        <el-input v-model="typeForm.typeCode" :disabled="!!typeForm.id" placeholder="大写英文，如 COLLEGE" />
      </el-form-item>
      <el-form-item label="类型名称" required>
        <el-input v-model="typeForm.typeName" />
      </el-form-item>
      <el-form-item label="说明">
        <el-input v-model="typeForm.remark" type="textarea" :rows="2" />
      </el-form-item>
    </el-form>
    <template #footer>
      <el-button @click="typeFormVisible = false">取消</el-button>
      <el-button type="primary" :loading="saving" @click="saveType">保存</el-button>
    </template>
  </el-dialog>

  <!-- 字典项表单 -->
  <el-dialog v-model="itemFormVisible" :title="itemForm.id ? '编辑字典项' : '新增字典项'" width="min(480px, 92vw)">
    <el-form :model="itemForm" label-width="90px">
      <el-form-item label="所属类型">
        <el-input :model-value="`${currentType?.typeName}（${activeType}）`" disabled />
      </el-form-item>
      <el-form-item v-if="itemForm.parentId" label="上级">
        <el-input :model-value="parentName" disabled />
      </el-form-item>
      <el-form-item label="名称" required>
        <el-input v-model="itemForm.itemName" placeholder="业务表将冗余存储该名称" />
      </el-form-item>
      <el-form-item label="编码">
        <el-input v-model="itemForm.itemCode" placeholder="留空自动生成" />
      </el-form-item>
      <el-form-item label="排序">
        <el-input-number v-model="itemForm.sortNo" :min="0" :max="9999" />
      </el-form-item>
      <el-form-item label="状态">
        <el-switch v-model="itemStatusSwitch" />
      </el-form-item>
      <el-form-item label="说明">
        <el-input v-model="itemForm.remark" type="textarea" :rows="2" />
      </el-form-item>
    </el-form>
    <template #footer>
      <el-button @click="itemFormVisible = false">取消</el-button>
      <el-button type="primary" :loading="saving" @click="saveItem">保存</el-button>
    </template>
  </el-dialog>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { dictApi } from '@/api'
import { useDictStore } from '@/stores/dict'
import { useResponsive } from '@/composables/useResponsive'
import type { DictItem, DictType } from '@/types'

const dictStore = useDictStore()
const { isMobile } = useResponsive()

const typeLoading = ref(false)
const itemLoading = ref(false)
const saving = ref(false)
const types = ref<DictType[]>([])
const activeType = ref('COLLEGE')
const tree = ref<DictItem[]>([])
const expandAll = ref(false)

const currentType = computed(() => types.value.find((item) => item.typeCode === activeType.value))

const typeFormVisible = ref(false)
const typeForm = reactive<DictType>({ typeCode: '', typeName: '', remark: '' })

const itemFormVisible = ref(false)
const itemForm = reactive<DictItem>({ typeCode: '', itemName: '', itemCode: '', parentId: null, sortNo: 0, status: 1, remark: '' })
const parentName = ref('')

const itemStatusSwitch = computed({
  get: () => itemForm.status === 1,
  set: (value: boolean) => {
    itemForm.status = value ? 1 : 0
  }
})

async function loadTypes() {
  typeLoading.value = true
  try {
    types.value = await dictApi.listTypes()
    if (types.value.length && !types.value.some((item) => item.typeCode === activeType.value)) {
      activeType.value = types.value[0].typeCode
    }
  } finally {
    typeLoading.value = false
  }
}

async function loadItems() {
  itemLoading.value = true
  try {
    tree.value = await dictApi.listItems({ typeCode: activeType.value, asTree: true })
  } finally {
    itemLoading.value = false
  }
}

async function selectType(typeCode: string) {
  activeType.value = typeCode
  await loadItems()
}

function openTypeForm(row?: DictType) {
  typeForm.id = row?.id
  typeForm.typeCode = row?.typeCode ?? ''
  typeForm.typeName = row?.typeName ?? ''
  typeForm.remark = row?.remark ?? ''
  typeFormVisible.value = true
}

async function saveType() {
  if (!typeForm.typeCode || !typeForm.typeName) {
    ElMessage.warning('请填写类型编码与名称')
    return
  }
  saving.value = true
  try {
    if (typeForm.id) {
      await dictApi.updateType(typeForm.id, typeForm)
    } else {
      await dictApi.createType(typeForm)
    }
    ElMessage.success('保存成功')
    typeFormVisible.value = false
    dictStore.clear()
    await loadTypes()
    await loadItems()
  } finally {
    saving.value = false
  }
}

async function removeType(row: DictType) {
  await ElMessageBox.confirm(`确定删除字典类型「${row.typeName}」？`, '提示', { type: 'warning' })
  await dictApi.deleteType(row.id as number)
  ElMessage.success('已删除')
  dictStore.clear()
  loadTypes()
}

function openItemForm(row?: DictItem, parent?: DictItem) {
  itemForm.id = row?.id
  itemForm.typeCode = activeType.value
  itemForm.itemName = row?.itemName ?? ''
  itemForm.itemCode = row?.itemCode ?? ''
  itemForm.sortNo = row?.sortNo ?? 0
  itemForm.status = row?.status ?? 1
  itemForm.remark = row?.remark ?? ''
  itemForm.parentId = row?.parentId ?? parent?.id ?? null
  parentName.value = parent?.itemName ?? row?.parentName ?? ''
  itemFormVisible.value = true
}

async function saveItem() {
  if (!itemForm.itemName) {
    ElMessage.warning('请填写名称')
    return
  }
  saving.value = true
  try {
    if (itemForm.id) {
      await dictApi.updateItem(itemForm.id, itemForm)
    } else {
      await dictApi.createItem(itemForm)
    }
    ElMessage.success('保存成功')
    itemFormVisible.value = false
    dictStore.clear()
    await loadItems()
    await loadTypes()
  } finally {
    saving.value = false
  }
}

async function removeItem(row: DictItem) {
  await ElMessageBox.confirm(`确定删除「${row.itemName}」？`, '提示', { type: 'warning' })
  await dictApi.deleteItem(row.id as number)
  ElMessage.success('已删除')
  dictStore.clear()
  await loadItems()
  await loadTypes()
}

onMounted(async () => {
  await loadTypes()
  await loadItems()
})
</script>

<style scoped>
.type-list {
  display: flex;
  flex-direction: column;
}

.type-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  padding: 10px;
  border-radius: 6px;
  cursor: pointer;
  transition: background 0.2s;
}

.type-item:hover {
  background: #f5f7fa;
}

.type-item.active {
  background: #ecf5ff;
}

.type-name {
  font-size: 14px;
  font-weight: 500;
}

.type-actions {
  display: flex;
  align-items: center;
  gap: 4px;
}
</style>
