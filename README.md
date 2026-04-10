# sandbox-comfyui

Local sandbox for running [ComfyUI](https://github.com/comfyanonymous/ComfyUI) with NVIDIA GPU acceleration in Docker.

## Requirements

- Docker with NVIDIA GPU support (`nvidia-container-toolkit`)
- `make`

## Quick start

```bash
# Check if nvidia-container-toolkit is installed
make nv-check

# If not installed, set it up (Ubuntu 22.04 x86_64)
make nv-prepare
sudo systemctl restart docker

# Start the container
make up
```

ComfyUI available at: http://localhost:8188

## Commands

| Command | Description |
|---------|-------------|
| `make nv-check` | Check if `nvidia-container-toolkit` is installed |
| `make nv-prepare` | Install `nvidia-container-toolkit` and configure Docker runtime |
| `make up` | Start the container |
| `make down` | Stop the container |
| `make logs` | Follow container logs |
| `make sh` | Open a shell in the container |

## Models

Models are defined in `models.json`, grouped by workflow and ComfyUI category:

```json
{
  "workflow_name": {
    "active": true,
    "models": {
      "checkpoints": ["https://huggingface.co/..."],
      "diffusion_models": ["..."],
      "text_encoders": ["..."],
      "vae": ["..."],
      "loras": ["..."],
      "upscale_models": ["..."]
    }
  }
}
```

Edit `models.json` manually to add or remove models, then run:

```bash
./download-models.sh
# or with a custom file
./download-models.sh /path/to/models.json
```

Files are downloaded to `basedir/models/<category>/`. Already-existing files are skipped.
Workflows with `active: false` are skipped. On startup the script checks for files in
`basedir/models/` that are not listed in `models.json` and offers to remove them.

## Structure

```
basedir/            # ComfyUI data (models, output, custom nodes)
run/                # ComfyUI installation, venv, HF cache
compose.yaml        # Docker Compose configuration
models.json         # Model list grouped by workflow (edit to add/remove models)
download-models.sh  # Model download script (requires jq, curl)
```
