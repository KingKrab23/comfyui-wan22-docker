import os, shutil, sys
from huggingface_hub import hf_hub_download

MODELS = os.environ.get("COMFY_MODELS_DIR", "/opt/ComfyUI/models")
TEXT_DIR = os.path.join(MODELS, "text_encoders")
VAE_DIR  = os.path.join(MODELS, "vae")
UNET_DIR = os.path.join(MODELS, "unet")
LORA_DIR = os.path.join(MODELS, "loras")
CLIPV_DIR= os.path.join(MODELS, "clip_vision")
for d in (TEXT_DIR, VAE_DIR, UNET_DIR, LORA_DIR, CLIPV_DIR):
    os.makedirs(d, exist_ok=True)

def dl(repo, filename, dest, outname=None):
    p = hf_hub_download(repo_id=repo, filename=filename, local_dir=dest)
    if outname and os.path.basename(p) != outname:
        shutil.move(p, os.path.join(dest, outname))
    return True

# 1) Text encoder (both, some workflows prefer fp8)
try:
    dl("Comfy-Org/Wan_2.1_ComfyUI_repackaged",
       "split_files/text_encoders/umt5_xxl_fp16.safetensors", TEXT_DIR,
       outname="umt5_xxl_fp16.safetensors")
except Exception as e:
    print("umt5 fp16 download failed:", e, file=sys.stderr)

try:
    dl("Comfy-Org/Wan_2.1_ComfyUI_repackaged",
       "split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors", TEXT_DIR,
       outname="umt5_xxl_fp8_e4m3fn_scaled.safetensors")
except Exception as e:
    print("umt5 fp8 download failed:", e, file=sys.stderr)

# 2) VAE 2.1
try:
    dl("Comfy-Org/Wan_2.1_ComfyUI_repackaged",
       "split_files/vae/wan_2.1_vae.safetensors", VAE_DIR,
       outname="wan_2.1_vae.safetensors")
except Exception as e:
    print("VAE download failed:", e, file=sys.stderr)

# 3) CLIP Vision H (used by many WAN/VACE workflows)
try:
    dl("Comfy-Org/Wan_2.1_ComfyUI_repackaged",
       "split_files/clip_vision/clip_vision_h.safetensors", CLIPV_DIR,
       outname="clip_vision_h.safetensors")
except Exception as e:
    print("clip_vision_h download failed:", e, file=sys.stderr)

# 4) Optional LoRA (Lightx2v for I2V 14B)
try:
    dl("Kijai/WanVideo_comfy",
       "Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank256_bf16.safetensors",
       LORA_DIR)
except Exception as e:
    print("Lightx2v LoRA download failed:", e, file=sys.stderr)

# 5) WAN 2.2 UNET GGUF pair (High/Low noise)
quant = os.environ.get("WAN_QUANT", "Q6_K")
pairs = [
    ("QuantStack/Wan2.2-I2V-A14B-GGUF", f"HighNoise/Wan2.2-I2V-A14B-HighNoise-{quant}.gguf"),
    ("QuantStack/Wan2.2-I2V-A14B-GGUF", f"LowNoise/Wan2.2-I2V-A14B-LowNoise-{quant}.gguf"),
]
fallbacks = [
    ("bullerwins/Wan2.2-I2V-A14B-GGUF", f"HighNoise/Wan2.2-I2V-A14B-HighNoise-{quant}.gguf"),
    ("bullerwins/Wan2.2-I2V-A14B-GGUF", f"LowNoise/Wan2.2-I2V-A14B-LowNoise-{quant}.gguf"),
]



for (repo, path), (frepo, fpath) in zip(pairs, fallbacks):
    target = os.path.join(UNET_DIR, os.path.basename(path))
    if os.path.exists(target):
        continue
    try:
        dl(repo, path, UNET_DIR)
    except Exception:
        dl(frepo, fpath, UNET_DIR)

print("WAN bootstrap complete.")
