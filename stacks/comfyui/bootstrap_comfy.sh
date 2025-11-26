#!/usr/bin/env bash
set -euo pipefail

echo "[bootstrap] start $(date -Is)"

# Resolve repo root (…/comfy-stack)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SERVICE_USER="$(whoami)"
SERVICE_HOME="$HOME"
SERVICE_PATH="$SERVICE_HOME/ComfyUI"

# 0) System deps
sudo apt update
sudo apt install -y python3 python3-pip python3-venv git curl

# 1) ComfyUI
cd ~
if [ ! -d "ComfyUI" ]; then
  git clone https://github.com/comfyanonymous/ComfyUI.git
fi
cd ComfyUI
git pull || true

# 2) Python venv
if [ ! -d "comfy-env" ]; then
  python3 -m venv comfy-env
fi
# shellcheck disable=SC1091
source comfy-env/bin/activate
pip install --upgrade pip

# 3) ComfyUI deps
pip install -r requirements.txt

# 4) PyTorch (CUDA 12.8)
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

# 5) ComfyUI-Manager
mkdir -p custom_nodes
if [ ! -d "custom_nodes/comfyui-manager" ]; then
  git clone https://github.com/Comfy-Org/ComfyUI-Manager custom_nodes/comfyui-manager
else
  (cd custom_nodes/comfyui-manager && git pull || true)
fi
if [ -f "custom_nodes/comfyui-manager/requirements.txt" ]; then
  pip install -r custom_nodes/comfyui-manager/requirements.txt || true
fi

# 6) Small test checkpoint (skip if present)
mkdir -p models/checkpoints
if [ ! -f "models/checkpoints/v1-5-pruned-emaonly-fp16.safetensors" ]; then
  curl -L "https://huggingface.co/Comfy-Org/stable-diffusion-v1-5-archive/resolve/main/v1-5-pruned-emaonly-fp16.safetensors?download=true" \
    -o models/checkpoints/v1-5-pruned-emaonly-fp16.safetensors
fi

# 7) Install/enable systemd service
pkill -f "python $SERVICE_PATH/main.py" || true
sudo install -m 0644 -o root -g root "$REPO_ROOT/stacks/comfyui/systemd/comfyui.service" /etc/systemd/system/comfyui.service
# Patch service to current user/home
sudo sed -i "s#User=ubuntu#User=$SERVICE_USER#; s#Group=ubuntu#Group=$SERVICE_USER#; s#/home/ubuntu/ComfyUI#$SERVICE_PATH#g" /etc/systemd/system/comfyui.service
sudo systemctl daemon-reload
sudo systemctl enable --now comfyui

# 8) Setup Tailscale (if auth key provided)
"$REPO_ROOT/networking/setup_tailscale.sh" || echo "[bootstrap] Tailscale setup skipped (no auth key)"

# Get final access information
TAILSCALE_IP=$(sudo tailscale ip -4 2>/dev/null || echo "not-configured")
if [ "$TAILSCALE_IP" != "not-configured" ]; then
    echo "[bootstrap] done $(date -Is). Tailscale access: http://$TAILSCALE_IP:8188 | SSH: ssh ubuntu@$TAILSCALE_IP"
else
    echo "[bootstrap] done $(date -Is). Local tunnel: ssh -i ~/.ssh/<KEY> -L 8188:localhost:8188 ubuntu@<VM_IP> -> http://localhost:8188"
fi
