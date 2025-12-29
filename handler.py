"""
ComfyUI WAN 2.2 Image-to-Video Serverless Handler
"""

import runpod
import json
import uuid
import base64
import os
import sys
import time
import subprocess
import urllib.request
import urllib.error

sys.path.insert(0, '/workspace/ComfyUI')

COMFYUI_DIR = "/workspace/ComfyUI"
INPUT_DIR = f"{COMFYUI_DIR}/input"
OUTPUT_DIR = f"{COMFYUI_DIR}/output"
WORKFLOW_PATH = "/workspace/workflow.json"

comfy_process = None

def start_comfyui():
    global comfy_process
    if comfy_process is None:
        print("Starting ComfyUI server...")
        comfy_process = subprocess.Popen(
            ["python", "main.py", "--listen", "127.0.0.1", "--port", "8188", "--disable-auto-launch"],
            cwd=COMFYUI_DIR,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        wait_for_comfyui()
    return comfy_process

def wait_for_comfyui(timeout=120):
    start_time = time.time()
    while time.time() - start_time < timeout:
        try:
            req = urllib.request.Request("http://127.0.0.1:8188/system_stats")
            with urllib.request.urlopen(req, timeout=5) as response:
                if response.status == 200:
                    print("ComfyUI is ready!")
                    return True
        except:
            time.sleep(2)
    raise TimeoutError("ComfyUI failed to start")

def save_input_image(image_data, filename):
    if "," in image_data:
        image_data = image_data.split(",")[1]
    image_bytes = base64.b64decode(image_data)
    filepath = os.path.join(INPUT_DIR, filename)
    with open(filepath, "wb") as f:
        f.write(image_bytes)
    return filename

def load_workflow():
    with open(WORKFLOW_PATH, "r") as f:
        return json.load(f)

def modify_workflow(workflow, params):
    if "image_filename" in params:
        workflow["97"]["inputs"]["image"] = params["image_filename"]
    if "prompt" in params:
        workflow["93"]["inputs"]["text"] = params["prompt"]
    if "negative_prompt" in params:
        workflow["89"]["inputs"]["text"] = params["negative_prompt"]
    if "width" in params:
        workflow["98"]["inputs"]["width"] = params["width"]
    if "height" in params:
        workflow["98"]["inputs"]["height"] = params["height"]
    if "length" in params:
        workflow["98"]["inputs"]["length"] = params["length"]
    if "seed" in params:
        workflow["86"]["inputs"]["noise_seed"] = params["seed"]
    else:
        import random
        workflow["86"]["inputs"]["noise_seed"] = random.randint(0, 2**53)
    if "steps" in params:
        workflow["85"]["inputs"]["steps"] = params["steps"]
        workflow["86"]["inputs"]["steps"] = params["steps"]
    if "cfg" in params:
        workflow["85"]["inputs"]["cfg"] = params["cfg"]
        workflow["86"]["inputs"]["cfg"] = params["cfg"]
    if "fps" in params:
        workflow["94"]["inputs"]["fps"] = params["fps"]
    return workflow

def queue_prompt(workflow):
    data = json.dumps({"prompt": workflow}).encode('utf-8')
    req = urllib.request.Request(
        "http://127.0.0.1:8188/prompt",
        data=data,
        headers={"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(req) as response:
        result = json.loads(response.read().decode('utf-8'))
        return result["prompt_id"]

def get_history(prompt_id):
    req = urllib.request.Request(f"http://127.0.0.1:8188/history/{prompt_id}")
    with urllib.request.urlopen(req) as response:
        return json.loads(response.read().decode('utf-8'))

def wait_for_completion(prompt_id, timeout=600):
    start_time = time.time()
    while time.time() - start_time < timeout:
        history = get_history(prompt_id)
        if prompt_id in history:
            status = history[prompt_id].get("status", {})
            if status.get("completed", False):
                return history[prompt_id]
            if status.get("status_str") == "error":
                raise RuntimeError(f"Workflow failed: {status}")
        time.sleep(2)
    raise TimeoutError(f"Workflow did not complete within {timeout} seconds")

def get_video_output(history):
    outputs = history.get("outputs", {})
    for node_id, node_output in outputs.items():
        if "videos" in node_output:
            for video in node_output["videos"]:
                video_path = os.path.join(OUTPUT_DIR, video.get("subfolder", ""), video["filename"])
                if os.path.exists(video_path):
                    with open(video_path, "rb") as f:
                        video_base64 = base64.b64encode(f.read()).decode('utf-8')
                    os.remove(video_path)
                    return video_base64
    raise FileNotFoundError("No video output found")

def handler(job):
    job_input = job.get("input", {})
    
    if "image" not in job_input:
        return {"error": "Missing required 'image' field"}
    if "prompt" not in job_input:
        return {"error": "Missing required 'prompt' field"}
    
    try:
        start_comfyui()
        
        image_filename = f"{uuid.uuid4()}.png"
        save_input_image(job_input["image"], image_filename)
        
        workflow = load_workflow()
        
        params = {
            "image_filename": image_filename,
            "prompt": job_input["prompt"],
            "negative_prompt": job_input.get("negative_prompt", "blurry, low quality, distorted face, extra limbs, bad anatomy, watermark, text, deformed"),
            "width": job_input.get("width", 720),
            "height": job_input.get("height", 1280),
            "length": job_input.get("length", 81),
            "seed": job_input.get("seed"),
            "steps": job_input.get("steps", 4),
            "cfg": job_input.get("cfg", 1.0),
            "fps": job_input.get("fps", 16)
        }
        
        workflow = modify_workflow(workflow, params)
        
        print(f"Generating video: {params['width']}x{params['height']}, {params['length']} frames")
        prompt_id = queue_prompt(workflow)
        
        timeout = job_input.get("timeout", 600)
        history = wait_for_completion(prompt_id, timeout=timeout)
        
        video_base64 = get_video_output(history)
        
        input_path = os.path.join(INPUT_DIR, image_filename)
        if os.path.exists(input_path):
            os.remove(input_path)
        
        return {
            "video": video_base64,
            "seed": workflow["86"]["inputs"]["noise_seed"],
            "parameters": params
        }
        
    except Exception as e:
        import traceback
        return {"error": str(e), "traceback": traceback.format_exc()}

if __name__ == "__main__":
    print("Starting WAN Video Serverless Handler...")
    runpod.serverless.start({"handler": handler})
