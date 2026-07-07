#!/usr/bin/env bash
set -euo pipefail

APPDIR="${1:?Usage: install_portable_launcher.sh AppDir}"
BINARY="$APPDIR/localsend_app"

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

_fix_interp() {
  command -v patchelf >/dev/null 2>&1 || return 1
  _current="$(patchelf --print-interpreter "$REAL" 2>/dev/null || true)"
  if [ -n "$_current" ] && [ -e "$_current" ]; then
    return 0
  fi
  _local=""
  for _c in \
    /usr/lib/ld-linux-x86-64.so.2 \
    /lib64/ld-linux-x86-64.so.2 \
    /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 \
    /usr/lib/ld-linux-aarch64.so.1 \
    /lib64/ld-linux-aarch64.so.1 \
    /lib/aarch64-linux-gnu/ld-linux-aarch64.so.1
  do
    if [ -e "$_c" ]; then
      _local="$_c"
      break
    fi
  done
  if [ -z "$_local" ]; then
    return 1
  fi
  patchelf --set-interpreter "$_local" "$REAL"
}

if ! _fix_interp; then
  _bad="$(patchelf --print-interpreter "$REAL" 2>/dev/null || echo unknown)"
  echo "localsend_app: ELF interpreter not usable on this system (${_bad})." >&2
  echo "Install patchelf (sudo pacman -S patchelf), then run:" >&2
  echo "  bash path/to/scripts/appimage/patch_appdir_portable.sh \"$APPDIR\"" >&2
  exit 127
fi

cd "$APPDIR" || exit 1
exec "$REAL" "$@"
EOF

chmod 755 "$BINARY"
