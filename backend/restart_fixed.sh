#!/bin/bash
echo "🔄 重启修复后的服务"
echo "==================="

# 停止所有服务
echo "停止所有服务..."
pkill -f "python.*app.py" 2>/dev/null || true
sleep 3

# 启动服务
echo "启动服务..."
./start.sh

# 等待服务启动
echo "等待服务启动..."
sleep 15

# 检查服务状态
echo "检查服务状态..."
echo "API网关 (5001):"
curl -s http://localhost:5001/ && echo "   ✅ 正常" || echo "   ❌ 无响应"

echo "Marker服务 (5002):"
curl -s http://localhost:5002/ && echo "   ✅ 正常" || echo "   ❌ 无响应"

echo "Paddle服务 (5003):"
curl -s http://localhost:5003/ && echo "   ✅ 正常" || echo "   ❌ 无响应"

echo ""
echo "✅ 服务重启完成！"
echo ""
echo "📋 现在需要做的："
echo "1. 在AutoDL控制台配置端口映射："
echo "   - 容器内端口: 5001"
echo "   - 外网端口: 41973 (或选择其他端口)"
echo "2. 测试外网连接: curl http://connect.westc.gpuhub.com:41973/"
echo "3. 如果外网连接成功，更新前端配置"
