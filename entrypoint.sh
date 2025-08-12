#!/usr/bin/env bash
set -euo pipefail

# Enable SageAttention (print once before exec)
[[ "${SAGEATTN:-0}" == "1" ]] && echo "[SagePatch] Enabling SageAttention (overriding torch.nn.functional.scaled_dot_product_attention)"

# Optional WAN model auto-download
if [[ "${WAN_AUTO_DL:-0}" == "1" ]]; then
  python /opt/tools/bootstrap_models.py 2>&1 | tee -a /var/log/bootstrap_models.log &
fi

exec python main.py --listen 0.0.0.0 --port "${COMFYUI_PORT:-8188}" --${VRAMSETTING:-normalvram}
