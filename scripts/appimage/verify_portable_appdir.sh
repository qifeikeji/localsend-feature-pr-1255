#!/usr/bin/env bash
set -euo pipefail

APPDIR="${1:?Usage: verify_portable_appdir.sh AppDir}"

LAUNCHER="$APPDIR/localsend_app"
REAL="$APPDIR/localsend_app.bin"

if [[ ! -f "$LAUNCHER" ]]; then
  echo "verify_portable_appdir: missing $LAUNCHER" >&2
  exit 1
fi

if [[ ! -f "$REAL" ]]; then
  echo "verify_portable_appdir: missing $REAL (still a raw ELF AppImage layout?)" >&2
  exit 1
fi

if ! head -1 "$LAUNCHER" | grep -q '^#!/'; then
  echo "verify_portable_appdir: $LAUNCHER is not a shell launcher (got: $(file -b "$LAUNCHER"))" >&2
  exit 1
fi

if ! file -b "$REAL" | grep -q 'ELF'; then
  echo "verify_portable_appdir: $REAL is not an ELF binary" >&2
  exit 1
fi

echo "verify_portable_appdir: OK (launcher + localsend_app.bin)"
