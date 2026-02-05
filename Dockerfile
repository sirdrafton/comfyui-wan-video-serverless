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
    bc \
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

# Clone ComfyUI (requirements installed later, after custom nodes)
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /comfyui
WORKDIR /comfyui

# Install RunPod SDK and additional dependencies
RUN pip install --no-cache-dir runpod huggingface_hub

# Create model directories
RUN mkdir -p models/checkpoints \
    models/text_encoders \
    models/diffusion_models \
    models/vae \
    models/loras \
    input \
    output \
    workflows

# Clone and install custom nodes (before ComfyUI requirements)
WORKDIR /comfyui/custom_nodes

# ComfyUI-NAG (provides KSamplerWithNAG node)
RUN git clone https://github.com/ChenDarYen/ComfyUI-NAG.git && \
    cd ComfyUI-NAG && \
    pip install --no-cache-dir -r requirements.txt || true

# VideoHelperSuite for video handling
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    cd ComfyUI-VideoHelperSuite && \
    pip install --no-cache-dir -r requirements.txt || true

# ComfyUI-KJNodes
RUN git clone https://github.com/kijai/ComfyUI-KJNodes.git && \
    cd ComfyUI-KJNodes && \
    pip install --no-cache-dir -r requirements.txt || true

# ComfyUI-Custom-Scripts (for MathExpression node)
RUN git clone https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git && \
    cd ComfyUI-Custom-Scripts && \
    pip install --no-cache-dir -r requirements.txt || true

# CRITICAL: Install ComfyUI requirements AFTER custom nodes so comfy deps take precedence
WORKDIR /comfyui
RUN pip install --no-cache-dir -r requirements.txt

# CRITICAL: Reinstall PyTorch last to fix any CUDA version conflicts
RUN pip install --no-cache-dir --force-reinstall torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Copy handler, workflow, and start script
COPY handler.py /handler.py
COPY start.sh /start.sh
COPY wan2_workflow.json /wan2_workflow.json
RUN chmod +x /start.sh

# Create symlink for backwards compatibility
RUN ln -sf /wan2_workflow.json /workflow.json

WORKDIR /
EXPOSE 8188
CMD ["/start.sh"]
