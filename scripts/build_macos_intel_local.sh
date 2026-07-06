#!/usr/bin/env bash
# Build LocalSend for Intel Mac (native x86_64). Use on your own Mac — GitHub Actions only ships arm64.
#
# Requirements (macOS 12.5 Monterey):
#   - Xcode 14+ (or Xcode CLT + full Xcode for macOS desktop)
#   - Flutter 3.22.3 (match CI): https://docs.flutter.dev/get-started/install/macos
#
# Usage from repo root:
#   bash scripts/build_macos_intel_local.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter not found. Install Flutter 3.22.x and add it to PATH."
  exit 1
fi

echo "Flutter: $(flutter --version | head -1)"
echo "Building for this Mac (Intel → x86_64, Apple Silicon → arm64)..."

cd "$ROOT/app"
flutter pub get
(cd macos && pod install)
flutter build macos --release

APP="$ROOT/app/build/macos/Build/Products/Release/LocalSend.app"
if [[ -d "$APP" ]]; then
  echo ""
  echo "Build OK:"
  echo "  $APP"
  echo ""
  echo "Run: open \"$APP\""
else
  echo "Build finished but .app not found at expected path."
  exit 1
fi
