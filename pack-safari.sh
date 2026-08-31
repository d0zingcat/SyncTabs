#!/bin/bash
set -e

# SyncTabs Safari Web Extension Build Script

WORK_DIR="$(pwd)"
VERSION=$(node -p "require('${WORK_DIR}/extension/manifest.json').version" 2>/dev/null || echo "1.0.4")
SAFARI_DIR="${WORK_DIR}/safari/SyncTabs"
BUILD_DIR="${SAFARI_DIR}/build"
ARCHIVE_PATH="${BUILD_DIR}/SyncTabs.xcarchive"
APP_BUNDLE="${ARCHIVE_PATH}/Products/Applications/SyncTabs.app"
DIST_DIR="${WORK_DIR}/dist"
OUTPUT_VERSIONED_ZIP="${DIST_DIR}/SyncTabs-Safari-v${VERSION}.zip"
OUTPUT_ZIP="${DIST_DIR}/SyncTabs-Safari.zip"

echo "🔨 Building Safari Web Extension v${VERSION}..."
echo ""

# Clean previous builds
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$DIST_DIR"

# Build archive using xcodebuild
echo "🏗️  Running xcodebuild archive..."
xcodebuild -project "${SAFARI_DIR}/SyncTabs.xcodeproj" \
           -scheme "SyncTabs" \
           -configuration Release \
           -archivePath "$ARCHIVE_PATH" \
           CODE_SIGN_IDENTITY="" \
           CODE_SIGNING_REQUIRED=NO \
           CODE_SIGNING_ALLOWED=NO \
           archive

if [ ! -d "$APP_BUNDLE" ]; then
    echo "❌ Error: App bundle not found at $APP_BUNDLE"
    exit 1
fi

# Package into zip for distribution
echo "📦 Packaging into zip..."
rm -f "$OUTPUT_VERSIONED_ZIP" "$OUTPUT_ZIP"
(
  cd "${ARCHIVE_PATH}/Products/Applications"
  zip -qry "$OUTPUT_VERSIONED_ZIP" "SyncTabs.app"
)
cp "$OUTPUT_VERSIONED_ZIP" "$OUTPUT_ZIP"

echo ""
echo "✨ Successfully packed Safari extension!"
echo "   Output: $OUTPUT_VERSIONED_ZIP"
echo "   Size: $(du -h "$OUTPUT_VERSIONED_ZIP" | cut -f1)"
echo ""
echo "🎉 To install/test on macOS:"
echo "   1. Unzip $OUTPUT_VERSIONED_ZIP and move SyncTabs.app to /Applications (or run from folder)"
echo "   2. In Safari -> Settings -> Advanced -> enable 'Show features for web developers'"
echo "   3. In Safari menu -> Develop -> check 'Allow Unsigned Extensions'"
echo "   4. In Safari -> Settings -> Extensions -> enable SyncTabs"
echo ""
