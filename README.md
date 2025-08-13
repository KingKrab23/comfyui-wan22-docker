# Wan 2.2 with SageAttention 2
```git pull https://github.com/KingKrab23/wan2.2-sageattn-comfyui.git```

### Build from Dockerfile
```docker build -t drummer33/comfyui-wan22:cu128 .```

## Choose your models
in docker-compose change WAN_QUANT to the QuantStack WAN 2.2 model you want to use

### Initial Startup
```docker compose up -d```

### ZzZz
Wait like 10-20 minutes for the models to download. You can see the progress in docker with ```docker exec -it comfyui-wan22-docker-comfy-1 tail -f /var/log/bootstrap_models.log``` 

### Restart if you don't see your models and or comfyui manager button
```docker compose down```

```docker compose up -d```

## Docker Settings
ComfyUI Port: ```COMFYUI_PORT: "8188"```

Download the Wan2.2 HighNoise, LowNoise, and misc supportive models/vae/etc automatically? ```WAN_AUTO_DL: "1"```

WAN 2.2 Model version to download: ```WAN_QUANT: "Q6_K"```

Whether to use SageAttention: ```SAGEATTN: "1"```

ComfyUI VRAM Setting: ```VRAMSETTING: "lowvram" # normalvram, lowvram, or highvram```

# Docker Windows Memory Settings for WSL2
Create/edit %UserProfile%\\.wslconfig (Windows path).

```
[wsl2]
memory=28GB          # RAM cap (e.g., 8GB, 16GB, 50%)
processors=8         # optional
swap=16GB            # optional
swapfile=C:\\wsl-swap.vhdx  # optional
```

Adjust the above values to fit your hardware.

powershell
```wsl --shutdown```

```wsl -d Ubuntu-24.04``` Change Ubuntu-24.04 to whatever your WSL2 distro is, ex Ubuntu

Verify inside WSL:

```free -h```