from flask import Flask, request, jsonify
import os
import tempfile
import fitz  # PyMuPDF
import cv2
import numpy as np
from PIL import Image
import logging
import re

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# 全局加载模型，避免每次请求都重新加载，提升性能
try:
    from paddleocr import PaddleOCR, PPStructure
    ocr_engine = PaddleOCR(use_angle_cls=True, lang="ch", use_gpu=True)
    structure_engine = PPStructure(show_log=False, use_gpu=True)
    logger.info("PaddleOCR和PPStructure模型加载成功")
except ImportError as e:
    logger.warning(f"PaddleOCR导入失败: {e}")
    ocr_engine = None
    structure_engine = None

def pdf_to_images(pdf_path):
    """将PDF转换为图像列表"""
    images = []
    try:
        doc = fitz.open(pdf_path)
        for page_num in range(len(doc)):
            page = doc.load_page(page_num)
            # 设置较高的分辨率以获得更好的OCR效果
            mat = fitz.Matrix(2.0, 2.0)  # 2倍缩放
            pix = page.get_pixmap(matrix=mat)
            img_data = pix.tobytes("png")
            
            # 转换为OpenCV格式
            nparr = np.frombuffer(img_data, np.uint8)
            img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            images.append(img)
            logger.info(f"转换第 {page_num + 1} 页为图像")
        
        doc.close()
    except Exception as e:
        logger.error(f"PDF转图像失败: {e}")
    
    return images

def extract_text_with_ocr(image):
    """使用PaddleOCR提取文本"""
    if ocr_engine is None:
        return "OCR引擎未加载"
    
    try:
        result = ocr_engine.ocr(image, cls=True)
        text_lines = []
        
        if result and result[0]:
            for line in result[0]:
                if line and len(line) >= 2:
                    text = line[1][0]  # 提取文本内容
                    confidence = line[1][1]  # 提取置信度
                    if confidence > 0.5:  # 只保留置信度较高的文本
                        text_lines.append(text)
        
        return "\n".join(text_lines)
    except Exception as e:
        logger.error(f"OCR文本提取失败: {e}")
        return ""

def extract_tables_with_structure(image):
    """使用PPStructure提取表格"""
    if structure_engine is None:
        return []
    
    try:
        result = structure_engine(image)
        tables = []
        
        for item in result:
            if item['type'] == 'table':
                # 提取表格内容
                table_content = item.get('res', {})
                if table_content:
                    # 这里需要根据PPStructure的实际输出格式来解析表格
                    # 暂时返回原始内容
                    tables.append(f"表格内容: {str(table_content)}")
        
        return tables
    except Exception as e:
        logger.error(f"表格结构提取失败: {e}")
        return []

def process_image_with_ocr(image, page_num):
    """处理单张图像，提取文本和表格"""
    logger.info(f"开始处理第 {page_num + 1} 页图像")
    
    # 提取文本
    text_content = extract_text_with_ocr(image)
    
    # 提取表格
    tables = extract_tables_with_structure(image)
    
    # 组合内容
    page_content = f"## 第 {page_num + 1} 页\n\n"
    
    if text_content.strip():
        page_content += f"### 文本内容\n\n{text_content.strip()}\n\n"
    
    if tables:
        page_content += "### 表格内容\n\n"
        for i, table in enumerate(tables):
            page_content += f"**表格 {i+1}:**\n{table}\n\n"
    
    return page_content

def run_ocr_on_pdf(pdf_path):
    """主要的OCR处理函数"""
    logger.info(f"开始OCR处理PDF文件: {pdf_path}")
    
    # 将PDF转换为图像
    images = pdf_to_images(pdf_path)
    
    if not images:
        return f"# {os.path.basename(pdf_path)}\n\n无法将PDF转换为图像，请检查文件格式。\n"
    
    # 处理每张图像
    all_content = []
    for i, image in enumerate(images):
        page_content = process_image_with_ocr(image, i)
        all_content.append(page_content)
    
    # 组合所有内容
    filename = os.path.basename(pdf_path)
    markdown_content = f"# {filename}\n\n"
    markdown_content += "## OCR识别结果\n\n"
    markdown_content += "\n".join(all_content)
    
    if not any(content.strip() for content in all_content):
        markdown_content += "未能识别到有效内容，请检查PDF文件质量。\n"
    
    logger.info(f"OCR处理完成: {filename}")
    return markdown_content

@app.route('/', methods=['GET'])
def health_check():
    return jsonify({'status': 'Paddle服务运行正常', 'message': '请使用 /convert 端点上传PDF文件'})

@app.route('/convert', methods=['POST'])
def handle_conversion():
    # ... 此处逻辑与 marker_service/app.py 类似 ...
    if 'file' not in request.files:
        return jsonify({'error': '没有上传文件'}), 400

    file = request.files['file']

    with tempfile.NamedTemporaryFile(delete=False, suffix=".pdf") as tmp:
        file.save(tmp.name)
        tmp_pdf_path = tmp.name

    try:
        md_content = run_ocr_on_pdf(tmp_pdf_path)
        return jsonify({'success': True, 'content': md_content})
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        if os.path.exists(tmp_pdf_path):
            os.remove(tmp_pdf_path)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5003)
