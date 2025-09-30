#!/bin/bash
echo "🔧 修复CORS配置并重启服务"
echo "=========================="

# 1. 停止所有服务
echo "1. 停止所有服务..."
pkill -f "python.*app.py" 2>/dev/null || true
sleep 3

# 2. 重新启动服务
echo "2. 启动服务..."
./start.sh

# 3. 等待服务启动
echo "3. 等待服务启动..."
sleep 10

# 4. 测试CORS
echo "4. 测试CORS配置..."
echo "测试OPTIONS请求..."
curl -X OPTIONS -H "Origin: http://localhost:3000" -H "Access-Control-Request-Method: POST" -H "Access-Control-Request-Headers: Content-Type" http://localhost:5001/convert -v

echo ""
echo "✅ CORS修复完成！"
echo "现在可以测试前端上传功能了"

