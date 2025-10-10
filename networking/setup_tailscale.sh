#!/usr/bin/env bash
set -euo pipefail

# Tailscale Setup Script for Automated VPS Provisioning
# This script is designed to be called from bootstrap_comfy.sh or standalone

echo "[tailscale] Starting Tailscale setup $(date -Is)"

# Check if auth key is provided via environment variable or parameter
TAILSCALE_AUTH_KEY="${TAILSCALE_AUTH_KEY:-${1:-}}"

if [ -z "$TAILSCALE_AUTH_KEY" ]; then
    echo "[tailscale] No auth key provided. Skipping Tailscale setup."
    echo "[tailscale] To setup later, export TAILSCALE_AUTH_KEY=your-key and run this script."
    exit 0
fi

# Install dependencies
sudo apt update
sudo apt install -y curl

# Add Tailscale repository
echo "[tailscale] Adding Tailscale repository..."

# Import Tailscale GPG key properly
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null

# Detect Ubuntu version
UBUNTU_VERSION=$(lsb_release -cs 2>/dev/null || echo "focal")
echo "[tailscale] Detected Ubuntu version: $UBUNTU_VERSION"

# Add repository with detected version
echo "deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/ubuntu $UBUNTU_VERSION main" | sudo tee /etc/apt/sources.list.d/tailscale.list > /dev/null

# Update and install Tailscale
sudo apt update
sudo apt install -y tailscale

# Start Tailscale daemon
sudo systemctl enable tailscaled
sudo systemctl start tailscaled

# Authenticate with the provided key
echo "[tailscale] Authenticating with Tailscale network..."
sudo tailscale up --authkey="$TAILSCALE_AUTH_KEY" --ssh --accept-routes

# Wait a moment for connection to establish
sleep 3

# Get and display Tailscale IP
TAILSCALE_IP=$(sudo tailscale ip -4 2>/dev/null || echo "pending")
echo "[tailscale] Tailscale IP: $TAILSCALE_IP"
echo "[tailscale] Device registered in Tailscale network"

# Configure ComfyUI to be accessible via Tailscale
# Update ComfyUI service to bind to all interfaces if it exists
if [ -f "/etc/systemd/system/comfyui.service" ]; then
    echo "[tailscale] Configuring ComfyUI for Tailscale access..."
    
    # Create a backup
    sudo cp /etc/systemd/system/comfyui.service /etc/systemd/system/comfyui.service.backup
    
    # Update service to bind to all interfaces (0.0.0.0) instead of localhost
    sudo sed -i 's/--listen 127\.0\.0\.1/--listen 0.0.0.0/g' /etc/systemd/system/comfyui.service
    
    # Reload and restart
    sudo systemctl daemon-reload
    sudo systemctl restart comfyui || true
    
    echo "[tailscale] ComfyUI configured for network access"
fi

echo "[tailscale] Setup complete $(date -Is)"
echo "[tailscale] Access ComfyUI via: http://$TAILSCALE_IP:8188"
echo "[tailscale] SSH access via: ssh ubuntu@$TAILSCALE_IP"