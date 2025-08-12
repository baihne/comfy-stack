#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ~/comfy-stack/scripts/wan22-download.sh TI2V_5B
#   ~/comfy-stack/scripts/wan22-download.sh T2V_A14B
#   ~/comfy-stack/scripts/wan22-download.sh I2V_A14B

cd ~/ComfyUI
# shellcheck disable=SC1091
source comfy-env/bin/activate

# modern HF CLI (uses `hf download`)
pip install -q --upgrade "huggingface_hub>=0.25"

mkdir -p models/diffusion_models models/vae models/text_encoders models/loras /tmp/wan22

VARIANT="${1:-I2V_A14B}"   # TI2V_5B | T2V_A14B | I2V_A14B
REPO="Comfy-Org/Wan_2.2_ComfyUI_Repackaged"

download() {
  hf download "$REPO" --include "$1" --local-dir /tmp/wan22
}

case "$VARIANT" in
  TI2V_5B)
    # 5B model + Wan2.2 VAE + UMT5-XXL (FP8)
    download "split_files/diffusion_models/wan2.2_ti2v_5B_fp16.safetensors"
    download "split_files/vae/wan2.2_vae.safetensors"
    download "split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
    mv -f /tmp/wan22/split_files/diffusion_models/wan2.2_ti2v_5B_fp16.safetensors models/diffusion_models/
    mv -f /tmp/wan22/split_files/vae/wan2.2_vae.safetensors models/vae/
    mv -f /tmp/wan22/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors models/text_encoders/
    ;;

  T2V_A14B)
    # 14B Text-to-Video (two shards) + Wan2.1 VAE + UMT5-XXL (FP8) + LoRAs
    download "split_files/diffusion_models/wan2.2_t2v_high_noise_14B_fp8_scaled.safetensors"
    download "split_files/diffusion_models/wan2.2_t2v_low_noise_14B_fp8_scaled.safetensors"
    download "split_files/vae/wan_2.1_vae.safetensors"
    download "split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
    # NEW: T2V LoRAs
    download "split_files/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors"
    download "split_files/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_low_noise.safetensors"

    mv -f /tmp/wan22/split_files/diffusion_models/wan2.2_t2v_*_14B_fp8_scaled.safetensors models/diffusion_models/
    mv -f /tmp/wan22/split_files/vae/wan_2.1_vae.safetensors models/vae/
    mv -f /tmp/wan22/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors models/text_encoders/
    mv -f /tmp/wan22/split_files/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_*.safetensors models/loras/
    ;;

  I2V_A14B|*)
    # 14B Image-to-Video (two shards) + Wan2.1 VAE + UMT5-XXL (FP8)
    download "split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors"
    download "split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors"
    download "split_files/vae/wan_2.1_vae.safetensors"
    download "split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
    mv -f /tmp/wan22/split_files/diffusion_models/wan2.2_i2v_*_14B_fp8_scaled.safetensors models/diffusion_models/
    mv -f /tmp/wan22/split_files/vae/wan_2.1_vae.safetensors models/vae/
    mv -f /tmp/wan22/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors models/text_encoders/
    ;;
esac

deactivate || true

# Restart ComfyUI if the service exists, else start a background process
if systemctl list-unit-files | grep -q '^comfyui\.service'; then
  sudo systemctl restart comfyui || true
else
  echo "comfyui.service not found; starting ComfyUI in background."
  nohup ~/ComfyUI/comfy-env/bin/python ~/ComfyUI/main.py --listen 127.0.0.1 --port 8188 > ~/comfyui.log 2>&1 &
fi

echo "Wan 2.2 ($VARIANT) installed. LoRAs (if T2V) placed in models/loras/. Tunnel to http://localhost:8188"
