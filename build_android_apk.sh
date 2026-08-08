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
    cp "$SCRIPT_DIR/rust/target/release/libreia_backend.so" "$SCRIPT_DIR/godot/build/bin/libreia_backend.linux.release.arm64.so" 2>/dev/null || true
    cp "$SCRIPT_DIR/rust/target/release/libreia_backend.so" "$SCRIPT_DIR/godot/build/bin/libreia_backend.linux.debug.arm64.so" 2>/dev/null || true
fi

mkdir -p "$SCRIPT_DIR/godot/bin"

# Determine Godot runner
GODOT_CMD=""
if command -v godot &> /dev/null; then
    GODOT_CMD="godot"
elif [ -f "$HOME/Godot_v4.6-stable_linux.arm64" ] && command -v proot-distro &> /dev/null; then
    GODOT_CMD="proot-distro login --isolated --shared-home -b /data/data/com.termux/files/home:/data/data/com.termux/files/home ubuntu -- /data/data/com.termux/files/home/Godot_v4.6-stable_linux.arm64"
fi

if [ -n "$GODOT_CMD" ]; then
    echo "[+] Importing Godot project assets and building class cache..."
    $GODOT_CMD --headless --path "$SCRIPT_DIR/godot" --editor --quit || true

    echo "[+] Exporting Release APK via Godot CLI..."
    $GODOT_CMD --headless --path "$SCRIPT_DIR/godot" --export-release "android" "$SCRIPT_DIR/godot/bin/Reia-Android.apk" || true
    
    if [ ! -s "$SCRIPT_DIR/godot/bin/Reia-Android.apk" ]; then
        echo "[+] Packaging and signing Release APK..."
        python3 -c '
import zipfile, os, shutil, subprocess
template_apk = os.path.expanduser("~/.local/share/godot/export_templates/4.6.stable/android_release.apk")
output_apk = "'"$SCRIPT_DIR"'/godot/bin/Reia-Android.apk"
keystore = "'"$KEYSTORE_PATH"'"
shutil.copyfile(template_apk, output_apk)
with zipfile.ZipFile(output_apk, "a", compression=zipfile.ZIP_DEFLATED) as z:
    so_path = "'"$SCRIPT_DIR"'/godot/build/bin/libreia_backend.android.release.arm64-v8a.so"
    if os.path.exists(so_path):
        z.write(so_path, "lib/arm64-v8a/libreia_backend.android.release.arm64-v8a.so")
    godot_dir = "'"$SCRIPT_DIR"'/godot"
    for root, dirs, files in os.walk(godot_dir):
        if any(x in root for x in ["bin", ".godot", "build"]):
            continue
        for f in files:
            if f.startswith(".") or "-" in f:
                continue
            full_p = os.path.join(root, f)
            if not os.path.exists(full_p):
                continue
            z.write(full_p, os.path.join("assets", rel_p))
aligned_apk = output_apk + ".aligned"
subprocess.run(f"zipalign -p -f 4 {output_apk} {aligned_apk}", shell=True, check=True)
os.replace(aligned_apk, output_apk)
subprocess.run(f"apksigner sign --ks {keystore} --ks-pass pass:android --ks-key-alias androiddebugkey {output_apk}", shell=True, check=True)
'
    fi
    echo "[✓] Build complete! APK generated at: $SCRIPT_DIR/godot/bin/Reia-Android.apk"
else
    echo "[!] Godot CLI was not found."
    echo "    To complete APK export, execute:"
    echo "    godot --headless --path \"$SCRIPT_DIR/godot\" --export-release \"android\" \"$SCRIPT_DIR/godot/bin/Reia-Android.apk\""
fi

