# Hunyuan3D Hybrid Workflow Guide

Based on comprehensive research, the **optimal production setup** combines:
- **Hunyuan3D-2mv** for shape generation (multiview + single-view capable)
- **Hunyuan3D-2.1** for PBR texture generation (production-quality materials)

## 🎯 Why Hybrid?

| Aspect | 2mv-only | 2.1-only | **Hybrid (Recommended)** |
|--------|----------|----------|---------------------------|
| **Multiview support** | ✅ Built-in | ❌ Not available | ✅ Via 2mv |
| **Single-view quality** | ⚠️ Adequate | ✅ Best-in-class | ✅ Adequate→Excellent |
| **PBR textures** | ❌ Basic RGB | ✅ Production PBR | ✅ Production PBR |
| **VRAM requirements** | 16GB total | 29GB total | **6GB + 21GB** |
| **Deployment complexity** | Simple | Simple | Moderate |

## 🚀 Quick Setup

### Option A: Unified Deployment (Recommended) ⭐

**Single command** deploys both models with automatic pipeline:

```bash
# 1. Clone repo
git clone https://github.com/baihne/comfy-stack.git
cd comfy-stack

# 2. Deploy unified hybrid interface (one command does everything)
./deployment/deploy_hunyuan_hybrid.sh TAILSCALE_AUTH_KEY standard

# 3. Access unified interface
# http://100.x.x.x:7862
```

**Features:**
- ✅ **Automatic workflow**: Input → 2mv Shape → 2.1 PBR → Output
- ✅ **Single interface** handles both single images and multiview
- ✅ **Smart routing** between shape and texture pipelines
- ✅ **Production ready** with proper error handling

### Option B: Separate Deployment (Manual Pipeline)

Deploy both stacks separately for manual workflow:

```bash
# 1. Clone repo
git clone https://github.com/baihne/comfy-stack.git
cd comfy-stack

# 2. Deploy multiview shape generation (port 7861)
./deployment/deploy_hunyuan_multiview.sh TAILSCALE_AUTH_KEY standard

# 3. Deploy PBR texture generation (port 7860)
./deployment/deploy_hunyuan.sh TAILSCALE_AUTH_KEY
```

## 📊 Workflow Options

### Option A: Unified Interface (Recommended) ⭐

**Access:** `http://100.x.x.x:7862`

**Automatic Pipeline:**
1. Upload single image OR multiple views (front/left/back/right)
2. Add optional texture prompt
3. Click "Generate Hybrid 3D"
4. System automatically:
   - Routes to 2mv for shape generation
   - Takes resulting mesh to 2.1 for PBR texturing
   - Returns final production-quality 3D model

**No manual steps needed!** The interface handles the complete pipeline.

### Option B: Manual Pipeline (Advanced Users)

1. **Generate Shape** via 2mv interface at `http://100.x.x.x:7861`:
   - Upload single image OR multiple views (front/left/back/right)
   - Download generated mesh (.obj/.glb)

2. **Add PBR Textures** via 2.1 interface at `http://100.x.x.x:7860`:
   - Upload the mesh + reference image(s)
   - Generate production-quality PBR materials

*Use this when you need fine control over each pipeline step.*

## 🔧 Resource Planning

### GPU Requirements

| Component | VRAM | Use Case |
|-----------|------|----------|
| **Shape (2mv)** | ~6GB | Can run on smaller GPUs (RTX 3060, etc.) |
| **Texture (2.1)** | ~21GB | Needs larger GPUs (RTX 4090, A100, etc.) |
| **Both sequential** | 21GB | Run shape first, then texture |
| **Both parallel** | 27GB+ | Ideal for high-throughput workflows |

### Storage Requirements

- **2mv models**: ~30GB download
- **2.1 models**: ~15GB download  
- **Total**: ~45GB for complete hybrid setup

## 🎨 Quality Comparison

Based on community testing and official metrics:

**Shape Generation:**
- **Single image**: 2.1 > 2mv > 2.0 (but 2mv is adequate)
- **Multiple views**: 2mv >> 2.1 (2.1 doesn't support multiview)

**Texture Generation:**
- **PBR quality**: 2.1 >> 2.0 (significant improvement)
- **Material realism**: 2.1 handles metals, leather, SSS much better

## 🔄 When to Use Each Approach

### Unified Hybrid Interface - **Recommended** ⭐
- ✅ Want the simplest possible user experience
- ✅ Need both multiview capability and PBR materials
- ✅ Prefer automatic pipeline routing
- ✅ VRAM allows ~27GB total (6GB + 21GB sequential)
- ✅ Single interface for all 3D generation needs

### Manual Hybrid (2mv + 2.1 separate) - **Advanced**
- ✅ Need fine control over each pipeline step
- ✅ Want to inspect intermediate mesh results
- ✅ Can manage two separate services
- ✅ VRAM allows 21GB+ for texture step

### 2mv Only (shape + 2.0 texture)
- ✅ VRAM constrained (16GB total limit)
- ✅ Want simplest single-service deployment
- ⚠️ Accept basic texture quality vs PBR

### 2.1 Only (shape + texture)
- ✅ Single-image focused workflows
- ✅ Maximum shape quality for single views
- ✅ Need one unified interface
- ❌ No multiview support

## 🛠 Troubleshooting

### Port Conflicts
- **Unified Hybrid** runs on port **7862** ⭐
- 2mv runs on port **7861**
- 2.1 runs on port **7860**
- All can coexist on same VPS

### VRAM Issues
If generation fails with OOM:
- **Unified interface**: Models run sequentially (6GB + 21GB)
- **Manual interface**: Process shape and texture separately
- Use `--low_vram_mode` flag in deployment
- Lower texture resolution in advanced settings

### Model Selection
- Use **standard** for best quality
- Use **turbo** for faster iteration (2mv only)
- Use **fast** for rapid prototyping (2mv only)

## 📚 Technical Details

### Mesh Compatibility
- 2mv outputs standard `trimesh` meshes
- 2.1 accepts any mesh format (OBJ, PLY, GLB)
- Direct pipeline: `2mv mesh → 2.1 texture pipeline`

### API Integration
All services expose standard Gradio APIs for programmatic access:
```python
# Unified hybrid interface (recommended)
import requests
hybrid_response = requests.post("http://100.x.x.x:7862/api/predict", ...)

# Individual services (manual pipeline)
shape_response = requests.post("http://100.x.x.x:7861/api/predict", ...)  # 2mv
texture_response = requests.post("http://100.x.x.x:7860/api/predict", ...)  # 2.1
```

## 🎯 Production Recommendations

1. **Start with unified hybrid deployment** for best user experience ⭐
2. **Use standard variant** for production, turbo for prototyping
3. **Monitor total VRAM usage** (~27GB for complete pipeline)
4. **Scale horizontally** with multiple VPS instances for high throughput
5. **Use manual pipeline** only when you need fine control over each step

**Quick Start:**
```bash
./deployment/deploy_hunyuan_hybrid.sh TAILSCALE_AUTH_KEY standard
```

This unified approach gives you the best of both worlds with the simplest possible user experience! 🎨✨