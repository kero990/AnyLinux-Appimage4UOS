#!/usr/bin/env bash
set -euo pipefail

: "${VERSION:?VERSION must be set}"
: "${TARGET_ARCH:?TARGET_ARCH must be set}"
: "${BUILD_DIR:?BUILD_DIR must be set}"
: "${OUTPUT_DIR:?OUTPUT_DIR must be set}"

quick_sharun_url="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/quick-sharun.sh"
deblob_url="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/get-debloated-pkgs.sh"

mkdir -p "$BUILD_DIR" "$OUTPUT_DIR"
cd "$BUILD_DIR"

wget -qO quick-sharun.sh "$quick_sharun_url"
wget -qO get-debloated-pkgs.sh "$deblob_url"
chmod +x quick-sharun.sh get-debloated-pkgs.sh

./get-debloated-pkgs.sh --add-common --prefer-nano

export QT_QPA_PLATFORMTHEME=qt6ct
export DEPLOY_OPENGL=0
export DEPLOY_VULKAN=0
export DEPLOY_QML=1
export DEPLOY_PYTHON=1
export ANYLINUX_DO_NOT_LOAD_LIBS='libGLX_mesa.so*:libEGL_mesa.so*:libgallium-:libvulkan'
export PATH_MAPPING='
/usr/share/krita:${SHARUN_DIR}/share/krita
/usr/share/kritaplugins:${SHARUN_DIR}/share/kritaplugins
/usr/lib/krita-python-libs:${SHARUN_DIR}/lib/krita-python-libs
/usr/share/color/icc/krita:${SHARUN_DIR}/share/color/icc/krita
/usr/share/color-schemes:${SHARUN_DIR}/share/color-schemes
'
export DESKTOP=/usr/share/applications/org.kde.krita.desktop
export ICON=/usr/share/icons/hicolor/256x256/apps/krita.png
export APPDIR="$BUILD_DIR/AppDir"
export OUTPATH="$BUILD_DIR/out"

mkdir -p "$OUTPATH"

shopt -s nullglob
color_schemes=(/usr/share/color-schemes/Krita*)

./quick-sharun.sh \
  /usr/bin/krita \
  /usr/bin/krita_version \
  /usr/bin/kritarunner \
  /usr/lib/krita-python-libs \
  /usr/share/color/icc/krita \
  /usr/share/kritaplugins \
  "${color_schemes[@]}"

printf '\nQT_QPA_PLATFORMTHEME=qt6ct\n' >> "$APPDIR/.env"

./quick-sharun.sh --make-appimage

appimages=("$OUTPATH"/*.AppImage)
if (( ${#appimages[@]} != 1 )); then
  printf 'Expected exactly one AppImage in %s, found %d\n' "$OUTPATH" "${#appimages[@]}" >&2
  exit 1
fi

output_app="$OUTPUT_DIR/krita-${VERSION}-${TARGET_ARCH}.AppImage"
install -Dm755 "${appimages[0]}" "$output_app"

zsync_file=''
for candidate in "$OUTPATH"/*.AppImage.zsync "$OUTPATH"/*.zsync; do
  if [[ -f "$candidate" ]]; then
    zsync_file="$candidate"
    break
  fi
done

if [[ -n "$zsync_file" ]]; then
  output_zsync="${output_app}.zsync"
  mkdir -p "$(dirname "$output_zsync")"
  sed "s/^Filename: .*/Filename: $(basename "$output_app")/" "$zsync_file" > "$output_zsync"
fi
