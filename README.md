# comfy-stack

## 🚀 Quick Commands

```bash
# 1. Clone
git clone https://github.com/baihne/comfy-stack && cd comfy-stack

# 2. Get Tailscale auth key: https://login.tailscale.com/admin/settings/keys

# 3. Deploy ComfyUI + Wan 2.2 models + Tailscale
./deployment/deploy_comfyui_wan.sh I2V_A14B tskey-auth-YOUR-KEY

# 4. Deploy Hunyuan3D + Tailscale
./deployment/deploy_hunyuan.sh tskey-auth-YOUR-KEY

# 5. Deploy both stacks (use the all-in-one script)
./deployment/deploy_complete_stack.sh both I2V_A14B tskey-auth-YOUR-KEY
```

**Access**: `http://100.x.x.x:8188` (ComfyUI) | `http://100.x.x.x:7860` (Hunyuan3D) | `ssh ubuntu@100.x.x.x`

---

## Without Tailscale (SSH Tunnel)

```bash
# Traditional setup
./stacks/comfyui/bootstrap_comfy.sh
./stacks/comfyui/wan22-download.sh I2V_A14B

# Access via tunnel
ssh -L 8188:localhost:8188 ubuntu@YOUR-VPS-IP
# Open: http://localhost:8188
```

---

## Available Stacks

| Stack | Command | Description |
|-------|---------|-------------|
| ComfyUI + I2V | `./deployment/deploy_comfyui_wan.sh I2V_A14B tskey-auth-KEY` | Image to Video 14B |
| ComfyUI + T2V | `./deployment/deploy_comfyui_wan.sh T2V_A14B tskey-auth-KEY` | Text to Video 14B |
| ComfyUI + TI2V | `./deployment/deploy_comfyui_wan.sh TI2V_5B tskey-auth-KEY` | Text/Image to Video 5B |
| Hunyuan3D | `./deployment/deploy_hunyuan.sh tskey-auth-KEY` | 3D Generation |

---

## Cloud-Init (Auto Deploy)

Edit [`deployment/cloud-init/user-data.yaml`](deployment/cloud-init/user-data.yaml), add your auth key, paste into VPS creation.

---

## Detailed Docs

- [Complete Tailscale Guide](networking/tailscale_vps_setup.md)
- [Quick Reference](networking/tailscale_quick_start.md)

---

## Requirements

- Ubuntu 24.04 + CUDA 12.8
- ≥100 GB disk space
- Internet access to GitHub/HuggingFace