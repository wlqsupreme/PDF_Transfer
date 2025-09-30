from flask import Flask, request, jsonify
from flask_cors import CORS, cross_origin
import requests
import io
import fitz # PyMuPDF
import logging

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# 配置CORS，允许所有来源的跨域请求
CORS(app, 
     origins=['http://localhost:3000', '*'], 
     methods=['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
     allow_headers=['Content-Type', 'Authorization', 'X-Requested-With'],
     supports_credentials=True)

MARKER_SERVICE_URL = "http://localhost:5002/convert"
PADDLE_SERVICE_URL = "http://localhost:5003/convert"

def has_text_layer(pdf_stream):
    try:
        doc = fitz.open(stream=pdf_stream, filetype="pdf")
        text_content = ""
        for page in doc:
            text_content += page.get_text()
        doc.close()
        return len(text_content.strip()) > 50
    except Exception:
        return False

@app.route('/', methods=['GET'])
def health_check():
    return jsonify({'status': 'API网关运行正常', 'message': '请使用 /api/convert 端点上传PDF文件'})

@app.route('/convert', methods=['POST', 'OPTIONS'])
@app.route('/api/convert', methods=['POST', 'OPTIONS'])
def convert_pdf_route():
    # 处理预检请求
    if request.method == 'OPTIONS':
        return jsonify({'status': 'OK'})
    
    if 'file' not in request.files:
        return jsonify({'error': '没有上传文件'}), 400

    file = request.files['file']
    pdf_bytes = file.read()

    files = {'file': (file.filename, pdf_bytes, 'application/pdf')}

    try:
        # 智能路由：根据PDF是否有文本层选择处理方式
        if has_text_layer(io.BytesIO(pdf_bytes)):
            logger.info(f"检测到文本层，使用marker_service处理: {file.filename}")
            response = requests.post(MARKER_SERVICE_URL, files=files, timeout=600)
        else:
            logger.info(f"未检测到文本层，使用paddle_service进行OCR处理: {file.filename}")
            response = requests.post(PADDLE_SERVICE_URL, files=files, timeout=600)

        response.raise_for_status()
        result = response.json()
        
        # 添加处理方式信息
        if 'content' in result:
            processing_method = "文本提取" if has_text_layer(io.BytesIO(pdf_bytes)) else "OCR识别"
            result['processing_method'] = processing_method
            result['filename'] = file.filename
        
        return jsonify(result)
    except requests.RequestException as e:
        logger.error(f"服务调用失败: {e}")
        return jsonify({'error': f'服务调用失败: {e}'}), 503
    except Exception as e:
        logger.error(f"处理失败: {e}")
        return jsonify({'error': f'处理失败: {e}'}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
