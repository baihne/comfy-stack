# Comfy Stack - AI Model Deployment

## 🔌 Step 1: SSH Access

First connect to your server:

```bash
ssh -i ~/.ssh/YOUR_KEY_FILE ubuntu@YOUR_SERVER_IP
```

**If you get a host key warning, run:**
```bash
ssh-keygen -R YOUR_SERVER_IP
```

This happens when the server IP changes or is reused.

## 🚀 Step 2: Clone & Deploy

```bash
# Clone the repository
rm -rf comfy-stack  # Remove existing directory if needed
git clone https://github.com/baihne/comfy-stack.git
cd comfy-stack

# Choose your deployment option:
```

### For 100GB VPS (Recommended)
```bash
./deployment/deploy_hunyuan_2mv_optimized.sh TAILSCALE_AUTH_KEY standard
```
**Access:** `http://100.x.x.x:7861`

### For Larger VPS (Hybrid Setup)
```bash
./deployment/deploy_hunyuan_hybrid.sh TAILSCALE_AUTH_KEY standard
```
**Access:** `http://100.x.x.x:7862`

### ComfyUI + Wan2.2
```bash
./deployment/deploy_comfyui_wan.sh TAILSCALE_AUTH_KEY
```
**Access:** `http://100.x.x.x:8188`

## 📱 Step 3: Access Services

| Service | Port | Access URL |
|---------|------|------------|
| Hunyuan3D-2mv | 7861 | `http://100.x.x.x:7861` |
| Hunyuan3D Hybrid | 7862 | `http://100.x.x.x:7862` |
| Hunyuan3D-2.1 | 7860 | `http://100.x.x.x:7860` |
| ComfyUI | 8188 | `http://100.x.x.x:8188` |

## 🎯 Model Variants

- `standard` - Best quality
- `turbo` - Fast generation  
- `fast` - Rapid prototyping

## 📚 Additional Documentation

See `docs/` folder for detailed guides and troubleshooting.