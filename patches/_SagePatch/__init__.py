# /opt/ComfyUI/custom_nodes/_SagePatch/__init__.py
import os, torch, inspect
from torch.nn import functional as F
try:
    from sageattention.core import sageattn as _sage
except Exception as e:
    print("[SagePatch] SageAttention unavailable, leaving SDPA as-is:", e)
else:
    _orig_sdpa = F.scaled_dot_product_attention

    def _sdpa_safe(q, k, v, attn_mask=None, dropout_p=0.0, is_causal=False):
        use_sage = os.getenv("SAGEATTN", "1").lower() not in ("0","false","off")

        # CPU or unknown device → use stock SDPA
        if not use_sage or q.device.type != "cuda":
            return _orig_sdpa(q, k, v, attn_mask=attn_mask, dropout_p=dropout_p, is_causal=is_causal)

        # Skip Sage for WAN VAE path or big head dims (e.g. 384)
        if any("wan/vae.py" in (f.filename or "") for f in inspect.stack()):
            return _orig_sdpa(q, k, v, attn_mask=attn_mask, dropout_p=dropout_p, is_causal=is_causal)

        head_dim = int(q.shape[-1])
        if head_dim > 256 or (head_dim % 16 != 0):
            return _orig_sdpa(q, k, v, attn_mask=attn_mask, dropout_p=dropout_p, is_causal=is_causal)

        try:
            return _sage(q, k, v, attn_mask, dropout_p, is_causal)
        except Exception:
            return _orig_sdpa(q, k, v, attn_mask=attn_mask, dropout_p=dropout_p, is_causal=is_causal)

    F.scaled_dot_product_attention = _sdpa_safe
    print("[SagePatch] CUDA-only + safe fallbacks (WAN VAE excluded, >256 head_dim skipped)")