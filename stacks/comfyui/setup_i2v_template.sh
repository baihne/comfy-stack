#!/usr/bin/env bash
set -euo pipefail

# Setup Wan 2.2 I2V Default Template
echo "Setting up Wan 2.2 I2V default workflow template..."

cd ~/ComfyUI

# Create user workflow directory if it doesn't exist
mkdir -p user/default/workflows

# Create a basic I2V workflow template
cat > user/default/workflows/wan22_i2v_template.json << 'EOF'
{
  "last_node_id": 7,
  "last_link_id": 6,
  "nodes": [
    {
      "id": 1,
      "type": "LoadImageMask",
      "pos": [100, 100],
      "size": {"0": 300, "1": 200},
      "flags": {},
      "order": 0,
      "mode": 0,
      "outputs": [
        {"name": "IMAGE", "type": "IMAGE", "links": [1]}
      ],
      "properties": {},
      "widgets_values": [""]
    },
    {
      "id": 2,
      "type": "DiffusionModelLoader", 
      "pos": [100, 350],
      "size": {"0": 300, "1": 100},
      "flags": {},
      "order": 1,
      "mode": 0,
      "outputs": [
        {"name": "MODEL", "type": "MODEL", "links": [2]}
      ],
      "properties": {},
      "widgets_values": ["wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors"]
    },
    {
      "id": 3,
      "type": "VAELoader",
      "pos": [100, 500],
      "size": {"0": 300, "1": 100},
      "flags": {},
      "order": 2,
      "mode": 0,
      "outputs": [
        {"name": "VAE", "type": "VAE", "links": [3]}
      ],
      "properties": {},
      "widgets_values": ["wan_2.1_vae.safetensors"]
    },
    {
      "id": 4,
      "type": "TextEncoderLoader",
      "pos": [450, 100],
      "size": {"0": 300, "1": 100},
      "flags": {},
      "order": 3,
      "mode": 0,
      "outputs": [
        {"name": "TEXT_ENCODER", "type": "TEXT_ENCODER", "links": [4]}
      ],
      "properties": {},
      "widgets_values": ["umt5_xxl_fp8_e4m3fn_scaled.safetensors"]
    },
    {
      "id": 5,
      "type": "LoraLoader",
      "pos": [450, 250],
      "size": {"0": 300, "1": 150},
      "flags": {},
      "order": 4,
      "mode": 0,
      "inputs": [
        {"name": "model", "type": "MODEL", "link": 2}
      ],
      "outputs": [
        {"name": "MODEL", "type": "MODEL", "links": [5]}
      ],
      "properties": {},
      "widgets_values": ["wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors", 1.0]
    },
    {
      "id": 6,
      "type": "VideoSampler",
      "pos": [800, 100],
      "size": {"0": 300, "1": 250},
      "flags": {},
      "order": 5,
      "mode": 0,
      "inputs": [
        {"name": "model", "type": "MODEL", "link": 5},
        {"name": "text_encoder", "type": "TEXT_ENCODER", "link": 4},
        {"name": "vae", "type": "VAE", "link": 3},
        {"name": "image", "type": "IMAGE", "link": 1}
      ],
      "outputs": [
        {"name": "VIDEO", "type": "VIDEO", "links": [6]}
      ],
      "properties": {},
      "widgets_values": [
        "A person walking through the scene",
        "",
        512, 512,
        25,
        6.0,
        1,
        123456789
      ]
    },
    {
      "id": 7,
      "type": "SaveVideo",
      "pos": [1150, 100],
      "size": {"0": 300, "1": 100},
      "flags": {},
      "order": 6,
      "mode": 0,
      "inputs": [
        {"name": "video", "type": "VIDEO", "link": 6}
      ],
      "properties": {},
      "widgets_values": ["wan22_i2v_output"]
    }
  ],
  "links": [
    [1, 1, 0, 6, 3, "IMAGE"],
    [2, 2, 0, 5, 0, "MODEL"],
    [3, 3, 0, 6, 2, "VAE"],
    [4, 4, 0, 6, 1, "TEXT_ENCODER"],
    [5, 5, 0, 6, 0, "MODEL"],
    [6, 6, 0, 7, 0, "VIDEO"]
  ],
  "groups": [],
  "config": {},
  "extra": {},
  "version": 0.4
}
EOF

echo "✅ Wan 2.2 I2V template created at user/default/workflows/wan22_i2v_template.json"
echo "📁 You can load this template in ComfyUI to get started with I2V generation"
echo "🎬 Template includes: Image input, Wan 2.2 I2V models, LoRAs, and video output"