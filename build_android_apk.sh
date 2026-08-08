#!/data/data/com.termux/files/usr/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=================================================="
echo "      Reia Android APK Export Builder"
echo "=================================================="

KEYSTORE_PATH="$SCRIPT_DIR/android_debug.keystore"
if [ ! -f "$KEYSTORE_PATH" ]; then
    echo "[+] Generating debug keystore..."
    keytool -genkey -v -keystore "$KEYSTORE_PATH" \
        -storepass android -alias androiddebugkey \
        -keypass android -keyalg RSA -keysize 2048 \
        -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
else
    echo "[✓] Debug keystore found: $KEYSTORE_PATH"
fi

if [ -d "$SCRIPT_DIR/rust" ]; then
    echo "[+] Building Rust GDExtension backend..."
    (cd "$SCRIPT_DIR/rust" && cargo build --release)
    mkdir -p "$SCRIPT_DIR/godot/build/bin"
    cp "$SCRIPT_DIR/rust/target/release/libreia_backend.so" "$SCRIPT_DIR/godot/build/bin/libreia_backend.android.release.arm64-v8a.so" 2>/dev/null || true
    cp "$SCRIPT_DIR/rust/target/release/libreia_backend.so" "$SCRIPT_DIR/godot/build/bin/libreia_backend.android.debug.arm64-v8a.so" 2>/dev/null || true
fi

mkdir -p "$SCRIPT_DIR/godot/bin"

# Determine Godot runner
GODOT_CMD=""
if command -v godot &> /dev/null; then
    GODOT_CMD="godot"
elif [ -f "$HOME/Godot_v4.6-stable_linux.arm64" ] && command -v proot-distro &> /dev/null; then
    GODOT_CMD="proot-distro login ubuntu -- $HOME/Godot_v4.6-stable_linux.arm64"
fi

if [ -n "$GODOT_CMD" ]; then
    echo "[+] Importing Godot project assets and building class cache..."
    $GODOT_CMD --headless --path "$SCRIPT_DIR/godot" --editor --quit || true

    echo "[+] Exporting Release APK via Godot CLI..."
    $GODOT_CMD --headless --path "$SCRIPT_DIR/godot" --export-release "android" "$SCRIPT_DIR/godot/bin/Reia-Android.apk"
    echo "[✓] Build complete! APK generated at: $SCRIPT_DIR/godot/bin/Reia-Android.apk"
else
    echo "[!] Godot CLI was not found."
    echo "    To complete APK export, execute:"
    echo "    godot --headless --path \"$SCRIPT_DIR/godot\" --export-release \"android\" \"$SCRIPT_DIR/godot/bin/Reia-Android.apk\""
fi

