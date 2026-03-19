#!/bin/bash
set -euo pipefail

SCHEME="MarkdownViewer"
CONFIG="Release"
DERIVED_DATA="$(pwd)/build"
APP_NAME="MarkdownViewer.app"

echo "→ Building $SCHEME ($CONFIG)..."
xcodebuild \
  -scheme "$SCHEME" \
  -configuration "$CONFIG" \
  -derivedDataPath "$DERIVED_DATA" \
  -quiet

BUILT_APP="$DERIVED_DATA/Build/Products/$CONFIG/$APP_NAME"

if [ ! -d "$BUILT_APP" ]; then
  echo "✗ Build failed — $APP_NAME not found"
  exit 1
fi

echo "→ Installing to /Applications..."
rm -rf "/Applications/$APP_NAME"
cp -r "$BUILT_APP" "/Applications/$APP_NAME"

echo "✓ Installed: /Applications/$APP_NAME"
echo "  To set as default viewer, open the app and click 'Set as Default'"
