# scripts/SaveData.gd
class_name SaveData
extends RefCounted

const SAVE_PATH: String = "user://save.cfg"
const SAVE_SECTION: String = "scores"
const BEST_KEY: String = "best"

static func load_best(path: String = SAVE_PATH) -> int:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return 0
	var content: String = file.get_as_text()
	file.close()
	if not _has_valid_save_format(content):
		return 0

	var config: ConfigFile = ConfigFile.new()
	if config.load(path) != OK:
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
	config.set_value(SAVE_SECTION, BEST_KEY, value)
	var save_error: Error = config.save(path)
	if save_error != OK:
		push_warning("En yüksek skor kaydedilemedi: %s" % error_string(save_error))

static func _has_valid_save_format(content: String) -> bool:
	var has_section: bool = false
	var has_best: bool = false
	for raw_line: String in content.split("\n"):
		var line: String = raw_line.strip_edges()
		if line.is_empty() or line.begins_with(";") or line.begins_with("#"):
			continue
		if line.begins_with("["):
			if has_section or line != "[%s]" % SAVE_SECTION:
				return false
			has_section = true
			continue
		var separator: int = line.find("=")
		if not has_section or has_best or separator <= 0:
			return false
		if line.substr(0, separator).strip_edges() != BEST_KEY:
			return false
		var value_text: String = line.substr(separator + 1).strip_edges()
		if not value_text.is_valid_int() or int(value_text) < 0:
			return false
		has_best = true
	return has_section and has_best
