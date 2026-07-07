#!/usr/bin/env bash
# Point an ELF at this machine's dynamic linker (PT_INTERP must exist on the host).
set -euo pipefail

TARGET="${1:?Usage: fix_elf_interpreter.sh /path/to/binary}"

if [[ ! -f "$TARGET" ]]; then
  echo "fix_elf_interpreter: not a file: $TARGET" >&2
  exit 1
fi

read_interp() {
  readelf -l "$1" 2>/dev/null | sed -n 's/.*Requesting program interpreter: \[\(.*\)\].*/\1/p' | head -1
}

current="$(read_interp "$TARGET")"
if [[ -n "$current" && -e "$current" ]]; then
  exit 0
fi

local_interp=""
for candidate in \
  /usr/lib/ld-linux-x86-64.so.2 \
  /lib64/ld-linux-x86-64.so.2 \
  /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 \
  /usr/lib/ld-linux-aarch64.so.1 \
  /lib64/ld-linux-aarch64.so.1 \
  /lib/aarch64-linux-gnu/ld-linux-aarch64.so.1
do
  if [[ -e "$candidate" ]]; then
    local_interp="$candidate"
    break
  fi
done

if [[ -z "$local_interp" ]]; then
  echo "fix_elf_interpreter: no system dynamic linker found" >&2
  exit 1
fi

patchelf_bin=""
if command -v patchelf >/dev/null 2>&1; then
  patchelf_bin="$(command -v patchelf)"
elif [[ -n "${PATCHELF:-}" && -x "$PATCHELF" ]] && "$PATCHELF" --version >/dev/null 2>&1; then
  patchelf_bin="$PATCHELF"
fi

if [[ -n "$patchelf_bin" ]]; then
  patchelf --set-interpreter "$local_interp" "$TARGET"
  echo "fix_elf_interpreter: ${current:-<missing>} -> $local_interp (patchelf)"
  exit 0
fi

objcopy_bin=""
for p in llvm-objcopy objcopy; do
  if command -v "$p" >/dev/null 2>&1; then
    objcopy_bin="$(command -v "$p")"
    break
  fi
done

if [[ -n "$objcopy_bin" ]] && "$objcopy_bin" --help 2>&1 | grep -q set-interpreter; then
  "$objcopy_bin" --set-interpreter "$local_interp" "$TARGET"
  echo "fix_elf_interpreter: ${current:-<missing>} -> $local_interp ($objcopy_bin)"
  exit 0
fi

echo "fix_elf_interpreter: need patchelf or llvm-objcopy (pacman -S patchelf llvm)" >&2
echo "fix_elf_interpreter: current PT_INTERP=${current:-<unreadable>}" >&2
exit 1
