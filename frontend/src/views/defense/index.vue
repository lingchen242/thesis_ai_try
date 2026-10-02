<template>
  <el-card shadow="never">
    <el-tabs v-model="activeTab" @tab-change="onTabChange">
      <el-tab-pane label="答辩组管理" name="groups" />
      <el-tab-pane label="答辩成绩" name="records" />
    </el-tabs>

    <!-- 答辩组 -->
    <template v-if="activeTab === 'groups'">
      <div class="table-toolbar">
        <span class="text-muted">共 {{ total }} 个答辩组</span>
        <el-button v-if="userStore.isAdmin" type="primary" @click="openGroupForm()">
          <el-icon><Plus /></el-icon>新建答辩组
        </el-button>
      </div>

      <el-table v-loading="loading" :data="groups" border stripe>
        <el-table-column prop="name" label="答辩组名称" min-width="160" />
        <el-table-column prop="grade" label="届别" width="80" align="center" />
        <el-table-column prop="defenseDate" label="答辩时间" width="170" />
        <el-table-column v-if="!isMobile" prop="location" label="地点" width="140" />
        <el-table-column label="成员" width="80" align="center">
          <template #default="{ row }">{{ row.memberCount ?? 0 }}</template>
        </el-table-column>
        <el-table-column label="学生" width="80" align="center">
          <template #default="{ row }">{{ row.thesisCount ?? 0 }}</template>
        </el-table-column>
        <el-table-column label="状态" width="90" align="center">
          <template #default="{ row }">
            <StatusTag :status="row.status" kind="defenseGroup" />
          </template>
        </el-table-column>
        <el-table-column label="操作" :width="isMobile ? 100 : 260" fixed="right">
          <template #default="{ row }">
            <el-button text type="primary" size="small" @click="openDetail(row)">详情</el-button>
            <template v-if="userStore.isAdmin">
              <el-button text size="small" @click="openGroupForm(row)">编辑</el-button>
              <el-button text type="danger" size="small" @click="removeGroup(row)">删除</el-button>
            </template>
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
    </template>

    <!-- 答辩成绩 -->
    <template v-else>
      <div class="search-bar">
        <el-select v-model="recordQuery.groupId" placeholder="答辩组" clearable>
          <el-option v-for="item in groups" :key="item.id" :label="item.name" :value="item.id as number" />
        </el-select>
        <el-button type="primary" @click="loadRecords">查询</el-button>
      </div>

      <el-table v-loading="recordsLoading" :data="records" border stripe>
        <el-table-column prop="studentName" label="学生" width="100" />
        <el-table-column v-if="!isMobile" prop="studentNo" label="学号" width="120" />
        <el-table-column prop="thesisTitle" label="论文题目" min-width="200" show-overflow-tooltip />
        <el-table-column prop="groupName" label="答辩组" width="150" />
        <el-table-column label="成绩" width="90" align="center">
          <template #default="{ row }">{{ row.score ?? '待录入' }}</template>
        </el-table-column>
        <el-table-column label="结论" width="90" align="center">
          <template #default="{ row }">
            <StatusTag v-if="row.result" :status="row.result" kind="defenseResult" />
            <span v-else>-</span>
          </template>
        </el-table-column>
        <el-table-column v-if="!isMobile" prop="comment" label="答辩评语" min-width="180" show-overflow-tooltip />
        <el-table-column label="操作" width="100" fixed="right">
          <template #default="{ row }">
            <el-button text type="primary" size="small" @click="openRecord(row)">录入</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination-wrap">
        <el-pagination
          v-model:current-page="recordQuery.pageNum"
          v-model:page-size="recordQuery.pageSize"
          :total="recordTotal"
          :page-sizes="[10, 20, 50]"
          layout="total, sizes, prev, pager, next"
          background
          @change="loadRecords"
        />
      </div>
    </template>
  </el-card>

  <!-- 新建 / 编辑答辩组 -->
  <el-drawer v-model="groupFormVisible" :title="groupForm.id ? '编辑答辩组' : '新建答辩组'" size="min(480px, 92%)">
    <el-form ref="groupFormRef" :model="groupForm" :rules="groupRules" label-width="90px">
      <el-form-item label="名称" prop="name">
        <el-input v-model="groupForm.name" maxlength="100" />
      </el-form-item>
      <el-form-item label="届别" prop="grade">
        <el-select v-model="groupForm.grade" style="width: 100%">
          <el-option v-for="item in gradeOptions" :key="item.id" :label="item.itemName" :value="item.itemName" />
        </el-select>
      </el-form-item>
      <el-form-item label="答辩时间" prop="defenseDate">
        <el-date-picker
          v-model="groupForm.defenseDate"
          type="datetime"
          value-format="YYYY-MM-DD HH:mm:ss"
          placeholder="选择时间"
          style="width: 100%"
        />
      </el-form-item>
      <el-form-item label="答辩地点">
        <el-input v-model="groupForm.location" maxlength="100" />
      </el-form-item>
      <el-form-item label="备注">
        <el-input v-model="groupForm.remark" type="textarea" :rows="3" maxlength="500" />
      </el-form-item>
      <el-form-item>
        <el-button type="primary" :loading="saving" @click="saveGroup">保存</el-button>
        <el-button @click="groupFormVisible = false">取消</el-button>
      </el-form-item>
    </el-form>
  </el-drawer>

  <!-- 答辩组详情：成员 + 学生 -->
  <el-drawer v-model="detailVisible" title="答辩组详情" size="min(760px, 96%)">
    <template v-if="detailGroup">
      <el-descriptions :column="isMobile ? 1 : 2" border size="small" class="mb-16">
        <el-descriptions-item label="名称">{{ detailGroup.group.name }}</el-descriptions-item>
        <el-descriptions-item label="届别">{{ detailGroup.group.grade }}</el-descriptions-item>
        <el-descriptions-item label="时间">{{ detailGroup.group.defenseDate || '-' }}</el-descriptions-item>
        <el-descriptions-item label="地点">{{ detailGroup.group.location || '-' }}</el-descriptions-item>
      </el-descriptions>

      <template v-if="userStore.isAdmin">
        <el-divider content-position="left">答辩组成员</el-divider>
        <el-form label-width="90px">
          <el-form-item label="成员">
            <el-select v-model="memberForm.memberIds" multiple filterable style="width: 100%" placeholder="选择答辩组成员">
              <el-option
                v-for="item in allTeachers"
                :key="item.id"
                :label="`${item.realName}（${item.teacherNo}）`"
                :value="item.id as number"
              />
            </el-select>
          </el-form-item>
          <el-form-item label="组长">
            <el-select v-model="memberForm.chairId" clearable style="width: 100%">
              <el-option
                v-for="id in memberForm.memberIds"
                :key="id"
                :label="teacherName(id)"
                :value="id"
              />
            </el-select>
          </el-form-item>
          <el-form-item label="秘书">
            <el-select v-model="memberForm.secretaryId" clearable style="width: 100%">
              <el-option
                v-for="id in memberForm.memberIds"
                :key="id"
                :label="teacherName(id)"
                :value="id"
              />
            </el-select>
          </el-form-item>
          <el-form-item>
            <el-button type="primary" :loading="saving" @click="saveMembers">保存成员</el-button>
          </el-form-item>
        </el-form>
      </template>
      <template v-else>
        <el-table :data="detailGroup.members" border size="small">
          <el-table-column prop="teacherName" label="姓名" width="110" />
          <el-table-column prop="title" label="职称" width="100" />
          <el-table-column label="角色" width="100">
            <template #default="{ row }">
              {{ { CHAIR: '组长', SECRETARY: '秘书', MEMBER: '委员' }[row.roleInGroup as string] ?? '委员' }}
            </template>
          </el-table-column>
          <el-table-column prop="college" label="学院" />
        </el-table>
      </template>

      <el-divider content-position="left">答辩学生（{{ detailGroup.theses.length }}）</el-divider>
      <div v-if="userStore.isAdmin" class="mb-16">
        <el-select v-model="scheduleIds" multiple filterable placeholder="从评阅通过的学生中选择编入本组" style="width: 100%">
          <el-option
            v-for="item in candidates"
            :key="item.id"
            :label="`${item.studentName}（${item.studentNo}） - ${item.title}`"
            :value="item.id as number"
          />
        </el-select>
        <el-button type="primary" class="mt-8" :loading="saving" @click="saveSchedule">
          编入答辩组
        </el-button>
      </div>

      <el-table :data="detailGroup.theses" border size="small">
        <el-table-column prop="studentName" label="学生" width="100" />
        <el-table-column prop="studentNo" label="学号" width="120" />
        <el-table-column prop="title" label="论文题目" min-width="180" show-overflow-tooltip />
        <el-table-column prop="statusLabel" label="阶段" width="110" />
        <el-table-column v-if="userStore.isAdmin" label="操作" width="80">
          <template #default="{ row }">
            <el-button text type="danger" size="small" @click="removeThesis(row)">移除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </template>
  </el-drawer>

  <!-- 录入答辩成绩 -->
  <el-dialog v-model="recordVisible" title="录入答辩成绩" width="min(560px, 94vw)">
    <template v-if="currentRecord">
      <el-descriptions :column="1" border size="small" class="mb-16">
        <el-descriptions-item label="学生">
          {{ currentRecord.studentName }}（{{ currentRecord.studentNo }}）
        </el-descriptions-item>
        <el-descriptions-item label="论文题目">{{ currentRecord.thesisTitle }}</el-descriptions-item>
        <el-descriptions-item label="答辩组">{{ currentRecord.groupName }}</el-descriptions-item>
      </el-descriptions>
      <el-form label-width="90px">
        <el-form-item label="答辩成绩">
          <el-input-number v-model="recordForm.score" :min="0" :max="100" :precision="1" />
        </el-form-item>
        <el-form-item label="答辩结论">
          <el-select v-model="recordForm.result" clearable placeholder="留空则按成绩自动判定" style="width: 100%">
            <el-option v-for="item in resultOptions" :key="item.value" :label="item.label" :value="item.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="答辩评语">
          <el-input v-model="recordForm.comment" type="textarea" :rows="4" maxlength="1000" />
        </el-form-item>
      </el-form>
    </template>
    <template #footer>
      <el-button @click="recordVisible = false">取消</el-button>
      <el-button type="primary" :loading="saving" @click="saveRecord">保存成绩</el-button>
    </template>
  </el-dialog>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox, type FormInstance, type FormRules } from 'element-plus'
import { defenseApi, userApi } from '@/api'
import { useUserStore } from '@/stores/user'
import { useRootDictOptions } from '@/composables/useDict'
import { useResponsive } from '@/composables/useResponsive'
import { DEFENSE_RESULT, DICT } from '@/constants'
import StatusTag from '@/components/StatusTag.vue'
import type {
  DefenseGroup,
  DefenseGroupMember,
  DefenseRecord,
  PageQuery,
  Teacher,
  Thesis
} from '@/types'

const userStore = useUserStore()
const { isMobile } = useResponsive()
const gradeOptions = useRootDictOptions(DICT.GRADE)

const resultOptions = Object.entries(DEFENSE_RESULT).map(([value, item]) => ({
  value,
  label: item.label
}))

const activeTab = ref('groups')
const loading = ref(false)
const recordsLoading = ref(false)
const saving = ref(false)

const groups = ref<DefenseGroup[]>([])
const total = ref(0)
const query = reactive<PageQuery>({ pageNum: 1, pageSize: 10 })

const records = ref<DefenseRecord[]>([])
const recordTotal = ref(0)
const recordQuery = reactive<PageQuery>({ pageNum: 1, pageSize: 10, groupId: undefined })

const allTeachers = ref<Teacher[]>([])

const groupFormVisible = ref(false)
const groupFormRef = ref<FormInstance>()
const groupForm = reactive<DefenseGroup>({ name: '', grade: '', defenseDate: '', location: '', remark: '' })
const groupRules: FormRules = {
  name: [{ required: true, message: '请输入答辩组名称', trigger: 'blur' }],
  grade: [{ required: true, message: '请选择届别', trigger: 'change' }]
}

interface GroupDetail {
  group: DefenseGroup
  members: DefenseGroupMember[]
  theses: Thesis[]
}

const detailVisible = ref(false)
const detailGroup = ref<GroupDetail | null>(null)
const candidates = ref<Thesis[]>([])
const scheduleIds = ref<number[]>([])
const memberForm = reactive<{ memberIds: number[]; chairId?: number; secretaryId?: number }>({
  memberIds: [],
  chairId: undefined,
  secretaryId: undefined
})

const recordVisible = ref(false)
const currentRecord = ref<DefenseRecord | null>(null)
const recordForm = reactive<{ score?: number; result?: string; comment: string }>({
  score: 85,
  result: '',
  comment: ''
})

const teacherName = computed(() => (id: number) => {
  const teacher = allTeachers.value.find((item) => item.id === id)
  return teacher ? `${teacher.realName}（${teacher.teacherNo}）` : String(id)
})

async function load() {
  loading.value = true
  try {
    const res = await defenseApi.pageGroups({ ...query })
    groups.value = res.records
    total.value = res.total
  } finally {
    loading.value = false
  }
}

async function loadRecords() {
  recordsLoading.value = true
  try {
    const res = await defenseApi.pageRecords({ ...recordQuery })
    records.value = res.records
    recordTotal.value = res.total
  } finally {
    recordsLoading.value = false
  }
}

function onTabChange(name: string | number) {
  if (name === 'records') {
    loadRecords()
  } else {
    load()
  }
}

async function ensureTeachers() {
  if (allTeachers.value.length) return
  const options = await userApi.teacherOptions()
  allTeachers.value = [...options.advisors, ...options.reviewers]
}

function openGroupForm(row?: DefenseGroup) {
  groupForm.id = row?.id
  groupForm.name = row?.name ?? ''
  groupForm.grade = row?.grade ?? ''
  groupForm.defenseDate = row?.defenseDate ?? ''
  groupForm.location = row?.location ?? ''
  groupForm.remark = row?.remark ?? ''
  groupForm.status = row?.status
  groupFormVisible.value = true
}

async function saveGroup() {
  const valid = await groupFormRef.value?.validate().catch(() => false)
  if (!valid) return
  saving.value = true
  try {
    if (groupForm.id) {
      await defenseApi.updateGroup(groupForm.id, groupForm)
    } else {
      await defenseApi.createGroup(groupForm)
    }
    ElMessage.success('保存成功')
    groupFormVisible.value = false
    load()
  } finally {
    saving.value = false
  }
}

async function removeGroup(row: DefenseGroup) {
  await ElMessageBox.confirm(`确定删除答辩组「${row.name}」？`, '提示', { type: 'warning' })
  await defenseApi.deleteGroup(row.id as number)
  ElMessage.success('已删除')
  load()
}

async function openDetail(row: DefenseGroup) {
  await ensureTeachers()
  detailGroup.value = await defenseApi.groupDetail(row.id as number)
  memberForm.memberIds = detailGroup.value.members.map((item) => item.teacherId as number)
  const chair = detailGroup.value.members.find((item) => item.roleInGroup === 'CHAIR')
  const secretary = detailGroup.value.members.find((item) => item.roleInGroup === 'SECRETARY')
  memberForm.chairId = chair?.teacherId
  memberForm.secretaryId = secretary?.teacherId
  scheduleIds.value = []
  candidates.value = await defenseApi.candidates(row.id as number)
  detailVisible.value = true
}

async function saveMembers() {
  if (!detailGroup.value?.group.id) return
  saving.value = true
  try {
    await defenseApi.setMembers(detailGroup.value.group.id, {
      memberIds: memberForm.memberIds,
      chairId: memberForm.chairId,
      secretaryId: memberForm.secretaryId
    })
    ElMessage.success('成员已保存')
    openDetail(detailGroup.value.group)
  } finally {
    saving.value = false
  }
}

async function saveSchedule() {
  if (!detailGroup.value?.group.id) return
  if (!scheduleIds.value.length) {
    ElMessage.warning('请先选择要编入的学生')
    return
  }
  saving.value = true
  try {
    await defenseApi.schedule(detailGroup.value.group.id, scheduleIds.value)
    ElMessage.success('已编入答辩组')
    openDetail(detailGroup.value.group)
  } finally {
    saving.value = false
  }
}

async function removeThesis(row: Thesis) {
  await ElMessageBox.confirm('确定将该学生移出答辩组？', '提示', { type: 'warning' })
  await defenseApi.removeThesis(row.id as number)
  if (detailGroup.value) {
    openDetail(detailGroup.value.group)
  }
}

function openRecord(row: DefenseRecord) {
  currentRecord.value = row
  recordForm.score = row.score ?? 85
  recordForm.result = row.result ?? ''
  recordForm.comment = row.comment ?? ''
  recordVisible.value = true
}

async function saveRecord() {
  if (!currentRecord.value?.thesisId || !currentRecord.value.groupId) return
  saving.value = true
  try {
    await defenseApi.record({
      thesisId: currentRecord.value.thesisId,
      groupId: currentRecord.value.groupId,
      score: recordForm.score,
      result: recordForm.result || undefined,
      comment: recordForm.comment
    })
    ElMessage.success('成绩已保存')
    recordVisible.value = false
    loadRecords()
    load()
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  await ensureTeachers()
  load()
})
</script>
