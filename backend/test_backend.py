#!/usr/bin/env python3
"""
后端服务测试脚本
"""

import requests
import json

def test_backend():
    base_url = "http://localhost:5000"
    
    print("🧪 测试后端服务...")
    print("=" * 50)
    
    # 测试1: 健康检查
    print("1. 测试API网关健康检查...")
    try:
        response = requests.get(f"{base_url}/", timeout=5)
        print(f"   状态码: {response.status_code}")
        print(f"   响应: {response.json()}")
        print("   ✅ API网关正常")
    except Exception as e:
        print(f"   ❌ API网关异常: {e}")
    
    print()
    
    # 测试2: 测试Marker服务
    print("2. 测试Marker服务...")
    try:
        response = requests.get("http://localhost:5001/", timeout=5)
        print(f"   状态码: {response.status_code}")
        print(f"   响应: {response.json()}")
        print("   ✅ Marker服务正常")
    except Exception as e:
        print(f"   ❌ Marker服务异常: {e}")
    
    print()
    
    # 测试3: 测试Paddle服务
    print("3. 测试Paddle服务...")
    try:
        response = requests.get("http://localhost:5002/", timeout=5)
        print(f"   状态码: {response.status_code}")
        print(f"   响应: {response.json()}")
        print("   ✅ Paddle服务正常")
    except Exception as e:
        print(f"   ❌ Paddle服务异常: {e}")
    
    print()
    
    # 测试4: 测试转换接口
    print("4. 测试转换接口...")
    try:
        response = requests.post(f"{base_url}/convert", timeout=5)
        print(f"   状态码: {response.status_code}")
        print(f"   响应: {response.json()}")
        print("   ✅ 转换接口可访问")
    except Exception as e:
        print(f"   ❌ 转换接口异常: {e}")
    
    print()
    print("=" * 50)
    print("测试完成！")

if __name__ == "__main__":
    test_backend()
