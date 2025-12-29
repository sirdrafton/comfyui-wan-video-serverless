# ComfyUI WAN 2.2 Video Serverless Endpoint
FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    ffmpeg \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Clone ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI

# Install ComfyUI dependencies
RUN pip install --no-cache-dir \
    torch \
    torchvision \
    torchaudio \
    xformers \
    accelerate \
    transformers \
    safetensors \
    aiohttp \
    einops \
    kornia \
    opencv-python \
    pillow \
    scipy \
    tqdm \
    runpod

RUN pip install --no-cache-dir -r /workspace/ComfyUI/requirements.txt

# Create model directories
RUN mkdir -p /workspace/ComfyUI/models/diffusion_models \
    && mkdir -p /workspace/ComfyUI/models/text_encoders \
    && mkdir -p /workspace/ComfyUI/models/vae \
    && mkdir -p /workspace/ComfyUI/models/clip_vision \
    && mkdir -p /workspace/ComfyUI/models/loras \
    && mkdir -p /workspace/ComfyUI/input \
    && mkdir -p /workspace/ComfyUI/output

COPY handler.py /workspace/handler.py
COPY start.sh /workspace/start.sh
COPY workflow.json /workspace/workflow.json

RUN chmod +x /workspace/start.sh

EXPOSE 8188

CMD ["/workspace/start.sh"]
