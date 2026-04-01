# sandbox-comfyui

Local sandbox for running [ComfyUI](https://github.com/comfyanonymous/ComfyUI) with NVIDIA GPU acceleration in Docker.

## Requirements

- Docker with NVIDIA GPU support (`nvidia-container-toolkit`)
- `make`

## Quick start

```bash
# Download models to basedir/models/
make init

# Start the container
make up
```

ComfyUI available at: http://localhost:8188

## Commands

| Command | Description |
|---------|-------------|
| `make up` | Start the container |
| `make down` | Stop the container |
| `make logs` | Follow container logs |
| `make sh` | Open a shell in the container |
| `make init` | Download models from HuggingFace |

## Structure

```
basedir/        # ComfyUI data (models, output, custom nodes)
run/            # ComfyUI installation, venv, HF cache
compose.yaml    # Docker Compose configuration
init-models.sh  # Model download script
```
