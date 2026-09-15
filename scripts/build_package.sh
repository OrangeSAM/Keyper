#!/bin/bash
# Build installer packages (.dmg and .pkg) for Keyper
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_DIR="$PROJECT_DIR/Keyper.app"
DIST_DIR="$PROJECT_DIR/dist"

echo "=========================================="
echo "🔨 1. 确保最新编译与代码签名"
echo "=========================================="
"$SCRIPT_DIR/build_app.sh"

if [ ! -d "$APP_DIR" ]; then
    echo "❌ 错误: $APP_DIR 不存在!"
    exit 1
fi

mkdir -p "$DIST_DIR"

VERSION="${1:-${VERSION:-1.0.0}}"
# Strip any leading 'v'
VERSION="${VERSION#v}"
PKG_FILE="$DIST_DIR/Keyper-${VERSION}.pkg"
DMG_FILE="$DIST_DIR/Keyper-${VERSION}.dmg"

export COPYFILE_DISABLE=1

# 清理历史旧包
rm -f "$DIST_DIR"/Tickeys* 2>/dev/null || true

echo ""
echo "=========================================="
echo "📦 2. 生成 macOS 标准安装包 (.pkg)"
echo "=========================================="
PKG_ROOT="$PROJECT_DIR/.build/pkg_root"
rm -rf "$PKG_ROOT"
mkdir -p "$PKG_ROOT"
cp -r "$APP_DIR" "$PKG_ROOT/"
xattr -cr "$PKG_ROOT" 2>/dev/null || true
dot_clean "$PKG_ROOT" 2>/dev/null || true

pkgbuild \
    --root "$PKG_ROOT" \
    --identifier "com.orangesam.keyper" \
    --version "$VERSION" \
    --install-location "/Applications" \
    "$PKG_FILE"

rm -rf "$PKG_ROOT"
echo "✅ PKG 安装包生成完毕: $PKG_FILE"

echo ""
echo "=========================================="
echo "💿 3. 生成 macOS 磁盘映像安装包 (.dmg)"
echo "=========================================="
DMG_TEMP="$PROJECT_DIR/.build/dmg_temp"
rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"

# 复制 App 和 Applications 快捷方式
cp -r "$APP_DIR" "$DMG_TEMP/"
ln -s /Applications "$DMG_TEMP/Applications"
xattr -cr "$DMG_TEMP" 2>/dev/null || true
dot_clean "$DMG_TEMP" 2>/dev/null || true

# 移除旧的 dmg
rm -f "$DMG_FILE"

# 生成压缩 DMG
hdiutil create \
    -volname "Keyper" \
    -srcfolder "$DMG_TEMP" \
    -ov \
    -format UDZO \
    "$DMG_FILE"

rm -rf "$DMG_TEMP"
echo "✅ DMG 镜像生成完毕: $DMG_FILE"

echo ""
echo "=========================================="
echo "🎉 所有安装包构建完成！"
echo "=========================================="
echo "📍 产物目录: $DIST_DIR"
ls -lh "$DIST_DIR"
echo ""
echo "💡 推荐使用双击安装包:"
echo "   1. PKG 自动向导安装器: $PKG_FILE"
echo "   2. DMG 拖拽式安装镜像: $DMG_FILE"
