#!/usr/bin/env bash
# Make extracted squashfs-root runnable on any distro (Arch/Manjaro, Ubuntu, …).
# Flutter requires direct exec of the ELF (/proc/self/exe); fix PT_INTERP on the host.
set -euo pipefail

APPDIR="${1:-AppDir}"
BINARY="$APPDIR/localsend_app"
REAL="$APPDIR/localsend_app.bin"
APPRUN_ENV="$APPDIR/AppRun.env"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIBEXEC="$APPDIR/usr/libexec"

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

mkdir -p "$LIBEXEC"
cp "$SCRIPT_DIR/fix_elf_interpreter.sh" "$LIBEXEC/fix_elf_interpreter.sh"
chmod 755 "$LIBEXEC/fix_elf_interpreter.sh"

if command -v patchelf >/dev/null 2>&1; then
  RPATH='$ORIGIN/lib:$ORIGIN/lib/x86_64-linux-gnu:$ORIGIN/usr/lib:$ORIGIN/usr/lib/x86_64-linux-gnu:$ORIGIN/usr/lib/aarch64-linux-gnu'
  patchelf --set-rpath "$RPATH" "$REAL" 2>/dev/null || true
fi

PATCHELF="" bash "$LIBEXEC/fix_elf_interpreter.sh" "$REAL"

bash "$SCRIPT_DIR/install_portable_launcher.sh" "$APPDIR"
