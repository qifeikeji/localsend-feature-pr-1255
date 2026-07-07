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

FIX="$APPDIR/usr/libexec/fix_elf_interpreter.sh"
if [ -x "$FIX" ]; then
  sh "$FIX" "$REAL" || exit 127
else
  echo "localsend_app: missing $FIX — re-run patch_appdir_portable.sh on this directory" >&2
  exit 127
fi

cd "$APPDIR" || exit 1
exec "$REAL" "$@"
EOF

chmod 755 "$BINARY"
