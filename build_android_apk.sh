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

mkdir -p "$SCRIPT_DIR/godot/bin"

if command -v godot &> /dev/null; then
    echo "[+] Exporting APK via Godot CLI..."
    godot --headless --path "$SCRIPT_DIR/godot" --export-debug "android" "$SCRIPT_DIR/godot/bin/Reia.apk"
    echo "[✓] Build complete! APK generated at: $SCRIPT_DIR/godot/bin/Reia.apk"
else
    echo "[!] Godot CLI was not found in PATH."
    echo "    To complete APK export, execute Godot with:"
    echo "    godot --headless --path \"$SCRIPT_DIR/godot\" --export-debug \"android\" \"$SCRIPT_DIR/godot/bin/Reia.apk\""
fi
