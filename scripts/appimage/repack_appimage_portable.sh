#!/usr/bin/env bash
# Extract a built AppImage, patch localsend_app for direct execution from squashfs-root,
# then repack with appimagetool (appimage-builder 1.1 has no post-AppDir recipe hook).
set -euo pipefail

APPIMAGE="${1:?Usage: repack_appimage_portable.sh /path/to/AppImage [x86_64|aarch64]}"
ARCH="${2:-x86_64}"

FINAL="$(readlink -f "$APPIMAGE")"
NAME="$(basename "$FINAL")"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

WORKDIR="$(mktemp -d)"
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

cp "$FINAL" "$WORKDIR/$NAME"
cd "$WORKDIR"
chmod +x "$NAME"
"./$NAME" --appimage-extract

bash "$REPO_ROOT/scripts/appimage/patch_appdir_portable.sh" squashfs-root
bash "$REPO_ROOT/scripts/appimage/verify_portable_appdir.sh" squashfs-root

OUT="$WORKDIR/${NAME}.repack"
bash "$REPO_ROOT/scripts/appimage/pack_appimage_from_appdir.sh" squashfs-root "$OUT" "$ARCH"
install -m 755 "$OUT" "$FINAL"
