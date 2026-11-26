# scripts/ThemeAccess.gd
class_name ThemeAccess
extends RefCounted

const ThemePalettesScript = preload("res://scripts/ThemePalettes.gd")

static func manager() -> Node:
	var scene_tree: SceneTree = Engine.get_main_loop() as SceneTree
	if scene_tree == null:
		return null
	return scene_tree.root.get_node_or_null("AppTheme")

static func current() -> ThemePalettesScript.ThemeId:
	var theme_manager: Node = manager()
	if theme_manager == null:
		return ThemePalettesScript.ThemeId.DARK
	var value: Variant = theme_manager.get("current")
	if typeof(value) == TYPE_INT and value == ThemePalettesScript.ThemeId.LIGHT:
		return ThemePalettesScript.ThemeId.LIGHT
	return ThemePalettesScript.ThemeId.DARK

static func color(key: String) -> Color:
	var theme_manager: Node = manager()
	if theme_manager != null:
		return theme_manager.call("color", key)
	var palette: Dictionary = ThemePalettesScript.get_palette(ThemePalettesScript.ThemeId.DARK)
	if not palette.has(key):
		return palette["TEXT"]
	return palette[key]

static func color_for(id: int) -> Color:
	var theme_manager: Node = manager()
	if theme_manager != null:
		return theme_manager.call("color_for", id)
	return color(ThemePalettesScript.key_for_color_id(id))

static func set_theme(id: ThemePalettesScript.ThemeId) -> void:
	var theme_manager: Node = manager()
	if theme_manager != null:
		theme_manager.call("set_theme", id)

static func connect_changed(callback: Callable) -> void:
	var theme_manager: Node = manager()
	if theme_manager == null:
		return
	var changed_signal: Signal = theme_manager.get("changed")
	if not changed_signal.is_connected(callback):
		changed_signal.connect(callback)
