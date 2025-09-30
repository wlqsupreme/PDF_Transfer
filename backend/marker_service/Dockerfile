# 使用NVIDIA官方PyTorch镜像 - 推荐版本
FROM nvcr.io/nvidia/pytorch:23.12-py3

WORKDIR /app

# 安装Camelot需要的系统依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    ghostscript \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

# 使用gunicorn启动服务，设置超时时间为10分钟以处理大文件
CMD ["gunicorn", "--workers", "1", "--threads", "4", "--timeout", "600", "--bind", "0.0.0.0:5001", "app:app"]
