#!/usr/bin/env bash
set -euo pipefail

# Hunyuan3D-2mv Optimized Deployment for 100GB VPS
# 
# Usage:
#   ./deploy_hunyuan_2mv_optimized.sh [TAILSCALE_AUTH_KEY] [MODEL_VARIANT]
#   
# Examples:
#   ./deploy_hunyuan_2mv_optimized.sh TAILSCALE_AUTH_KEY standard
#   ./deploy_hunyuan_2mv_optimized.sh TAILSCALE_AUTH_KEY turbo
#   ./deploy_hunyuan_2mv_optimized.sh "" fast  # no Tailscale

echo "======================================================================"
echo "🎭 Hunyuan3D-2mv Optimized Deployment (100GB VPS Friendly)"
echo "======================================================================"
echo "Starting optimized deployment at $(date -Is)"

# Resolve repo root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Parameters
TAILSCALE_AUTH_KEY="${1:-${TAILSCALE_AUTH_KEY:-}}"
MODEL_VARIANT="${2:-standard}"  # standard | turbo | fast

echo "📋 Configuration:"
echo "   Stack: Hunyuan3D-2mv (Multiview Only - Optimized)"
echo "   Model variant: $MODEL_VARIANT"
echo "   Tailscale: $([ -n "$TAILSCALE_AUTH_KEY" ] && echo "✅ Enabled" || echo "❌ Disabled")"
echo "   Repo: $REPO_ROOT"
echo "   Storage: Optimized for 100GB VPS (~35GB total)"
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

# Step 2: Setup Hunyuan3D-2mv with optimizations
echo "🎭 Step 2: Setting up Hunyuan3D-2mv (Optimized for 100GB VPS)..."

# Set environment variables for Tailscale compatibility
if [ -n "$TAILSCALE_AUTH_KEY" ]; then
    export GRADIO_HOST="0.0.0.0"
    export GRADIO_PORT="7861"
fi

# Use the optimized installation script
"$REPO_ROOT/stacks/hunyuan/scripts/install_hunyuan3d2mv_2404.sh"

# Step 3: Additional optimizations for 100GB VPS
echo "🧹 Step 3: Applying additional storage optimizations..."

# Clean any remaining cache files
echo "   Cleaning additional cache files..."
rm -rf ~/.cache/pip/* || true
rm -rf ~/.cache/huggingface/hub/*--partial* || true
rm -rf ~/Hunyuan3D-2mv/.git/objects/pack/*.pack || true

# Optimize git repository to save space
if [ -d "$HOME/Hunyuan3D-2mv/.git" ]; then
    cd "$HOME/Hunyuan3D-2mv"
    git gc --aggressive --prune=now || true
fi

# Create startup script with monitoring
cat > "$HOME/Hunyuan3D-2mv/start_optimized.sh" << 'EOS'
#!/usr/bin/env bash
set -Eeuo pipefail

echo "🎭 Starting Hunyuan3D-2mv with monitoring..."
echo "💾 Checking available storage..."

# Show disk usage
df -h ~ | head -2
echo ""

# Start the application
cd ~/Hunyuan3D-2mv
./run_hunyuan3d_mv.sh
EOS

chmod +x "$HOME/Hunyuan3D-2mv/start_optimized.sh"

# Final verification
echo ""
echo "🧪 Final Step: Verifying optimized installation..."

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

# Check storage usage
echo ""
echo "💾 Storage Usage Summary:"
if [ -d "$HOME/Hunyuan3D-2mv" ]; then
    MODEL_SIZE=$(du -sh "$HOME/Hunyuan3D-2mv/models" 2>/dev/null | cut -f1 || echo "unknown")
    TOTAL_SIZE=$(du -sh "$HOME/Hunyuan3D-2mv" 2>/dev/null | cut -f1 || echo "unknown")
    echo "   📦 Models: $MODEL_SIZE"
    echo "   📁 Total installation: $TOTAL_SIZE"
fi

# Display disk space
echo ""
echo "🗂️  Available disk space:"
df -h ~ | head -2

# Display final access information
echo ""
echo "======================================================================"
echo "🎉 Hunyuan3D-2mv Optimized Deployment Complete!"
echo "======================================================================"
echo "Timestamp: $(date -Is)"
echo "Model variant: $MODEL_VARIANT"
echo "Storage footprint: ~35GB (optimized for 100GB VPS)"

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
echo "🎭 Hunyuan3D-2mv features:"
echo "   ✅ Multiview shape generation (front, left, back, etc.)"
echo "   ✅ Single-view to 3D conversion"
echo "   ✅ Multiple quality variants (standard/turbo/fast)"
echo "   ✅ Optimized storage (~35GB total)"
echo "   ✅ Low VRAM mode enabled"
echo ""

echo "🔧 Usage:"
echo "   # Start with monitoring:"
echo "   ~/Hunyuan3D-2mv/start_optimized.sh"
echo ""
echo "   # Or start directly:"
echo "   ~/Hunyuan3D-2mv/run_hunyuan3d_mv.sh"
echo ""
echo "   # With custom settings:"
echo "   GRADIO_HOST=0.0.0.0 GRADIO_PORT=7861 ~/Hunyuan3D-2mv/run_hunyuan3d_mv.sh"
echo ""

if [ -n "$TAILSCALE_IP" ]; then
    echo "   # Check Tailscale connection:"
    echo "   sudo tailscale status"
    echo ""
fi

echo "💡 Tips for 100GB VPS:"
echo "   - Monitor storage with: df -h ~"
echo "   - Models are stored locally (not in cache)"
echo "   - Git repository optimized for space"
echo "   - Use 'turbo' variant for faster generation with less VRAM"
echo "   - Clear pip cache if needed: pip cache purge"
echo ""

echo "🎨 Ready to generate amazing multiview 3D content! 🎨✨"