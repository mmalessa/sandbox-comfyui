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

## Structure

```
basedir/        # ComfyUI data (models, output, custom nodes)
run/            # ComfyUI installation, venv, HF cache
compose.yaml    # Docker Compose configuration
init-models.sh  # Model download script
```
