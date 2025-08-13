# Hunyuan3D-2.1 on Ubuntu 24.04 (Py 3.11, CUDA 12.x) — **Quick Use & Options**

## TL;DR — Start it

```bash
# on the VM
~/Hunyuan3D-2.1/run_hunyuan3d.sh
```

### Access the UI (from your laptop)

```bash
ssh -i ~/.ssh/<KEY> -L 7860:localhost:7860 ubuntu@<VM_IP>
# then open:
http://localhost:7860
```

---

## Most useful options (put these in front)

You can pass these **as env vars** or by **editing the run script**:

* **Port / Host**

  ```bash
  GRADIO_PORT=7861 GRADIO_HOST=127.0.0.1 ~/Hunyuan3D-2.1/run_hunyuan3d.sh
  ```
* **Low VRAM mode** (safer on smaller GPUs; already enabled in the script)

  * Keep `--low_vram_mode` in the run script, or remove it for H100/A100.
* **Disable textures (shape-only)** if you want faster runs:

  ```bash
  # add this to the python command inside run_hunyuan3d.sh
  --disable_tex
  ```
* **Model paths** (defaults are correct; only change if you mirror/cache elsewhere)

  * `--model_path tencent/Hunyuan3D-2.1`
  * `--subfolder hunyuan3d-dit-v2-1`
  * `--texgen_model_path tencent/Hunyuan3D-2.1`
* **Where outputs go**

  * UI writes under: `~/Hunyuan3D-2.1/save_dir/<uuid>/…`

> The runner (`run_hunyuan3d.sh`) already sets the tricky env (Torch libs, PYTHONPATH) for textures to work.

---

## File locations (you’ll reach for these a lot)

* **Repo:** `~/Hunyuan3D-2.1`
* **Venv:** `~/Hunyuan3D-2.1/hy3d-py311`
* **Runner:** `~/Hunyuan3D-2.1/run_hunyuan3d.sh`
* **Weights cache:** `~/.cache/hy3dgen/tencent/Hunyuan3D-2.1`
* **ESRGAN ckpt:** `~/Hunyuan3D-2.1/hy3dpaint/ckpt/RealESRGAN_x4plus.pth`
* **Outputs:** `~/Hunyuan3D-2.1/save_dir/…`

---

## Install it (one-shot script)

Create the installer with **vim** and paste the script we built:

```bash
vim ~/install_hunyuan3d21_2404.sh
# in vim: :set paste  → i → paste → Esc → :set nopaste → :wq
chmod +x ~/install_hunyuan3d21_2404.sh
~/install_hunyuan3d21_2404.sh
```

What it does:

* Installs **Python 3.11**, system deps
* Clones/updates the repo
* Installs **PyTorch 2.5.1 (cu124)** + pins to avoid known breakages
* Builds native bits:

  * `custom_rasterizer` (against Torch)
  * `mesh_inpaint_processor` for **cp311** (via **pybind11 2.13.4**)
* Downloads ESRGAN and model weights
* Writes `run_hunyuan3d.sh` (the runner)

> It’s **idempotent**: it won’t delete your repo/weights; it rebuilds in place.

---

## Health checks

```bash
# Is the server listening?
ss -ltnp | grep :7860 || true
curl -I http://127.0.0.1:7860
curl -s http://127.0.0.1:7860/config | head -c 300; echo
```

---

## Known-good pins (why these matter)

* `gradio==5.33.0`, `gradio_client==1.10.2`, `pydantic==2.10.6` → fixes **“Loading…”** loop
* `numpy==1.26.4`, `opencv-python-headless==4.8.1.78` → avoids `_ARRAY_API` / `multiarray` errors
* `pybind11==2.13.4` → reliable include paths for building the mesh inpaint module
* Torch cu124 wheels work fine with NVIDIA **570**/**CUDA 12.8** driver/runtime on 24.04

---

## Troubleshooting (the real fixes we used)

* **UI stuck on “Loading…”**
  Re-pin: `pip install -U "gradio==5.33.0" "gradio_client==1.10.2" "pydantic==2.10.6"`
  Run on `--host 127.0.0.1 --port 7860`, hard refresh or new private window.

* **`ImportError: libc10.so` (loading native modules)**
  Torch shared libs must be on `LD_LIBRARY_PATH`. The runner already does:

  ```bash
  export LD_LIBRARY_PATH="$(python - <<'PY'
  import os, torch; print(os.path.join(os.path.dirname(torch.__file__), "lib"))
  PY
  ):${LD_LIBRARY_PATH:-}"
  ```

* **`custom_rasterizer` missing `rasterize`**
  Build without isolation (so setup sees Torch):

  ```bash
  cd ~/Hunyuan3D-2.1/hy3dpaint/custom_rasterizer
  pip uninstall -y custom_rasterizer || true
  pip install . --no-build-isolation
  ```

* **`NameError: meshVerticeInpaint` or `mesh_painter` import issues**
  Rebuild the mesh inpaint extension for **Python 3.11**:

  ```bash
  cd ~/Hunyuan3D-2.1/hy3dpaint/DifferentiableRenderer
  pip install -U 'pybind11==2.13.4'
  rm -f mesh_inpaint_processor*.so
  INCLUDES="$(python3.11 -m pybind11 --includes)"
  PYINC="$(python3.11 -c 'import sysconfig; print(sysconfig.get_paths()["include"])')"
  EXT="$(python3.11-config --extension-suffix)"
  c++ -O3 -Wall -shared -std=c++11 -fPIC \
    $INCLUDES -I"$PYINC" \
    mesh_inpaint_processor.cpp \
    -o "mesh_inpaint_processor$EXT"
  ```

  And ensure it’s on `PYTHONPATH` at runtime (runner already does).

* **`ModuleNotFoundError: hy3dshape.utils`**
  Run from repo root (the runner now `cd`s into it). Manually:

  ```bash
  cd ~/Hunyuan3D-2.1 && ./run_hunyuan3d.sh
  ```

---

## Rebuilding after upgrades (Torch/Python)

```bash
# custom_rasterizer
cd ~/Hunyuan3D-2.1/hy3dpaint/custom_rasterizer
pip uninstall -y custom_rasterizer || true
pip install . --no-build-isolation

# mesh_inpaint (Py3.11)
cd ~/Hunyuan3D-2.1/hy3dpaint/DifferentiableRenderer
pip install -U 'pybind11==2.13.4'
rm -f mesh_inpaint_processor*.so
INCLUDES="$(python3.11 -m pybind11 --includes)"
PYINC="$(python3.11 -c 'import sysconfig; print(sysconfig.get_paths()["include"])')"
EXT="$(python3.11-config --extension-suffix)"
c++ -O3 -Wall -shared -std=c++11 -fPIC $INCLUDES -I"$PYINC" \
  mesh_inpaint_processor.cpp -o "mesh_inpaint_processor$EXT"
```

---

## Notes

* **Textures** are fully enabled on Ubuntu **24.04** + **Py 3.11** (`bpy>=4.2`).
* On **22.04**, keep **shape-only** (Blender/Embree mismatch there).
* Keep `--low_vram_mode` on smaller GPUs; remove it for big cards (H100/A100).
* For headless/batch workflows, you can script against the Gradio API or call the pipelines directly once you’re happy with settings.

---

If you want this README bundled into your repo (e.g., `README-setup.md`), just drop it in `~/Hunyuan3D-2.1/` and commit.
