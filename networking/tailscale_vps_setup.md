# Tailscale VPS Setup Guide

## Overview
This guide will help you set up Tailscale on your Hyperstack VPS to bypass firewall restrictions and securely access your ComfyUI and Gradio applications.

## Prerequisites
- Ubuntu/Debian VPS with root/sudo access ✓
- Existing Tailscale personal account ✓
- SSH key access to your VPS ✓
- Tailscale installed on your local machines ✓

## Step-by-Step Implementation

### Step 1: Generate Tailscale Auth Key

1. Go to [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys)
2. Click **"Generate auth key"**
3. Configure the key:
   - **Reusable**: ✓ (recommended for spot instances)
   - **Ephemeral**: ✗ (uncheck - you want persistent access)
   - **Pre-approved**: ✓ (skip manual approval)
   - **Tags**: Leave empty for personal use
4. Copy the generated key (starts with `tskey-auth-`)

### Step 2: Upload and Execute Installation Script

```bash
# 1. Copy script to your VPS
scp -i /path/to/your/key scripts/install_tailscale_vps.sh user@your-vps-ip:~/

# 2. SSH into your VPS
ssh -i /path/to/your/key user@your-vps-ip

# 3. Make script executable
chmod +x install_tailscale_vps.sh

# 4. Run installation with your auth key
sudo ./install_tailscale_vps.sh YOUR-TAILSCALE-AUTH-KEY
```

### Step 3: Verify Installation

After installation, the script will display:
- ✅ Tailscale IP address (format: 100.x.x.x)
- ✅ Device status in your network
- ✅ Connection instructions

### Step 4: Test Connectivity

```bash
# From any of your Tailscale-enabled devices:

# SSH access
ssh user@100.x.x.x

# ComfyUI access (browser)
http://100.x.x.x:8188

# Gradio access (browser) 
http://100.x.x.x:7860  # or your specific port
```

## Post-Installation Workflow

### Daily Usage
Instead of dealing with firewall issues, you'll now use:

```bash
# Old way (blocked by firewall)
ssh -i ~/.ssh/key user@public-vps-ip

# New way (works everywhere)
ssh user@100.x.x.x  # Tailscale IP
```

### Service Access
- **ComfyUI**: `http://100.x.x.x:8188`
- **Gradio Apps**: `http://100.x.x.x:[port]`
- **File Transfer**: `scp file user@100.x.x.x:~/`
- **Port Forwarding**: `ssh -L 8188:localhost:8188 user@100.x.x.x`

## Spot Instance Considerations

Since you're using Hyperstack spot instances:

### Automatic Restart
- Tailscale will auto-start on reboot
- Same Tailscale IP will be maintained
- No reconfiguration needed

### Instance Recreation
If your spot instance is terminated and recreated:

1. **Save this setup**: Keep the installation script and auth key
2. **Quick reinstall**: Run the script again on the new instance
3. **Same network**: The new instance joins your existing Tailscale network
4. **Update references**: Tailscale IP might change, update your bookmarks

## Troubleshooting

### Connection Issues
```bash
# Check Tailscale status
sudo tailscale status

# Restart Tailscale
sudo systemctl restart tailscaled

# Re-authenticate if needed
sudo tailscale up --ssh
```

### Firewall Configuration
```bash
# Allow Tailscale through UFW (if enabled)
sudo ufw allow in on tailscale0
sudo ufw allow out on tailscale0
```

### Service Access Issues
```bash
# Check if ComfyUI is running
ps aux | grep comfy
netstat -tlnp | grep 8188

# Check if services bind to all interfaces
# Services should bind to 0.0.0.0:port, not 127.0.0.1:port
```

## Security Benefits

✅ **End-to-end encryption** between your devices and VPS  
✅ **Zero-trust networking** - only your authenticated devices can connect  
✅ **No open ports** - VPS doesn't expose services to the internet  
✅ **Firewall bypass** - works through corporate/restrictive networks  
✅ **Device authentication** - stolen credentials alone can't access your VPS  

## Useful Commands

```bash
# Get Tailscale IP
sudo tailscale ip -4

# List connected devices
sudo tailscale status

# View logs
sudo journalctl -u tailscaled -f

# Logout from network
sudo tailscale logout

# Update Tailscale
sudo apt update && sudo apt upgrade tailscale
```

## Network Topology

```
[Your Laptop] ←→ [Tailscale Mesh Network] ←→ [VPS]
     ↓                                           ↓
[Home Network]                            [ComfyUI:8188]
[Office Network]                          [Gradio Apps]
[Mobile Device]
```

All your Tailscale-enabled devices can now securely access your VPS services regardless of network restrictions.