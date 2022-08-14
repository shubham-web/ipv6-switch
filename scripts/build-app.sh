#!/usr/bin/env bash
# Builds "build/IPv6 Switch.app".
#
# Environment:
#   UNIVERSAL=1        build for both Apple silicon and Intel (default: this Mac's architecture)
#   VERSION=x.y.z      override the version in ./VERSION
#   SIGN_IDENTITY=...  codesign identity, e.g. "Developer ID Application: ..." (default: ad-hoc)
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="IPv6 Switch"
EXECUTABLE="IPv6Switch"
MIN_MACOS="13.0"
VERSION="${VERSION:-$(tr -d '[:space:]' < VERSION)}"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"
BUILD_DIR="build"
APP="$BUILD_DIR/$APP_NAME.app"

echo "==> Compiling $EXECUTABLE $VERSION"
if [[ "${UNIVERSAL:-0}" == "1" ]]; then
  slices=()
  for arch in arm64 x86_64; do
    # A separate scratch path per arch, since some SwiftPM versions share one bin path across triples.
    args=(-c release --triple "$arch-apple-macosx$MIN_MACOS" --scratch-path ".build/$arch")
    swift build "${args[@]}"
    slices+=("$(swift build "${args[@]}" --show-bin-path)/$EXECUTABLE")
  done
  mkdir -p "$BUILD_DIR"
  BIN="$BUILD_DIR/$EXECUTABLE"
  lipo -create -output "$BIN" "${slices[@]}"
else
  swift build -c release
  BIN="$(swift build -c release --show-bin-path)/$EXECUTABLE"
fi

echo "==> Assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/$EXECUTABLE"
cp Support/Info.plist "$APP/Contents/Info.plist"
plutil -replace CFBundleShortVersionString -string "$VERSION" "$APP/Contents/Info.plist"
plutil -replace CFBundleVersion -string "$VERSION" "$APP/Contents/Info.plist"

echo "==> Drawing icon"
ICON_TMP="$(mktemp -d)"
trap 'rm -rf "$ICON_TMP"' EXIT
swiftc scripts/make-icon.swift -o "$ICON_TMP/make-icon"
"$ICON_TMP/make-icon" "$ICON_TMP/AppIcon.iconset"
iconutil -c icns "$ICON_TMP/AppIcon.iconset" -o "$APP/Contents/Resources/AppIcon.icns"

echo "==> Signing"
if [[ "$SIGN_IDENTITY" == "-" ]]; then
  codesign --force --sign - "$APP"
else
  codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP"
fi

echo "Built: $PWD/$APP ($(lipo -archs "$APP/Contents/MacOS/$EXECUTABLE"))"
