#!/usr/bin/env bash
set -euo pipefail

# ComfyUI + Flux 2 (full upstream) Deployment Script
#
# Usage:
#   ./deployment/deploy_comfyui_flux2_full.sh [TAILSCALE_AUTH_KEY]
# Env:
#   HF_TOKEN          - Hugging Face token if the Flux repo is gated
#   MODEL_REPO        - Override Flux repo (default: black-forest-labs/FLUX.2-dev)
#   MODEL_INCLUDE_PAT - Override include patterns (default: "*.safetensors")

echo "======================================================================"
echo "🎨 ComfyUI + Flux 2 (full) Deployment"
echo "======================================================================"
echo "Starting deployment at $(date -Is)"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TAILSCALE_AUTH_KEY="${1:-${TAILSCALE_AUTH_KEY:-}}"

echo "📋 Configuration:"
echo "   Flux repo: ${MODEL_REPO:-black-forest-labs/FLUX.2-dev}"
echo "   Tailscale: $([ -n "$TAILSCALE_AUTH_KEY" ] && echo '✅ Enabled' || echo '❌ Disabled')"
echo ""

export TAILSCALE_AUTH_KEY

if [ -n "$TAILSCALE_AUTH_KEY" ]; then
    echo "🔒 Step 1: Setting up Tailscale..."
    "$REPO_ROOT/networking/setup_tailscale.sh"
    echo ""
else
    echo "⚠️  Step 1: Skipping Tailscale setup (no auth key provided)"
    echo ""
fi

echo "🎨 Step 2: Bootstrapping ComfyUI..."
"$REPO_ROOT/stacks/comfyui/bootstrap_comfy.sh"

echo ""
echo "📥 Step 3: Installing Flux 2 (full) models..."
"$REPO_ROOT/stacks/comfyui/flux2-download.sh"

echo ""
echo "🧪 Final Step: Verifying installation..."

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

if systemctl is-active --quiet comfyui; then
    echo "   ✅ ComfyUI service is running"
else
    echo "   ❌ ComfyUI service not running"
    sudo systemctl status comfyui --no-pager || true
fi

echo ""
echo "======================================================================"
echo "🎉 ComfyUI + Flux 2 (full) Deployment Complete!"
echo "======================================================================"
echo "Timestamp: $(date -Is)"

if [ -n "$TAILSCALE_IP" ]; then
    echo "🌐 Access via Tailscale: http://$TAILSCALE_IP:8188"
    echo "SSH: ssh ubuntu@$TAILSCALE_IP"
else
    PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "unknown")
    echo "🔗 Access via SSH tunnel:"
    echo "   ssh -L 8188:localhost:8188 ubuntu@$PUBLIC_IP"
    echo "   Then open: http://localhost:8188"
fi

echo ""
echo "Notes:"
echo " - Set HF_TOKEN if the Flux repo is gated."
echo " - Override MODEL_REPO/MODEL_INCLUDE_PAT to target a different Flux build."
