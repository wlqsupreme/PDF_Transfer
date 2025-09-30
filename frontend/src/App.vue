<template>
  <div id="app">
    <div class="main-container">
      <div class="converter-card fade-in">
        <!-- 标题区域 -->
        <div class="title">
          <h1>📄 PDF智能转换器</h1>
          <p>支持普通PDF和扫描件PDF的智能识别转换，提取文本、表格和图像内容</p>
        </div>

        <!-- 文件上传组件 -->
        <FileUpload 
          @file-selected="handleFileSelected"
          @upload-start="handleUploadStart"
          @upload-progress="handleUploadProgress"
          @upload-complete="handleUploadComplete"
          @upload-error="handleUploadError"
        />

        <!-- 进度显示组件 -->
        <ProgressDisplay 
          v-if="isUploading"
          :progress="uploadProgress"
          :status="uploadStatus"
          :filename="selectedFile?.name"
        />

        <!-- 结果展示组件 -->
        <ResultDisplay 
          v-if="conversionResult"
          :result="conversionResult"
          :filename="selectedFile?.name"
          @download="handleDownload"
          @reset="handleReset"
        />

        <!-- 操作按钮 -->
        <div v-if="!isUploading && !conversionResult" class="action-buttons">
          <button class="btn-secondary" @click="showHelp">
            <el-icon><QuestionFilled /></el-icon>
            使用帮助
          </button>
        </div>
      </div>
    </div>

    <!-- 帮助对话框 -->
    <el-dialog v-model="helpVisible" title="使用帮助" width="600px">
      <div class="help-content">
        <h3>📋 支持的文件类型</h3>
        <ul>
          <li><strong>普通PDF</strong>：包含文本层的PDF文件，支持直接文本提取</li>
          <li><strong>扫描件PDF</strong>：纯图像PDF文件，使用OCR技术识别</li>
        </ul>

        <h3>🔧 处理能力</h3>
        <ul>
          <li>中英文文本识别</li>
          <li>表格数据提取</li>
          <li>数学公式识别</li>
          <li>目录结构解析</li>
          <li>角标和编号处理</li>
          <li>零件图和示意图识别</li>
        </ul>

        <h3>⚡ 处理流程</h3>
        <ol>
          <li>上传PDF文件</li>
          <li>系统自动检测文件类型</li>
          <li>选择最适合的处理方式</li>
          <li>生成Markdown格式结果</li>
          <li>支持下载转换结果</li>
        </ol>

        <h3>💡 使用提示</h3>
        <ul>
          <li>文件大小建议不超过50MB</li>
          <li>处理时间取决于文件大小和复杂度</li>
          <li>扫描件PDF需要更长的处理时间</li>
          <li>建议使用清晰、高质量的PDF文件</li>
        </ul>
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { QuestionFilled } from '@element-plus/icons-vue'
import FileUpload from './components/FileUpload.vue'
import ProgressDisplay from './components/ProgressDisplay.vue'
import ResultDisplay from './components/ResultDisplay.vue'
import { convertPDF } from './api/pdfConverter'

// 响应式数据
const selectedFile = ref(null)
const isUploading = ref(false)
const uploadProgress = ref(0)
const uploadStatus = ref('')
const conversionResult = ref(null)
const helpVisible = ref(false)

// 处理文件选择
const handleFileSelected = (file) => {
  selectedFile.value = file
  ElMessage.success(`已选择文件: ${file.name}`)
}

// 处理上传开始
const handleUploadStart = () => {
  isUploading.value = true
  uploadProgress.value = 0
  uploadStatus.value = '正在上传文件...'
  conversionResult.value = null
}

// 处理上传进度
const handleUploadProgress = (progress) => {
  uploadProgress.value = progress
}

// 处理上传完成
const handleUploadComplete = async (file) => {
  try {
    uploadStatus.value = '正在处理文件...'
    uploadProgress.value = 50
    
    const result = await convertPDF(file)
    
    uploadProgress.value = 100
    uploadStatus.value = '处理完成！'
    
    setTimeout(() => {
      conversionResult.value = result
      isUploading.value = false
      ElMessage.success('PDF转换完成！')
    }, 1000)
    
  } catch (error) {
    handleUploadError(error)
  }
}

// 处理上传错误
const handleUploadError = (error) => {
  isUploading.value = false
  uploadProgress.value = 0
  uploadStatus.value = ''
  
  console.error('上传错误:', error)
  ElMessage.error(`转换失败: ${error.message || '未知错误'}`)
}

// 处理下载
const handleDownload = () => {
  if (!conversionResult.value) return
  
  const blob = new Blob([conversionResult.value.content], { type: 'text/markdown' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `${selectedFile.value.name.replace('.pdf', '')}_converted.md`
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  URL.revokeObjectURL(url)
  
  ElMessage.success('文件下载完成！')
}

// 处理重置
const handleReset = () => {
  selectedFile.value = null
  isUploading.value = false
  uploadProgress.value = 0
  uploadStatus.value = ''
  conversionResult.value = null
}

// 显示帮助
const showHelp = () => {
  helpVisible.value = true
}
</script>

<style scoped>
.help-content h3 {
  color: #2c3e50;
  margin: 1.5rem 0 0.5rem 0;
  font-size: 1.1rem;
}

.help-content h3:first-child {
  margin-top: 0;
}

.help-content ul, .help-content ol {
  margin: 0.5rem 0 1rem 1.5rem;
  line-height: 1.6;
}

.help-content li {
  margin: 0.3rem 0;
  color: #4a5568;
}

.help-content strong {
  color: #2d3748;
  font-weight: 600;
}
</style>
