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
