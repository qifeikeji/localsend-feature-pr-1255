#!/usr/bin/env bash
# CI only: build macOS arm64 only (skip x86_64 slice on Apple Silicon runners).
set -euo pipefail

python3 << 'PY'
from pathlib import Path

ARCH_LINES = (
    "\t\t\t\tARCHS = arm64;\n"
    "\t\t\t\tEXCLUDED_ARCHS = x86_64;\n"
    "\t\t\t\tONLY_ACTIVE_ARCH = YES;\n"
)

def patch_pbxproj(path: Path) -> None:
    if not path.exists():
        print(f"Skip (missing): {path}")
        return
    text = path.read_text()
    if "ARCHS = arm64" in text:
        print(f"Already arm64-only: {path}")
        return
    out: list[str] = []
    for line in text.splitlines(keepends=True):
        out.append(line)
        if line.strip() == "buildSettings = {":
            out.append(ARCH_LINES)
    path.write_text("".join(out))
    print(f"Patched arm64-only: {path}")

patch_pbxproj(Path("app/macos/Runner.xcodeproj/project.pbxproj"))
patch_pbxproj(Path("app/macos/Pods/Pods.xcodeproj/project.pbxproj"))
PY
