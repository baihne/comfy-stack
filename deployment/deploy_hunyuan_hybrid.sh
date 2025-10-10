#!/usr/bin/env bash
set -euo pipefail

# Hunyuan3D Hybrid (2mv + 2.1 PBR) Unified Deployment
# 
# Usage:
#   ./deploy_hunyuan_hybrid.sh [TAILSCALE_AUTH_KEY] [MODEL_VARIANT]
#   
# Examples:
#   ./deploy_hunyuan_hybrid.sh TAILSCALE_AUTH_KEY standard
#   ./deploy_hunyuan_hybrid.sh TAILSCALE_AUTH_KEY turbo

echo "======================================================================"
echo "🎭 Hunyuan3D Hybrid Deployment (2mv Shape + 2.1 PBR)"
echo "======================================================================"
echo "Starting unified deployment at $(date -Is)"

# Resolve repo root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Parameters
TAILSCALE_AUTH_KEY="${1:-${TAILSCALE_AUTH_KEY:-}}"
MODEL_VARIANT="${2:-standard}"  # standard | turbo | fast

echo "📋 Configuration:"
echo "   Stack: Hunyuan3D Hybrid (2mv + 2.1)"
echo "   Model variant: $MODEL_VARIANT"
echo "   Tailscale: $([ -n "$TAILSCALE_AUTH_KEY" ] && echo "✅ Enabled" || echo "❌ Disabled")"
echo "   Repo: $REPO_ROOT"
echo ""

# Export variables for sub-scripts
export TAILSCALE_AUTH_KEY
export MODEL_VARIANT

# Step 1: Setup Tailscale first (if enabled)
if [ -n "$TAILSCALE_AUTH_KEY" ]; then
    echo "🔒 Step 1: Setting up Tailscale..."
    "$REPO_ROOT/networking/setup_tailscale.sh"
    echo ""
else
    echo "⚠️  Step 1: Skipping Tailscale setup (no auth key provided)"
    echo ""
fi

# Step 2: Install Hunyuan3D-2mv (for shape generation)
echo "🎭 Step 2: Installing Hunyuan3D-2mv (shape generation)..."
"$REPO_ROOT/stacks/hunyuan/scripts/install_hunyuan3d2mv_2404.sh"
echo ""

# Step 3: Install Hunyuan3D-2.1 (for PBR texturing)
echo "🎨 Step 3: Installing Hunyuan3D-2.1 (PBR texturing)..."
"$REPO_ROOT/stacks/hunyuan/scripts/install_hunyuan3d21_2404.sh"
echo ""

# Step 4: Create unified hybrid interface
echo "🔗 Step 4: Creating unified hybrid interface..."

# Set environment variables for Tailscale compatibility
if [ -n "$TAILSCALE_AUTH_KEY" ]; then
    export GRADIO_HOST="0.0.0.0"
    export GRADIO_PORT="7862"  # New port for hybrid interface
fi

# Create hybrid application directory
HYBRID_DIR="$HOME/Hunyuan3D-Hybrid"
mkdir -p "$HYBRID_DIR"

# Create unified gradio app that uses both pipelines
cat > "$HYBRID_DIR/hybrid_app.py" << 'EOF'
#!/usr/bin/env python3
import sys
import os
import tempfile
import gradio as gr
import argparse
from pathlib import Path

# Add both model paths
sys.path.append('/home/ubuntu/Hunyuan3D-2mv')
sys.path.append('/home/ubuntu/Hunyuan3D-2.1')

def generate_hybrid_3d(input_images, prompt, variant="standard"):
    """
    Unified pipeline: Input → 2mv Shape → 2.1 PBR → Output
    """
    try:
        # Step 1: Generate shape using 2mv
        print("🎭 Step 1: Generating shape with Hunyuan3D-2mv...")
        
        # Import 2mv pipeline
        from hy3dgen.shapegen import Hunyuan3DDiTFlowMatchingPipeline
        
        # Load 2mv model
        shape_pipe = Hunyuan3DDiTFlowMatchingPipeline.from_pretrained(
            "tencent/Hunyuan3D-2mv",
            subfolder=f"hunyuan3d-dit-v2-mv{'-%s' % variant if variant != 'standard' else ''}",
            use_safetensors=True,
            device="cuda"
        )
        
        # Process input (single image or multiview dict)
        if isinstance(input_images, str):
            # Single image
            image_input = input_images
        else:
            # Multiple images - create view dict
            image_input = {}
            view_names = ["front", "left", "back", "right", "top", "bottom"]
            for i, img in enumerate(input_images[:len(view_names)]):
                if img is not None:
                    image_input[view_names[i]] = img
        
        # Generate mesh
        mesh = shape_pipe(
            image=image_input,
            num_inference_steps=30,
            octree_resolution=380,
            num_chunks=20000,
            output_type="trimesh"
        )[0]
        
        # Save mesh temporarily
        mesh_path = tempfile.mktemp(suffix=".obj")
        mesh.export(mesh_path)
        print(f"✅ Shape generated: {mesh_path}")
        
        # Step 2: Add PBR textures using 2.1
        print("🎨 Step 2: Adding PBR textures with Hunyuan3D-2.1...")
        
        # Import 2.1 paint pipeline
        from hy3dpaint.textureGenPipeline import Hunyuan3DPaintPipeline
        
        # Load 2.1 paint model
        paint_pipe = Hunyuan3DPaintPipeline.from_pretrained(
            "tencent/Hunyuan3D-2.1",
            use_safetensors=True,
            device="cuda"
        )
        
        # Generate PBR textures
        reference_image = input_images[0] if isinstance(input_images, list) else input_images
        textured_mesh = paint_pipe(
            mesh_path=mesh_path,
            reference_image=reference_image,
            prompt=prompt,
            num_inference_steps=50,
            guidance_scale=7.5
        )
        
        # Save final result
        output_path = tempfile.mktemp(suffix=".glb")
        textured_mesh.export(output_path)
        print(f"✅ PBR textured mesh: {output_path}")
        
        return output_path, "✅ Hybrid generation complete! Shape: 2mv, Textures: 2.1 PBR"
        
    except Exception as e:
        return None, f"❌ Error: {str(e)}"

def create_interface():
    """Create unified Gradio interface"""
    
    with gr.Blocks(title="Hunyuan3D Hybrid (2mv + 2.1 PBR)") as interface:
        gr.Markdown("# 🎭 Hunyuan3D Hybrid Pipeline")
        gr.Markdown("**Automatic workflow**: Input → 2mv Shape Generation → 2.1 PBR Texturing")
        
        with gr.Row():
            with gr.Column():
                gr.Markdown("### 📸 Input Images")
                input_images = gr.Gallery(
                    label="Upload images (single for I2-3D, multiple for multiview)",
                    show_label=True,
                    elem_id="gallery",
                    columns=3,
                    rows=2,
                    object_fit="contain",
                    height="auto"
                )
                
                prompt = gr.Textbox(
                    label="Texture Prompt (optional)",
                    placeholder="Describe the material/texture you want...",
                    lines=2
                )
                
                variant = gr.Dropdown(
                    choices=["standard", "turbo", "fast"],
                    value="standard",
                    label="Model Variant",
                    info="standard=best quality, turbo=fast, fast=fastest"
                )
                
                generate_btn = gr.Button("🚀 Generate Hybrid 3D", variant="primary")
                
            with gr.Column():
                gr.Markdown("### 🎨 Generated 3D Model")
                output_model = gr.Model3D(
                    label="Hybrid Result (2mv Shape + 2.1 PBR)",
                    show_label=True,
                    height=400
                )
                
                status = gr.Textbook(
                    label="Status",
                    lines=3
                )
                
                gr.Markdown("### 📋 Pipeline Info")
                gr.Markdown("""
                - **Shape**: Hunyuan3D-2mv (supports single + multiview)
                - **Texture**: Hunyuan3D-2.1 PBR (production quality)
                - **VRAM**: ~27GB total (6GB shape + 21GB texture)
                - **Output**: GLB with PBR materials
                """)
        
        generate_btn.click(
            fn=generate_hybrid_3d,
            inputs=[input_images, prompt, variant],
            outputs=[output_model, status]
        )
    
    return interface

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="127.0.0.1", help="Host address")
    parser.add_argument("--port", type=int, default=7862, help="Port number")
    args = parser.parse_args()
    
    interface = create_interface()
    interface.launch(
        server_name=args.host,
        server_port=args.port,
        share=False
    )
EOF

# Create run script for hybrid interface
cat > "$HYBRID_DIR/run_hybrid.sh" << EOS
#!/usr/bin/env bash
set -Eeuo pipefail
HYBRID_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"

# Activate 2.1 environment (has both dependencies)
source /home/ubuntu/Hunyuan3D-2.1/hy3d-py311/bin/activate

# Set up Python paths for both models
export PYTHONPATH="/home/ubuntu/Hunyuan3D-2mv:/home/ubuntu/Hunyuan3D-2.1:/home/ubuntu/Hunyuan3D-2.1/hy3dshape:\${PYTHONPATH:-}"

# Set LD_LIBRARY_PATH for torch
export LD_LIBRARY_PATH="\$(python - <<'PY'
import os, torch; print(os.path.join(os.path.dirname(torch.__file__), "lib"))
PY
):\${LD_LIBRARY_PATH:-}"

echo "🎭 Starting Hunyuan3D Hybrid Interface..."
echo "🔗 Pipeline: Input → 2mv Shape → 2.1 PBR → Output"
echo "📡 Access: http://\${GRADIO_HOST:-127.0.0.1}:\${GRADIO_PORT:-7862}"

exec python "\$HYBRID_DIR/hybrid_app.py" \\
  --host \${GRADIO_HOST:-127.0.0.1} \\
  --port \${GRADIO_PORT:-7862}
EOS

chmod +x "$HYBRID_DIR/run_hybrid.sh"

# Final verification
echo ""
echo "🧪 Final Step: Verifying installation..."

# Check Tailscale status
TAILSCALE_IP=""
if command -v tailscale >/dev/null 2>&1; then
    TAILSCALE_IP=$(sudo tailscale ip -4 2>/dev/null || echo "")
    if [ -n "$TAILSCALE_IP" ]; then
        echo "   ✅ Tailscale connected: $TAILSCALE_IP"
    else
        echo "   ⚠️  Tailscale installed but not connected"
    fi
else
    echo "   ❌ Tailscale not installed"
fi

# Check installations
if [ -f "$HOME/Hunyuan3D-2mv/run_hunyuan3d_mv.sh" ] && [ -f "$HOME/Hunyuan3D-2.1/run_hunyuan3d.sh" ]; then
    echo "   ✅ Both Hunyuan3D models installed"
else
    echo "   ❌ Missing Hunyuan3D installations"
fi

if [ -f "$HYBRID_DIR/run_hybrid.sh" ]; then
    echo "   ✅ Hybrid interface created"
else
    echo "   ❌ Hybrid interface creation failed"
fi

# Display final access information
echo ""
echo "======================================================================"
echo "🎉 Hunyuan3D Hybrid Deployment Complete!"
echo "======================================================================"
echo "Timestamp: $(date -Is)"
echo "Model variant: $MODEL_VARIANT"

if [ -n "$TAILSCALE_IP" ]; then
    echo ""
    echo "🌐 Access via Tailscale (recommended):"
    echo "   Hybrid Interface: http://$TAILSCALE_IP:7862"
    echo "   SSH Access:      ssh ubuntu@$TAILSCALE_IP"
    echo ""
    echo "🔗 Direct access from any of your Tailscale-enabled devices!"
else
    # Get public IP for fallback
    PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "unknown")
    echo ""
    echo "🔗 Access via SSH tunnel:"
    echo "   ssh -L 7862:localhost:7862 ubuntu@$PUBLIC_IP"
    echo "   Then open: http://localhost:7862"
fi

echo ""
echo "🎭 Hybrid Pipeline Components:"
echo "   - Hunyuan3D-2mv: Shape generation (6GB VRAM)"
echo "   - Hunyuan3D-2.1: PBR texturing (21GB VRAM)"
echo "   - Unified interface: Automatic workflow"
echo "   - Run script: $HYBRID_DIR/run_hybrid.sh"

echo ""
echo "🔧 Usage:"
echo "   # Start unified hybrid interface:"
echo "   $HYBRID_DIR/run_hybrid.sh"
echo ""
echo "   # Or with custom settings:"
echo "   GRADIO_HOST=0.0.0.0 GRADIO_PORT=7862 $HYBRID_DIR/run_hybrid.sh"
echo ""
if [ -n "$TAILSCALE_IP" ]; then
    echo "   # Check Tailscale connection:"
    echo "   sudo tailscale status"
    echo ""
fi
echo "🎨 Unified Features:"
echo "   - Single interface for complete 3D generation"
echo "   - Automatic routing: Input → 2mv → 2.1 → Output"
echo "   - Supports single image AND multiview inputs"
echo "   - Production-ready PBR materials"
echo ""
echo "Ready for unified 3D generation! 🎨✨"