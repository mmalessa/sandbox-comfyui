#!/usr/bin/env bash
# Downloads models listed in models.yaml into basedir/models/<category>/

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YAML_FILE="${1:-"$SCRIPT_DIR/models.yaml"}"
BASE_DIR="$SCRIPT_DIR/basedir/models"

if [[ ! -f "$YAML_FILE" ]]; then
  echo "Error: $YAML_FILE not found"
  exit 1
fi

# Parse YAML and download — requires python3
python3 - "$YAML_FILE" "$BASE_DIR" <<'EOF'
import sys
import os
import urllib.request
import urllib.error

yaml_file = sys.argv[1]
base_dir  = sys.argv[2]

# Minimal YAML parser: handles only the flat list-of-strings structure used here.
def parse_yaml(path):
    result = {}
    current_key = None
    with open(path) as f:
        for raw in f:
            line = raw.rstrip()
            # skip comments and empty lines
            stripped = line.lstrip()
            if not stripped or stripped.startswith('#'):
                continue
            # top-level key
            if not line.startswith(' ') and not line.startswith('\t') and line.endswith(':'):
                current_key = line[:-1].strip()
                result[current_key] = []
            elif not line.startswith(' ') and not line.startswith('\t') and ': []' in line:
                key = line.split(':')[0].strip()
                result[key] = []
                current_key = key
            elif current_key is not None and stripped.startswith('- '):
                url = stripped[2:].strip()
                # ignore inline comments
                url = url.split('  #')[0].strip()
                if url:
                    result[current_key].append(url)
    return result

categories = parse_yaml(yaml_file)

for category, urls in categories.items():
    if not urls:
        continue
    target_dir = os.path.join(base_dir, category)
    os.makedirs(target_dir, exist_ok=True)

    for url in urls:
        filename = os.path.basename(url.split('?')[0])
        target_path = os.path.join(target_dir, filename)

        if os.path.isfile(target_path):
            print(f"✔  {filename} already exists")
            continue

        print(f"⬇  {filename}  →  {category}/")
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req) as response, open(target_path, 'wb') as out:
                total = int(response.headers.get('Content-Length', 0))
                downloaded = 0
                block = 1024 * 1024  # 1 MB
                while True:
                    chunk = response.read(block)
                    if not chunk:
                        break
                    out.write(chunk)
                    downloaded += len(chunk)
                    if total:
                        pct = downloaded * 100 // total
                        print(f"\r   {pct}% ({downloaded // 1024 // 1024} MB / {total // 1024 // 1024} MB)", end='', flush=True)
            print()
        except urllib.error.HTTPError as e:
            print(f"\n✗  HTTP {e.code} — {url}")
            # remove partial file
            if os.path.exists(target_path):
                os.remove(target_path)
        except Exception as e:
            print(f"\n✗  {e} — {url}")
            if os.path.exists(target_path):
                os.remove(target_path)

print("✅  Done")
EOF
