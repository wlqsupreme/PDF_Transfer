#!/bin/bash

# PDF转换器后端部署脚本（适配AutoDL容器）
# 使用方法: ./deploy.sh
# 功能: 安装依赖并启动后端微服务，支持前端连接

echo "=========================================="
echo "PDF转换器后端微服务部署脚本（AutoDL版）"
echo "=========================================="

# 获取服务器IP地址
SERVER_IP=$(hostname -I | awk '{print $1}')
if [ -z "$SERVER_IP" ]; then
    SERVER_IP="localhost"
fi

echo "🖥️  服务器IP: $SERVER_IP"

# 检查Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 未安装，请先安装 Python3"
    exit 1
fi

# 检查pip
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 未安装，请先安装 pip"
    exit 1
fi

# 检查GPU
if command -v nvidia-smi &> /dev/null; then
    echo "✅ 检测到 NVIDIA GPU"
    nvidia-smi
else
    echo "⚠️ 未检测到 GPU，将使用 CPU 模式"
fi

# 创建统一的requirements.txt
echo "📦 创建统一依赖文件..."
cat > requirements.txt << 'EOF'
Flask==2.3.3
Flask-CORS==4.0.0
requests==2.31.0
werkzeug==2.3.7
PyMuPDF>=1.24.0
gunicorn
pandas>=1.5.0
tabulate>=0.9.0
opencv-python==4.9.0.80
Pillow>=10.2.0
numpy>=1.21.0
EOF

# 安装基础依赖
echo "📦 安装基础依赖..."
pip3 install -r requirements.txt --no-cache-dir

# 安装深度学习框架（根据GPU情况选择）
echo "🧠 安装深度学习框架..."
if command -v nvidia-smi &> /dev/null; then
    echo "检查PyTorch是否已安装..."
    if ! python3 -c "import torch" 2>/dev/null; then
        echo "安装PyTorch GPU版本..."
        pip3 install torch torchvision torchaudio --no-cache-dir
    else
        echo "✅ PyTorch已安装"
    fi
    
    echo "检查PaddlePaddle是否已安装..."
    if ! python3 -c "import paddle" 2>/dev/null; then
        echo "安装PaddlePaddle GPU版本..."
        pip3 install paddlepaddle-gpu --no-cache-dir
    else
        echo "✅ PaddlePaddle已安装"
    fi
else
    echo "检查PyTorch是否已安装..."
    if ! python3 -c "import torch" 2>/dev/null; then
        echo "安装PyTorch CPU版本..."
        pip3 install torch torchvision torchaudio --no-cache-dir
    else
        echo "✅ PyTorch已安装"
    fi
    
    echo "检查PaddlePaddle是否已安装..."
    if ! python3 -c "import paddle" 2>/dev/null; then
        echo "安装PaddlePaddle CPU版本..."
        pip3 install paddlepaddle --no-cache-dir
    else
        echo "✅ PaddlePaddle已安装"
    fi
fi

# 安装其他依赖
echo "📦 安装其他依赖..."
pip3 install paddleocr --no-cache-dir || echo "⚠️ PaddleOCR安装失败，将跳过"
pip3 install camelot-py[cv] --no-cache-dir || echo "⚠️ Camelot安装失败，将跳过"
pip3 install pdfplumber --no-cache-dir || echo "⚠️ pdfplumber安装失败，将跳过"

# 停止已有进程
echo "🛑 停止旧服务..."
pkill -f "python.*app.py" 2>/dev/null || true
pkill -f "gunicorn" 2>/dev/null || true

# 创建日志目录
mkdir -p logs

# 检查并创建管理脚本
echo "📝 检查管理脚本..."

# 如果脚本不存在，则创建
if [ ! -f start.sh ]; then
    echo "创建启动脚本..."
    cat > start.sh << 'EOF'
#!/bin/bash
echo "🚀 启动PDF转换器后端服务..."

# 创建日志目录
mkdir -p logs

# 停止旧进程
pkill -f "python.*app.py" 2>/dev/null || true

# 启动API网关
echo "启动API网关 (端口5000)..."
cd api_gateway
nohup python3 app.py > ../logs/api_gateway.log 2>&1 &
echo "API网关 PID: $!"
cd ..

# 启动Marker服务
echo "启动Marker服务 (端口5001)..."
cd marker_service
nohup python3 app.py > ../logs/marker_service.log 2>&1 &
echo "Marker服务 PID: $!"
cd ..

# 启动Paddle服务
echo "启动Paddle服务 (端口5002)..."
cd paddle_service
nohup python3 app.py > ../logs/paddle_service.log 2>&1 &
echo "Paddle服务 PID: $!"
cd ..

echo "✅ 所有服务已启动"
echo "📡 服务地址:"
echo "  - API网关: http://localhost:5000"
echo "  - 健康检查: curl http://localhost:5000/"
echo "  - 转换接口: http://localhost:5000/convert"
echo ""
echo "📊 查看日志:"
echo "  - API网关: tail -f logs/api_gateway.log"
echo "  - Marker服务: tail -f logs/marker_service.log"
echo "  - Paddle服务: tail -f logs/paddle_service.log"
EOF
fi

if [ ! -f stop.sh ]; then
    echo "创建停止脚本..."
    cat > stop.sh << 'EOF'
#!/bin/bash
echo "🛑 停止PDF转换器后端服务..."

# 停止所有Python应用进程
pkill -f "python.*app.py" 2>/dev/null || true
pkill -f "gunicorn" 2>/dev/null || true

echo "✅ 所有服务已停止"
echo "📊 检查进程: ps aux | grep python"
EOF
fi

if [ ! -f status.sh ]; then
    echo "创建状态检查脚本..."
    cat > status.sh << 'EOF'
#!/bin/bash
echo "📊 PDF转换器服务状态检查"
echo "=========================="

# 检查进程
echo "🔍 运行中的Python进程:"
ps aux | grep python | grep -v grep || echo "  无Python进程运行"

echo ""
echo "🌐 服务连接测试:"

# 测试API网关
if curl -f http://localhost:5000/ &> /dev/null; then
    echo "✅ API网关 (端口5000): 正常"
else
    echo "❌ API网关 (端口5000): 无响应"
fi

# 测试Marker服务
if curl -f http://localhost:5001/ &> /dev/null; then
    echo "✅ Marker服务 (端口5001): 正常"
else
    echo "❌ Marker服务 (端口5001): 无响应"
fi

# 测试Paddle服务
if curl -f http://localhost:5002/ &> /dev/null; then
    echo "✅ Paddle服务 (端口5002): 正常"
else
    echo "❌ Paddle服务 (端口5002): 无响应"
fi

echo ""
echo "📋 最新日志 (最后5行):"
if [ -f logs/api_gateway.log ]; then
    echo "--- API网关日志 ---"
    tail -5 logs/api_gateway.log
fi

if [ -f logs/marker_service.log ]; then
    echo "--- Marker服务日志 ---"
    tail -5 logs/marker_service.log
fi

if [ -f logs/paddle_service.log ]; then
    echo "--- Paddle服务日志 ---"
    tail -5 logs/paddle_service.log
fi
EOF
fi

# 给脚本执行权限
chmod +x start.sh stop.sh status.sh

# 启动服务
echo "🚀 启动后端微服务..."
./start.sh

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 15

# 健康检查
echo "📊 检查服务状态..."
if curl -f http://localhost:5000/ &> /dev/null; then
    echo "✅ API网关已启动"
    
    # 测试CORS配置
    echo "🧪 测试CORS配置..."
    if python3 test_cors.py 2>/dev/null; then
        echo "✅ CORS配置正常"
    else
        echo "⚠️ CORS配置可能有问题，请检查"
    fi
else
    echo "⚠️ API网关未响应，请检查日志:"
    echo "API网关日志: tail -f logs/api_gateway.log"
    echo "Marker服务日志: tail -f logs/marker_service.log"
    echo "Paddle服务日志: tail -f logs/paddle_service.log"
    exit 1
fi

# 显示服务信息
echo ""
echo "=========================================="
echo "🎉 后端微服务部署完成！"
echo ""
echo "📡 服务地址:"
echo "  - API网关: http://$SERVER_IP:5000/"
echo "  - 健康检查: http://$SERVER_IP:5000/"
echo "  - 转换接口: http://$SERVER_IP:5000/convert"
echo ""
echo "🔧 管理命令:"
echo "  - 启动服务: ./start.sh"
echo "  - 停止服务: ./stop.sh"
echo "  - 检查状态: ./status.sh"
echo "  - 查看日志: tail -f logs/*.log"
echo "  - 查看进程: ps aux | grep python"
echo ""
echo "🚀 下一步:"
echo "  1. 在前端项目里设置 API 地址为: http://connect.westc.gpuhub.com:41973"
echo "  2. 上传 PDF 测试转换功能"
echo ""
echo "💡 提示:"
echo "  - 如果外部访问不了，请检查 AutoDL 安全组/端口映射是否开放 5000 端口"
echo "  - 建议使用 screen 或 tmux 保持服务运行"
echo "  - 查看详细日志排查问题"
echo "=========================================="
