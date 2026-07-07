#!/usr/bin/env bash
# Point an ELF at this machine's dynamic linker (PT_INTERP must exist on the host).
set -euo pipefail

TARGET="${1:?Usage: fix_elf_interpreter.sh /path/to/binary}"

if ! command -v patchelf >/dev/null 2>&1; then
  echo "fix_elf_interpreter: patchelf is required (e.g. pacman -S patchelf)" >&2
  exit 1
fi

if [[ ! -f "$TARGET" ]]; then
  echo "fix_elf_interpreter: not a file: $TARGET" >&2
  exit 1
fi

current="$(patchelf --print-interpreter "$TARGET" 2>/dev/null || true)"
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

patchelf --set-interpreter "$local_interp" "$TARGET"
echo "fix_elf_interpreter: ${current:-<missing>} -> $local_interp"
