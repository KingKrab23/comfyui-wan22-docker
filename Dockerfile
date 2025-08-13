# ---------- builder ----------
    ARG CUDA_VER=12.8.0
    ARG UBUNTU_VER=22.04
    FROM nvidia/cuda:${CUDA_VER}-devel-ubuntu${UBUNTU_VER} AS builder

    ENV DEBIAN_FRONTEND=noninteractive \
        PYTHONUNBUFFERED=1 \
        PIP_DISABLE_PIP_VERSION_CHECK=1

    RUN apt-get update && apt-get install -y --no-install-recommends \
        git build-essential python3 python3-venv python3-pip python3-dev \
        ffmpeg curl ca-certificates pkg-config \
        libgl1 libglib2.0-0 \
     && rm -rf /var/lib/apt/lists/*

    RUN python3 -m venv /opt/venv
    ENV PATH=/opt/venv/bin:$PATH

    # PyTorch CUDA 12.8 wheels (+ torchvision/torchaudio)
    RUN python -m pip install --upgrade pip wheel setuptools
    RUN python -m pip install --index-url https://download.pytorch.org/whl/cu128 \
        torch==2.8.0+cu128 torchvision==0.23.0+cu128 torchaudio==2.8.0+cu128

    # ComfyUI
    WORKDIR /opt
    RUN git clone https://github.com/comfyanonymous/ComfyUI.git
    WORKDIR /opt/ComfyUI
    RUN python -m pip install -r requirements.txt
    RUN python -m pip install --upgrade \
        "numpy>=2.0" "opencv-python>=4.10.0.0" "pillow>=10.3" "imageio[ffmpeg]" "scipy" \
        "huggingface_hub[hf_xet]>=0.34,<1.0" "transformers==4.55.0" hf-transfer \
        "triton>=3.0.0"

# --- Extra custom nodes you asked for ---
    RUN mkdir -p /opt/ComfyUI/custom_nodes && cd /opt/ComfyUI/custom_nodes \
        && git clone https://github.com/pollockjj/ComfyUI-MultiGPU.git \
        && git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git \
        && git clone https://github.com/rgthree/rgthree-comfy.git \
        && git clone https://github.com/cubiq/ComfyUI_essentials.git \
        && git clone https://github.com/Comfy-Org/ComfyUI-Manager.git \
        && git clone https://github.com/city96/ComfyUI-GGUF.git \
        && git clone https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git \
        && git clone https://github.com/kijai/ComfyUI-GIMM-VFI.git \
        && git clone https://github.com/kijai/ComfyUI-KJNodes.git \
        && git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git \
        && git clone https://github.com/ltdrdata/ComfyUI-Inspire-Pack.git

   # ==== Arch + build env (Ampere-safe; no SM90) ====
    ARG CUDA_ARCHES_SM="86;89;100"
    ARG CUDA_ARCHES_TORCH="8.6;8.9;10.0"
    ENV CUDAARCHS="${CUDA_ARCHES_SM}" \
        CMAKE_CUDA_ARCHITECTURES="${CUDA_ARCHES_SM}" \
        TORCH_CUDA_ARCH_LIST="${CUDA_ARCHES_TORCH}" \
        FORCE_CUDA=1

    # Ensure no FP8/Hopper stacks are present
    RUN python -m pip uninstall -y flash-attn flash_attn* transformer-engine nvidia-transformer-engine || true

    # GIMM-VFI (optional)
    RUN python -m pip install "cupy-cuda12x==13.3.0" || python -m pip install "cupy-cuda12x"

    # --- SageAttention 2.2/2.2++ (compile from source)
    WORKDIR /opt
    RUN git clone https://github.com/thu-ml/SageAttention.git
    WORKDIR /opt/SageAttention

    ARG SAGE_CUDA_ARCH_LIST=${CUDA_ARCHES_TORCH}
    ENV TORCH_CUDA_ARCH_LIST=${CUDA_ARCHES_TORCH}
    ENV FORCE_CUDA=1 EXT_PARALLEL=4 NVCC_APPEND_FLAGS="--threads 8" MAX_JOBS=32

    ARG SAGEATTN_REF=2aecfa8
    RUN git checkout ${SAGEATTN_REF}

    RUN python -m pip install --no-build-isolation .

    # Shims
    RUN mkdir -p /opt/ComfyUI/custom_nodes/_GGUFPathMap /opt/ComfyUI/custom_nodes/_SagePatch
    COPY patches/_GGUFPathMap/__init__.py /opt/ComfyUI/custom_nodes/_GGUFPathMap/__init__.py
    COPY patches/_SagePatch/__init__.py   /opt/ComfyUI/custom_nodes/_SagePatch/__init__.py

# ---------- runtime ----------
    FROM nvidia/cuda:${CUDA_VER}-runtime-ubuntu${UBUNTU_VER}
    ENV DEBIAN_FRONTEND=noninteractive
    
    RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 git curl unzip ffmpeg libgl1 libglib2.0-0 ca-certificates \
        python3-dev build-essential ninja-build cmake clang \
     && rm -rf /var/lib/apt/lists/*
    
    # copy venv + app first so we can use /opt/venv/bin/python
    COPY --from=builder /opt/venv    /opt/venv
    COPY --from=builder /opt/ComfyUI /opt/ComfyUI
    
    # now install extra deps with the venv python
    RUN /opt/venv/bin/python -m pip install --no-cache-dir omegaconf webcolors piexif gguf && \
        for req in /opt/ComfyUI/custom_nodes/*/requirements.txt; do \
          [ -f "$req" ] && /opt/venv/bin/python -m pip install --no-cache-dir -r "$req"; \
        done
    
    ENV PATH=/opt/venv/bin:$PATH \
        COMFYUI_PORT=8188 \
        HF_HUB_ENABLE_HF_TRANSFER=1 \
        PYTORCH_CUDA_ALLOC_CONF="expandable_segments:True,max_split_size_mb:128" \
        PYTORCH_ALLOW_TF32=1 \
        NVIDIA_TF32_OVERRIDE=1 \
        SAGEATTN=1
    
    VOLUME ["/opt/ComfyUI/models"]

    COPY tools/bootstrap_models.py /opt/tools/bootstrap_models.py

    WORKDIR /opt/ComfyUI
    COPY entrypoint.sh /entrypoint.sh
    RUN sed -i 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh
    EXPOSE 8188
    ENTRYPOINT ["/entrypoint.sh"]
    