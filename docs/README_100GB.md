# Hunyuan3D for 100GB VPS

## 🎯 Optimized Setup for 100GB VPS

Use the 2mv-only deployment to fit within storage limits:

```bash
./deployment/deploy_hunyuan_2mv_optimized.sh TAILSCALE_AUTH_KEY standard
```

**Access:** `http://100.x.x.x:7861`

## 📊 Storage vs Quality

| Setup | Storage | VRAM | Quality | 100GB VPS |
|-------|---------|------|---------|-----------|
| **2mv Only** | ~35GB | 6GB | Good | ✅ Recommended |
| Hybrid | ~90GB | 27GB | Best | ❌ Too large |

## 🚀 Quick Start

```bash
# Deploy optimized 2mv
./deployment/deploy_hunyuan_2mv_optimized.sh TAILSCALE_AUTH_KEY standard

# Start manually
~/Hunyuan3D-2mv/start_optimized.sh
```

## 🎨 Model Variants

- `standard` - Best quality (6GB VRAM)
- `turbo` - Fast generation (4GB VRAM)  
- `fast` - Rapid prototyping (3GB VRAM)

That's it! Your 100GB VPS is ready for 3D generation.