#!/usr/bin/env bash
set -Eeuo pipefail

# ---------- Config ----------
APP_DIR="${APP_DIR:-$HOME/Hunyuan3D-2.1}"
VENV="${VENV:-$APP_DIR/hy3d-py311}"
HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-7860}"
REPO_URL="${REPO_URL:-https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1.git}"

# ---------- System deps (Ubuntu 24.04) ----------
sudo apt-get update -y
sudo apt-get install -y software-properties-common
# 24.04 defaults to Python 3.12; install 3.11 explicitly
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt-get update -y
sudo apt-get install -y \
  python3.11 python3.11-venv python3.11-dev \
  git build-essential cmake ninja-build pkg-config \
  libgl1-mesa-dev libegl1 libglib2.0-0 libglu1-mesa \
  libx11-6 libxi6 libxxf86vm1 libxrender1 libxfixes3 libxext6 libxrandr2 libxinerama1 libxkbcommon0 \
  ffmpeg wget curl

# ---------- Repo ----------
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

# ---------- PyTorch (CUDA 12.4 wheels; fine on driver 570/CUDA 12.8) ----------
pip install torch==2.5.1 torchvision==0.20.1 torchaudio==2.5.1 \
  --index-url https://download.pytorch.org/whl/cu124
python - <<'PY'
import torch; print("✓ torch", torch.__version__, "cuda", torch.version.cuda, "avail", torch.cuda.is_available())
PY

# ---------- Requirements (24.04 + Py3.11 + texture-ready) ----------
cd "$APP_DIR"
awk '
  /^bpy==/           { print "bpy>=4.2"; next }
  /^opencv-python==/ { print "opencv-python-headless==4.8.1.78"; next }
  /^numpy==/         { print "numpy==1.26.4"; next }
  { print }
' requirements.txt > requirements-24.04.txt
pip install -r requirements-24.04.txt

# Gradio/pydantic pins that fix the “Loading…” loop
pip install -U "gradio==5.33.0" "gradio_client==1.10.2" "pydantic==2.10.6"

# ---------- Native: custom_rasterizer (needs torch during build) ----------
cd "$APP_DIR/hy3dpaint/custom_rasterizer"
pip uninstall -y custom_rasterizer || true
pip install . --no-build-isolation

# ---------- Native: mesh_inpaint for Python 3.11 (quote-safe; pin pybind11) ----------
cd "$APP_DIR/hy3dpaint/DifferentiableRenderer"
pip install -U 'pybind11==2.13.4'
rm -f mesh_inpaint_processor*.so
INCLUDES="$(python3.11 -m pybind11 --includes)"
PYINC="$(python3.11 -c 'import sysconfig; print(sysconfig.get_paths()["include"])')"
EXT="$(python3.11-config --extension-suffix)"
c++ -O3 -Wall -shared -std=c++11 -fPIC \
  $INCLUDES -I"$PYINC" \
  mesh_inpaint_processor.cpp \
  -o "mesh_inpaint_processor$EXT"

# ---------- ESRGAN checkpoint (texture upscaling) ----------
cd "$APP_DIR"
mkdir -p hy3dpaint/ckpt
[ -f hy3dpaint/ckpt/RealESRGAN_x4plus.pth ] || \
  wget -q https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth \
  -P hy3dpaint/ckpt

# ---------- Model weights (cache them up-front) ----------
pip install -U "huggingface_hub>=0.34" hf_transfer
export HF_HUB_ENABLE_HF_TRANSFER=1
python - <<'PY'
from huggingface_hub import snapshot_download
import os
cache = os.path.expanduser("~/.cache/hy3dgen/tencent/Hunyuan3D-2.1")
snapshot_download(
    repo_id="tencent/Hunyuan3D-2.1",
    allow_patterns=[
        "hunyuan3d-dit-v2-1/*",
        "hunyuan3d-paintpbr-v2-1/*",
        "hunyuan3d-vae-v2-1/*",
    ],
    local_dir=cache,
    local_dir_use_symlinks=False,
)
print("✓ weights cached at", cache)
PY

# ---------- Run wrapper (adds LD_LIBRARY_PATH & PYTHONPATH) ----------
cd "$APP_DIR"
cat > run_hunyuan3d.sh <<'EOS'
#!/usr/bin/env bash
set -Eeuo pipefail
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$APP_DIR/hy3d-py311/bin/activate"

# Make Torch shared libs visible (libc10.so, etc.)
export LD_LIBRARY_PATH="$(python - <<'PY'
import os, torch; print(os.path.join(os.path.dirname(torch.__file__), "lib"))
PY
):${LD_LIBRARY_PATH:-}"

# Make mesh_inpaint_processor importable
export PYTHONPATH="$APP_DIR/hy3dpaint/DifferentiableRenderer:${PYTHONPATH:-}"

exec python "$APP_DIR/gradio_app.py" \
  --model_path tencent/Hunyuan3D-2.1 \
  --subfolder hunyuan3d-dit-v2-1 \
  --texgen_model_path tencent/Hunyuan3D-2.1 \
  --low_vram_mode \
  --host ${GRADIO_HOST:-127.0.0.1} \
  --port ${GRADIO_PORT:-7860}
EOS
chmod +x run_hunyuan3d.sh

echo
echo "===================================="
echo "✓ Install complete."
echo "Run the app with:"
echo "  $APP_DIR/run_hunyuan3d.sh"
echo
echo "Tunnel from your laptop:"
echo "  ssh -i ~/.ssh/<KEY> -L ${PORT}:localhost:${PORT} ubuntu@<VM_IP>"
echo "  open http://localhost:${PORT}"
echo "===================================="
