# Wan 2.2 with SageAttention 2
```git pull https://github.com/KingKrab23/wan2.2-sageattn-comfyui.git```

### Build from Dockerfile
```docker build -t drummer33/comfyui-wan22:cu128 .```

## Choose your models
in docker-compose change WAN_QUANT to the QuantStack WAN 2.2 model you want to use

### Initial Startup
```docker compose up -d```

### ZzZz
Wait like 10-20 minutes for the models to download. You can see the progress in docker-desktop with ```docker exec -it comfyui-wan22-docker-comfy-1 tail -f /var/log/bootstrap_models.log```

### Restart if you don't see your models and or comfyui manager button
```docker compose down```

```docker compose up -d```