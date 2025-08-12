#!/usr/bin/env bash
set -euo pipefail

# Optional WAN model auto-download on first run
if [[ "${WAN_AUTO_DL:-0}" == "1" ]]; then
  python /opt/tools/bootstrap_models.py 2>&1 | tee -a /var/log/bootstrap_models.log &
  exec python /opt/ComfyUI/main.py --listen 0.0.0.0 --port "$COMFYUI_PORT"
fi

# Enable SageAttention by patching PyTorch SDPA (opt-in)
if [[ "${SAGEATTN:-0}" == "1" ]]; then
  echo "[SagePatch] Enabling SageAttention (overriding torch.nn.functional.scaled_dot_product_attention)"
fi

exec python main.py --listen 0.0.0.0 --port "${COMFYUI_PORT:-8188}" --${VRAMSETTING:-normalvram}