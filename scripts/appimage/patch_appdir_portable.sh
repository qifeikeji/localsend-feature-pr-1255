#!/usr/bin/env bash
# Make extracted squashfs-root runnable via ./localsend_app on any distro (Arch/Manjaro,
# Ubuntu, etc.) by wrapping the ELF. AppRun must exec the real ELF (see AppRun.env).
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
  sed -i 's|^APPDIR_EXEC_PATH=\$APPDIR/localsend_app$|APPDIR_EXEC_PATH=$APPDIR/localsend_app.bin|' "$APPRUN_ENV" || true
  if grep -q '^APPDIR_EXEC_PATH=$APPDIR/localsend_app$' "$APPRUN_ENV" 2>/dev/null; then
    sed -i 's|^APPDIR_EXEC_PATH=$APPDIR/localsend_app$|APPDIR_EXEC_PATH=$APPDIR/localsend_app.bin|' "$APPRUN_ENV"
  fi
fi

if command -v patchelf >/dev/null 2>&1; then
  # Only adjust RUNPATH. Do not set PT_INTERP here — CI uses Ubuntu paths that break on Arch/Manjaro.
  RPATH='$ORIGIN/lib:$ORIGIN/lib/x86_64-linux-gnu:$ORIGIN/usr/lib:$ORIGIN/usr/lib/x86_64-linux-gnu:$ORIGIN/usr/lib/aarch64-linux-gnu'
  patchelf --set-rpath "$RPATH" "$REAL" 2>/dev/null || true
fi

cat > "$BINARY" << 'EOF'
#!/bin/sh
# Direct launch from extracted squashfs-root (not via ./AppRun).
# Uses the host glibc + libraries bundled inside this directory.
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

# Do not use runtime/compat (Ubuntu glibc 2.35) on rolling distros — it breaks against /usr/lib.
export LD_LIBRARY_PATH="$APPDIR_LIBRARY_PATH"
unset LD_PRELOAD

if [ ! -f "$REAL" ]; then
  echo "localsend_app: missing $REAL" >&2
  exit 1
fi

# Use the host dynamic linker (AppImage may ship a PT_INTERP path that only exists on Ubuntu).
LD_LINUX=""
for candidate in \
  /usr/lib/ld-linux-x86-64.so.2 \
  /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 \
  /lib64/ld-linux-x86-64.so.2 \
  /usr/lib/ld-linux-aarch64.so.1 \
  /lib/aarch64-linux-gnu/ld-linux-aarch64.so.1 \
  /lib64/ld-linux-aarch64.so.1
do
  if [ -e "$candidate" ]; then
    LD_LINUX=$candidate
    break
  fi
done

if [ -n "$LD_LINUX" ]; then
  exec "$LD_LINUX" --library-path "$LD_LIBRARY_PATH" "$REAL" "$@"
fi

exec "$REAL" "$@"
EOF

chmod 755 "$BINARY"
