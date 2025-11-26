#!/usr/bin/env bash
set -euo pipefail

# Interactive launcher for comfy-stack deployments.
# Prompts for Tailscale auth key and HF token once, then dispatches to selected script.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

prompt_var() {
  local var_name="$1" prompt="$2" default_val="${3:-}"
  local current="${!var_name:-}"
  local input
  read -r -p "$prompt [${current:-$default_val}]: " input
  if [ -n "$input" ]; then
    export "$var_name"="$input"
  elif [ -n "$current" ]; then
    export "$var_name"="$current"
  elif [ -n "$default_val" ]; then
    export "$var_name"="$default_val"
  fi
}

select_option() {
  cat <<'EOF'
Select deployment:
  1) ComfyUI + Flux 2 (repack / FP8 mixed, Comfy-Org/flux2-dev; smallest download)
  2) ComfyUI + Flux 2 (full upstream, black-forest-labs/FLUX.2-dev; ~178GB)
  3) ComfyUI + Wan2.2 (TI2V_5B | T2V_A14B | I2V_A14B)
  4) Hunyuan3D-2mv Optimized (100GB VPS)
  5) Hunyuan3D Hybrid (larger VPS)
  6) Complete stack
EOF
  local choice
  read -r -p "Enter choice [1-6]: " choice
  # trim spaces
  choice="${choice#"${choice%%[![:space:]]*}"}"
  choice="${choice%"${choice##*[![:space:]]}"}"
  echo "$choice"
}

main() {
  CHOICE="$(select_option)"

  # Common prompts
  prompt_var TAILSCALE_AUTH_KEY "Tailscale auth key (empty to skip)" ""
  prompt_var HF_TOKEN "Hugging Face token (if needed; empty to skip)" ""

  case "$CHOICE" in
    1)
      echo "Launching ComfyUI + Flux 2 (repack)..."
      exec "$REPO_ROOT/deployment/deploy_comfyui_flux2_dev.sh" "${TAILSCALE_AUTH_KEY:-}"
      ;;
    2)
      echo "Launching ComfyUI + Flux 2 (full upstream)..."
      exec "$REPO_ROOT/deployment/deploy_comfyui_flux2_full.sh" "${TAILSCALE_AUTH_KEY:-}"
      ;;
    3)
      prompt_var MODEL_VARIANT "Wan2.2 model variant (TI2V_5B|T2V_A14B|I2V_A14B)" "I2V_A14B"
      echo "Launching ComfyUI + Wan2.2..."
      exec "$REPO_ROOT/deployment/deploy_comfyui_wan.sh" "${MODEL_VARIANT:-I2V_A14B}" "${TAILSCALE_AUTH_KEY:-}"
      ;;
    4)
      echo "Launching Hunyuan3D-2mv Optimized..."
      exec "$REPO_ROOT/deployment/deploy_hunyuan_2mv_optimized.sh" "${TAILSCALE_AUTH_KEY:-}" "standard"
      ;;
    5)
      echo "Launching Hunyuan3D Hybrid..."
      exec "$REPO_ROOT/deployment/deploy_hunyuan_hybrid.sh" "${TAILSCALE_AUTH_KEY:-}" "standard"
      ;;
    6)
      echo "Launching complete stack..."
      exec "$REPO_ROOT/deployment/deploy_complete_stack.sh" "${TAILSCALE_AUTH_KEY:-}"
      ;;
    *)
      echo "Invalid choice." >&2
      exit 1
      ;;
  esac
}

main "$@"
