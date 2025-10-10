#!/bin/bash

# Tailscale Installation Script for Ubuntu/Debian VPS
# Usage: ./install_tailscale_vps.sh [AUTH_KEY]
# If no AUTH_KEY is provided, manual authentication will be required

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Tailscale VPS Installation Script ===${NC}"
echo -e "${YELLOW}Starting Tailscale installation on $(lsb_release -d | cut -f2-)${NC}"

# Check if running as root or with sudo
if [[ $EUID -eq 0 ]]; then
    echo -e "${GREEN}✓ Running with root privileges${NC}"
    SUDO=""
else
    echo -e "${YELLOW}⚠ Running with sudo privileges${NC}"
    SUDO="sudo"
fi

# Update package list
echo -e "\n${BLUE}Step 1: Updating package list...${NC}"
$SUDO apt update

# Install curl if not present
if ! command -v curl &> /dev/null; then
    echo -e "${YELLOW}Installing curl...${NC}"
    $SUDO apt install -y curl
fi

# Add Tailscale's GPG key and repository
echo -e "\n${BLUE}Step 2: Adding Tailscale repository...${NC}"
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.noarmor.gpg | $SUDO tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.list | $SUDO tee /etc/apt/sources.list.d/tailscale.list

# Update package list with new repository
echo -e "${BLUE}Updating package list with Tailscale repository...${NC}"
$SUDO apt update

# Install Tailscale
echo -e "\n${BLUE}Step 3: Installing Tailscale...${NC}"
$SUDO apt install -y tailscale

# Enable and start Tailscale daemon
echo -e "\n${BLUE}Step 4: Enabling Tailscale service...${NC}"
$SUDO systemctl enable tailscaled
$SUDO systemctl start tailscaled

# Check if auth key is provided
AUTH_KEY=$1
if [ -n "$AUTH_KEY" ]; then
    echo -e "\n${BLUE}Step 5: Authenticating with provided auth key...${NC}"
    $SUDO tailscale up --authkey="$AUTH_KEY" --ssh
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Tailscale authentication successful!${NC}"
    else
        echo -e "${RED}✗ Authentication failed. Please check your auth key.${NC}"
        exit 1
    fi
else
    echo -e "\n${YELLOW}Step 5: Manual authentication required${NC}"
    echo -e "${BLUE}Run the following command and follow the authentication URL:${NC}"
    echo -e "${GREEN}sudo tailscale up --ssh${NC}"
    echo ""
    echo -e "${YELLOW}Note: The --ssh flag enables Tailscale SSH for easier access${NC}"
fi

# Display current status
echo -e "\n${BLUE}Step 6: Checking Tailscale status...${NC}"
$SUDO tailscale status

# Get Tailscale IP
TAILSCALE_IP=$($SUDO tailscale ip -4 2>/dev/null || echo "Not available yet")
echo -e "\n${GREEN}=== Installation Complete! ===${NC}"
echo -e "${BLUE}Tailscale IP: ${GREEN}$TAILSCALE_IP${NC}"
echo -e "${BLUE}Device name: ${GREEN}$(hostname)${NC}"

# Display usage instructions
echo -e "\n${YELLOW}=== Next Steps ===${NC}"
echo -e "1. If authentication is pending, complete it via the provided URL"
echo -e "2. Test SSH access: ${GREEN}ssh username@$TAILSCALE_IP${NC}"
echo -e "3. Access ComfyUI: ${GREEN}http://$TAILSCALE_IP:8188${NC}"
echo -e "4. Access Gradio apps on their respective ports"

# Show additional useful commands
echo -e "\n${YELLOW}=== Useful Tailscale Commands ===${NC}"
echo -e "Check status: ${GREEN}sudo tailscale status${NC}"
echo -e "Get IP address: ${GREEN}sudo tailscale ip -4${NC}"
echo -e "Logout: ${GREEN}sudo tailscale logout${NC}"
echo -e "Restart daemon: ${GREEN}sudo systemctl restart tailscaled${NC}"

# Create a systemd service to ensure Tailscale starts on boot (redundant but ensures reliability)
echo -e "\n${BLUE}Step 7: Ensuring boot persistence...${NC}"
cat << 'EOF' | $SUDO tee /etc/systemd/system/tailscale-startup.service > /dev/null
[Unit]
Description=Tailscale client startup
Wants=network-pre.target
After=network-pre.target
Before=network.target
RequiresMountsFor=/var/lib

[Service]
Type=notify
ExecStart=/usr/bin/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock --port=41641
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

$SUDO systemctl daemon-reload
$SUDO systemctl enable tailscale-startup.service

echo -e "${GREEN}✓ Tailscale installation and configuration complete!${NC}"
echo -e "${BLUE}The VPS will now be accessible via Tailscale even after reboots.${NC}"