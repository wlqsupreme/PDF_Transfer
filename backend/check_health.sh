#!/bin/bash
echo "🔍 检查后端服务健康状态"
echo "========================"

# 检查进程
echo "1. 检查Python进程:"
ps aux | grep python | grep app.py || echo "   ❌ 没有找到运行中的app.py进程"

echo ""
echo "2. 检查端口占用:"
netstat -tlnp | grep -E ":(5000|5001|5002)" || echo "   ❌ 没有找到服务端口"

echo ""
echo "3. 测试本地连接:"
echo "   API网关 (5000):"
curl -s http://localhost:5000/ && echo "   ✅ 正常" || echo "   ❌ 无响应"

echo "   Marker服务 (5001):"
curl -s http://localhost:5001/ && echo "   ✅ 正常" || echo "   ❌ 无响应"

echo "   Paddle服务 (5002):"
curl -s http://localhost:5002/ && echo "   ✅ 正常" || echo "   ❌ 无响应"

echo ""
echo "4. 测试外网连接:"
echo "   外网地址测试:"
curl -s http://connect.westc.gpuhub.com:41973/ && echo "   ✅ 外网可访问" || echo "   ❌ 外网无响应"

echo ""
echo "5. 检查日志:"
if [ -f logs/api_gateway.log ]; then
    echo "   API网关最新日志:"
    tail -3 logs/api_gateway.log
fi

echo ""
echo "检查完成！"
