#!/usr/bin/env bash
# Make extracted squashfs-root runnable on any distro (Arch/Manjaro, Ubuntu, …).
# Flutter needs /proc/self/exe to point at the real binary — do not launch via ld-linux.
set -euo pipefail

APPDIR="${1:-AppDir}"
BINARY="$APPDIR/localsend_app"
REAL="$APPDIR/localsend_app.bin"
APPRUN_ENV="$APPDIR/AppRun.env"

if [[ ! -f "$BINARY" && ! -f "$REAL" ]]; then
  echo "patch_appdir_portable: missing $BINARY" >&2
  exit 1
fi

if [[ -f "$BINARY" ]] && [[ ! -f "$REAL" ]]; then
  if file -b "$BINARY" | grep -q 'ELF'; then
    mv "$BINARY" "$REAL"
  elif head -1 "$BINARY" 2>/dev/null | grep -q '^#!'; then
    echo "patch_appdir_portable: $BINARY is already a launcher script but $REAL is missing" >&2
    exit 1
  fi
fi

if [[ ! -f "$REAL" ]]; then
  echo "patch_appdir_portable: missing $REAL" >&2
  exit 1
fi

if [[ -f "$APPRUN_ENV" ]]; then
  sed -i 's|^APPDIR_EXEC_PATH=$APPDIR/localsend_app.bin$|APPDIR_EXEC_PATH=$APPDIR/localsend_app|' "$APPRUN_ENV" || true
  sed -i 's|^APPDIR_EXEC_PATH=\$APPDIR/localsend_app.bin$|APPDIR_EXEC_PATH=$APPDIR/localsend_app|' "$APPRUN_ENV" || true
fi

if command -v patchelf >/dev/null 2>&1; then
  RPATH='$ORIGIN/lib:$ORIGIN/lib/x86_64-linux-gnu:$ORIGIN/usr/lib:$ORIGIN/usr/lib/x86_64-linux-gnu:$ORIGIN/usr/lib/aarch64-linux-gnu'
  patchelf --set-rpath "$RPATH" "$REAL" 2>/dev/null || true
  for interp in /usr/lib/ld-linux-x86-64.so.2 /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2 \
    /usr/lib/ld-linux-aarch64.so.1 /lib/aarch64-linux-gnu/ld-linux-aarch64.so.1 /lib64/ld-linux-aarch64.so.1; do
    if [[ -e "$interp" ]]; then
      patchelf --set-interpreter "$interp" "$REAL" 2>/dev/null && break
    fi
  done
else
  echo "patch_appdir_portable: warning: patchelf not found; install patchelf and re-run on this machine" >&2
fi

cat > "$BINARY" << 'EOF'
#!/bin/sh
APPDIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
ORIGIN="$APPDIR"
export APPDIR ORIGIN

if [ -f "$APPDIR/AppRun.env" ]; then
  set -a
  # shellcheck disable=SC1091
  . "$APPDIR/AppRun.env"
  set +a
else
  APPDIR_LIBRARY_PATH="$APPDIR/lib:$APPDIR/lib/x86_64-linux-gnu:$APPDIR/lib/x86_64-linux-gnu/security:$APPDIR/usr/lib/x86_64-linux-gnu:$APPDIR/lib/x86_64"
fi

REAL="$APPDIR/localsend_app.bin"
LIBPATH="$APPDIR_LIBRARY_PATH"

export LD_LIBRARY_PATH="$LIBPATH"
if [ -z "${APPRUN_RUNTIME-}" ]; then
  unset LD_PRELOAD
fi

if [ ! -f "$REAL" ]; then
  echo "localsend_app: missing $REAL" >&2
  exit 1
fi

# Flutter resolves lib/libapp.so from /proc/self/exe — must exec the ELF directly (not via ld-linux).
cd "$APPDIR" || exit 1
exec "$REAL" "$@"
EOF

chmod 755 "$BINARY"
