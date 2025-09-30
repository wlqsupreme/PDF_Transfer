from flask import Flask, request, jsonify
import os
import tempfile
import fitz  # PyMuPDF
import camelot
import pdfplumber
import pandas as pd
import re
from pathlib import Path
import logging

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

def extract_tables_with_camelot(pdf_path):
    """使用Camelot提取表格"""
    tables = []
    try:
        # 尝试使用Camelot提取表格
        camelot_tables = camelot.read_pdf(pdf_path, pages='all', flavor='lattice')
        
        for i, table in enumerate(camelot_tables):
            if table.df is not None and not table.df.empty:
                # 转换为Markdown表格格式
                df = table.df
                markdown_table = df.to_markdown(index=False)
                tables.append(f"## 表格 {i+1}\n\n{markdown_table}\n")
                logger.info(f"使用Camelot提取到表格 {i+1}")
    except Exception as e:
        logger.warning(f"Camelot提取表格失败: {e}")
    
    return tables

def extract_tables_with_pdfplumber(pdf_path):
    """使用pdfplumber提取表格作为备选方案"""
    tables = []
    try:
        with pdfplumber.open(pdf_path) as pdf:
            for page_num, page in enumerate(pdf.pages):
                page_tables = page.extract_tables()
                for i, table in enumerate(page_tables):
                    if table and len(table) > 1:  # 确保表格有内容
                        # 转换为DataFrame
                        df = pd.DataFrame(table[1:], columns=table[0])
                        markdown_table = df.to_markdown(index=False)
                        tables.append(f"## 表格 {page_num+1}-{i+1}\n\n{markdown_table}\n")
                        logger.info(f"使用pdfplumber提取到表格 {page_num+1}-{i+1}")
    except Exception as e:
        logger.warning(f"pdfplumber提取表格失败: {e}")
    
    return tables

def extract_text_with_pymupdf(pdf_path):
    """使用PyMuPDF提取文本内容"""
    text_content = []
    try:
        doc = fitz.open(pdf_path)
        
        for page_num in range(len(doc)):
            page = doc.load_page(page_num)
            text = page.get_text()
            
            if text.strip():
                # 清理和格式化文本
                text = re.sub(r'\n\s*\n', '\n\n', text)  # 合并多个空行
                text_content.append(f"## 第 {page_num + 1} 页\n\n{text.strip()}\n")
                logger.info(f"提取第 {page_num + 1} 页文本")
        
        doc.close()
    except Exception as e:
        logger.error(f"PyMuPDF提取文本失败: {e}")
    
    return text_content

def run_marker_and_tables(pdf_path):
    """主要的PDF处理函数"""
    logger.info(f"开始处理PDF文件: {pdf_path}")
    
    # 提取文本内容
    text_content = extract_text_with_pymupdf(pdf_path)
    
    # 提取表格
    tables = []
    tables.extend(extract_tables_with_camelot(pdf_path))
    if not tables:  # 如果Camelot没有提取到表格，尝试pdfplumber
        tables.extend(extract_tables_with_pdfplumber(pdf_path))
    
    # 组合所有内容
    filename = os.path.basename(pdf_path)
    markdown_content = f"# {filename}\n\n"
    
    # 添加文本内容
    if text_content:
        markdown_content += "## 文本内容\n\n"
        markdown_content += "\n".join(text_content)
        markdown_content += "\n\n"
    
    # 添加表格内容
    if tables:
        markdown_content += "## 表格内容\n\n"
        markdown_content += "\n".join(tables)
    
    if not text_content and not tables:
        markdown_content += "未能提取到有效内容，请检查PDF文件。\n"
    
    logger.info(f"PDF处理完成: {filename}")
    return markdown_content

@app.route('/', methods=['GET'])
def health_check():
    return jsonify({'status': 'Marker服务运行正常', 'message': '请使用 /convert 端点上传PDF文件'})

@app.route('/convert', methods=['POST'])
def handle_conversion():
    if 'file' not in request.files:
        return jsonify({'error': '没有上传文件'}), 400

    file = request.files['file']

    # 将上传的文件保存到临时位置
    with tempfile.NamedTemporaryFile(delete=False, suffix=".pdf") as tmp:
        file.save(tmp.name)
        tmp_pdf_path = tmp.name

    try:
        md_content = run_marker_and_tables(tmp_pdf_path)
        return jsonify({'success': True, 'content': md_content})
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        if os.path.exists(tmp_pdf_path):
            os.remove(tmp_pdf_path)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5002)
