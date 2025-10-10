#!/usr/bin/env bash
# Verification script to test all paths and dependencies

echo "🔍 Verifying comfy-stack setup..."

# Check repo structure
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "📁 Repository root: $REPO_ROOT"

echo ""
echo "📋 Checking file structure..."

# Critical files that should exist
FILES_TO_CHECK=(
    "stacks/comfyui/bootstrap_comfy.sh"
    "stacks/comfyui/wan22-download.sh"
    "stacks/comfyui/systemd/comfyui.service"
    "stacks/hunyuan/scripts/install_hunyuan3d21_2404.sh"
    "networking/setup_tailscale.sh"
    "networking/install_tailscale_vps.sh"
    "deployment/deploy_comfyui_wan.sh"
    "deployment/deploy_hunyuan.sh"
    "deployment/deploy_complete_stack.sh"
    "deployment/cloud-init/user-data.yaml"
)

ALL_GOOD=true
for file in "${FILES_TO_CHECK[@]}"; do
    if [ -f "$REPO_ROOT/$file" ]; then
        echo "   ✅ $file"
    else
        echo "   ❌ Missing: $file"
        ALL_GOOD=false
    fi
done

echo ""
echo "🔧 Checking script executability..."
EXEC_SCRIPTS=(
    "stacks/comfyui/bootstrap_comfy.sh"
    "stacks/comfyui/wan22-download.sh"
    "stacks/hunyuan/scripts/install_hunyuan3d21_2404.sh"
    "networking/setup_tailscale.sh"
    "networking/install_tailscale_vps.sh"
    "deployment/deploy_comfyui_wan.sh"
    "deployment/deploy_hunyuan.sh"
    "deployment/deploy_complete_stack.sh"
)

for script in "${EXEC_SCRIPTS[@]}"; do
    if [ -x "$REPO_ROOT/$script" ]; then
        echo "   ✅ $script (executable)"
    else
        echo "   ⚠️  $script (not executable)"
        ALL_GOOD=false
    fi
done

echo ""
echo "📝 Checking critical path references..."

# Check bootstrap_comfy.sh paths
if grep -q "stacks/comfyui/systemd/comfyui.service" "$REPO_ROOT/stacks/comfyui/bootstrap_comfy.sh"; then
    echo "   ✅ bootstrap_comfy.sh: systemd path correct"
else
    echo "   ❌ bootstrap_comfy.sh: systemd path incorrect"
    ALL_GOOD=false
fi

if grep -q "networking/setup_tailscale.sh" "$REPO_ROOT/stacks/comfyui/bootstrap_comfy.sh"; then
    echo "   ✅ bootstrap_comfy.sh: networking path correct"
else
    echo "   ❌ bootstrap_comfy.sh: networking path incorrect"
    ALL_GOOD=false
fi

# Check deployment scripts
for script in deploy_comfyui_wan.sh deploy_hunyuan.sh deploy_complete_stack.sh; do
    if grep -q "networking/setup_tailscale.sh" "$REPO_ROOT/deployment/$script"; then
        echo "   ✅ $script: networking path correct"
    else
        echo "   ❌ $script: networking path incorrect"
        ALL_GOOD=false
    fi
    
    if grep -q "stacks/.*/" "$REPO_ROOT/deployment/$script"; then
        echo "   ✅ $script: stacks paths present"
    else
        echo "   ❌ $script: stacks paths missing"
        ALL_GOOD=false
    fi
done

echo ""
if [ "$ALL_GOOD" = true ]; then
    echo "🎉 All checks passed! Setup is ready."
    echo ""
    echo "🚀 Usage examples:"
    echo "   ./deployment/deploy_comfyui_wan.sh I2V_A14B TAILSCALE_AUTH_KEY"
    echo "   ./deployment/deploy_hunyuan.sh TAILSCALE_AUTH_KEY"
    echo "   ./deployment/deploy_complete_stack.sh both I2V_A14B TAILSCALE_AUTH_KEY"
else
    echo "❌ Some issues found. Please fix the above errors."
    exit 1
fi