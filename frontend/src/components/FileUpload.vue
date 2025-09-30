<template>
  <div class="file-upload-container">
    <!-- 上传区域 -->
    <div 
      class="upload-area"
      :class="{ 'dragover': isDragOver }"
      @click="triggerFileInput"
      @dragover.prevent="handleDragOver"
      @dragleave.prevent="handleDragLeave"
      @drop.prevent="handleDrop"
    >
      <div v-if="!selectedFile" class="upload-content">
        <div class="upload-icon">
          <el-icon size="64"><Upload /></el-icon>
        </div>
        <div class="upload-text">点击或拖拽PDF文件到此处</div>
        <div class="upload-hint">支持普通PDF和扫描件PDF，最大50MB</div>
      </div>
      
      <div v-else class="file-info">
        <div class="file-icon">
          <el-icon size="48" color="#667eea"><Document /></el-icon>
        </div>
        <div class="file-details">
          <div class="file-name">{{ selectedFile.name }}</div>
          <div class="file-size">{{ formatFileSize(selectedFile.size) }}</div>
          <div class="file-type">{{ getFileType() }}</div>
        </div>
        <div class="file-actions">
          <el-button type="primary" @click.stop="startUpload" :loading="isUploading">
            <el-icon><Upload /></el-icon>
            开始转换
          </el-button>
          <el-button @click.stop="removeFile">
            <el-icon><Delete /></el-icon>
            移除
          </el-button>
        </div>
      </div>
    </div>

    <!-- 隐藏的文件输入 -->
    <input
      ref="fileInput"
      type="file"
      accept=".pdf"
      @change="handleFileSelect"
      style="display: none"
    />

    <!-- 文件类型提示 -->
    <div v-if="selectedFile" class="file-type-info">
      <el-alert
        :title="getFileTypeDescription()"
        :type="getFileTypeAlertType()"
        :closable="false"
        show-icon
      />
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { ElMessage } from 'element-plus'
import { Upload, Document, Delete } from '@element-plus/icons-vue'

// Props
const props = defineProps({
  disabled: {
    type: Boolean,
    default: false
  }
})

// Emits
const emit = defineEmits(['file-selected', 'upload-start', 'upload-progress', 'upload-complete', 'upload-error'])

// 响应式数据
const fileInput = ref(null)
const selectedFile = ref(null)
const isDragOver = ref(false)
const isUploading = ref(false)

// 触发文件选择
const triggerFileInput = () => {
  if (props.disabled) return
  fileInput.value?.click()
}

// 处理文件选择
const handleFileSelect = (event) => {
  const file = event.target.files[0]
  if (file) {
    validateAndSelectFile(file)
  }
}

// 处理拖拽悬停
const handleDragOver = (event) => {
  if (props.disabled) return
  isDragOver.value = true
}

// 处理拖拽离开
const handleDragLeave = (event) => {
  isDragOver.value = false
}

// 处理文件拖拽
const handleDrop = (event) => {
  if (props.disabled) return
  isDragOver.value = false
  
  const files = event.dataTransfer.files
  if (files.length > 0) {
    validateAndSelectFile(files[0])
  }
}

// 验证并选择文件
const validateAndSelectFile = (file) => {
  // 检查文件类型
  if (!file.type.includes('pdf')) {
    ElMessage.error('请选择PDF文件')
    return
  }

  // 检查文件大小 (50MB)
  const maxSize = 50 * 1024 * 1024
  if (file.size > maxSize) {
    ElMessage.error('文件大小不能超过50MB')
    return
  }

  selectedFile.value = file
  emit('file-selected', file)
}

// 移除文件
const removeFile = () => {
  selectedFile.value = null
  if (fileInput.value) {
    fileInput.value.value = ''
  }
}

// 开始上传
const startUpload = async () => {
  if (!selectedFile.value) return

  try {
    isUploading.value = true
    emit('upload-start')
    
    // 模拟上传进度
    for (let progress = 0; progress <= 100; progress += 10) {
      emit('upload-progress', progress)
      await new Promise(resolve => setTimeout(resolve, 100))
    }
    
    emit('upload-complete', selectedFile.value)
    
  } catch (error) {
    emit('upload-error', error)
  } finally {
    isUploading.value = false
  }
}

// 格式化文件大小
const formatFileSize = (bytes) => {
  if (bytes === 0) return '0 Bytes'
  const k = 1024
  const sizes = ['Bytes', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

// 获取文件类型
const getFileType = () => {
  if (!selectedFile.value) return ''
  
  // 这里可以根据文件内容判断，暂时返回通用类型
  return 'PDF文档'
}

// 获取文件类型描述
const getFileTypeDescription = () => {
  if (!selectedFile.value) return ''
  
  const size = selectedFile.value.size
  if (size < 1024 * 1024) { // 小于1MB，可能是普通PDF
    return '检测到小文件，可能是普通PDF，将使用文本提取方式处理'
  } else { // 大于1MB，可能是扫描件
    return '检测到大文件，可能是扫描件PDF，将使用OCR识别方式处理'
  }
}

// 获取文件类型警告类型
const getFileTypeAlertType = () => {
  if (!selectedFile.value) return 'info'
  
  const size = selectedFile.value.size
  if (size < 1024 * 1024) {
    return 'success'
  } else {
    return 'warning'
  }
}
</script>

<style scoped>
.file-upload-container {
  margin-bottom: 2rem;
}

.upload-area {
  border: 2px dashed #d1d5db;
  border-radius: 12px;
  padding: 2rem;
  text-align: center;
  transition: all 0.3s ease;
  cursor: pointer;
  background: #fafafa;
  min-height: 200px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.upload-area:hover {
  border-color: #667eea;
  background: #f0f4ff;
  transform: translateY(-2px);
}

.upload-area.dragover {
  border-color: #667eea;
  background: #e6f0ff;
  transform: scale(1.02);
}

.upload-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
}

.upload-icon {
  color: #9ca3af;
}

.upload-text {
  color: #6b7280;
  font-size: 1.1rem;
  font-weight: 500;
}

.upload-hint {
  color: #9ca3af;
  font-size: 0.9rem;
}

.file-info {
  display: flex;
  align-items: center;
  gap: 1rem;
  width: 100%;
  padding: 1rem;
  background: white;
  border-radius: 8px;
  border: 1px solid #e5e7eb;
}

.file-icon {
  flex-shrink: 0;
}

.file-details {
  flex: 1;
  text-align: left;
}

.file-name {
  font-weight: 600;
  color: #1f2937;
  margin-bottom: 0.25rem;
  word-break: break-all;
}

.file-size {
  color: #6b7280;
  font-size: 0.9rem;
  margin-bottom: 0.25rem;
}

.file-type {
  color: #9ca3af;
  font-size: 0.8rem;
}

.file-actions {
  display: flex;
  gap: 0.5rem;
  flex-shrink: 0;
}

.file-type-info {
  margin-top: 1rem;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .file-info {
    flex-direction: column;
    text-align: center;
  }
  
  .file-details {
    text-align: center;
  }
  
  .file-actions {
    justify-content: center;
  }
}
</style>
