# Tailscale VPS Quick Start

## 🚀 Ready to Go Commands

### 1. Generate Auth Key
Visit: https://login.tailscale.com/admin/settings/keys
- ✅ Reusable
- ❌ Ephemeral 
- ✅ Pre-approved

### 2. Deploy with Auto-Install
```bash
# Clone repo on VPS
git clone https://github.com/baihne/comfy-stack && cd comfy-stack

# Deploy ComfyUI + Wan 2.2 (video generation)
./deployment/deploy_comfyui_wan.sh I2V_A14B YOUR-TAILSCALE-AUTH-KEY

# Deploy Hunyuan3D Hybrid (3D generation - recommended)
./deployment/deploy_hunyuan_hybrid.sh YOUR-TAILSCALE-AUTH-KEY standard

# Deploy complete AI stack
./deployment/deploy_complete_stack.sh both I2V_A14B YOUR-TAILSCALE-AUTH-KEY
```

### 3. Test Connection
```bash
# Get Tailscale IP from VPS
sudo tailscale ip -4

# From your local machine
ssh user@100.x.x.x
```

### 4. Access Services
- **ComfyUI** (video): http://100.x.x.x:8188
- **Hunyuan3D Hybrid** (3D): http://100.x.x.x:7862 ⭐
- **Hunyuan3D-2.1** (PBR): http://100.x.x.x:7860
- **Hunyuan3D-2mv** (multiview): http://100.x.x.x:7861

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