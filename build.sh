#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
build=build
app="$build/YZ.app"
resources="$app/Contents/Resources"
iconset="$build/AppIcon.iconset"
mkdir -p "$resources" "$app/Contents/MacOS" "$iconset"
xcrun swiftc -swift-version 5 -target "$(uname -m)-apple-macosx14.0" -parse-as-library YZ.swift -o "$app/Contents/MacOS/YZ"
for size in 16 32 128 256 512; do
    sips -z "$size" "$size" AppIcon.png --out "$iconset/icon_${size}x${size}.png" >/dev/null
    double=$((size * 2))
    sips -z "$double" "$double" AppIcon.png --out "$iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$iconset" -o "$resources/AppIcon.icns"
cp sources.json workbench.py "$resources/"
cp Info.plist "$app/Contents/"
plutil -lint "$app/Contents/Info.plist"
codesign --force --sign - "$app"
codesign --verify --strict "$app"
