#!/usr/bin/env bash
# After appimage-builder bundles dependencies, reset the main binary so it can be
# executed directly from an extracted squashfs-root/ (not only via ./AppRun).
# AppImage-builder often sets PT_INTERP to a bundled ld-linux path that the kernel
# cannot resolve when the bundle is moved or extracted outside the FUSE mount.
set -euo pipefail

APPDIR="${1:-AppDir}"
BINARY="$APPDIR/localsend_app"

if [[ ! -f "$BINARY" ]]; then
  echo "patch_appdir_portable: missing $BINARY" >&2
  exit 1
fi

if ! command -v patchelf >/dev/null 2>&1; then
  echo "patch_appdir_portable: patchelf is required" >&2
  exit 1
fi

INTERP=""
for candidate in \
  /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 \
  /lib64/ld-linux-x86-64.so.2 \
  /lib/aarch64-linux-gnu/ld-linux-aarch64.so.1 \
  /lib64/ld-linux-aarch64.so.1
do
  if [[ -e "$candidate" ]]; then
    INTERP="$candidate"
    break
  fi
done

if [[ -z "$INTERP" ]]; then
  echo "patch_appdir_portable: system dynamic linker not found" >&2
  exit 1
fi

# Kernel loads PT_INTERP as a plain path ($ORIGIN is not supported). Libraries use RUNPATH.
RPATH='$ORIGIN/lib:$ORIGIN/usr/lib:$ORIGIN/usr/lib/x86_64-linux-gnu:$ORIGIN/usr/lib/aarch64-linux-gnu'

patchelf --set-interpreter "$INTERP" "$BINARY"
patchelf --set-rpath "$RPATH" "$BINARY"
