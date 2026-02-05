# ComfyUI WAN 2.2 Video Serverless Endpoint

Docker image for image-to-video generation using WAN 2.2 I2V with LightX2V 4-step distillation and NAG guidance, via RunPod serverless.

## Docker Image

`sirdrafton/comfyui-wan-video:latest`

## Models

| Model                                         | Size    | Description              |
| --------------------------------------------- | ------- | ------------------------ |
| umt5_xxl_fp8_e4m3fn_scaled                    | ~6.7 GB | CLIP text encoder        |
| wan2.2_i2v_high_noise_14B_fp8_scaled          | ~15 GB  | UNET high noise pass     |
| wan2.2_i2v_low_noise_14B_fp8_scaled           | ~15 GB  | UNET low noise pass      |
| wan_2.1_vae                                   | ~254 MB | VAE decoder              |
| wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise | ~1.2 GB | LightX2V LoRA high noise |
| wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise  | ~1.2 GB | LightX2V LoRA low noise  |

## Usage

```json
{
  "input": {
    "image": "<base64_encoded_image>",
    "prompt": "Description of motion/action",
    "num_frames": 81,
    "fps": 16
  }
}
```

## Parameters

| Parameter       | Default                | Description                         |
| --------------- | ---------------------- | ----------------------------------- |
| image           | **required**           | Base64 input image                  |
| prompt          | **required**           | Motion/action description           |
| negative_prompt | (mouth movement terms) | What to avoid                       |
| width           | 720                    | Output width                        |
| height          | 720                    | Output height                       |
| num_frames      | 81                     | Number of frames (~5s at 16fps)     |
| steps           | 4                      | Sampling steps (LightX2V distilled) |
| cfg             | 1                      | CFG scale                           |
| fps             | 16                     | Frames per second                   |
| seed            | random                 | Reproducibility                     |
| timeout         | 600                    | Max wait time (seconds)             |

## Response

```json
{
  "video": "<base64_encoded_mp4>",
  "seed": 123456789,
  "parameters": { ... },
  "elapsed_time": 45.2
}
```
