#!/bin/bash
echo "🔧 完整修复PDF转换器系统"
echo "=========================="

# 1. 停止所有服务
echo "1. 停止所有服务..."
pkill -f "python.*app.py" 2>/dev/null || true
sleep 3

# 2. 检查并安装依赖
echo "2. 检查依赖..."
pip3 install Flask Flask-CORS requests PyMuPDF --no-cache-dir

# 3. 重新启动服务
echo "3. 启动服务..."
./start.sh

# 4. 等待服务启动
echo "4. 等待服务启动..."
sleep 15

# 5. 测试后端
echo "5. 测试后端服务..."
python3 test_backend.py

# 6. 显示状态
echo "6. 显示服务状态..."
./status.sh

echo ""
echo "✅ 修复完成！"
echo ""
echo "📋 下一步操作："
echo "1. 在本地前端目录运行: npm run dev"
echo "2. 访问: http://localhost:3000"
echo "3. 上传PDF测试转换功能"
echo ""
echo "💡 如果还有问题，请检查："
echo "- AutoDL端口映射是否正确"
echo "- 防火墙是否阻止了连接"
echo "- 后端日志是否有错误信息"
