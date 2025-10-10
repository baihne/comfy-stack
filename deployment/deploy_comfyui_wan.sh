#!/usr/bin/env bash
set -euo pipefail

# ComfyUI + Wan 2.2 + Tailscale Deployment Script
# 
# Usage:
#   ./deploy_comfyui_wan.sh [MODEL_VARIANT] [TAILSCALE_AUTH_KEY]
#
# Examples:
#   ./deploy_comfyui_wan.sh I2V_A14B tskey-auth-your-key
#   ./deploy_comfyui_wan.sh T2V_A14B
#   ./deploy_comfyui_wan.sh TI2V_5B

echo "======================================================================"
echo "🎨 ComfyUI + Wan 2.2 Deployment with Tailscale"
echo "======================================================================"
echo "Starting deployment at $(date -Is)"

# Resolve repo root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Parameters
MODEL_VARIANT="${1:-I2V_A14B}"
TAILSCALE_AUTH_KEY="${2:-${TAILSCALE_AUTH_KEY:-}}"

echo "📋 Configuration:"
echo "   Model: $MODEL_VARIANT"
echo "   Tailscale: $([ -n "$TAILSCALE_AUTH_KEY" ] && echo "✅ Enabled" || echo "❌ Disabled")"
echo "   Repo: $REPO_ROOT"
echo ""

# Export auth key for sub-scripts
export TAILSCALE_AUTH_KEY

# Step 1: Setup Tailscale first (if enabled)
if [ -n "$TAILSCALE_AUTH_KEY" ]; then
    echo "🔒 Step 1: Setting up Tailscale..."
    "$REPO_ROOT/networking/setup_tailscale.sh"
    echo ""
else
    echo "⚠️  Step 1: Skipping Tailscale setup (no auth key provided)"
    echo ""
fi

# Step 2: Setup ComfyUI
echo "🎨 Step 2: Setting up ComfyUI..."
"$REPO_ROOT/stacks/comfyui/bootstrap_comfy.sh"

# Step 3: Install model
echo ""
echo "📥 Step 3: Installing $MODEL_VARIANT model..."
"$REPO_ROOT/stacks/comfyui/wan22-download.sh" "$MODEL_VARIANT"

# Final verification
echo ""
echo "🧪 Final Step: Verifying installation..."

# Check Tailscale status
TAILSCALE_IP=""
if command -v tailscale >/dev/null 2>&1; then
    TAILSCALE_IP=$(sudo tailscale ip -4 2>/dev/null || echo "")
    if [ -n "$TAILSCALE_IP" ]; then
        echo "   ✅ Tailscale connected: $TAILSCALE_IP"
    else
        echo "   ⚠️  Tailscale installed but not connected"
    fi
else
    echo "   ❌ Tailscale not installed"
fi

# Check ComfyUI service
if systemctl is-active --quiet comfyui; then
    echo "   ✅ ComfyUI service is running"
else
    echo "   ❌ ComfyUI service not running"
    sudo systemctl status comfyui --no-pager || true
fi

# Display final access information
echo ""
echo "======================================================================"
echo "🎉 ComfyUI Deployment Complete!"
echo "======================================================================"
echo "Model: $MODEL_VARIANT"
echo "Timestamp: $(date -Is)"

if [ -n "$TAILSCALE_IP" ]; then
    echo ""
    echo "🌐 Access via Tailscale (recommended):"
    echo "   ComfyUI Web: http://$TAILSCALE_IP:8188"
    echo "   SSH Access:  ssh ubuntu@$TAILSCALE_IP"
    echo ""
    echo "🔗 Direct access from any of your Tailscale-enabled devices!"
else
    # Get public IP for fallback
    PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "unknown")
    echo ""
    echo "🔗 Access via SSH tunnel:"
    echo "   ssh -L 8188:localhost:8188 ubuntu@$PUBLIC_IP"
    echo "   Then open: http://localhost:8188"
fi

echo ""
echo "📁 Wan 2.2 model files installed:"
case "$MODEL_VARIANT" in
    TI2V_5B)
        echo "   - wan2.2_ti2v_5B_fp16.safetensors"
        echo "   - wan2.2_vae.safetensors"
        echo "   - umt5_xxl_fp8_e4m3fn_scaled.safetensors"
        ;;
    T2V_A14B)
        echo "   - wan2.2_t2v_high_noise_14B_fp8_scaled.safetensors"
        echo "   - wan2.2_t2v_low_noise_14B_fp8_scaled.safetensors"
        echo "   - wan_2.1_vae.safetensors"
        echo "   - umt5_xxl_fp8_e4m3fn_scaled.safetensors"
        echo "   - T2V LoRAs (lightx2v 4-step)"
        ;;
    I2V_A14B)
        echo "   - wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors"
        echo "   - wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors"
        echo "   - wan_2.1_vae.safetensors"
        echo "   - umt5_xxl_fp8_e4m3fn_scaled.safetensors"
        ;;
esac

echo ""
echo "🔧 Useful commands:"
echo "   sudo systemctl status comfyui    # Check service status"
echo "   sudo journalctl -u comfyui -f    # View real-time logs"
if [ -n "$TAILSCALE_IP" ]; then
    echo "   sudo tailscale status            # Check Tailscale connection"
fi
echo ""
echo "Ready to generate amazing videos! 🎥✨"