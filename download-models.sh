#!/bin/sh
# Downloads models listed in models.json into basedir/models/<category>/
# Only workflows marked with active: true are processed.
# Requires: jq, curl

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
JSON_FILE="${1:-"$SCRIPT_DIR/models.json"}"
BASE_DIR="$SCRIPT_DIR/basedir/models"

for cmd in jq curl; do
  if ! command -v "$cmd" > /dev/null 2>&1; then
    echo "Error: $cmd is required but not installed"
    exit 1
  fi
done

if [ ! -f "$JSON_FILE" ]; then
  echo "Error: $JSON_FILE not found"
  exit 1
fi

if ! jq empty "$JSON_FILE" 2>/dev/null; then
  echo "Error: $JSON_FILE contains invalid JSON — removing all models"
  if [ -d "$BASE_DIR" ]; then
    find "$BASE_DIR" -name "*.safetensors" -type f -delete
    echo "   All .safetensors files removed from $BASE_DIR"
  fi
  exit 1
fi

# --- Orphan check (all workflows, regardless of active flag) ---

expected=$(mktemp)
orphans=$(mktemp)
trap 'rm -f "$expected" "$orphans"' EXIT INT TERM

jq -r '
  to_entries[] | .value.models | to_entries[] |
  . as {key: $cat, value: $urls} |
  $urls[] |
  $cat + "/" + (split("/") | last)
' "$JSON_FILE" | sort -u > "$expected"

if [ -d "$BASE_DIR" ]; then
  for category_dir in "$BASE_DIR"/*/; do
    [ -d "$category_dir" ] || continue
    category=$(basename "$category_dir")
    for filepath in "$category_dir"*.safetensors; do
      [ -f "$filepath" ] || continue
      key="$category/$(basename "$filepath")"
      if ! grep -qxF "$key" "$expected"; then
        echo "$filepath" >> "$orphans"
      fi
    done
  done
fi

if [ -s "$orphans" ]; then
  echo "⚠  Files not listed in $JSON_FILE:"
  while read -r f; do
    echo "   $(echo "$f" | sed "s|$BASE_DIR/||")"
  done < "$orphans"
  echo ""
  printf "Remove these files? [y/N] "
  read -r answer < /dev/tty
  if [ "$answer" = "y" ]; then
    while read -r f; do
      rm "$f"
      echo "   removed $(echo "$f" | sed "s|$BASE_DIR/||")"
    done < "$orphans"
    echo ""
  else
    echo "   Skipped."
    echo ""
  fi
fi

# --- Download active workflows ---

jq -r 'to_entries[] | select(.value.active == true) | .key' "$JSON_FILE" | \
while read -r workflow; do
  echo ""
  echo "▶  [$workflow]"

  jq -r --arg w "$workflow" '
    .[$w].models | to_entries[] |
    . as {key: $cat, value: $urls} |
    $urls[] |
    $cat + " " + .
  ' "$JSON_FILE" | while read -r category url; do
    filename=$(basename "$(echo "$url" | cut -d'?' -f1)")
    target_dir="$BASE_DIR/$category"
    target_path="$target_dir/$filename"

    mkdir -p "$target_dir"

    printf "   %s  " "$filename"

    headers=$(curl -sIL "$url")
    http_status=$(printf '%s' "$headers" | grep -i '^HTTP/' | tail -1 | awk '{print $2}')
    expected_size=$(printf '%s' "$headers" | grep -i '^content-length:' | tail -1 | tr -d '\r' | awk '{print $2}')

    case "$http_status" in
      2*) ;;
      *) echo "✗  HTTP ${http_status:-???} — file not available on server, skipping"; continue ;;
    esac

    # Minimum sane model size: 1 MB. Anything smaller is likely an error page.
    min_size=1048576
    if [ -n "$expected_size" ] && [ "$expected_size" -lt "$min_size" ] 2>/dev/null; then
      echo "✗  server reports only ${expected_size} bytes — not a valid model file, skipping"
      continue
    fi

    if [ -f "$target_path" ]; then
      local_size=$(stat -c%s "$target_path")
      if [ -n "$expected_size" ] && [ "$local_size" = "$expected_size" ]; then
        echo "✔  $((local_size / 1024 / 1024)) MB — up to date"
        continue
      elif [ -z "$expected_size" ]; then
        echo "✔  $((local_size / 1024 / 1024)) MB — up to date (unknown remote size)"
        continue
      else
        echo "size mismatch (local $((local_size / 1024 / 1024)) MB / remote $((expected_size / 1024 / 1024)) MB) — re-downloading"
      fi
    else
      if [ -n "$expected_size" ]; then
        echo "⬇  $((expected_size / 1024 / 1024)) MB  →  $category/"
      else
        echo "⬇  ? MB  →  $category/"
      fi
    fi

    if ! curl -L --progress-bar -o "$target_path" "$url"; then
      echo "✗  download failed — $url"
      rm -f "$target_path"
      continue
    fi

    downloaded_size=$(stat -c%s "$target_path" 2>/dev/null || echo 0)
    if [ "$downloaded_size" -lt "$min_size" ]; then
      echo "✗  downloaded file too small (${downloaded_size} bytes) — not a valid model, removing"
      rm -f "$target_path"
    fi
  done
done

echo ""
echo "✅  Done"
