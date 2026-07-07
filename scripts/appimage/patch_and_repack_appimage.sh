#!/usr/bin/env bash
# Patch AppDir after appimage-builder, then overwrite the AppImage (avoids extract when AppDir exists).
set -euo pipefail

APPIMAGE="${1:?Usage: patch_and_repack_appimage.sh /path/to/AppImage [x86_64|aarch64]}"
ARCH="${2:-x86_64}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FINAL="$(readlink -f "$APPIMAGE")"

if [[ -d AppDir && -f AppDir/localsend_app ]]; then
  bash "$REPO_ROOT/scripts/appimage/patch_appdir_portable.sh" AppDir
  bash "$REPO_ROOT/scripts/appimage/verify_portable_appdir.sh" AppDir
  TMP="$(mktemp)"
  bash "$REPO_ROOT/scripts/appimage/pack_appimage_from_appdir.sh" AppDir "$TMP" "$ARCH"
  install -m 755 "$TMP" "$FINAL"
  rm -f "$TMP"
else
  bash "$REPO_ROOT/scripts/appimage/repack_appimage_portable.sh" "$FINAL" "$ARCH"
fi

# Sanity-check what users get after --appimage-extract
CHECKDIR="$(mktemp -d)"
trap 'rm -rf "$CHECKDIR"' EXIT
cp "$FINAL" "$CHECKDIR/$(basename "$FINAL")"
cd "$CHECKDIR"
chmod +x ./*.AppImage
./*.AppImage --appimage-extract
bash "$REPO_ROOT/scripts/appimage/verify_portable_appdir.sh" squashfs-root
