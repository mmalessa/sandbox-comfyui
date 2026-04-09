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

HEADERS = {"User-Agent": "Mozilla/5.0"}

def remote_size(url):
    """Return Content-Length from a HEAD request, or None if unavailable."""
    req = urllib.request.Request(url, headers=HEADERS, method='HEAD')
    try:
        with urllib.request.urlopen(req) as r:
            val = r.headers.get('Content-Length')
            return int(val) if val else None
    except Exception:
        return None

def download(url, target_path):
    req = urllib.request.Request(url, headers=HEADERS)
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
                print(f"\r   {pct}%  {downloaded // 1024 // 1024} / {total // 1024 // 1024} MB",
                      end='', flush=True)
    print()

for category, urls in categories.items():
    if not urls:
        continue
    target_dir = os.path.join(base_dir, category)
    os.makedirs(target_dir, exist_ok=True)

    for url in urls:
        filename = os.path.basename(url.split('?')[0])
        target_path = os.path.join(target_dir, filename)

        print(f"   {filename}", end='  ', flush=True)

        try:
            expected = remote_size(url)
        except Exception as e:
            print(f"\n✗  HEAD failed: {e}")
            continue

        if expected is None:
            print("(unknown remote size)", end='  ')

        local_size = os.path.getsize(target_path) if os.path.isfile(target_path) else None

        if local_size is not None and (expected is None or local_size == expected):
            print(f"✔  {local_size // 1024 // 1024} MB — up to date")
            continue

        if local_size is not None:
            print(f"size mismatch (local {local_size // 1024 // 1024} MB / remote {expected // 1024 // 1024} MB) — re-downloading")
        else:
            size_str = f"{expected // 1024 // 1024} MB" if expected else "? MB"
            print(f"⬇  {size_str}  →  {category}/")

        try:
            download(url, target_path)
        except urllib.error.HTTPError as e:
            print(f"\n✗  HTTP {e.code} — {url}")
            if os.path.exists(target_path):
                os.remove(target_path)
        except Exception as e:
            print(f"\n✗  {e} — {url}")
            if os.path.exists(target_path):
                os.remove(target_path)

print("✅  Done")
EOF
