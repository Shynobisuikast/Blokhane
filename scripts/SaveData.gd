# scripts/SaveData.gd
class_name SaveData
extends RefCounted

const SAVE_PATH: String = "user://save.cfg"
const SAVE_SECTION: String = "scores"
const BEST_KEY: String = "best"
const THEME_SECTION: String = "settings"
const THEME_KEY: String = "theme"
const AUDIO_SECTION: String = "audio"
const MUSIC_ENABLED_KEY: String = "music_enabled"
const SFX_ENABLED_KEY: String = "sfx_enabled"

static func load_best(path: String = SAVE_PATH) -> int:
	var config: ConfigFile = ConfigFile.new()
	if not _load_valid_config(config, path):
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
	_load_valid_config(config, path)
	config.set_value(SAVE_SECTION, BEST_KEY, value)
	_save_config(config, path)

static func load_theme(path: String = SAVE_PATH) -> ThemePalettes.ThemeId:
	var config: ConfigFile = ConfigFile.new()
	if not _load_valid_config(config, path):
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
	_load_valid_config(config, path)
	config.set_value(THEME_SECTION, THEME_KEY, id)
	_save_config(config, path)

static func load_audio_preferences(path: String = SAVE_PATH) -> Dictionary:
	var preferences: Dictionary = {"music_enabled": true, "sfx_enabled": true}
	var config: ConfigFile = ConfigFile.new()
	if not _load_valid_config(config, path):
		return preferences
	var music_enabled: Variant = config.get_value(AUDIO_SECTION, MUSIC_ENABLED_KEY, true)
	var sfx_enabled: Variant = config.get_value(AUDIO_SECTION, SFX_ENABLED_KEY, true)
	if typeof(music_enabled) == TYPE_BOOL:
		preferences["music_enabled"] = music_enabled
	if typeof(sfx_enabled) == TYPE_BOOL:
		preferences["sfx_enabled"] = sfx_enabled
	return preferences

static func save_audio_preferences(
	music_enabled: bool,
	sfx_enabled: bool,
	path: String = SAVE_PATH
) -> void:
	var config: ConfigFile = ConfigFile.new()
	_load_valid_config(config, path)
	config.set_value(AUDIO_SECTION, MUSIC_ENABLED_KEY, music_enabled)
	config.set_value(AUDIO_SECTION, SFX_ENABLED_KEY, sfx_enabled)
	_save_config(config, path)

static func reset_best(path: String = SAVE_PATH) -> void:
	var config: ConfigFile = ConfigFile.new()
	_load_valid_config(config, path)
	config.set_value(SAVE_SECTION, BEST_KEY, 0)
	_save_config(config, path)

static func _load_valid_config(config: ConfigFile, path: String) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var content: String = file.get_as_text()
	file.close()
	if not _has_valid_save_format(content):
		return false
	return config.load(path) == OK

static func _save_config(config: ConfigFile, path: String) -> void:
	var save_error: Error = config.save(path)
	if save_error != OK:
		push_warning("Kayıt dosyası yazılamadı: %s" % error_string(save_error))

static func _has_valid_save_format(content: String) -> bool:
	var section: String = ""
	var sections: Array[String] = []
	var has_best: bool = false
	var has_theme: bool = false
	var has_music: bool = false
	var has_sfx: bool = false
	for raw_line: String in content.split("\n"):
		var line: String = raw_line.strip_edges()
		if line.is_empty() or line.begins_with(";") or line.begins_with("#"):
			continue
		if line.begins_with("[") or line.ends_with("]"):
			if not line.begins_with("[") or not line.ends_with("]"):
				return false
			section = line.substr(1, line.length() - 2)
			if (
				section != SAVE_SECTION
				and section != THEME_SECTION
				and section != AUDIO_SECTION
			) or sections.has(section):
				return false
			sections.append(section)
			continue

		var separator: int = line.find("=")
		if section.is_empty() or separator <= 0:
			return false
		var key: String = line.substr(0, separator).strip_edges()
		var value_text: String = line.substr(separator + 1).strip_edges()
		if section == AUDIO_SECTION:
			if value_text.to_lower() != "true" and value_text.to_lower() != "false":
				return false
			if key == MUSIC_ENABLED_KEY and not has_music:
				has_music = true
			elif key == SFX_ENABLED_KEY and not has_sfx:
				has_sfx = true
			else:
				return false
			continue

		if not value_text.is_valid_int():
			return false
		var value: int = int(value_text)
		if section == SAVE_SECTION and key == BEST_KEY and not has_best and value >= 0:
			has_best = true
		elif section == THEME_SECTION and key == THEME_KEY and not has_theme:
			if value != ThemePalettes.ThemeId.DARK and value != ThemePalettes.ThemeId.LIGHT:
				return false
			has_theme = true
		else:
			return false
	return has_best or has_theme or has_music or has_sfx
