#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h}"
OUTPUT_DIR="${APP_OUTPUT_DIR:-$PROJECT_DIR/dist}"
APP_DIR="$OUTPUT_DIR/MacDuo.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-14.0}"
BUILD_ARCH="${BUILD_ARCH:-$(uname -m)}"

mkdir -p "$MACOS_DIR" "$CONTENTS_DIR/Resources"
cp "$PROJECT_DIR/Assets/MacDuo.icns" "$CONTENTS_DIR/Resources/"
cp "$PROJECT_DIR/Assets/MacDuo.png" "$CONTENTS_DIR/Resources/"
cp "$PROJECT_DIR/Info.plist" "$CONTENTS_DIR/Info.plist"

xcrun swiftc -parse-as-library -O \
  -target "$BUILD_ARCH-apple-macosx$DEPLOYMENT_TARGET" \
  -framework SwiftUI -framework AppKit -framework IOKit -framework QuartzCore \
  -framework MetalKit -framework ScreenCaptureKit -framework Carbon \
  -o "$MACOS_DIR/MacDuo" "$PROJECT_DIR"/Sources/*.swift

if [[ -n "${CODE_SIGN_IDENTITY:-}" ]]; then
  codesign --force --options runtime --timestamp --sign "$CODE_SIGN_IDENTITY" "$APP_DIR"
else
  codesign --force --sign - "$APP_DIR"
fi
codesign --verify --strict "$APP_DIR"
echo "Built: $APP_DIR ($BUILD_ARCH, macOS $DEPLOYMENT_TARGET+)"
