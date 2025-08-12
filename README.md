# comfy-stack

Bootstrap ComfyUI on a fresh HyperStack VM (Ubuntu 24.04 + CUDA 12.8), keep it idempotent, and run it as a systemd service bound to `127.0.0.1` (access via SSH tunnel). Includes an optional post-boot script to download Wan 2.2 models (5B / 14B T2V / 14B I2V). Good defaults for A4000 testing; use H100 80GB for Wan 2.2 A14B variants.

---

## Requirements

* HyperStack VM image: Ubuntu 24.04 LTS with NVIDIA drivers + CUDA 12.8
* SSH key for the `ubuntu` user
* Disk space: recommend ≥100 GB free if using Wan 2.2 (models + cache + outputs)
* Network egress to GitHub and Hugging Face

---

## Quick start (manual)

1. SSH to a new VM:

   ```
   ssh -i ~/.ssh/HyperStackCanada_Hyperstack ubuntu@<VM_IP>
   ```

2. Clone repo and run bootstrap:

   ```
   git clone https://github.com/baihne/comfy-stack
   cd comfy-stack/scripts
   ./bootstrap_comfy.sh
   ```

3. Connect from your laptop via SSH tunnel (keep this terminal open):

   ```
   ssh -i ~/.ssh/HyperStackCanada_Hyperstack -L 8188:localhost:8188 ubuntu@<VM_IP>
   ```

   Open in your browser:

   ```
   http://localhost:8188
   ```

---

## Cloud-init deployment (HyperStack)

Paste this into the VM’s “Cloud-init scripts” field when creating a VM:

```
#cloud-config
runcmd:
  - [ su, -l, ubuntu, -c, "cd /home/ubuntu && git clone https://github.com/<you>/comfy-stack || true" ]
  - [ su, -l, ubuntu, -c, "cd /home/ubuntu/comfy-stack/scripts && ./bootstrap_comfy.sh" ]
```

Replace `https://github.com/baihne/comfy-stack` with your repo URL. After boot, tunnel from your laptop:

```
ssh -i ~/.ssh/<KEY> -L 8188:localhost:8188 ubuntu@<VM_IP>
# http://localhost:8188
```

systemctl is-active comfyui
wait to be active (about 4min since the start of the VM)


---

## Repository layout

```
comfy-stack/
  README.md
  .gitignore
  cloud-init/
    user-data.yaml
  systemd/
    comfyui.service
  scripts/
    bootstrap_comfy.sh
    wan22-download.sh
  workflows/
    test_workflow.json
```

---

## What bootstrap does

* Installs minimal system deps: `python3-venv`, `pip`, `git`, `curl`
* Clones/updates ComfyUI into `~/ComfyUI`
* Creates/activates Python venv `~/ComfyUI/comfy-env`
* Installs ComfyUI requirements
* Installs PyTorch CUDA 12.8 wheels
* Installs/updates ComfyUI-Manager
* (Optional) Downloads SD1.5 fp16 checkpoint for a quick smoke test
* Installs and enables a systemd service that binds ComfyUI to `127.0.0.1:8188`

---

## Wan 2.2 (post-boot)

Run one of the following on the VM **after** bootstrap completes:

```
# 5B hybrid (may OOM on 16 GB GPUs, better on larger cards)
~/comfy-stack/scripts/wan22-download.sh TI2V_5B

# 14B Text->Video (H100 80GB recommended)
~/comfy-stack/scripts/wan22-download.sh T2V_A14B

# 14B Image->Video (H100 80GB recommended)
~/comfy-stack/scripts/wan22-download.sh I2V_A14B
```

This installs the required Wan 2.2 files into ComfyUI’s expected folders and restarts the service.

### Disk planning (approx)

* 5B diffusion: \~10 GB
* 14B shards: \~14.3 GB × 2
* Wan 2.2 VAE (for 5B): \~1.4 GB
* Wan 2.1 VAE (for 14B): \~0.25 GB
* UMT5-XXL FP8 text encoder: \~6.7 GB

---

## Service control and logs

```
# status
systemctl status comfyui --no-pager

# logs
journalctl -u comfyui -n 100 --no-pager

# restart / stop
sudo systemctl restart comfyui
sudo systemctl stop comfyui
```

The service binds to `127.0.0.1:8188`. Use an SSH tunnel to access the UI from your laptop.

---

## SSH tunnel helper (optional)

Add this function to your local `~/.bashrc` or `~/.zshrc`:

```
comfyconnect() {
  if [ -z "$1" ]; then echo "Usage: comfyconnect <VM_IP>"; return 1; fi
  ssh -i ~/.ssh/<KEY> -L 8188:localhost:8188 ubuntu@"$1"
}
```

Then run:

```
comfyconnect <VM_IP>
# open http://localhost:8188
```

---

## Smoke test workflow (SD1.5)

Trigger a tiny txt2img to validate the stack:

```
curl -s -X POST -H "Content-Type: application/json" \
  -d @workflows/test_workflow.json http://localhost:8188/prompt >/dev/null
ls -1t ~/ComfyUI/output | head
```

---

## Troubleshooting

* Cloud-init logs:

  ```
  sudo tail -n 120 /var/log/cloud-init-output.log
  sudo cloud-init status --long
  ```
* Service not running:

  ```
  systemctl status comfyui --no-pager
  journalctl -u comfyui -n 200 --no-pager
  ```
* Port check:

  ```
  ss -ltnp | grep 8188 || true
  curl -s http://localhost:8188/ | head -n 1
  ```

---

## Security note

The service is **not** exposed publicly by default (binds to `127.0.0.1`). If you need public access, change `--listen 127.0.0.1` to `--listen 0.0.0.0` in `systemd/comfyui.service` and restrict access using firewall/security groups.
