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

### Step 2: Deploy AI Stack with Tailscale

```bash
# 1. SSH into your VPS
ssh -i /path/to/your/key user@your-vps-ip

# 2. Clone the repository
git clone https://github.com/baihne/comfy-stack && cd comfy-stack

# 3. Deploy with Tailscale (choose one):

# Option A: Hunyuan3D Hybrid (recommended for 3D generation)
./deployment/deploy_hunyuan_hybrid.sh YOUR-TAILSCALE-AUTH-KEY standard

# Option B: ComfyUI + Wan 2.2 (video generation)
./deployment/deploy_comfyui_wan.sh I2V_A14B YOUR-TAILSCALE-AUTH-KEY

# Option C: Complete AI stack (both video + 3D)
./deployment/deploy_complete_stack.sh both I2V_A14B YOUR-TAILSCALE-AUTH-KEY
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

# AI Services access (browser):
# ComfyUI (video generation)
http://100.x.x.x:8188

# Hunyuan3D Hybrid (3D generation - recommended)
http://100.x.x.x:7862

# Hunyuan3D-2.1 (PBR textures)
http://100.x.x.x:7860

# Hunyuan3D-2mv (multiview shapes)
http://100.x.x.x:7861
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
- **ComfyUI** (video): `http://100.x.x.x:8188`
- **Hunyuan3D Hybrid** (3D): `http://100.x.x.x:7862` ⭐
- **Hunyuan3D-2.1** (PBR): `http://100.x.x.x:7860`
- **Hunyuan3D-2mv** (multiview): `http://100.x.x.x:7861`
- **File Transfer**: `scp file user@100.x.x.x:~/`
- **Port Forwarding**: `ssh -L 7862:localhost:7862 user@100.x.x.x`

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
# Check if services are running
ps aux | grep comfy           # ComfyUI
ps aux | grep python          # Hunyuan3D services
netstat -tlnp | grep 8188     # ComfyUI
netstat -tlnp | grep 7862     # Hunyuan3D Hybrid
netstat -tlnp | grep 7860     # Hunyuan3D-2.1
netstat -tlnp | grep 7861     # Hunyuan3D-2mv

# Check if services bind to all interfaces
# Services should bind to 0.0.0.0:port, not 127.0.0.1:port

# Restart services if needed
~/Hunyuan3D-Hybrid/run_hybrid.sh          # Hybrid interface
~/Hunyuan3D-2.1/run_hunyuan3d.sh         # 2.1 only
~/Hunyuan3D-2mv/run_hunyuan3d_mv.sh      # 2mv only
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
[Office Network]                          [Hunyuan3D Hybrid:7862]
[Mobile Device]                           [Hunyuan3D-2.1:7860]
                                         [Hunyuan3D-2mv:7861]
```

All your Tailscale-enabled devices can now securely access your VPS services regardless of network restrictions.