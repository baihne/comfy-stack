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

Deploy both stacks on the same VPS:

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

### Option A: Manual Pipeline (Recommended for Learning)

1. **Generate Shape** via 2mv interface at `http://100.x.x.x:7861`:
   - Upload single image OR multiple views (front/left/back/right)
   - Download generated mesh (.obj/.glb)

2. **Add PBR Textures** via 2.1 interface at `http://100.x.x.x:7860`:
   - Upload the mesh + reference image(s)
   - Generate production-quality PBR materials

### Option B: Integrated Pipeline (Future Enhancement)

A unified interface that routes:
- **Input → 2mv shape → 2.1 texture → Output**

*Note: This requires custom integration - both UIs currently run separately.*

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

### Hybrid (2mv shape + 2.1 texture) - **Recommended**
- ✅ You want multiview capability when available
- ✅ You need production-quality PBR materials
- ✅ You can manage two separate services
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
- 2mv runs on port **7861**
- 2.1 runs on port **7860**
- Both can coexist on same VPS

### VRAM Issues
If texture generation fails with OOM:
- Use `--low_vram_mode` flag
- Lower texture resolution
- Process textures on separate GPU/VPS

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
Both services expose standard Gradio APIs for programmatic access:
```python
# 2mv shape generation
import requests
shape_response = requests.post("http://100.x.x.x:7861/api/predict", ...)

# 2.1 texture generation  
texture_response = requests.post("http://100.x.x.x:7860/api/predict", ...)
```

## 🎯 Production Recommendations

1. **Start with hybrid deployment** to test both capabilities
2. **Use 2mv-turbo for prototyping**, standard for finals
3. **Batch texture jobs** on high-VRAM instances
4. **Monitor VRAM usage** and scale texture workers as needed
5. **Consider async workflows** for high-throughput scenarios

This hybrid approach gives you the best of both worlds: multiview flexibility and production-quality materials! 🎨✨