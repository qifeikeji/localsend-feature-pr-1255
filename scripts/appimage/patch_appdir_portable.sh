#!/usr/bin/env bash
# Make extracted squashfs-root runnable via ./localsend_app on any distro (Arch/Manjaro,
# Ubuntu, etc.) by wrapping the ELF and starting it with the bundled dynamic linker.
set -euo pipefail

APPDIR="${1:-AppDir}"
BINARY="$APPDIR/localsend_app"
REAL="$APPDIR/localsend_app.bin"

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

if command -v patchelf >/dev/null 2>&1; then
  RPATH='$ORIGIN/lib:$ORIGIN/usr/lib:$ORIGIN/usr/lib/x86_64-linux-gnu:$ORIGIN/usr/lib/aarch64-linux-gnu'
  patchelf --set-rpath "$RPATH" "$REAL" 2>/dev/null || true
fi

cat > "$BINARY" << 'EOF'
#!/bin/sh
# LocalSend portable launcher (extracted AppImage / squashfs-root).
APPDIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
REAL="$APPDIR/localsend_app.bin"

LIBPATH="$APPDIR/lib:$APPDIR/usr/lib:$APPDIR/usr/lib/x86_64-linux-gnu:$APPDIR/usr/lib/aarch64-linux-gnu"

export XDG_DATA_DIRS="$APPDIR/usr/local/share:$APPDIR/usr/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"

LD_LINUX=""
for candidate in \
  "$APPDIR/usr/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2" \
  "$APPDIR/usr/lib/aarch64-linux-gnu/ld-linux-aarch64.so.1" \
  /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 \
  /usr/lib/ld-linux-x86-64.so.2 \
  /lib64/ld-linux-x86-64.so.2 \
  /lib/aarch64-linux-gnu/ld-linux-aarch64.so.1 \
  /usr/lib/ld-linux-aarch64.so.1 \
  /lib64/ld-linux-aarch64.so.1
do
  if [ -f "$candidate" ]; then
    LD_LINUX=$candidate
    break
  fi
done

if [ ! -f "$REAL" ]; then
  echo "localsend_app: missing $REAL" >&2
  exit 1
fi

if [ -n "$LD_LINUX" ]; then
  exec "$LD_LINUX" --library-path "$LIBPATH" "$REAL" "$@"
fi

exec "$REAL" "$@"
EOF

chmod 755 "$BINARY"
