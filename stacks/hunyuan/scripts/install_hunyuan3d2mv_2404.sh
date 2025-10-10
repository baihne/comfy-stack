#!/usr/bin/env bash
set -Eeuo pipefail

# Hunyuan3D-2mv (Multiview) Installation Script for Ubuntu 24.04
# Based on research findings - uses the 2.0 repo with multiview models

# ---------- Config ----------
APP_DIR="${APP_DIR:-$HOME/Hunyuan3D-2mv}"
VENV="${VENV:-$APP_DIR/hy3d2mv-py311}"
HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-7861}"  # Different port from 2.1
REPO_URL="${REPO_URL:-https://github.com/Tencent-Hunyuan/Hunyuan3D-2.git}"
MODEL_VARIANT="${MODEL_VARIANT:-standard}"  # standard | turbo

echo "🎭 Installing Hunyuan3D-2mv (Multiview) on Ubuntu 24.04"
echo "   Model variant: $MODEL_VARIANT"
echo "   App directory: $APP_DIR"
echo "   Port: $PORT"

# ---------- System deps (Ubuntu 24.04) ----------
sudo apt-get update -y
sudo apt-get install -y software-properties-common
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt-get update -y
sudo apt-get install -y \
  python3.11 python3.11-venv python3.11-dev \
  git build-essential cmake ninja-build pkg-config \
  libgl1-mesa-dev libegl1 libglib2.0-0 libglu1-mesa \
  libx11-6 libxi6 libxxf86vm1 libxrender1 libxfixes3 libxext6 libxrandr2 libxinerama1 libxkbcommon0 \
  ffmpeg wget curl

# ---------- Repo (Hunyuan3D-2, not 2.1) ----------
mkdir -p "$APP_DIR"
if [ ! -d "$APP_DIR/.git" ]; then
  git clone "$REPO_URL" "$APP_DIR"
else
  git -C "$APP_DIR" pull || true
fi

# ---------- Python venv ----------
python3.11 -m venv "$VENV"
source "$VENV/bin/activate"
pip install -U pip wheel setuptools

# ---------- PyTorch (CUDA 12.4 wheels) ----------
pip install torch==2.5.1 torchvision==0.20.1 torchaudio==2.5.1 \
  --index-url https://download.pytorch.org/whl/cu124
python - <<'PY'
import torch; print("✓ torch", torch.__version__, "cuda", torch.version.cuda, "avail", torch.cuda.is_available())
PY

# ---------- Install Hunyuan3D-2 requirements ----------
cd "$APP_DIR"
pip install -r requirements.txt
pip install -e .

# ---------- Model weights (cache multiview models) ----------
pip install -U "huggingface_hub>=0.34" hf_transfer
export HF_HUB_ENABLE_HF_TRANSFER=1

echo "📥 Downloading multiview models..."
python - <<'PY'
from huggingface_hub import snapshot_download
import os

# Cache multiview shape models
cache_mv = os.path.expanduser("~/.cache/huggingface/hub/models--tencent--Hunyuan3D-2mv")
snapshot_download(
    repo_id="tencent/Hunyuan3D-2mv",
    allow_patterns=[
        "hunyuan3d-dit-v2-mv/*",
        "hunyuan3d-dit-v2-mv-turbo/*",
        "hunyuan3d-dit-v2-mv-fast/*",
    ],
    local_dir_use_symlinks=False,
)

# Cache texture models (from Hunyuan3D-2)
cache_2 = os.path.expanduser("~/.cache/huggingface/hub/models--tencent--Hunyuan3D-2")
snapshot_download(
    repo_id="tencent/Hunyuan3D-2",
    allow_patterns=[
        "hunyuan3d-texgen-v2-0/*",
    ],
    local_dir_use_symlinks=False,
)

print("✓ Multiview models cached")
PY

# ---------- Determine model subfolder based on variant ----------
case "$MODEL_VARIANT" in
  turbo)
    SUBFOLDER="hunyuan3d-dit-v2-mv-turbo"
    FLASH_VDM="--enable_flashvdm"
    ;;
  fast)
    SUBFOLDER="hunyuan3d-dit-v2-mv-fast"
    FLASH_VDM=""
    ;;
  standard|*)
    SUBFOLDER="hunyuan3d-dit-v2-mv"
    FLASH_VDM=""
    ;;
esac

# ---------- Create example prompts file (required by gradio_app.py) ----------
mkdir -p "$APP_DIR/assets"
cat > "$APP_DIR/assets/example_prompts.txt" << 'PROMPTS'
A cute cat
A red sports car
A wooden chair
A futuristic robot
A vintage camera
A coffee cup
A tree
A house
A dragon
A spaceship
PROMPTS

# ---------- Run wrapper for multiview ----------
cd "$APP_DIR"
cat > run_hunyuan3d_mv.sh <<EOS
#!/usr/bin/env bash
set -Eeuo pipefail
APP_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
source "\$APP_DIR/hy3d2mv-py311/bin/activate"

# Change to correct directory for assets
cd "\$APP_DIR"

# Make Torch shared libs visible
export LD_LIBRARY_PATH="\$(python - <<'PY'
import os, torch; print(os.path.join(os.path.dirname(torch.__file__), "lib"))
PY
):\${LD_LIBRARY_PATH:-}"

# Set Python path for proper imports
export PYTHONPATH="\$APP_DIR:\${PYTHONPATH:-}"

echo "🎭 Starting Hunyuan3D-2mv (Multiview) - Variant: $MODEL_VARIANT"
echo "📡 Access via: http://\${GRADIO_HOST:-0.0.0.0}:\${GRADIO_PORT:-$PORT}"

exec python "\$APP_DIR/gradio_app.py" \\
  --model_path tencent/Hunyuan3D-2mv \\
  --subfolder $SUBFOLDER \\
  --texgen_model_path tencent/Hunyuan3D-2 \\
  --low_vram_mode \\
  $FLASH_VDM \\
  --host \${GRADIO_HOST:-0.0.0.0} \\
  --port \${GRADIO_PORT:-$PORT}
EOS
chmod +x run_hunyuan3d_mv.sh

echo
echo "===================================="
echo "✅ Hunyuan3D-2mv installation complete!"
echo "===================================="
echo "Model variant: $MODEL_VARIANT"
echo "Run the multiview app:"
echo "  $APP_DIR/run_hunyuan3d_mv.sh"
echo ""
echo "🔧 Environment variables:"
echo "  GRADIO_HOST=0.0.0.0 (for Tailscale access)"
echo "  GRADIO_PORT=$PORT (default)"
echo ""
echo "📖 Multiview usage:"
echo "  - Upload multiple view images (front, left, back, etc.)"
echo "  - Better shape consistency than single-view"
echo "  - Same output format (trimesh/GLB/OBJ)"
echo ""
echo "🎨 Available variants:"
echo "  standard: Full quality multiview generation"
echo "  turbo:    Fast distilled model with --enable_flashvdm"
echo "  fast:     Speed-optimized variant"
echo "===================================="