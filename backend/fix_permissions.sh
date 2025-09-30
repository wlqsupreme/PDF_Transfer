#!/bin/bash
echo "🔧 修复权限并重启服务"
echo "====================="

# 1. 给所有脚本添加执行权限
echo "1. 添加执行权限..."
chmod +x start.sh stop.sh status.sh restart_fixed.sh

# 2. 停止所有服务
echo "2. 停止所有服务..."
pkill -f "python.*app.py" 2>/dev/null || true
sleep 3

# 3. 重新启动服务
echo "3. 启动服务..."
./start.sh

# 4. 等待服务启动
echo "4. 等待服务启动..."
sleep 15

# 5. 检查服务状态
echo "5. 检查服务状态..."
echo "API网关 (5001):"
curl -s http://localhost:5001/ && echo "   ✅ 正常" || echo "   ❌ 无响应"

echo "Marker服务 (5002):"
curl -s http://localhost:5002/ && echo "   ✅ 正常" || echo "   ❌ 无响应"

echo "Paddle服务 (5003):"
curl -s http://localhost:5003/ && echo "   ✅ 正常" || echo "   ❌ 无响应"

echo ""
echo "✅ 修复完成！"
echo ""
echo "📋 下一步："
echo "1. 在AutoDL控制台配置端口映射："
echo "   - 容器内端口: 5001"
echo "   - 外网端口: 41973"
echo "2. 测试外网连接: curl http://connect.westc.gpuhub.com:41973/"
