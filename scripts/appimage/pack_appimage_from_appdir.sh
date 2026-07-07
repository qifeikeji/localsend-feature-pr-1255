#!/usr/bin/env bash
set -euo pipefail

APPDIR="${1:?Usage: pack_appimage_from_appdir.sh AppDir output.AppImage [x86_64|aarch64]}"
OUT="${2:?}"
ARCH="${3:-x86_64}"

WORKDIR="$(mktemp -d)"
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

TOOL="appimagetool-${ARCH}.AppImage"
TOOL_URL="https://github.com/AppImage/AppImageKit/releases/download/continuous/${TOOL}"
cd "$WORKDIR"
curl -fsSL -o "$TOOL" "$TOOL_URL"
chmod +x "$TOOL"

export ARCH="$ARCH"
APPIMAGE_EXTRACT_AND_RUN=1 "./$TOOL" --no-appstream "$(readlink -f "$APPDIR")" "$(readlink -f "$OUT")"
