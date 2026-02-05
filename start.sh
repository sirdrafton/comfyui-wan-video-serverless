#!/bin/bash
set -e
echo "=========================================="
echo "Starting ComfyUI WAN 2.2 Video Worker"
echo "=========================================="

download_file() {
    local url=$1
    local dest=$2

    if [ -f "$dest" ]; then
        local size=$(du -h "$dest" | cut -f1)
        echo "✓ Already exists: $(basename $dest) ($size)"
        return 0
    fi

    echo "  Downloading: $(basename $dest)"
    mkdir -p "$(dirname "$dest")"

    if curl -L --fail --progress-bar --max-time 3600 -o "$dest" "$url"; then
        local size=$(du -h "$dest" | cut -f1)
        echo "  ✓ Downloaded: $(basename $dest) ($size)"
        return 0
    fi

    echo "  ✗ FAILED: $(basename $dest)"
    return 1
}

echo ""
echo "=========================================="
echo "Downloading Models..."
echo "=========================================="

# 1. CLIP/Text Encoder (~6.7 GB)
echo ""
echo "[1/6] CLIP Text Encoder (UMT5-XXL)"
download_file \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
    "/comfyui/models/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"

# 2. UNET High Noise (~15 GB)
echo ""
echo "[2/6] UNET High Noise (14B fp8)"
download_file \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors" \
    "/comfyui/models/diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors"

# 3. UNET Low Noise (~15 GB)
echo ""
echo "[3/6] UNET Low Noise (14B fp8)"
download_file \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors" \
    "/comfyui/models/diffusion_models/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors"

# 4. VAE (~254 MB)
echo ""
echo "[4/6] VAE"
download_file \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors" \
    "/comfyui/models/vae/wan_2.1_vae.safetensors"

# 5. LoRA High Noise (~1.2 GB)
echo ""
echo "[5/6] LightX2V LoRA High Noise"
download_file \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors" \
    "/comfyui/models/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors"

# 6. LoRA Low Noise (~1.2 GB)
echo ""
echo "[6/6] LightX2V LoRA Low Noise"
download_file \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors" \
    "/comfyui/models/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors"

echo ""
echo "=========================================="
echo "Verifying Models..."
echo "=========================================="

for f in \
    "/comfyui/models/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
    "/comfyui/models/diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors" \
    "/comfyui/models/diffusion_models/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors" \
    "/comfyui/models/vae/wan_2.1_vae.safetensors" \
    "/comfyui/models/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors" \
    "/comfyui/models/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors"
do
    if [ -f "$f" ]; then
        size=$(du -h "$f" | cut -f1)
        echo "✓ $(basename $f) ($size)"
    else
        echo "✗ MISSING: $(basename $f)"
    fi
done

echo ""
echo "=========================================="
echo "Starting ComfyUI..."
echo "=========================================="

cd /comfyui
python main.py --listen 0.0.0.0 --port 8188 --disable-auto-launch &

echo "Waiting for ComfyUI..."
sleep 15

for i in $(seq 1 30); do
    if curl -s http://127.0.0.1:8188/system_stats > /dev/null 2>&1; then
        echo "✓ ComfyUI is running!"
        break
    fi
    echo "  Waiting... ($i/30)"
    sleep 2
done

echo ""
echo "=========================================="
echo "Starting Handler..."
echo "=========================================="
cd /
python -u /handler.py
