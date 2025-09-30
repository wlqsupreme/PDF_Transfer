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
echo "  - API网关: http://localhost:5001"
echo "  - 健康检查: curl http://localhost:5001/"
echo "  - 转换接口: http://localhost:5001/convert"
echo ""
echo "📊 查看日志:"
echo "  - API网关: tail -f logs/api_gateway.log"
echo "  - Marker服务: tail -f logs/marker_service.log"
echo "  - Paddle服务: tail -f logs/paddle_service.log"
