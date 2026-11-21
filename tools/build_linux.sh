#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname -- "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

readonly PRESET_NAME="Linux"
readonly EXPORT_PATH="build/Blokhane.x86_64"
readonly APP_DIR="build/AppDir"
readonly APPIMAGE_PATH="build/Blokhane-x86_64.AppImage"
readonly ICON_PATH="assets/Blokhane.png"
readonly APPIMAGETOOL_BIN="${APPIMAGETOOL:-appimagetool}"
readonly GODOT_BIN="${GODOT_BIN:-godot}"

MISSING_REQUIREMENTS=0

if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
	printf 'HATA: Godot çalıştırılabilir dosyası bulunamadı: %s\n' "$GODOT_BIN" >&2
	MISSING_REQUIREMENTS=1
else
	GODOT_VERSION_RAW="$("$GODOT_BIN" --version)"
	GODOT_VERSION="$(printf '%s\n' "$GODOT_VERSION_RAW" | sed -E 's/^([0-9]+\.[0-9]+\.[0-9]+).*/\1/')"
	if [[ "$GODOT_VERSION" != 4.7.* ]]; then
		printf 'HATA: Godot 4.7 gerekli; bulunan sürüm: %s\n' "$GODOT_VERSION_RAW" >&2
		MISSING_REQUIREMENTS=1
	fi
	GODOT_DATA_ROOT="${XDG_DATA_HOME:-${HOME:?HOME tanımlı değil}/.local/share}"
	GODOT_TEMPLATE_DIR="${GODOT_EXPORT_TEMPLATES_DIR:-$GODOT_DATA_ROOT/godot/export_templates/$GODOT_VERSION.stable}"
	if [[ ! -f "$GODOT_TEMPLATE_DIR/linux_release.x86_64" ]]; then
		printf 'HATA: Godot %s Linux x86_64 dışa aktarma şablonu bulunamadı: %s\n' \
			"$GODOT_VERSION" "$GODOT_TEMPLATE_DIR" >&2
		printf 'Godot Editör > Editor > Manage Export Templates bölümünden %s şablonlarını kurun.\n' \
			"$GODOT_VERSION" >&2
		MISSING_REQUIREMENTS=1
	fi
fi

if [[ ! -f export_presets.cfg ]]; then
	printf 'HATA: Yerel export_presets.cfg yok. Şablonu kopyalayın: cp export_presets.cfg.example export_presets.cfg\n' >&2
	MISSING_REQUIREMENTS=1
fi

if [[ ! -f "$ICON_PATH" ]]; then
	printf 'HATA: AppImage simgesi bulunamadı: %s\n' "$ICON_PATH" >&2
	MISSING_REQUIREMENTS=1
fi

if command -v "$APPIMAGETOOL_BIN" >/dev/null 2>&1; then
	APPIMAGETOOL_COMMAND="$(command -v "$APPIMAGETOOL_BIN")"
elif [[ -x "$APPIMAGETOOL_BIN" ]]; then
	APPIMAGETOOL_COMMAND="$APPIMAGETOOL_BIN"
else
	printf 'HATA: appimagetool bulunamadı. Otomatik indirme yapılmadı.\n' >&2
	printf 'İndirme: https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage\n' >&2
	printf 'Kurulum: chmod +x appimagetool-x86_64.AppImage\n' >&2
	printf 'Kullanım: APPIMAGETOOL=./appimagetool-x86_64.AppImage ./tools/build_linux.sh\n' >&2
	MISSING_REQUIREMENTS=1
fi

if [[ "$MISSING_REQUIREMENTS" -ne 0 ]]; then
	exit 1
fi

mkdir -p build
"$GODOT_BIN" --headless --path . --export-release "$PRESET_NAME" "$EXPORT_PATH"

if [[ ! -f "$EXPORT_PATH" ]]; then
	printf 'HATA: Godot dışa aktarma çıktısı oluşturulmadı: %s\n' "$EXPORT_PATH" >&2
	exit 1
fi

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/usr/bin"
cp "$EXPORT_PATH" "$APP_DIR/usr/bin/Blokhane"
cp "$ICON_PATH" "$APP_DIR/Blokhane.png"
chmod +x "$APP_DIR/usr/bin/Blokhane"
ln -s usr/bin/Blokhane "$APP_DIR/AppRun"

cat > "$APP_DIR/Blokhane.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Blokhane
Exec=Blokhane
Icon=Blokhane
Categories=Game;LogicGame;
Terminal=false
DESKTOP

"$APPIMAGETOOL_COMMAND" "$APP_DIR" "$APPIMAGE_PATH"
chmod +x "$APPIMAGE_PATH"
printf 'AppImage oluşturuldu: %s\n' "$APPIMAGE_PATH"
