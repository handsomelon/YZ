#!/bin/bash
# 原地增量更新已安装的 YZ.app
#
# 用途：把仓库里的最新源码编译进 /Applications/YZ.app 本身，
#       而不是生成一个新的程序包。程序坞图标、bundle ID、
#       钥匙串授权、本机工单数据全部保持不变。
#
# 用法：
#   bash scripts/update-in-place.sh            # 用 Info.plist 里的当前版本
#   bash scripts/update-in-place.sh 0.4.1 7    # 顺便改版本号（版本, build）
#   bash scripts/update-in-place.sh --check    # 只看会不会更新，不动文件
#
# 原理：只替换 Contents/MacOS/YZ 和 Contents/Resources/ 下的文件，
#       CodeResources 由 codesign 重新封装，所以与「同一路径重新构建」等价。
set -euo pipefail
cd "$(dirname "$0")/.."

app="${YZ_APP_PATH:-/Applications/YZ.app}"
check_only=false
if [[ "${1:-}" == "--check" ]]; then check_only=true; shift; fi

# 可选：先更新版本号，让「关于」里能看到迭代
if [[ $# -ge 1 ]]; then
    version="$1"
    [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "版本号要写成 0.4.1 这样" >&2; exit 2; }
    /usr/libexec/PlistBuddy -c "Set CFBundleShortVersionString $version" Info.plist
    if [[ $# -ge 2 ]]; then
        [[ "$2" =~ ^[0-9]+$ ]] || { echo "build 号要是整数" >&2; exit 2; }
        /usr/libexec/PlistBuddy -c "Set CFBundleVersion $2" Info.plist
    fi
fi

version="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Info.plist)"
build="$(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' Info.plist)"

if [[ ! -d "$app" ]]; then
    echo "没有找到 $app。先用 bash scripts/install.sh 装一次。" >&2
    exit 1
fi

# 目标目录可写性，提前说清楚，别编译完了才失败
for dir in "$app/Contents/MacOS" "$app/Contents/Resources" "$app/Contents"; do
    [[ -w "$dir" ]] || { echo "没有写权限：$dir" >&2; exit 1; }
done

echo "目标：$app"
echo "版本：$version ($build)"
if [[ -x "$app/Contents/MacOS/YZ" ]]; then
    installed="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$app/Contents/Info.plist" 2>/dev/null || echo '未知')"
    echo "已装：$installed"
fi

if $check_only; then
    echo "（--check：只检查，不改动任何文件）"
    exit 0
fi

# 正在运行就先关掉，否则替换可执行文件后程序坞会指向旧内存镜像
if pgrep -f "$app/Contents/MacOS/YZ" >/dev/null 2>&1; then
    echo "正在运行，先退出…"
    osascript -e 'tell application "YZ" to quit' >/dev/null 2>&1 || true
    for _ in $(seq 1 20); do
        pgrep -f "$app/Contents/MacOS/YZ" >/dev/null 2>&1 || break
        sleep 0.25
    done
    pkill -f "$app/Contents/MacOS/YZ" >/dev/null 2>&1 || true
fi

work="build/inplace"
rm -rf "$work"
mkdir -p "$work/Resources" "$work/AppIcon.iconset"

echo "编译 YZ.swift…"
xcrun swiftc -swift-version 5 -target "$(uname -m)-apple-macosx14.0" \
    -parse-as-library YZ.swift -o "$work/YZ"

echo "生成图标…"
for size in 16 32 128 256 512; do
    sips -z "$size" "$size" AppIcon.png --out "$work/AppIcon.iconset/icon_${size}x${size}.png" >/dev/null
    double=$((size * 2))
    sips -z "$double" "$double" AppIcon.png --out "$work/AppIcon.iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$work/AppIcon.iconset" -o "$work/Resources/AppIcon.icns"

cp sources.json workbench.py "$work/Resources/"

# 原地覆盖：只动这三个位置，其余（含 _CodeSignature）交给 codesign 重封
echo "写入已安装的程序包…"
cp "$work/YZ" "$app/Contents/MacOS/YZ"
chmod 755 "$app/Contents/MacOS/YZ"
cp "$work/Resources/AppIcon.icns" "$work/Resources/sources.json" "$work/Resources/workbench.py" "$app/Contents/Resources/"
cp Info.plist "$app/Contents/Info.plist"
plutil -lint "$app/Contents/Info.plist" >/dev/null

echo "重新签名…"
codesign --force --sign - "$app"
codesign --verify --strict "$app"

# 让 Finder / 程序坞丢弃旧的图标缓存；不动 Dock 的固定项，图标位置不变
touch "$app"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -f "$app" >/dev/null 2>&1 || true

rm -rf "$work"

# 校验产物确实是最新的
installed_version="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$app/Contents/Info.plist")"
installed_build="$(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' "$app/Contents/Info.plist")"
[[ "$version" == "$installed_version" && "$build" == "$installed_build" ]] || {
    echo "版本写入不一致：期望 $version ($build)，实际 $installed_version ($installed_build)" >&2
    exit 1
}
python3 -c 'import ast,pathlib,sys; ast.parse(pathlib.Path(sys.argv[1]).read_bytes())' \
    "$app/Contents/Resources/workbench.py"
codesign --verify --strict "$app"

echo
echo "✅ 已原地更新：$app"
echo "   版本 $installed_version ($installed_build) · 签名通过 · 程序坞位置不变"
echo "   打开：open \"$app\""
