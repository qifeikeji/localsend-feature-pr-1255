#!/usr/bin/env bash
set -euo pipefail

APP_PATH="${1:?Usage: create_macos_dmg.sh path/to/LocalSend.app output.dmg [volume_name]}"
DMG_PATH="${2:?Usage: create_macos_dmg.sh path/to/LocalSend.app output.dmg [volume_name]}"
VOLUME_NAME="${3:-LocalSend}"

if [[ ! -d "$APP_PATH" ]]; then
  echo "App bundle not found: $APP_PATH" >&2
  exit 1
fi

STAGING_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

rm -f "$DMG_PATH"
hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"
