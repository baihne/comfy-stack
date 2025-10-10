# Comfy Stack - Quick Model Access Guide

## 🚀 Deployment Options

### Hunyuan3D-2mv (100GB VPS Optimized)
```bash
./deployment/deploy_hunyuan_2mv_optimized.sh TAILSCALE_AUTH_KEY standard
```
**Access:** `http://100.x.x.x:7861`
- Multiview shape generation
- ~35GB storage
- 6GB VRAM

### Hunyuan3D Hybrid (2mv + 2.1 PBR)
```bash
./deployment/deploy_hunyuan_hybrid.sh TAILSCALE_AUTH_KEY standard
```
**Access:** `http://100.x.x.x:7862` (unified interface)
- Shape + PBR texturing
- ~90GB storage
- 27GB VRAM

### ComfyUI + Wan2.2
```bash
./deployment/deploy_comfyui_wan.sh TAILSCALE_AUTH_KEY
```
**Access:** `http://100.x.x.x:8188`
- Image/video generation
- ~20GB storage
- 12GB VRAM

## 📱 Access via Tailscale

All services use Tailscale for secure access:
- **Hunyuan3D-2mv:** `http://100.x.x.x:7861`
- **Hunyuan3D Hybrid:** `http://100.x.x.x:7862`
- **Hunyuan3D-2.1:** `http://100.x.x.x:7860`
- **ComfyUI:** `http://100.x.x.x:8188`

## 🔧 Manual Start Commands

```bash
# Hunyuan3D-2mv
~/Hunyuan3D-2mv/run_hunyuan3d_mv.sh

# Hunyuan3D-2.1
~/Hunyuan3D-2.1/run_hunyuan3d.sh

# Hybrid Interface
~/Hunyuan3D-Hybrid/run_hybrid.sh

# ComfyUI
cd ~/ComfyUI && python main.py
```

## 🎯 Model Variants

- **standard:** Best quality
- **turbo:** Fast generation
- **fast:** Rapid prototyping

That's it! Deploy what you need and access via the URLs above.