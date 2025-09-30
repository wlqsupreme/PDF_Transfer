#!/bin/bash
echo "🧪 测试不同端口的连接"
echo "====================="

# 测试常用端口
PORTS=(41973 41974 41975 41976 5000 8080 3000)

for port in "${PORTS[@]}"; do
    echo "测试端口 $port..."
    if curl -s --connect-timeout 5 "http://connect.westc.gpuhub.com:$port/" > /dev/null; then
        echo "  ✅ 端口 $port 可访问"
        # 测试具体响应
        response=$(curl -s --connect-timeout 5 "http://connect.westc.gpuhub.com:$port/")
        echo "  响应: $response"
    else
        echo "  ❌ 端口 $port 无响应"
    fi
    echo ""
done

echo "💡 如果所有端口都无响应，请检查："
echo "1. AutoDL端口映射是否已配置"
echo "2. 容器是否正在运行"
echo "3. 防火墙设置"
