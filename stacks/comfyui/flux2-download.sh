#!/usr/bin/env bash
set -euo pipefail

# Flux 2 (dev) model downloader for ComfyUI.
# Usage:
#   ./stacks/comfyui/flux2-download.sh                # defaults to FLUX.2-dev repo
#   MODEL_REPO=black-forest-labs/FLUX.1-dev ./stacks/comfyui/flux2-download.sh
# Env:
#   HF_TOKEN          - optional Hugging Face token for gated repos
#   MODEL_REPO        - HF repo id to download from (default: black-forest-labs/FLUX.2-dev)
#   MODEL_INCLUDE_PAT - comma-separated patterns to include (default: "*.safetensors")

cd ~/ComfyUI
# shellcheck disable=SC1091
source comfy-env/bin/activate

pip install -q --upgrade "huggingface_hub>=0.36,<1.0" hf-transfer || true
export HF_HUB_ENABLE_HF_TRANSFER=1

MODEL_REPO="${MODEL_REPO:-black-forest-labs/FLUX.2-dev}"
MODEL_INCLUDE_PAT="${MODEL_INCLUDE_PAT:-*.safetensors}"
TMP_DIR="$(mktemp -d -t flux2-model-XXXX)"
export MODEL_REPO MODEL_INCLUDE_PAT TMP_DIR HF_TOKEN

echo "📥 Downloading Flux models from $MODEL_REPO (include: $MODEL_INCLUDE_PAT)"
python - <<'PY'
import os
from huggingface_hub import snapshot_download

repo = os.environ.get("MODEL_REPO", "black-forest-labs/FLUX.2-dev")
patterns = [p.strip() for p in os.environ.get("MODEL_INCLUDE_PAT", "*.safetensors").split(",") if p.strip()]
token = os.environ.get("HF_TOKEN") or None
tmp_dir = os.environ["TMP_DIR"]

snapshot_download(
    repo_id=repo,
    local_dir=tmp_dir,
    allow_patterns=patterns,
    token=token,
    resume_download=True,
    local_dir_use_symlinks=False,
)
PY

mkdir -p models/diffusion_models models/vae models/text_encoders

echo "📂 Placing model files into ComfyUI directories..."
shopt -s nullglob
for f in "$TMP_DIR"/**/*.safetensors "$TMP_DIR"/*.safetensors; do
  rel="${f#$TMP_DIR/}"           # keep original subdir
  base="$(basename "$f")"
  case "$rel" in
    text_encoder/*|*text_encoder*|*text-encoder*|*textencoder*|*clip*|*CLIP*|*t5*|*T5*)
      dest="models/text_encoders"
      ;;
    vae/*|*vae*|*VAE*|ae.safetensors)
      dest="models/vae"
      ;;
    *)
      dest="models/diffusion_models"
      ;;
  esac
  echo " - $rel -> $dest/"
  mv -f "$f" "$dest/"
done
shopt -u nullglob

rm -rf "$TMP_DIR"
deactivate || true

if systemctl list-unit-files | grep -q '^comfyui\.service'; then
  sudo systemctl restart comfyui || true
fi

IP=$(hostname -I | awk '{print $1}')
echo "✅ Flux models installed. Open ComfyUI at: http://$IP:8188"
