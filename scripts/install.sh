#!/bin/bash
# 首次安装 YZ 到 /Applications，并固定到程序坞
#
# 只会有一个 /Applications/YZ.app。之后的更新一律用
# scripts/update-in-place.sh 原地替换，不会再产生新的程序包。
set -euo pipefail
cd "$(dirname "$0")/.."

app="${YZ_APP_PATH:-/Applications/YZ.app}"

# 已经有就退出去走原地更新，避免出现两份
if [[ -d "$app" ]]; then
    echo "$app 已存在，不重复安装。要更新请运行："
    echo "  bash scripts/update-in-place.sh"
    exit 0
fi

echo "构建…"
bash build.sh
codesign --verify --strict build/YZ.app

echo "安装到 $app…"
rm -rf "$app"
ditto build/YZ.app "$app"

# 清掉下载隔离标记，免去第一次的双击拦截
xattr -dr com.apple.quarantine "$app" 2>/dev/null || true

/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -f "$app" >/dev/null 2>&1 || true

# 固定到程序坞（已存在则跳过，位置不变）
if ! defaults read com.apple.dock persistent-apps 2>/dev/null | grep -q "file://$app/"; then
    echo "加入程序坞…"
    defaults write com.apple.dock persistent-apps -array-add \
        "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>file://$app/</string><key>_CFURLStringType</key><integer>15</integer></dict></dict></dict>"
    killall Dock 2>/dev/null || true
else
    echo "程序坞里已有 YZ，位置保持不变。"
fi

echo
echo "✅ 安装完成：$app"
echo "   以后更新用 bash scripts/update-in-place.sh（原地替换，不会新增程序包）"
