# ComfyUI LTX-2 Video Serverless Endpoint

Docker image for image-to-video generation using LTX-2 model via RunPod serverless.

## Docker Image
`sirdrafton/comfyui-ltx2-serverless:latest`

## Supported Modes

### 1. Generated Audio Mode (Default)
LTX-2 generates audio based on the prompt.

```json
{
  "input": {
    "image": "<base64_encoded_image>",
    "prompt": "Description of motion/action",
    "frame_count": 97,
    "fps": 25
  }
}
```

### 2. Custom Audio Mode
Use pre-generated audio (e.g., from ElevenLabs). Video length automatically matches audio duration.

```json
{
  "input": {
    "image": "<base64_encoded_image>",
    "prompt": "Character speaking, mouth moving in sync with audio",
    "audio": "<base64_encoded_mp3_or_wav>",
    "fps": 25
  }
}
```

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| image | **required** | Base64 input image |
| prompt | **required** | Motion/action description |
| audio | null | Base64 audio file (enables custom audio mode) |
| negative_prompt | (see code) | What to avoid |
| width | 720 | Output width |
| height | 720 | Output height |
| frame_count | 97 | Number of frames (ignored in custom audio mode) |
| steps | 20 | Sampling steps |
| cfg | 4.0 | CFG scale |
| fps | 25 | Frames per second |
| seed | random | Reproducibility |
| timeout | 600 | Max wait time (seconds) |
| i2v_strength_second | 0.7 | I2V strength for 2nd pass (custom audio mode) |

## Response

```json
{
  "video": "<base64_encoded_mp4>",
  "seed": 123456789,
  "mode": "custom_audio",
  "audio_duration": 6.4,
  "parameters": { ... },
  "elapsed_time": 180.5
}
```
