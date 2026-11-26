# scripts/ThemePalettes.gd
class_name ThemePalettes
extends RefCounted

enum ThemeId { DARK, LIGHT }

const _DARK: Dictionary = {
	"BG": Color("#0D1A38"),
	"PANEL": Color("#14264F"),
	"CELL_EMPTY": Color("#22407F"),
	"BLUE": Color("#3F6BFF"),
	"TEAL": Color("#1FB8A8"),
	"YELLOW": Color("#F2B632"),
	"RED": Color("#E8553E"),
	"GREEN": Color("#3FA66B"),
	"TEXT": Color("#F2EEE4"),
	"TEXT_SECONDARY": Color("#9FB0D4"),
	"ACCENT": Color("#F2B632"),
	"ON_ACCENT": Color("#0D1A38")
}
const _LIGHT: Dictionary = {
	"BG": Color("#E8EEF0"),
	"PANEL": Color("#D3DEE2"),
	"CELL_EMPTY": Color("#C2D1D7"),
	"BLUE": Color("#2F6FED"),
	"TEAL": Color("#0F8B8D"),
	"YELLOW": Color("#E0A100"),
	"RED": Color("#E2563B"),
	"GREEN": Color("#4F9D5D"),
	"TEXT": Color("#14262C"),
	"TEXT_SECONDARY": Color("#4F6A72"),
	"ACCENT": Color("#0F8B8D"),
	"ON_ACCENT": Color("#FFFFFF")
}

static func key_for_color_id(id: int) -> String:
	match id:
		1:
			return "BLUE"
		2:
			return "TEAL"
		3:
			return "YELLOW"
		4:
			return "RED"
		5:
			return "GREEN"
		_:
			return "CELL_EMPTY"

static func get_palette(id: ThemeId) -> Dictionary:
	if id == ThemeId.LIGHT:
		return _LIGHT.duplicate()
	return _DARK.duplicate()
