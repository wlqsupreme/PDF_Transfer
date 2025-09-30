<template>
  <div class="progress-container">
    <div class="progress-header">
      <div class="progress-title">
        <el-icon class="loading-spinner" v-if="progress < 100"><Loading /></el-icon>
        <el-icon v-else color="#67c23a"><SuccessFilled /></el-icon>
        {{ status }}
      </div>
      <div class="progress-percentage">{{ progress }}%</div>
    </div>

    <!-- 进度条 -->
    <el-progress 
      :percentage="progress" 
      :status="progressStatus"
      :stroke-width="8"
      :show-text="false"
      class="progress-bar"
    />

    <!-- 文件信息 -->
    <div v-if="filename" class="file-info">
      <div class="file-name">
        <el-icon><Document /></el-icon>
        {{ filename }}
      </div>
    </div>

    <!-- 处理步骤 -->
    <div class="processing-steps">
      <div 
        v-for="(step, index) in processingSteps" 
        :key="index"
        class="step-item"
        :class="{ 
          'active': step.active, 
          'completed': step.completed,
          'pending': step.pending
        }"
      >
        <div class="step-icon">
          <el-icon v-if="step.completed" color="#67c23a"><Check /></el-icon>
          <el-icon v-else-if="step.active" class="loading-spinner"><Loading /></el-icon>
          <el-icon v-else color="#c0c4cc"><Clock /></el-icon>
        </div>
        <div class="step-content">
          <div class="step-title">{{ step.title }}</div>
          <div class="step-description">{{ step.description }}</div>
        </div>
      </div>
    </div>

    <!-- 处理提示 -->
    <div class="processing-tips">
      <el-alert
        :title="getProcessingTip()"
        :type="getTipType()"
        :closable="false"
        show-icon
      />
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { Loading, SuccessFilled, Document, Check, Clock } from '@element-plus/icons-vue'

// Props
const props = defineProps({
  progress: {
    type: Number,
    default: 0
  },
  status: {
    type: String,
    default: ''
  },
  filename: {
    type: String,
    default: ''
  }
})

// 响应式数据
const processingSteps = ref([
  {
    title: '文件上传',
    description: '正在上传PDF文件到服务器',
    active: false,
    completed: false,
    pending: true
  },
  {
    title: '文件检测',
    description: '分析PDF文件类型和结构',
    active: false,
    completed: false,
    pending: true
  },
  {
    title: '内容提取',
    description: '提取文本、表格和图像内容',
    active: false,
    completed: false,
    pending: true
  },
  {
    title: '格式转换',
    description: '转换为Markdown格式',
    active: false,
    completed: false,
    pending: true
  },
  {
    title: '处理完成',
    description: '生成最终转换结果',
    active: false,
    completed: false,
    pending: true
  }
])

// 计算属性
const progressStatus = computed(() => {
  if (props.progress === 100) return 'success'
  if (props.progress > 0) return ''
  return 'exception'
})

// 监听进度变化，更新处理步骤
watch(() => props.progress, (newProgress) => {
  updateProcessingSteps(newProgress)
})

// 更新处理步骤状态
const updateProcessingSteps = (progress) => {
  const stepProgress = progress / 20 // 每个步骤占20%
  
  processingSteps.value.forEach((step, index) => {
    if (index < Math.floor(stepProgress)) {
      step.completed = true
      step.active = false
      step.pending = false
    } else if (index === Math.floor(stepProgress)) {
      step.completed = false
      step.active = true
      step.pending = false
    } else {
      step.completed = false
      step.active = false
      step.pending = true
    }
  })
}

// 获取处理提示
const getProcessingTip = () => {
  if (props.progress === 0) {
    return '准备开始处理，请稍候...'
  } else if (props.progress < 20) {
    return '正在上传文件，请保持网络连接稳定'
  } else if (props.progress < 40) {
    return '正在分析文件结构，检测PDF类型'
  } else if (props.progress < 60) {
    return '正在提取内容，这可能需要一些时间'
  } else if (props.progress < 80) {
    return '正在转换格式，生成Markdown文档'
  } else if (props.progress < 100) {
    return '即将完成，正在生成最终结果'
  } else {
    return '处理完成！您可以查看和下载转换结果'
  }
}

// 获取提示类型
const getTipType = () => {
  if (props.progress === 100) return 'success'
  if (props.progress > 50) return 'info'
  return 'warning'
}
</script>

<style scoped>
.progress-container {
  margin: 2rem 0;
  padding: 1.5rem;
  background: #f8fafc;
  border-radius: 12px;
  border: 1px solid #e2e8f0;
}

.progress-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.progress-title {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 1.1rem;
  font-weight: 600;
  color: #1f2937;
}

.progress-percentage {
  font-size: 1.2rem;
  font-weight: 700;
  color: #667eea;
}

.progress-bar {
  margin-bottom: 1.5rem;
}

.file-info {
  margin-bottom: 1.5rem;
  padding: 1rem;
  background: white;
  border-radius: 8px;
  border: 1px solid #e5e7eb;
}

.file-name {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: #4b5563;
  font-weight: 500;
}

.processing-steps {
  margin-bottom: 1.5rem;
}

.step-item {
  display: flex;
  align-items: flex-start;
  gap: 1rem;
  padding: 0.75rem 0;
  border-bottom: 1px solid #f3f4f6;
}

.step-item:last-child {
  border-bottom: none;
}

.step-icon {
  flex-shrink: 0;
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.step-content {
  flex: 1;
}

.step-title {
  font-weight: 600;
  color: #1f2937;
  margin-bottom: 0.25rem;
}

.step-description {
  font-size: 0.9rem;
  color: #6b7280;
  line-height: 1.4;
}

/* 步骤状态样式 */
.step-item.completed .step-title {
  color: #059669;
}

.step-item.completed .step-description {
  color: #047857;
}

.step-item.active .step-title {
  color: #667eea;
}

.step-item.active .step-description {
  color: #5a67d8;
}

.step-item.pending .step-title {
  color: #9ca3af;
}

.step-item.pending .step-description {
  color: #d1d5db;
}

.processing-tips {
  margin-top: 1rem;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .progress-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.5rem;
  }
  
  .step-item {
    gap: 0.75rem;
  }
  
  .step-content {
    font-size: 0.9rem;
  }
}
</style>
