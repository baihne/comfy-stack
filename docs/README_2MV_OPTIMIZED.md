# Hunyuan3D-2mv Optimized Setup (100GB VPS Friendly)

This guide provides an optimized deployment of Hunyuan3D-2mv specifically designed for 100GB VPS environments.

## 🎯 What You Get

**Hunyuan3D-2mv (Multiview Only)**
- ✅ Multiview shape generation (front, left, back, right, top, bottom)
- ✅ Single-view to 3D conversion
- ✅ Multiple quality variants (standard/turbo/fast)
- ✅ Optimized storage footprint (~35GB total)
- ✅ Low VRAM mode enabled
- ❌ No PBR texturing (saves ~15GB + 21GB VRAM)

## 📊 Storage Comparison

| Setup | Models | Total Size | VRAM | 100GB VPS |
|-------|--------|------------|------|-----------|
| **Hybrid (2mv + 2.1)** | ~45GB | ~90GB | 27GB | ❌ Too large |
| **2mv Only (Optimized)** | ~30GB | ~35GB | 6GB | ✅ Perfect fit |

## 🚀 Quick Start

### Option A: Optimized Deployment (Recommended)

```bash
# 1. Clone repo
git clone https://github.com/baihne/comfy-stack.git
cd comfy-stack

# 2. Deploy optimized 2mv-only setup
./deployment/deploy_hunyuan_2mv_optimized.sh TAILSCALE_AUTH_KEY standard

# 3. Access the interface
# http://100.x.x.x:7861
```

### Option B: Standard 2mv Deployment

```bash
# Use the existing multiview deployment
./deployment/deploy_hunyuan_multiview.sh TAILSCALE_AUTH_KEY standard
```

## 🎨 Model Variants

| Variant | Quality | Speed | VRAM | Use Case |
|---------|---------|-------|------|----------|
| **standard** | Best | Slow | 6GB | Production quality |
| **turbo** | Good | Fast | 4GB | Quick iteration |
| **fast** | Adequate | Fastest | 3GB | Rapid prototyping |

## 💾 Storage Optimizations Applied

1. **Local Model Storage**: Models downloaded directly to app directory (not cache)
2. **Cache Cleanup**: Automatic HuggingFace cache cleanup after download
3. **Git Optimization**: Repository packed to save space
4. **Pip Cache Cleanup**: Remove unnecessary pip cache files
5. **No PBR Dependencies**: Removed 2.1 texture generation components

## 🔧 Usage

### Starting the Application

```bash
# With storage monitoring
~/Hunyuan3D-2mv/start_optimized.sh

# Or direct start
~/Hunyuan3D-2mv/run_hunyuan3d_mv.sh

# With custom settings
GRADIO_HOST=0.0.0.0 GRADIO_PORT=7861 ~/Hunyuan3D-2mv/run_hunyuan3d_mv.sh
```

### Access Methods

**Via Tailscale (Recommended):**
- Web Interface: `http://100.x.x.x:7861`
- SSH: `ssh ubuntu@100.x.x.x`

**Via SSH Tunnel (Fallback):**
```bash
ssh -L 7861:localhost:7861 ubuntu@PUBLIC_IP
# Then open: http://localhost:7861
```

## 📸 Input Options

### Single Image Upload
- Upload one image
- System generates 3D shape
- Good for quick prototyping

### Multiview Upload (Recommended)
- Upload multiple images (front, left, back, right, etc.)
- Better shape consistency and accuracy
- Supports up to 6 views

## 🎯 Output Formats

- **GLB**: Web-ready 3D format (recommended)
- **OBJ**: Standard 3D format
- **PLY**: Point cloud format

## 💡 Tips for 100GB VPS

### Storage Management
```bash
# Check storage usage
df -h ~

# Monitor model directory size
du -sh ~/Hunyuan3D-2mv/models

# Clear pip cache if needed
pip cache purge
```

### Performance Optimization
- Use **turbo** variant for faster generation
- Enable **low_vram_mode** (already enabled)
- Monitor VRAM usage with `nvidia-smi`

### Troubleshooting
- Restart with: `~/Hunyuan3D-2mv/start_optimized.sh`
- Check logs for memory issues
- Use smaller image resolutions if OOM occurs

## 🔄 Migration from Hybrid

If you currently have the hybrid setup and want to switch to 2mv-only:

```bash
# 1. Stop existing services
sudo pkill -f gradio_app.py

# 2. Remove 2.1 installation (optional, saves space)
rm -rf ~/Hunyuan3D-2.1

# 3. Deploy optimized 2mv
./deployment/deploy_hunyuan_2mv_optimized.sh TAILSCALE_AUTH_KEY standard
```

## 📚 Technical Details

### Model Storage Location
```
~/Hunyuan3D-2mv/models/tencent--Hunyuan3D-2mv/
├── hunyuan3d-dit-v2-mv/          # Standard model
├── hunyuan3d-dit-v2-mv-turbo/    # Turbo model
└── hunyuan3d-dit-v2-mv-fast/     # Fast model
```

### Python Environment
- Python 3.11
- PyTorch 2.5.1 (CUDA 12.4)
- Isolated virtual environment: `~/Hunyuan3D-2mv/hy3d2mv-py311`

### GPU Requirements
- **Minimum**: RTX 3060 (12GB VRAM)
- **Recommended**: RTX 4090 (24GB VRAM)
- **Cloud**: A10G (24GB VRAM) or similar

## 🆘 Troubleshooting

### Common Issues

**Out of Memory (OOM)**
```bash
# Use turbo variant
export MODEL_VARIANT=turbo
~/Hunyuan3D-2mv/run_hunyuan3d_mv.sh
```

**Storage Full**
```bash
# Check what's using space
du -sh ~/* | sort -hr | head -10

# Clean pip cache
pip cache purge

# Remove git history to save space
cd ~/Hunyuan3D-2mv && git gc --aggressive --prune=now
```

**Connection Issues**
```bash
# Check Tailscale
sudo tailscale status

# Check if service is running
ps aux | grep gradio_app.py

# Restart with correct host
export GRADIO_HOST=0.0.0.0
~/Hunyuan3D-2mv/run_hunyuan3d_mv.sh
```

## 🎉 Ready to Go!

Your optimized Hunyuan3D-2mv setup is now ready for 3D generation on your 100GB VPS! The system is configured to:

- ✅ Fit comfortably within storage limits
- ✅ Run efficiently with available VRAM
- ✅ Provide high-quality multiview 3D generation
- ✅ Scale with your needs

**Quick Start Command:**
```bash
./deployment/deploy_hunyuan_2mv_optimized.sh TAILSCALE_AUTH_KEY standard
```

This gives you a working Hunyuan3D-2mv installation that's perfectly sized for your 100GB VPS! 🎨✨