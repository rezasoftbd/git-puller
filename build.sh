#!/bin/bash
# Builds Git Puller.app into ./build
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="Git Puller"
BUNDLE="build/${APP_NAME}.app"

echo "==> Rendering icon"
swift icon/RenderIcon.swift icon/GitPuller.iconset >/dev/null
iconutil -c icns icon/GitPuller.iconset -o icon/GitPuller.icns

echo "==> Compiling (release, universal)"
swift build -c release --arch arm64 --arch x86_64

echo "==> Assembling bundle"
rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"

cp .build/apple/Products/Release/GitPuller "$BUNDLE/Contents/MacOS/GitPuller"
cp icon/GitPuller.icns "$BUNDLE/Contents/Resources/AppIcon.icns"

cat > "$BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>            <string>Git Puller</string>
    <key>CFBundleDisplayName</key>     <string>Git Puller</string>
    <key>CFBundleExecutable</key>      <string>GitPuller</string>
    <key>CFBundleIdentifier</key>      <string>com.softbdltd.gitpuller</string>
    <key>CFBundleIconFile</key>        <string>AppIcon</string>
    <key>CFBundlePackageType</key>     <string>APPL</string>
    <key>CFBundleShortVersionString</key> <string>1.0</string>
    <key>CFBundleVersion</key>         <string>1</string>
    <key>LSMinimumSystemVersion</key>  <string>13.0</string>
    <key>NSHighResolutionCapable</key> <true/>
    <key>NSSupportsAutomaticTermination</key> <true/>
</dict>
</plist>
PLIST

echo "==> Signing"
codesign --force --deep --sign - "$BUNDLE"

# Refresh Finder's icon cache so the new icon shows immediately.
touch "$BUNDLE"

echo ""
echo "Built: $BUNDLE"
