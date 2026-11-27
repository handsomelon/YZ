#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

version="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Info.plist)"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Expected a numeric major.minor.patch version in Info.plist" >&2
    exit 2
fi

bash build.sh
app="build/YZ.app"
installed_version="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$app/Contents/Info.plist")"
[[ "$version" == "$installed_version" ]]
file "$app/Contents/MacOS/YZ"
python3 -c 'import ast, pathlib, sys; ast.parse(pathlib.Path(sys.argv[1]).read_bytes())' "$app/Contents/Resources/workbench.py"
codesign --verify --strict "$app"

mkdir -p build/release
release_name="YZ-${version}-macOS-$(uname -m).zip"
temporary="build/release/.partial-${release_name}"
trap 'rm -f "$temporary"' EXIT
ditto -c -k --sequesterRsrc --keepParent "$app" "$temporary"
unzip -tq "$temporary"
mv "$temporary" "build/release/$release_name"
(cd build/release && shasum -a 256 "$release_name" > "$release_name.sha256")
printf '%s\n' "build/release/$release_name"
