#!/usr/bin/env bash
set -euo pipefail

# Hunyuan3D 2.1 + Tailscale Deployment Script
# 
# Usage:
#   ./deploy_hunyuan.sh [TAILSCALE_AUTH_KEY]
#   
# Examples:
#   ./deploy_hunyuan.sh TAILSCALE_AUTH_KEY
#   ./deploy_hunyuan.sh

echo "======================================================================"
echo "🎭 Hunyuan3D 2.1 Deployment with Tailscale"
echo "======================================================================"
echo "Starting deployment at $(date -Is)"

# Resolve repo root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Parameters
TAILSCALE_AUTH_KEY="${1:-${TAILSCALE_AUTH_KEY:-}}"

echo "📋 Configuration:"
echo "   Stack: Hunyuan3D 2.1"
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

# Step 2: Setup Hunyuan3D
echo "🎭 Step 2: Setting up Hunyuan3D 2.1..."

# Set environment variables for Tailscale compatibility
if [ -n "$TAILSCALE_AUTH_KEY" ]; then
    export GRADIO_HOST="0.0.0.0"
    export GRADIO_PORT="7860"
fi

"$REPO_ROOT/stacks/hunyuan/scripts/install_hunyuan3d21_2404.sh"

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

# Check Hunyuan3D installation
if [ -f "$HOME/Hunyuan3D-2.1/run_hunyuan3d.sh" ]; then
    echo "   ✅ Hunyuan3D installation complete"
else
    echo "   ❌ Hunyuan3D installation may have failed"
fi

# Display final access information
echo ""
echo "======================================================================"
echo "🎉 Hunyuan3D Deployment Complete!"
echo "======================================================================"
echo "Timestamp: $(date -Is)"

if [ -n "$TAILSCALE_IP" ]; then
    echo ""
    echo "🌐 Access via Tailscale (recommended):"
    echo "   Hunyuan3D Web: http://$TAILSCALE_IP:7860"
    echo "   SSH Access:    ssh ubuntu@$TAILSCALE_IP"
    echo ""
    echo "🔗 Direct access from any of your Tailscale-enabled devices!"
else
    # Get public IP for fallback
    PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "unknown")
    echo ""
    echo "🔗 Access via SSH tunnel:"
    echo "   ssh -L 7860:localhost:7860 ubuntu@$PUBLIC_IP"
    echo "   Then open: http://localhost:7860"
fi

echo ""
echo "🎭 Hunyuan3D components installed:"
echo "   - Hunyuan3D 2.1 models (cached from Hugging Face)"
echo "   - Custom rasterizer and mesh inpaint processor"
echo "   - RealESRGAN texture upscaling"
echo "   - Run script: ~/Hunyuan3D-2.1/run_hunyuan3d.sh"

echo ""
echo "🔧 Usage:"
echo "   # Start Hunyuan3D manually:"
echo "   ~/Hunyuan3D-2.1/run_hunyuan3d.sh"
echo ""
if [ -n "$TAILSCALE_IP" ]; then
    echo "   # Check Tailscale connection:"
    echo "   sudo tailscale status"
    echo ""
fi
echo "Ready to generate amazing 3D content! 🎨✨"