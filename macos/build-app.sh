#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build-macos"
STAGE_ROOT="$BUILD_DIR/stage-root"
DIST_DIR="$ROOT_DIR/dist"
APP="$DIST_DIR/Meld.app"
CONTENTS="$APP/Contents"
RESOURCES="$CONTENTS/Resources"
PREFIX_ROOT="$STAGE_ROOT/opt/meld-macos"
PYTHON_PREFIX=/opt/homebrew/opt/python@3.13
PYTHON="$PYTHON_PREFIX/bin/python3.13"

for tool in meson ninja pkg-config rsvg-convert glib-compile-schemas itstool \
            codesign cc plutil; do
    if ! command -v "$tool" >/dev/null; then
        echo "Missing required tool: $tool" >&2
        echo "Install prerequisites with: brew install python@3.13 gtksourceview4 pygobject3 py3cairo librsvg itstool" >&2
        exit 1
    fi
done

if [[ ! -x "$PYTHON" ]]; then
    echo "Missing required Python: $PYTHON" >&2
    echo "Install it with: brew install python@3.13" >&2
    exit 1
fi

for package in gtk+-3.0 gtksourceview-4 pygobject-3.0 py3cairo; do
    if ! pkg-config --exists "$package"; then
        echo "Missing required package: $package" >&2
        echo "Install prerequisites with: brew install python@3.13 gtksourceview4 pygobject3 py3cairo librsvg itstool" >&2
        exit 1
    fi
done

export PATH="$PYTHON_PREFIX/bin:$PATH"

MESON_OPTIONS=(
    --wrap-mode=nofallback
    --buildtype=release
    --prefix=/opt/meld-macos
)

if [[ -f "$BUILD_DIR/meson-private/coredata.dat" ]]; then
    meson setup --reconfigure "$BUILD_DIR" "${MESON_OPTIONS[@]}"
else
    meson setup "$BUILD_DIR" "${MESON_OPTIONS[@]}"
fi
meson compile -C "$BUILD_DIR"

if [[ "$STAGE_ROOT" != "$BUILD_DIR/"* || "$APP" != "$DIST_DIR/Meld.app" ]]; then
    echo "Refusing to clean an unexpected output path" >&2
    exit 1
fi
rm -rf "$STAGE_ROOT" "$APP"
DESTDIR="$STAGE_ROOT" meson install -C "$BUILD_DIR"

PYTHON_VERSION="$($PYTHON -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
STAGED_SITE="$(find "$PREFIX_ROOT" -type d \
    -path "*/lib/python$PYTHON_VERSION/site-packages" -print -quit)"
BUNDLE_SITE="$RESOURCES/lib/python$PYTHON_VERSION/site-packages"

if [[ -z "$STAGED_SITE" || ! -d "$STAGED_SITE/meld" ]]; then
    echo "Unable to locate the staged Meld Python package" >&2
    exit 1
fi

mkdir -p "$CONTENTS/MacOS" "$BUNDLE_SITE" "$RESOURCES/bin" \
         "$RESOURCES/share/glib-2.0/schemas"

install -m 755 "$PREFIX_ROOT/bin/meld" "$RESOURCES/bin/meld"
cp -R "$STAGED_SITE/meld" "$BUNDLE_SITE/"
cp -R "$PREFIX_ROOT/share/meld" "$RESOURCES/share/"
cp -R "$PREFIX_ROOT/share/locale" "$RESOURCES/share/"
cp -R "$PREFIX_ROOT/share/icons" "$RESOURCES/share/"
install -m 644 "$ROOT_DIR/macos/Info.plist" "$CONTENTS/Info.plist"

find /opt/homebrew/share/glib-2.0/schemas -maxdepth 1 -name '*.xml' \
    -exec cp {} "$RESOURCES/share/glib-2.0/schemas/" \;
install -m 644 "$PREFIX_ROOT/share/glib-2.0/schemas/org.gnome.meld.gschema.xml" \
    "$RESOURCES/share/glib-2.0/schemas/"
glib-compile-schemas "$RESOURCES/share/glib-2.0/schemas"

cc -O2 -Wl,-rpath,/opt/homebrew/lib \
    -o "$CONTENTS/MacOS/Meld-bin" "$ROOT_DIR/macos/meld-launcher.c" \
    $("$PYTHON_PREFIX/bin/python3.13-config" --embed --cflags --ldflags)
install -m 755 "$ROOT_DIR/macos/meld-launcher" "$CONTENTS/MacOS/Meld"

ICONSET="$BUILD_DIR/Meld.iconset"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"
for size in 16 32 128 256 512; do
    rsvg-convert -w "$size" -h "$size" \
        "$ROOT_DIR/data/icons/hicolor/scalable/apps/org.gnome.Meld.svg" \
        -o "$ICONSET/icon_${size}x${size}.png"
    double_size=$((size * 2))
    rsvg-convert -w "$double_size" -h "$double_size" \
        "$ROOT_DIR/data/icons/hicolor/scalable/apps/org.gnome.Meld.svg" \
        -o "$ICONSET/icon_${size}x${size}@2x.png"
done

ICNS_BUILDER="$BUILD_DIR/make-icns"
cc -O2 -o "$ICNS_BUILDER" "$ROOT_DIR/macos/make-icns.c"
"$ICNS_BUILDER" "$RESOURCES/Meld.icns" \
    icp4 "$ICONSET/icon_16x16.png" \
    icp5 "$ICONSET/icon_32x32.png" \
    icp6 "$ICONSET/icon_32x32@2x.png" \
    ic07 "$ICONSET/icon_128x128.png" \
    ic08 "$ICONSET/icon_256x256.png" \
    ic09 "$ICONSET/icon_512x512.png" \
    ic10 "$ICONSET/icon_512x512@2x.png"

codesign --force --deep --sign - "$APP"
install -m 755 "$ROOT_DIR/macos/meld-launcher" "$DIST_DIR/meld"
plutil -lint "$CONTENTS/Info.plist"
codesign --verify --deep --strict "$APP"

echo
echo "Built $APP"
