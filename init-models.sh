#!/usr/bin/env bash

set -e

BASE_DIR="basedir/models"

echo "📁 Creating directories..."
mkdir -p "$BASE_DIR/checkpoints"
mkdir -p "$BASE_DIR/diffusion_models"
mkdir -p "$BASE_DIR/text_encoders"
mkdir -p "$BASE_DIR/vae"
mkdir -p "$BASE_DIR/loras"

# 📦 Lista modeli
URLS=(
  "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors"
  "https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/text_encoders/mistral_3_small_flux2_bf16.safetensors"
  "https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/diffusion_models/flux2_dev_fp8mixed.safetensors"
  "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors"
  "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors"
  "https://huggingface.co/ByteZSzn/Flux.2-Turbo-ComfyUI/resolve/main/Flux_2-Turbo-LoRA_comfyui.safetensors"
  "https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/vae/flux2-vae.safetensors"
)

echo "⬇️ Downloading models..."

for URL in "${URLS[@]}"; do
  FILE_NAME=$(basename "$URL")

  # 🧠 routing → katalog docelowy
  case "$URL" in
    */diffusion_models/*)
      TARGET_DIR="$BASE_DIR/diffusion_models"
      ;;
    */text_encoders/*)
      TARGET_DIR="$BASE_DIR/text_encoders"
      ;;
    */vae/*)
      TARGET_DIR="$BASE_DIR/vae"
      ;;
    */Flux*LoRA*|*/loras/*)
      TARGET_DIR="$BASE_DIR/loras"
      ;;
    *)
      echo "⚠️ Unknown model type for URL: $URL"
      continue
      ;;
  esac

  TARGET_PATH="$TARGET_DIR/$FILE_NAME"

  if [[ -f "$TARGET_PATH" ]]; then
    echo "✔ $FILE_NAME already exists"
    continue
  fi

  echo "➡️ Downloading $FILE_NAME → $TARGET_DIR"
  curl -L -o "$TARGET_PATH" "$URL"
done

echo "✅ All models ready"
