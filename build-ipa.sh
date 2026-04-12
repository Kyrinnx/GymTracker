#!/usr/bin/env bash
# build-ipa.sh — Builds an unsigned .ipa for AltStore.
#
# Usage:
#   ./build-ipa.sh           # builds and prints the .ipa path
#   ./build-ipa.sh --open    # builds and reveals the .ipa in Finder

set -euo pipefail

cd "$(dirname "$0")"

PROJECT="GymTracker.xcodeproj"
SCHEME="GymTracker"
BUILD_DIR="$(pwd)/build"
DERIVED_DATA="/tmp/gymtracker-dd-$$"
IPA_DIR="$BUILD_DIR/ipa"
IPA_FINAL="$BUILD_DIR/GymTracker.ipa"

# Regenerate project
if command -v xcodegen >/dev/null 2>&1; then
    echo "→ Regenerating Xcode project from project.yml..."
    xcodegen generate >/dev/null
fi

mkdir -p "$BUILD_DIR"
rm -rf "$IPA_DIR" "$IPA_FINAL"

echo "→ Building for iOS device (unsigned)..."
xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -sdk iphoneos \
    -destination 'generic/platform=iOS' \
    -derivedDataPath "$DERIVED_DATA" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    ENABLE_BITCODE=NO \
    build > "$BUILD_DIR/build.log" 2>&1 &
XB_PID=$!

# Workaround: Xcode 26 sometimes hangs on a `clang -v -E -dM` probe at build start.
# We watch for it and kill it gently after 5 seconds if it's still alive.
(
    sleep 5
    CLANG_PID=$(pgrep -f "clang -v -E -dM.*iPhoneOS" 2>/dev/null || true)
    if [[ -n "$CLANG_PID" ]]; then
        kill "$CLANG_PID" 2>/dev/null  # SIGTERM first
        sleep 1
        kill -9 "$CLANG_PID" 2>/dev/null || true  # SIGKILL if still alive
    fi
) &
KILLER=$!

wait $XB_PID
XB_EXIT=$?
kill $KILLER 2>/dev/null || true

if [[ $XB_EXIT -ne 0 ]]; then
    echo ""
    echo "❌ Build failed (exit $XB_EXIT). Last 20 lines:"
    tail -20 "$BUILD_DIR/build.log"
    exit 1
fi

echo "** BUILD SUCCEEDED **"

# Find the .app
APP_PATH=$(find "$DERIVED_DATA/Build/Products" -name "GymTracker.app" -type d | head -1)
if [[ -z "$APP_PATH" || ! -d "$APP_PATH" ]]; then
    echo "❌ GymTracker.app not found in build products"
    exit 1
fi

echo "→ Packaging .ipa..."
mkdir -p "$IPA_DIR/Payload"
cp -R "$APP_PATH" "$IPA_DIR/Payload/"
cd "$IPA_DIR"
zip -qry "../GymTracker.ipa" Payload
cd - >/dev/null

if [[ ! -f "$IPA_FINAL" ]]; then
    echo "❌ Failed to produce .ipa"
    exit 1
fi

SIZE=$(du -h "$IPA_FINAL" | cut -f1)
echo ""
echo "✅ Built: $IPA_FINAL  ($SIZE)"
echo ""

if [[ "${1:-}" == "--open" ]]; then
    open -R "$IPA_FINAL"
fi
