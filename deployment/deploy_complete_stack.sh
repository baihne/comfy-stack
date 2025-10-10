#!/usr/bin/env bash
set -euo pipefail

# Master Deployment Script for AI Stacks + Tailscale
#
# Usage:
#   ./deploy_complete_stack.sh [STACK] [MODEL_VARIANT] [TAILSCALE_AUTH_KEY]
#
# Stacks:
#   comfy     - ComfyUI + Wan 2.2 models (default)
#   hunyuan   - Hunyuan3D 2.1
#   both      - Both ComfyUI and Hunyuan3D
#
# Examples:
#   ./deploy_complete_stack.sh comfy I2V_A14B TAILSCALE_AUTH_KEY
#   ./deploy_complete_stack.sh hunyuan "" TAILSCALE_AUTH_KEY
#   ./deploy_complete_stack.sh both I2V_A14B TAILSCALE_AUTH_KEY

echo "======================================================================"
echo "🚀 AI Stack Complete Deployment with Tailscale"
echo "======================================================================"
echo "Starting deployment at $(date -Is)"

# Resolve repo root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Parameters
STACK="${1:-comfy}"
MODEL_VARIANT="${2:-I2V_A14B}"
TAILSCALE_AUTH_KEY="${3:-${TAILSCALE_AUTH_KEY:-}}"

# Support old usage (backwards compatibility)
if [[ "$STACK" =~ ^(TI2V_5B|T2V_A14B|I2V_A14B)$ ]]; then
    MODEL_VARIANT="$STACK"
    STACK="comfy"
    TAILSCALE_AUTH_KEY="${2:-${TAILSCALE_AUTH_KEY:-}}"
fi

echo "📋 Configuration:"
echo "   Stack: $STACK"
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

# Step 2: Deploy requested stack(s)
case "$STACK" in
    "comfy")
        echo "🎨 Step 2: Setting up ComfyUI..."
        "$REPO_ROOT/stacks/comfyui/bootstrap_comfy.sh"
        
        echo ""
        echo "📥 Step 3: Installing $MODEL_VARIANT model..."
        "$REPO_ROOT/stacks/comfyui/wan22-download.sh" "$MODEL_VARIANT"
        ;;
        
    "hunyuan")
        echo "🎭 Step 2: Setting up Hunyuan3D..."
        # Set environment variables for Tailscale compatibility
        if [ -n "$TAILSCALE_AUTH_KEY" ]; then
            export GRADIO_HOST="0.0.0.0"
        fi
        "$REPO_ROOT/stacks/hunyuan/scripts/install_hunyuan3d21_2404.sh"
        ;;
        
    "both")
        echo "🎨 Step 2a: Setting up ComfyUI..."
        "$REPO_ROOT/stacks/comfyui/bootstrap_comfy.sh"
        
        echo ""
        echo "📥 Step 2b: Installing $MODEL_VARIANT model..."
        "$REPO_ROOT/stacks/comfyui/wan22-download.sh" "$MODEL_VARIANT"
        
        echo ""
        echo "🎭 Step 2c: Setting up Hunyuan3D..."
        # Set environment variables for Tailscale compatibility
        if [ -n "$TAILSCALE_AUTH_KEY" ]; then
            export GRADIO_HOST="0.0.0.0"
            export GRADIO_PORT="7860"
        fi
        "$REPO_ROOT/stacks/hunyuan/scripts/install_hunyuan3d21_2404.sh"
        ;;
        
    *)
        echo "❌ Error: Unknown stack '$STACK'"
        echo "Supported stacks: comfy, hunyuan, both"
        exit 1
        ;;
esac

# Final verification and status
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

# Check services based on stack
case "$STACK" in
    "comfy")
        if systemctl is-active --quiet comfyui; then
            echo "   ✅ ComfyUI service is running"
        else
            echo "   ❌ ComfyUI service not running"
            sudo systemctl status comfyui --no-pager || true
        fi
        ;;
    "hunyuan")
        if [ -f "$HOME/Hunyuan3D-2.1/run_hunyuan3d.sh" ]; then
            echo "   ✅ Hunyuan3D installation complete"
        else
            echo "   ❌ Hunyuan3D installation may have failed"
        fi
        ;;
    "both")
        if systemctl is-active --quiet comfyui; then
            echo "   ✅ ComfyUI service is running"
        else
            echo "   ❌ ComfyUI service not running"
        fi
        if [ -f "$HOME/Hunyuan3D-2.1/run_hunyuan3d.sh" ]; then
            echo "   ✅ Hunyuan3D installation complete"
        else
            echo "   ❌ Hunyuan3D installation may have failed"
        fi
        ;;
esac

# Display final access information
echo ""
echo "======================================================================"
echo "🎉 Deployment Complete!"
echo "======================================================================"
echo "Stack: $STACK"
if [[ "$STACK" == "comfy" || "$STACK" == "both" ]]; then
    echo "Model: $MODEL_VARIANT"
fi
echo "Timestamp: $(date -Is)"

if [ -n "$TAILSCALE_IP" ]; then
    echo ""
    echo "🌐 Access via Tailscale (recommended):"
    echo "   SSH Access:  ssh ubuntu@$TAILSCALE_IP"
    
    if [[ "$STACK" == "comfy" || "$STACK" == "both" ]]; then
        echo "   ComfyUI Web: http://$TAILSCALE_IP:8188"
    fi
    
    if [[ "$STACK" == "hunyuan" || "$STACK" == "both" ]]; then
        echo "   Hunyuan3D:   http://$TAILSCALE_IP:7860"
    fi
    
    echo ""
    echo "🔗 Direct access from any of your Tailscale-enabled devices!"
else
    # Get public IP for fallback
    PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "unknown")
    echo ""
    echo "🔗 Access via SSH tunnel:"
    
    if [[ "$STACK" == "comfy" || "$STACK" == "both" ]]; then
        echo "   ssh -L 8188:localhost:8188 ubuntu@$PUBLIC_IP"
        echo "   Then open ComfyUI: http://localhost:8188"
    fi
    
    if [[ "$STACK" == "hunyuan" || "$STACK" == "both" ]]; then
        echo "   ssh -L 7860:localhost:7860 ubuntu@$PUBLIC_IP"
        echo "   Then open Hunyuan3D: http://localhost:7860"
    fi
fi

# Show installed components
if [[ "$STACK" == "comfy" || "$STACK" == "both" ]]; then
    echo ""
    echo "📁 ComfyUI Wan 2.2 model files installed:"
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
fi

if [[ "$STACK" == "hunyuan" || "$STACK" == "both" ]]; then
    echo ""
    echo "🎭 Hunyuan3D components installed:"
    echo "   - Hunyuan3D 2.1 models (cached from Hugging Face)"
    echo "   - Custom rasterizer and mesh inpaint processor"
    echo "   - RealESRGAN texture upscaling"
    echo "   - Run script: ~/Hunyuan3D-2.1/run_hunyuan3d.sh"
fi

echo ""
echo "🔧 Useful commands:"
if [[ "$STACK" == "comfy" || "$STACK" == "both" ]]; then
    echo "   sudo systemctl status comfyui    # Check ComfyUI service"
    echo "   sudo journalctl -u comfyui -f    # View ComfyUI logs"
fi
if [[ "$STACK" == "hunyuan" || "$STACK" == "both" ]]; then
    echo "   ~/Hunyuan3D-2.1/run_hunyuan3d.sh # Start Hunyuan3D manually"
fi
if [ -n "$TAILSCALE_IP" ]; then
    echo "   sudo tailscale status            # Check Tailscale connection"
fi
echo ""
echo "Ready to generate amazing content! 🎨✨"