#!/usr/bin/env bash
set -euo pipefail

# Hunyuan3D-2mv (Multiview) + Tailscale Deployment Script
# 
# Usage:
#   ./deploy_hunyuan_multiview.sh [TAILSCALE_AUTH_KEY] [MODEL_VARIANT]
#   
# Examples:
#   ./deploy_hunyuan_multiview.sh TAILSCALE_AUTH_KEY standard
#   ./deploy_hunyuan_multiview.sh TAILSCALE_AUTH_KEY turbo
#   ./deploy_hunyuan_multiview.sh "" fast  # no Tailscale

echo "======================================================================"
echo "🎭 Hunyuan3D-2mv (Multiview) Deployment with Tailscale"
echo "======================================================================"
echo "Starting deployment at $(date -Is)"

# Resolve repo root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Parameters
TAILSCALE_AUTH_KEY="${1:-${TAILSCALE_AUTH_KEY:-}}"
MODEL_VARIANT="${2:-standard}"  # standard | turbo | fast

echo "📋 Configuration:"
echo "   Stack: Hunyuan3D-2mv (Multiview)"
echo "   Model variant: $MODEL_VARIANT"
echo "   Tailscale: $([ -n "$TAILSCALE_AUTH_KEY" ] && echo "✅ Enabled" || echo "❌ Disabled")"
echo "   Repo: $REPO_ROOT"
echo ""

# Export variables for sub-scripts
export TAILSCALE_AUTH_KEY
export MODEL_VARIANT

# Step 1: Setup Tailscale first (if enabled)
if [ -n "$TAILSCALE_AUTH_KEY" ]; then
    echo "🔒 Step 1: Setting up Tailscale..."
    "$REPO_ROOT/networking/setup_tailscale.sh"
    echo ""
else
    echo "⚠️  Step 1: Skipping Tailscale setup (no auth key provided)"
    echo ""
fi

# Step 2: Setup Hunyuan3D-2mv
echo "🎭 Step 2: Setting up Hunyuan3D-2mv (Multiview)..."

# Set environment variables for Tailscale compatibility
if [ -n "$TAILSCALE_AUTH_KEY" ]; then
    export GRADIO_HOST="0.0.0.0"
    export GRADIO_PORT="7861"  # Different port from 2.1
fi

"$REPO_ROOT/stacks/hunyuan/scripts/install_hunyuan3d2mv_2404.sh"

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

# Check Hunyuan3D-2mv installation
if [ -f "$HOME/Hunyuan3D-2mv/run_hunyuan3d_mv.sh" ]; then
    echo "   ✅ Hunyuan3D-2mv installation complete"
else
    echo "   ❌ Hunyuan3D-2mv installation may have failed"
fi

# Display final access information
echo ""
echo "======================================================================"
echo "🎉 Hunyuan3D-2mv Deployment Complete!"
echo "======================================================================"
echo "Timestamp: $(date -Is)"
echo "Model variant: $MODEL_VARIANT"

if [ -n "$TAILSCALE_IP" ]; then
    echo ""
    echo "🌐 Access via Tailscale (recommended):"
    echo "   Hunyuan3D-2mv Web: http://$TAILSCALE_IP:7861"
    echo "   SSH Access:        ssh ubuntu@$TAILSCALE_IP"
    echo ""
    echo "🔗 Direct access from any of your Tailscale-enabled devices!"
else
    # Get public IP for fallback
    PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "unknown")
    echo ""
    echo "🔗 Access via SSH tunnel:"
    echo "   ssh -L 7861:localhost:7861 ubuntu@$PUBLIC_IP"
    echo "   Then open: http://localhost:7861"
fi

echo ""
echo "🎭 Hunyuan3D-2mv components installed:"
echo "   - Hunyuan3D-2mv multiview models (shape generation)"
echo "   - Hunyuan3D-2 texture models (compatible texturing)"
echo "   - Model variant: $MODEL_VARIANT"
echo "   - Run script: ~/Hunyuan3D-2mv/run_hunyuan3d_mv.sh"

echo ""
echo "🔧 Usage:"
echo "   # Start Hunyuan3D-2mv manually:"
echo "   ~/Hunyuan3D-2mv/run_hunyuan3d_mv.sh"
echo ""
echo "   # Or with custom settings:"
echo "   GRADIO_HOST=0.0.0.0 GRADIO_PORT=7861 ~/Hunyuan3D-2mv/run_hunyuan3d_mv.sh"
echo ""
if [ -n "$TAILSCALE_IP" ]; then
    echo "   # Check Tailscale connection:"
    echo "   sudo tailscale status"
    echo ""
fi
echo "🎨 Multiview features:"
echo "   - Upload multiple view images (front, left, back, etc.)"
echo "   - Better shape consistency than single-view"
echo "   - Supports standard, turbo, and fast variants"
echo ""
echo "Ready to generate amazing multiview 3D content! 🎨✨"