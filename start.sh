#!/bin/bash
set -e

echo "Starting ComfyUI WAN Video Serverless..."

DIFFUSION_DIR="/workspace/ComfyUI/models/diffusion_models"
TEXT_ENCODER_DIR="/workspace/ComfyUI/models/text_encoders"
VAE_DIR="/workspace/ComfyUI/models/vae"
LORAS_DIR="/workspace/ComfyUI/models/loras"

if [ ! -f "$DIFFUSION_DIR/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors" ]; then
    wget -q -O "$DIFFUSION_DIR/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors" "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors"
fi

if [ ! -f "$DIFFUSION_DIR/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors" ]; then
    wget -q -O "$DIFFUSION_DIR/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors" "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors"
fi

if [ ! -f "$TEXT_ENCODER_DIR/umt5_xxl_fp8_e4m3fn_scaled.safetensors" ]; then
    wget -q -O "$TEXT_ENCODER_DIR/umt5_xxl_fp8_e4m3fn_scaled.safetensors" "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
fi

if [ ! -f "$VAE_DIR/wan_2.1_vae.safetensors" ]; then
    wget -q -O "$VAE_DIR/wan_2.1_vae.safetensors" "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors"
fi

if [ ! -f "$LORAS_DIR/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors" ]; then
    wget -q -O "$LORAS_DIR/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors" "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors"
fi

if [ ! -f "$LORAS_DIR/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors" ]; then
    wget -q -O "$LORAS_DIR/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors" "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors"
fi

echo "All models ready. Starting handler..."
cd /workspace
python handler.py
