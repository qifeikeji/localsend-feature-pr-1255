#!/usr/bin/env bash
# Extract a built AppImage, patch localsend_app for direct execution from squashfs-root,
# then repack with appimagetool (appimage-builder 1.1 has no post-AppDir recipe hook).
set -euo pipefail

APPIMAGE="${1:?Usage: repack_appimage_portable.sh /path/to/AppImage [x86_64|aarch64]}"
ARCH="${2:-x86_64}"

ROOT="$(cd "$(dirname "$APPIMAGE")" && pwd)"
NAME="$(basename "$APPIMAGE")"
cd "$ROOT"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

chmod +x "$NAME"
"./$NAME" --appimage-extract
bash "$REPO_ROOT/scripts/appimage/patch_appdir_portable.sh" squashfs-root

TOOL="appimagetool-${ARCH}.AppImage"
TOOL_URL="https://github.com/AppImage/AppImageKit/releases/download/continuous/${TOOL}"
if [[ ! -x "$TOOL" ]]; then
  curl -fsSL -o "$TOOL" "$TOOL_URL"
  chmod +x "$TOOL"
fi

OUT="${NAME}.repack"
rm -f "$OUT"
export ARCH="$ARCH"
APPIMAGE_EXTRACT_AND_RUN=1 "./$TOOL" --no-appstream squashfs-root "$OUT"
mv "$OUT" "$NAME"
rm -rf squashfs-root
