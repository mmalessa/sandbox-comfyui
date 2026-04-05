#!/usr/bin/env bash
# This script downloads selected models used for TXT2IMG and IMG2VIDEO workflows.

set -e

BASE_DIR="basedir/models"

echo "📁 Creating directories..."
mkdir -p "$BASE_DIR/checkpoints"
mkdir -p "$BASE_DIR/diffusion_models"
mkdir -p "$BASE_DIR/text_encoders"
mkdir -p "$BASE_DIR/vae"
mkdir -p "$BASE_DIR/loras"
mkdir -p "$BASE_DIR/clip_vision"

# 📦 Lista modeli
URLS=(
  "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors"
  "https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/text_encoders/mistral_3_small_flux2_bf16.safetensors"
  "https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/diffusion_models/flux2_dev_fp8mixed.safetensors"
  "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors"
  "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors"
  "https://huggingface.co/ByteZSzn/Flux.2-Turbo-ComfyUI/resolve/main/Flux_2-Turbo-LoRA_comfyui.safetensors"
  "https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/vae/flux2-vae.safetensors"

  "https://huggingface.co/Comfy-Org/sigclip_vision_384/resolve/main/sigclip_vision_patch14_384.safetensors"
  "https://huggingface.co/Comfy-Org/HunyuanVideo_1.5_repackaged/resolve/main/split_files/diffusion_models/capybara_v0.1.safetensors"
  "https://huggingface.co/Comfy-Org/HunyuanImage_2.1_ComfyUI/resolve/main/split_files/text_encoders/qwen_2.5_vl_7b.safetensors"
  "https://huggingface.co/Comfy-Org/HunyuanVideo_1.5_repackaged/resolve/main/split_files/text_encoders/byt5_small_glyphxl_fp16.safetensors"
  "https://huggingface.co/Comfy-Org/HunyuanVideo_1.5_repackaged/resolve/main/split_files/vae/hunyuanvideo15_vae_fp16.safetensors"
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
    *sigclip*|*clip_vision*)
      TARGET_DIR="$BASE_DIR/clip_vision"
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
