#!/bin/bash
# Pack Chrome extension into .zip format for Chrome Web Store and .crx for direct distribution
#
# Usage: ./pack-extension.sh

set -e

WORK_DIR="$(pwd)"
EXTENSION_DIR="${WORK_DIR}/extension"
PEM_FILE="${WORK_DIR}/extension.pem"
DIST_DIR="${WORK_DIR}/dist"

# Ensure dist directory exists
mkdir -p "$DIST_DIR"

echo "🔨 Validating and Packing SyncTabs Extension..."
echo ""

# 1. Read version from manifest.json
VERSION=$(node -p "require('${EXTENSION_DIR}/manifest.json').version" 2>/dev/null || echo "1.0.4")
echo "📌 Extension Version: v${VERSION}"

# 2. Syntax validation
echo "🔍 Validating JavaScript syntax..."
for jsfile in "${EXTENSION_DIR}"/*.js; do
  if [ -f "$jsfile" ]; then
    node -c "$jsfile"
    echo "  ✓ $(basename "$jsfile") passed syntax check"
  fi
done
echo ""

# 3. Create Chrome Web Store ZIP package
OUTPUT_VERSIONED_ZIP="${DIST_DIR}/synctabs-extension-v${VERSION}.zip"
OUTPUT_ZIP="${DIST_DIR}/synctabs-extension.zip"

echo "📦 Creating Chrome Web Store ZIP package..."
rm -f "$OUTPUT_VERSIONED_ZIP" "$OUTPUT_ZIP"

(
  cd "$EXTENSION_DIR"
  zip -r -FS -q "$OUTPUT_VERSIONED_ZIP" . -x "*.DS_Store" "*__MACOSX*" "*.git*" "*Thumbs.db*"
)

cp "$OUTPUT_VERSIONED_ZIP" "$OUTPUT_ZIP"
echo "✨ Created Web Store Zip: $OUTPUT_VERSIONED_ZIP"
echo "   Size: $(du -h "$OUTPUT_VERSIONED_ZIP" | cut -f1)"
echo ""

# 4. Optional .crx packing (if .pem file exists and Chrome is installed)
if [ -f "$PEM_FILE" ]; then
  OUTPUT_CRX="${DIST_DIR}/synctabs-extension.crx"
  echo "🔑 Found extension.pem, packing .crx..."

  CHROME=""
  if command -v google-chrome &> /dev/null; then
    CHROME="google-chrome"
  elif command -v chromium &> /dev/null; then
    CHROME="chromium"
  elif command -v chromium-browser &> /dev/null; then
    CHROME="chromium-browser"
  elif [ -f "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then
    CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
  fi

  if [ -n "$CHROME" ]; then
    "$CHROME" \
      --pack-extension="$EXTENSION_DIR" \
      --pack-extension-key="$PEM_FILE" \
      --no-message-box 2>/dev/null || true

    if [ -f "$(dirname "$EXTENSION_DIR")/extension.crx" ]; then
      mv "$(dirname "$EXTENSION_DIR")/extension.crx" "$OUTPUT_CRX"
      echo "✨ Created CRX: $OUTPUT_CRX"
    fi
  else
    echo "ℹ️  Chrome binary not found; skipping .crx generation."
  fi
else
  echo "ℹ️  extension.pem not found (only needed for direct CRX signing). Web Store ZIP created successfully!"
fi

echo ""
echo "🎉 Package ready for upload to Chrome Web Store:"
echo "   👉 $OUTPUT_VERSIONED_ZIP"
echo ""
