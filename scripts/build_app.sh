#!/bin/bash
# Build Keyper.app bundle from Swift Package Manager project
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/.build"
APP_DIR="$PROJECT_DIR/Keyper.app"

echo "🔨 Building Keyper..."
cd "$PROJECT_DIR"

# Build with SPM
swift build -c release 2>&1

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "📦 Creating app bundle: $APP_DIR..."

# Create .app bundle structure
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copy binary
cp "$BUILD_DIR/release/Keyper" "$APP_DIR/Contents/MacOS/Keyper"
chmod +x "$APP_DIR/Contents/MacOS/Keyper"

# Copy Info.plist
cp "$PROJECT_DIR/Info.plist" "$APP_DIR/Contents/Info.plist"

# Copy resources (audio data from SPM bundle)
if [ -d "$BUILD_DIR/release/Keyper_Keyper.bundle" ]; then
    cp -r "$BUILD_DIR/release/Keyper_Keyper.bundle" "$APP_DIR/Contents/Resources/"
fi

# Also copy data directory directly for direct access
if [ -d "$PROJECT_DIR/Sources/Keyper/Resources/data" ]; then
    cp -r "$PROJECT_DIR/Sources/Keyper/Resources/data" "$APP_DIR/Contents/Resources/"
fi

# Copy icon
if [ -f "$PROJECT_DIR/Resources/keyper.icns" ]; then
    cp "$PROJECT_DIR/Resources/keyper.icns" "$APP_DIR/Contents/Resources/"
fi

# Sign the app bundle ad-hoc to ensure TCC Accessibility registration works properly
echo "✍️ Signing app bundle (ad-hoc)..."
codesign --force --deep -s - "$APP_DIR"

# Clean up any legacy test bundles
rm -rf "$PROJECT_DIR/Tickeys.app" "$PROJECT_DIR/TickeysX.app" 2>/dev/null || true

echo "✅ Build & CodeSign complete!"
echo "📍 App location: $APP_DIR"
echo ""
echo "To run: open $APP_DIR"
echo ""
echo "⚠️  首次使用：打开应用后会自动弹出系统设置中的「辅助功能」授权页，"
echo "   请在列表中开启「Keyper」的开关。"
