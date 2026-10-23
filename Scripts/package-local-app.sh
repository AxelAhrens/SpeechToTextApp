#!/bin/bash
# Build a local, ad-hoc-signed macOS app. Run on the Mac that will use it.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

swift build -c release --product SpeechToTextApp
BIN_DIR="$(swift build -c release --show-bin-path)"
SOURCE="$BIN_DIR/SpeechToTextApp"
test -x "$SOURCE"

OUTPUT="${APP_OUTPUT_DIR:-$ROOT/.build/local}"
mkdir -p "$OUTPUT"
LOCK="$OUTPUT/.package-local-app.lock"
mkdir "$LOCK"  # Only one publisher may replace the bundle at a time.
STAGE=""
TARGET="$OUTPUT/SpeechToTextApp.app"
BACKUP=""
cleanup() {
    status=$?
    if [ -n "$BACKUP" ] && { [ -e "$BACKUP" ] || [ -L "$BACKUP" ]; }; then
        rm -rf -- "$TARGET"
        mv "$BACKUP" "$TARGET"
    fi
    if [ -n "$STAGE" ]; then
        rm -rf -- "$STAGE"
    fi
    rmdir "$LOCK"
    exit "$status"
}
trap cleanup EXIT
STAGE="$(mktemp -d "$OUTPUT/.bundle.XXXXXX")"
BACKUP="$STAGE/previous.app"
APP="$STAGE/SpeechToTextApp.app"
mkdir -p "$APP/Contents/MacOS"
cp "$SOURCE" "$APP/Contents/MacOS/SpeechToTextApp"
cp "$ROOT/Sources/Resources/Info.plist" "$APP/Contents/Info.plist"

plutil -lint "$APP/Contents/Info.plist"
test "$(plutil -extract CFBundleIdentifier raw -o - "$APP/Contents/Info.plist")" = "com.axelahrens.speechtotext"
test -n "$(plutil -extract NSMicrophoneUsageDescription raw -o - "$APP/Contents/Info.plist")"
codesign --force --sign - --entitlements \
    "$ROOT/Sources/Resources/SpeechToTextApp.entitlements" "$APP"
codesign --verify --strict --verbose=2 "$APP"

if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
    mv "$TARGET" "$BACKUP"
fi
mv "$APP" "$TARGET"
rm -rf -- "$BACKUP"
printf 'Local app created: %s\n' "$TARGET"
