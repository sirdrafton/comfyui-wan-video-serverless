FROM nvidia/cuda:12.1.0-runtime-ubuntu22.04
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    python3.10-venv \
    git \
    wget \
    curl \
    unzip \
    ffmpeg \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Set python3.10 as default
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1
RUN update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

# Install PyTorch with CUDA 12.1
RUN pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Clone ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /comfyui
WORKDIR /comfyui
RUN pip install --no-cache-dir -r requirements.txt

# Install RunPod SDK
RUN pip install --no-cache-dir runpod

# Create directories
RUN mkdir -p models/diffusion_models models/text_encoders models/vae models/loras models/clip_vision input output

# Copy handler and start script
COPY handler.py /handler.py
COPY start.sh /start.sh
COPY workflow.json /workflow.json
RUN chmod +x /start.sh

WORKDIR /
EXPOSE 8188
CMD ["/start.sh"]
