#!/bin/bash
echo "🔄 更改服务端口配置"
echo "==================="

# 停止所有服务
echo "停止所有服务..."
pkill -f "python.*app.py" 2>/dev/null || true
sleep 3

# 备份原始文件
echo "备份原始配置..."
cp api_gateway/app.py api_gateway/app.py.backup

# 修改API网关端口为5001（避免冲突）
echo "修改API网关端口为5001..."
sed -i 's/port=5000/port=5001/g' api_gateway/app.py

# 修改Marker服务端口为5002
echo "修改Marker服务端口为5002..."
sed -i 's/port=5001/port=5002/g' marker_service/app.py

# 修改Paddle服务端口为5003
echo "修改Paddle服务端口为5003..."
sed -i 's/port=5002/port=5003/g' paddle_service/app.py

# 修改API网关中的服务URL
echo "更新服务URL配置..."
sed -i 's/localhost:5001/localhost:5002/g' api_gateway/app.py
sed -i 's/localhost:5002/localhost:5003/g' api_gateway/app.py

echo "✅ 端口配置已更改："
echo "  - API网关: 5001"
echo "  - Marker服务: 5002" 
echo "  - Paddle服务: 5003"
echo ""
echo "📋 下一步："
echo "1. 在AutoDL控制台配置端口映射："
echo "   - 容器内端口: 5001"
echo "   - 外网端口: 41973 (或选择其他端口)"
echo "2. 运行: ./start.sh"
echo "3. 测试外网连接"
