#!/bin/sh
# Builds GhosttyHL and installs it as /Applications/GhosttyHL.app, next to an
# official Ghostty: its own bundle identifier, name and ad hoc signature.
#
# Needs Zig 0.15.2 at ZIG_DIR, Xcode and its Metal Toolchain
# (xcodebuild -downloadComponent MetalToolchain).
set -eu

ZIG_DIR=${ZIG_DIR:-$HOME/.local/zig/zig-aarch64-macos-0.15.2}
DEST=${DEST:-/Applications/GhosttyHL.app}
BUNDLE_ID=com.hugohl.ghosttyhl
ROOT=$(cd "$(dirname "$0")/.." && pwd)

# Zig 0.15.2 links against the SDK `xcrun --sdk macosx --show-sdk-path` names.
# The macOS 26 and 27 SDKs list only arm64e in libSystem.tbd, which Zig cannot
# use, so Zig is handed the 15.4 SDK of the Command Line Tools instead.
SHIM=$(mktemp -d)
trap 'rm -rf "$SHIM"' EXIT
cat > "$SHIM/xcrun" <<'SH'
#!/bin/sh
if [ "$#" -eq 3 ] && [ "$1" = "--sdk" ] && [ "$2" = "macosx" ] && [ "$3" = "--show-sdk-path" ]; then
  echo /Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
  exit 0
fi
exec /usr/bin/xcrun "$@"
SH
chmod +x "$SHIM/xcrun"

cd "$ROOT"
PATH="$SHIM:$ZIG_DIR:$PATH" zig build -Doptimize=ReleaseFast -Dxcframework-target=native

rm -rf "$DEST"
cp -R zig-out/Ghostty.app "$DEST"
plist="$DEST/Contents/Info.plist"
/usr/libexec/PlistBuddy \
  -c "Set :CFBundleIdentifier $BUNDLE_ID" \
  -c "Set :CFBundleName GhosttyHL" \
  -c "Set :CFBundleDisplayName GhosttyHL" \
  "$plist"
codesign --force --deep --sign - --preserve-metadata=entitlements "$DEST"
echo "Installed $DEST ($BUNDLE_ID)"
