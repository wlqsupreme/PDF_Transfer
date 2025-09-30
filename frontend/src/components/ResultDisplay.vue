<template>
  <div class="result-container">
    <!-- 结果头部 -->
    <div class="result-header">
      <div class="result-title">
        <el-icon color="#67c23a"><SuccessFilled /></el-icon>
        转换完成
      </div>
      <div class="result-meta">
        <span class="processing-method">{{ result.processing_method }}</span>
        <span class="file-size">{{ formatFileSize(result.content.length) }}</span>
      </div>
    </div>

    <!-- 处理信息 -->
    <div class="processing-info">
      <el-row :gutter="16">
        <el-col :span="8">
          <div class="info-item">
            <div class="info-label">处理方式</div>
            <div class="info-value">
              <el-tag :type="getMethodTagType(result.processing_method)">
                {{ result.processing_method }}
              </el-tag>
            </div>
          </div>
        </el-col>
        <el-col :span="8">
          <div class="info-item">
            <div class="info-label">文件大小</div>
            <div class="info-value">{{ formatFileSize(result.content.length) }}</div>
          </div>
        </el-col>
        <el-col :span="8">
          <div class="info-item">
            <div class="info-label">处理时间</div>
            <div class="info-value">{{ formatProcessingTime() }}</div>
          </div>
        </el-col>
      </el-row>
    </div>

    <!-- 内容预览 -->
    <div class="content-preview">
      <div class="preview-header">
        <h3>转换结果预览</h3>
        <div class="preview-actions">
          <el-button size="small" @click="togglePreview">
            <el-icon><View /></el-icon>
            {{ showPreview ? '隐藏预览' : '显示预览' }}
          </el-button>
          <el-button size="small" @click="copyToClipboard">
            <el-icon><CopyDocument /></el-icon>
            复制内容
          </el-button>
        </div>
      </div>

      <div v-if="showPreview" class="preview-content">
        <div class="content-tabs">
          <el-tabs v-model="activeTab" type="card">
            <el-tab-pane label="Markdown源码" name="source">
              <div class="markdown-source">
                <pre><code>{{ result.content }}</code></pre>
              </div>
            </el-tab-pane>
            <el-tab-pane label="渲染预览" name="rendered">
              <div class="markdown-rendered" v-html="renderedMarkdown"></div>
            </el-tab-pane>
          </el-tabs>
        </div>
      </div>
    </div>

    <!-- 操作按钮 -->
    <div class="action-buttons">
      <el-button type="primary" size="large" @click="handleDownload">
        <el-icon><Download /></el-icon>
        下载Markdown文件
      </el-button>
      <el-button size="large" @click="handleCopy">
        <el-icon><CopyDocument /></el-icon>
        复制到剪贴板
      </el-button>
      <el-button size="large" @click="handleReset">
        <el-icon><RefreshLeft /></el-icon>
        重新转换
      </el-button>
    </div>

    <!-- 统计信息 -->
    <div class="statistics">
      <el-row :gutter="16">
        <el-col :span="6">
          <div class="stat-item">
            <div class="stat-number">{{ getWordCount() }}</div>
            <div class="stat-label">字符数</div>
          </div>
        </el-col>
        <el-col :span="6">
          <div class="stat-item">
            <div class="stat-number">{{ getLineCount() }}</div>
            <div class="stat-label">行数</div>
          </div>
        </el-col>
        <el-col :span="6">
          <div class="stat-item">
            <div class="stat-number">{{ getTableCount() }}</div>
            <div class="stat-label">表格数</div>
          </div>
        </el-col>
        <el-col :span="6">
          <div class="stat-item">
            <div class="stat-number">{{ getImageCount() }}</div>
            <div class="stat-label">图片数</div>
          </div>
        </el-col>
      </el-row>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { ElMessage } from 'element-plus'
import { 
  SuccessFilled, 
  View, 
  CopyDocument, 
  Download, 
  RefreshLeft 
} from '@element-plus/icons-vue'

// Props
const props = defineProps({
  result: {
    type: Object,
    required: true
  },
  filename: {
    type: String,
    default: ''
  }
})

// Emits
const emit = defineEmits(['download', 'reset'])

// 响应式数据
const showPreview = ref(true)
const activeTab = ref('source')
const processingStartTime = ref(Date.now())

// 计算属性
const renderedMarkdown = computed(() => {
  // 简单的Markdown渲染，实际项目中可以使用marked.js等库
  return props.result.content
    .replace(/^# (.*$)/gim, '<h1>$1</h1>')
    .replace(/^## (.*$)/gim, '<h2>$1</h2>')
    .replace(/^### (.*$)/gim, '<h3>$1</h3>')
    .replace(/\*\*(.*)\*\*/gim, '<strong>$1</strong>')
    .replace(/\*(.*)\*/gim, '<em>$1</em>')
    .replace(/\n/gim, '<br>')
})

// 方法
const formatFileSize = (bytes) => {
  if (bytes === 0) return '0 Bytes'
  const k = 1024
  const sizes = ['Bytes', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

const formatProcessingTime = () => {
  const duration = Date.now() - processingStartTime.value
  const seconds = Math.floor(duration / 1000)
  if (seconds < 60) {
    return `${seconds}秒`
  } else {
    const minutes = Math.floor(seconds / 60)
    const remainingSeconds = seconds % 60
    return `${minutes}分${remainingSeconds}秒`
  }
}

const getMethodTagType = (method) => {
  return method === '文本提取' ? 'success' : 'warning'
}

const togglePreview = () => {
  showPreview.value = !showPreview.value
}

const copyToClipboard = async () => {
  try {
    await navigator.clipboard.writeText(props.result.content)
    ElMessage.success('内容已复制到剪贴板')
  } catch (error) {
    ElMessage.error('复制失败，请手动复制')
  }
}

const handleDownload = () => {
  emit('download')
}

const handleCopy = () => {
  copyToClipboard()
}

const handleReset = () => {
  emit('reset')
}

// 统计方法
const getWordCount = () => {
  return props.result.content.length
}

const getLineCount = () => {
  return props.result.content.split('\n').length
}

const getTableCount = () => {
  return (props.result.content.match(/\|/g) || []).length / 3 || 0
}

const getImageCount = () => {
  return (props.result.content.match(/!\[.*?\]\(.*?\)/g) || []).length
}
</script>

<style scoped>
.result-container {
  margin-top: 2rem;
  padding: 1.5rem;
  background: #f8fafc;
  border-radius: 12px;
  border: 1px solid #e2e8f0;
}

.result-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid #e2e8f0;
}

.result-title {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: #1f2937;
  font-size: 1.3rem;
  font-weight: 600;
}

.result-meta {
  display: flex;
  gap: 1rem;
  align-items: center;
}

.processing-method {
  color: #667eea;
  font-weight: 600;
}

.file-size {
  color: #6b7280;
  font-size: 0.9rem;
}

.processing-info {
  margin-bottom: 1.5rem;
  padding: 1rem;
  background: white;
  border-radius: 8px;
  border: 1px solid #e5e7eb;
}

.info-item {
  text-align: center;
}

.info-label {
  color: #6b7280;
  font-size: 0.9rem;
  margin-bottom: 0.5rem;
}

.info-value {
  color: #1f2937;
  font-weight: 600;
}

.content-preview {
  margin-bottom: 1.5rem;
}

.preview-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.preview-header h3 {
  color: #1f2937;
  font-size: 1.1rem;
  margin: 0;
}

.preview-actions {
  display: flex;
  gap: 0.5rem;
}

.preview-content {
  background: white;
  border-radius: 8px;
  border: 1px solid #e5e7eb;
  overflow: hidden;
}

.markdown-source {
  max-height: 400px;
  overflow-y: auto;
  padding: 1rem;
  background: #f8f9fa;
}

.markdown-source pre {
  margin: 0;
  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
  font-size: 0.9rem;
  line-height: 1.5;
  color: #2d3748;
  white-space: pre-wrap;
  word-break: break-word;
}

.markdown-rendered {
  max-height: 400px;
  overflow-y: auto;
  padding: 1rem;
  line-height: 1.6;
  color: #2d3748;
}

.action-buttons {
  display: flex;
  gap: 1rem;
  justify-content: center;
  margin-bottom: 1.5rem;
}

.statistics {
  padding: 1rem;
  background: white;
  border-radius: 8px;
  border: 1px solid #e5e7eb;
}

.stat-item {
  text-align: center;
}

.stat-number {
  font-size: 1.5rem;
  font-weight: 700;
  color: #667eea;
  margin-bottom: 0.25rem;
}

.stat-label {
  color: #6b7280;
  font-size: 0.9rem;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .result-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.5rem;
  }
  
  .result-meta {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.25rem;
  }
  
  .preview-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 1rem;
  }
  
  .action-buttons {
    flex-direction: column;
    align-items: center;
  }
  
  .statistics .el-col {
    margin-bottom: 1rem;
  }
}
</style>
