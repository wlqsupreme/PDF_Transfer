import axios from 'axios'

// 创建axios实例
const api = axios.create({
  baseURL: 'http://localhost:5001', // 通过SSH隧道连接后端
  timeout: 300000, // 5分钟超时
  headers: {
    'Content-Type': 'multipart/form-data'
  }
})

// 请求拦截器
api.interceptors.request.use(
  (config) => {
    console.log('发送请求:', config.url)
    return config
  },
  (error) => {
    console.error('请求错误:', error)
    return Promise.reject(error)
  }
)

// 响应拦截器
api.interceptors.response.use(
  (response) => {
    console.log('收到响应:', response.status)
    return response
  },
  (error) => {
    console.error('响应错误:', error)
    
    // 处理不同类型的错误
    if (error.response) {
      // 服务器响应了错误状态码
      const { status, data } = error.response
      
      switch (status) {
        case 400:
          throw new Error(data.error || '请求参数错误')
        case 413:
          throw new Error('文件过大，请选择小于50MB的文件')
        case 500:
          throw new Error('服务器内部错误，请稍后重试')
        case 503:
          throw new Error('服务暂时不可用，请稍后重试')
        default:
          throw new Error(data.error || `请求失败 (${status})`)
      }
    } else if (error.request) {
      // 请求已发出但没有收到响应
      throw new Error('网络连接失败，请检查网络设置')
    } else {
      // 其他错误
      throw new Error(error.message || '未知错误')
    }
  }
)

/**
 * 转换PDF文件
 * @param {File} file - PDF文件
 * @param {Function} onProgress - 进度回调函数
 * @returns {Promise<Object>} 转换结果
 */
export const convertPDF = async (file, onProgress) => {
  try {
    // 创建FormData
    const formData = new FormData()
    formData.append('file', file)

    // 发送请求
    const response = await api.post('/convert', formData, {
      onUploadProgress: (progressEvent) => {
        if (onProgress) {
          const progress = Math.round(
            (progressEvent.loaded * 100) / progressEvent.total
          )
          onProgress(progress)
        }
      }
    })

    // 检查响应
    if (response.data.success) {
      return {
        success: true,
        content: response.data.content,
        processing_method: response.data.processing_method,
        filename: response.data.filename,
        note: response.data.note
      }
    } else {
      throw new Error(response.data.error || '转换失败')
    }
  } catch (error) {
    console.error('PDF转换错误:', error)
    throw error
  }
}

/**
 * 检查API健康状态
 * @returns {Promise<Object>} 健康状态
 */
export const checkHealth = async () => {
  try {
    const baseURL = import.meta.env.VITE_API_BASE_URL || ''
    const response = await axios.get(`${baseURL}/`)
    return {
      success: true,
      status: response.data.status,
      message: response.data.message
    }
  } catch (error) {
    console.error('健康检查失败:', error)
    return {
      success: false,
      error: error.message
    }
  }
}

/**
 * 获取支持的文件类型
 * @returns {Array} 支持的文件类型列表
 */
export const getSupportedFileTypes = () => {
  return [
    {
      type: 'application/pdf',
      extension: '.pdf',
      description: 'PDF文档',
      maxSize: 50 * 1024 * 1024 // 50MB
    }
  ]
}

/**
 * 验证文件
 * @param {File} file - 要验证的文件
 * @returns {Object} 验证结果
 */
export const validateFile = (file) => {
  const supportedTypes = getSupportedFileTypes()
  const fileType = supportedTypes.find(type => 
    file.type === type.type || file.name.toLowerCase().endsWith(type.extension)
  )

  if (!fileType) {
    return {
      valid: false,
      error: '不支持的文件类型，请选择PDF文件'
    }
  }

  if (file.size > fileType.maxSize) {
    return {
      valid: false,
      error: `文件过大，请选择小于${formatFileSize(fileType.maxSize)}的文件`
    }
  }

  return {
    valid: true,
    fileType: fileType
  }
}

/**
 * 格式化文件大小
 * @param {number} bytes - 字节数
 * @returns {string} 格式化后的文件大小
 */
export const formatFileSize = (bytes) => {
  if (bytes === 0) return '0 Bytes'
  const k = 1024
  const sizes = ['Bytes', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

/**
 * 获取处理时间估算
 * @param {File} file - PDF文件
 * @returns {number} 估算的处理时间（秒）
 */
export const estimateProcessingTime = (file) => {
  const sizeInMB = file.size / (1024 * 1024)
  
  // 基于文件大小的简单估算
  if (sizeInMB < 1) {
    return 10 // 小文件，10秒
  } else if (sizeInMB < 5) {
    return 30 // 中等文件，30秒
  } else if (sizeInMB < 20) {
    return 60 // 大文件，1分钟
  } else {
    return 120 // 超大文件，2分钟
  }
}

/**
 * 检测PDF类型
 * @param {File} file - PDF文件
 * @returns {Promise<string>} PDF类型 ('text' | 'image' | 'unknown')
 */
export const detectPDFType = async (file) => {
  try {
    // 这里可以实现PDF类型检测逻辑
    // 暂时基于文件大小进行简单判断
    const sizeInMB = file.size / (1024 * 1024)
    
    if (sizeInMB < 1) {
      return 'text' // 小文件通常是文本PDF
    } else {
      return 'image' // 大文件可能是扫描件
    }
  } catch (error) {
    console.error('PDF类型检测失败:', error)
    return 'unknown'
  }
}

export default {
  convertPDF,
  checkHealth,
  getSupportedFileTypes,
  validateFile,
  formatFileSize,
  estimateProcessingTime,
  detectPDFType
}
