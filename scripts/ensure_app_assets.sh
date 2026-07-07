#!/usr/bin/env bash
# Ensures bundled UI images/icons exist before Flutter build (CI or sparse checkout).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ASSET_DIR="$ROOT/app/assets/img"
BASE_URL="${LOCALSEND_ASSETS_BASE:-https://raw.githubusercontent.com/localsend/localsend/main/app/assets/img}"

mkdir -p "$ASSET_DIR"

FILES=(
  logo-32.png
  logo-32-white.png
  logo-32-black.png
  logo-128.png
  logo-256.png
  logo-512.png
  logo.ico
)

for f in "${FILES[@]}"; do
  if [[ ! -s "$ASSET_DIR/$f" ]]; then
    echo "Downloading missing asset: $f"
    curl -fsSL "$BASE_URL/$f" -o "$ASSET_DIR/$f"
  fi
done

echo "App assets OK under $ASSET_DIR"
