# scripts/AppTheme.gd
extends Node

signal changed

var current: ThemePalettes.ThemeId = ThemePalettes.ThemeId.DARK

func _ready() -> void:
	current = SaveData.load_theme()

func color(key: String) -> Color:
	var palette: Dictionary = ThemePalettes.get_palette(current)
	if not palette.has(key):
		return palette["TEXT"]
	return palette[key] as Color

func color_for(id: int) -> Color:
	var palette_key: String = "CELL_EMPTY"
	match id:
		1:
			palette_key = "BLUE"
		2:
			palette_key = "TEAL"
		3:
			palette_key = "YELLOW"
		4:
			palette_key = "RED"
		5:
			palette_key = "GREEN"
	return color(palette_key)

func set_theme(id: ThemePalettes.ThemeId) -> void:
	if id != ThemePalettes.ThemeId.DARK and id != ThemePalettes.ThemeId.LIGHT:
		return
	if current == id:
		return
	current = id
	SaveData.save_theme(id)
	changed.emit()
