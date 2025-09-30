#!/bin/bash
echo "🛑 停止PDF转换器后端服务..."

# 停止所有Python应用进程
pkill -f "python.*app.py" 2>/dev/null || true
pkill -f "gunicorn" 2>/dev/null || true

echo "✅ 所有服务已停止"
echo "📊 检查进程: ps aux | grep python"
