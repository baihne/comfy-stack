# Tailscale VPS Quick Start

## 🚀 Ready to Go Commands

### 1. Generate Auth Key
Visit: https://login.tailscale.com/admin/settings/keys
- ✅ Reusable
- ❌ Ephemeral 
- ✅ Pre-approved

### 2. Upload & Install
```bash
# Upload script to VPS
scp -i /path/to/your/key scripts/install_tailscale_vps.sh user@your-vps-ip:~/

# SSH to VPS
ssh -i /path/to/your/key user@your-vps-ip

# Run installation
chmod +x install_tailscale_vps.sh
sudo ./install_tailscale_vps.sh tskey-auth-YOUR-KEY-HERE
```

### 3. Test Connection
```bash
# Get Tailscale IP from VPS
sudo tailscale ip -4

# From your local machine
ssh user@100.x.x.x
```

### 4. Access Services
- **ComfyUI**: http://100.x.x.x:8188
- **Gradio**: http://100.x.x.x:7860

## 🔧 Troubleshooting
```bash
sudo tailscale status          # Check connection
sudo systemctl restart tailscaled  # Restart service
sudo tailscale up --ssh       # Re-authenticate
```

## ✅ Success Indicators
- VPS shows in `tailscale status` on your local machine
- Can SSH using Tailscale IP (100.x.x.x)
- Web services accessible via Tailscale IP