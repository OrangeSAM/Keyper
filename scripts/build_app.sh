#!/bin/bash
# Build TickeysX.app bundle from Swift Package Manager project
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/.build"
APP_DIR="$PROJECT_DIR/TickeysX.app"

echo "🔨 Building TickeysX..."
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
cp "$BUILD_DIR/release/TickeysX" "$APP_DIR/Contents/MacOS/TickeysX"
chmod +x "$APP_DIR/Contents/MacOS/TickeysX"

# Copy Info.plist
cp "$PROJECT_DIR/Info.plist" "$APP_DIR/Contents/Info.plist"

# Copy resources (audio data from SPM bundle)
if [ -d "$BUILD_DIR/release/TickeysX_TickeysX.bundle" ]; then
    cp -r "$BUILD_DIR/release/TickeysX_TickeysX.bundle" "$APP_DIR/Contents/Resources/"
fi

# Also copy data directory directly for direct access
if [ -d "$PROJECT_DIR/Sources/TickeysX/Resources/data" ]; then
    cp -r "$PROJECT_DIR/Sources/TickeysX/Resources/data" "$APP_DIR/Contents/Resources/"
fi

# Copy icon
if [ -f "$PROJECT_DIR/Resources/tickeys.icns" ]; then
    cp "$PROJECT_DIR/Resources/tickeys.icns" "$APP_DIR/Contents/Resources/"
fi

# Sign the app bundle ad-hoc to ensure TCC Accessibility registration works properly
echo "✍️ Signing app bundle (ad-hoc)..."
codesign --force --deep -s - "$APP_DIR"

# Clean up old Tickeys.app if present in this directory to avoid confusion
if [ -d "$PROJECT_DIR/Tickeys.app" ]; then
    rm -rf "$PROJECT_DIR/Tickeys.app"
fi

echo "✅ Build & CodeSign complete!"
echo "📍 App location: $APP_DIR"
echo ""
echo "To run: open $APP_DIR"
echo ""
echo "⚠️  首次使用：打开应用后会自动弹出系统设置中的「辅助功能」授权页，"
echo "   请在列表中开启「TickeysX」的开关。"
