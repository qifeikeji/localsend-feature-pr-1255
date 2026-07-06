#!/usr/bin/env bash
# Ad-hoc signing for unsigned CI builds (no Apple Developer certificate on runner).
set -euo pipefail

python3 << 'PY'
from pathlib import Path

p = Path("app/macos/Runner.xcodeproj/project.pbxproj")
text = p.read_text()
replacements = [
    ("DEVELOPMENT_TEAM = 3W7H4PYMCV;", 'DEVELOPMENT_TEAM = "";'),
    ('CODE_SIGN_IDENTITY = "Apple Development";', 'CODE_SIGN_IDENTITY = "-";'),
    ('"CODE_SIGN_IDENTITY[sdk=macosx*]" = "Apple Development";', '"CODE_SIGN_IDENTITY[sdk=macosx*]" = "-";'),
    ("CODE_SIGN_STYLE = Automatic;", "CODE_SIGN_STYLE = Manual;"),
]
for old, new in replacements:
    text = text.replace(old, new)
p.write_text(text)
print("Configured ad-hoc code signing for macOS CI.")
PY
