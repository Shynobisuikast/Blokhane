# scripts/SaveData.gd
class_name SaveData
extends RefCounted

const SAVE_PATH: String = "user://save.cfg"
const SAVE_SECTION: String = "scores"
const BEST_KEY: String = "best"
const THEME_SECTION: String = "settings"
const THEME_KEY: String = "theme"
const AUDIO_SECTION: String = "audio"
const SFX_ENABLED_KEY: String = "sfx_enabled"

static func load_best(path: String = SAVE_PATH) -> int:
	var config: ConfigFile = ConfigFile.new()
	if not _load_config(config, path):
		return 0
	var value: Variant = config.get_value(SAVE_SECTION, BEST_KEY, 0)
	if typeof(value) != TYPE_INT or value < 0:
		return 0
	return value

static func save_best(value: int, path: String = SAVE_PATH) -> void:
	if value < 0:
		push_warning("Negatif en yüksek skor kaydedilmedi.")
		return
	var config: ConfigFile = ConfigFile.new()
	_load_config(config, path)
	config.set_value(SAVE_SECTION, BEST_KEY, value)
	_save_config(config, path)

static func load_theme(path: String = SAVE_PATH) -> ThemePalettes.ThemeId:
	var config: ConfigFile = ConfigFile.new()
	if not _load_config(config, path):
		return ThemePalettes.ThemeId.DARK
	var value: Variant = config.get_value(THEME_SECTION, THEME_KEY, ThemePalettes.ThemeId.DARK)
	if typeof(value) != TYPE_INT:
		return ThemePalettes.ThemeId.DARK
	if value == ThemePalettes.ThemeId.LIGHT:
		return ThemePalettes.ThemeId.LIGHT
	if value == ThemePalettes.ThemeId.DARK:
		return ThemePalettes.ThemeId.DARK
	return ThemePalettes.ThemeId.DARK

static func save_theme(id: ThemePalettes.ThemeId, path: String = SAVE_PATH) -> void:
	if id != ThemePalettes.ThemeId.DARK and id != ThemePalettes.ThemeId.LIGHT:
		push_warning("Geçersiz tema kaydedilmedi.")
		return
	var config: ConfigFile = ConfigFile.new()
	_load_config(config, path)
	config.set_value(THEME_SECTION, THEME_KEY, id)
	_save_config(config, path)

static func load_audio_preferences(path: String = SAVE_PATH) -> Dictionary:
	var preferences: Dictionary = {"sfx_enabled": true}
	var config: ConfigFile = ConfigFile.new()
	if not _load_config(config, path):
		return preferences
	var sfx_enabled: Variant = config.get_value(AUDIO_SECTION, SFX_ENABLED_KEY, true)
	if typeof(sfx_enabled) == TYPE_BOOL:
		preferences["sfx_enabled"] = sfx_enabled
	return preferences

# music_enabled anahtarı geri dönüş uyumluluğu için dosyada korunur; bkz. tests/SaveDataTestRunner.gd 96.
static func save_audio_preferences(sfx_enabled: bool, path: String = SAVE_PATH) -> void:
	var config: ConfigFile = ConfigFile.new()
	_load_config(config, path)
	config.set_value(AUDIO_SECTION, SFX_ENABLED_KEY, sfx_enabled)
	_save_config(config, path)

static func reset_best(path: String = SAVE_PATH) -> void:
	var config: ConfigFile = ConfigFile.new()
	_load_config(config, path)
	config.set_value(SAVE_SECTION, BEST_KEY, 0)
	_save_config(config, path)

static func _load_config(config: ConfigFile, path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	return config.load(path) == OK

static func _save_config(config: ConfigFile, path: String) -> void:
	var tmp_path: String = path + ".tmp"
	var save_error: Error = config.save(tmp_path)
	if save_error != OK:
		push_warning("Geçici kayıt dosyası yazılamadı: %s" % error_string(save_error))
		_remove_tmp_file(tmp_path)
		return

	var rename_error: Error = DirAccess.rename_absolute(
		ProjectSettings.globalize_path(tmp_path),
		ProjectSettings.globalize_path(path)
	)
	if rename_error != OK:
		push_warning("Kayıt dosyası değiştirilemedi: %s" % error_string(rename_error))
		_remove_tmp_file(tmp_path)

static func _remove_tmp_file(tmp_path: String) -> void:
	if not FileAccess.file_exists(tmp_path):
		return
	var remove_error: Error = DirAccess.remove_absolute(
		ProjectSettings.globalize_path(tmp_path)
	)
	if remove_error != OK:
		push_warning("Geçici kayıt dosyası silinemedi: %s" % error_string(remove_error))
