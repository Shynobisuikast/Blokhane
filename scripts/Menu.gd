# scripts/Menu.gd
class_name Menu
extends Control

signal play_requested
signal settings_requested

const SaveDataScript = preload("res://scripts/SaveData.gd")

var _best_score: int = 0
var _title_font: Font
var _play_button: Button
var _settings_button: Button
var _title_font_size: int = Config.MENU_TITLE_FONT_SIZE

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_buttons()
	ThemeAccess.connect_changed(_on_theme_changed)
	_apply_theme()
	var title_variation: FontVariation = FontVariation.new()
	title_variation.base_font = ThemeDB.fallback_font
	title_variation.variation_embolden = Config.MENU_TITLE_EMBOLDEN
	_title_font = title_variation
	_fit_title_font()
	refresh_best()

func refresh_best() -> void:
	_best_score = SaveDataScript.load_best()
	queue_redraw()

func _on_theme_changed() -> void:
	_apply_theme()
	queue_redraw()

func _apply_theme() -> void:
	_set_button_theme(_play_button, ThemeAccess.color("ACCENT"), ThemeAccess.color("ON_ACCENT"))
	_set_button_theme(_settings_button, ThemeAccess.color("PANEL"), ThemeAccess.color("TEXT"))

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Config.SCREEN_SIZE), ThemeAccess.color("BG"))
	_draw_rounded_rect(
		Config.MENU_LOGO_POSITION,
		Config.MENU_LOGO_SIZE,
		Config.MENU_LOGO_RADIUS,
		ThemeAccess.color("PANEL")
	)
	_draw_logo_cells()
	draw_string(
		_title_font,
		Config.MENU_TITLE_POSITION,
		"Blokhane",
		HORIZONTAL_ALIGNMENT_CENTER,
		Config.MENU_TITLE_MAX_WIDTH,
		_title_font_size,
		ThemeAccess.color("TEXT")
	)
	draw_string(
		ThemeDB.fallback_font,
		Config.MENU_SUBTITLE_POSITION,
		"Parçaları yerleştir, çizgileri temizle.",
		HORIZONTAL_ALIGNMENT_CENTER,
		Config.MENU_SUBTITLE_WIDTH,
		Config.MENU_SUBTITLE_FONT_SIZE,
		ThemeAccess.color("TEXT_SECONDARY")
	)
	var best_label: String = "En yüksek skor"
	var label_width: float = ThemeDB.fallback_font.get_string_size(
		best_label,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		Config.MENU_BEST_LABEL_FONT_SIZE
	).x
	draw_string(
		ThemeDB.fallback_font,
		Vector2((Config.SCREEN_SIZE.x - label_width) / 2.0, Config.MENU_BEST_LABEL_POSITION.y),
		best_label,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		Config.MENU_BEST_LABEL_FONT_SIZE,
		ThemeAccess.color("TEXT_SECONDARY")
	)
	var best_value: String = str(_best_score)
	var value_width: float = ThemeDB.fallback_font.get_string_size(
		best_value,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		Config.MENU_BEST_VALUE_FONT_SIZE
	).x
	draw_string(
		ThemeDB.fallback_font,
		Vector2((Config.SCREEN_SIZE.x - value_width) / 2.0, Config.MENU_BEST_VALUE_POSITION.y),
		best_value,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		Config.MENU_BEST_VALUE_FONT_SIZE,
		ThemeAccess.color("TEXT")
	)

func _draw_logo_cells() -> void:
	var colors: Array[Color] = [
		ThemeAccess.color("BLUE"), ThemeAccess.color("CELL_EMPTY"), ThemeAccess.color("TEAL"),
		ThemeAccess.color("BLUE"), ThemeAccess.color("YELLOW"), ThemeAccess.color("YELLOW"),
		ThemeAccess.color("BLUE"), ThemeAccess.color("YELLOW"), ThemeAccess.color("YELLOW")
	]
	for index: int in range(colors.size()):
		var cell_position: Vector2 = Config.MENU_LOGO_CELL_ORIGIN + Vector2(
			(index % 3) * Config.MENU_LOGO_CELL_STEP,
			(index / 3) * Config.MENU_LOGO_CELL_STEP
		)
		var cell_rect: Rect2 = Rect2(cell_position, Vector2.ONE * Config.MENU_LOGO_CELL_SIZE)
		_draw_rounded_rect(
			cell_position,
			cell_rect.size,
			Config.MENU_LOGO_CELL_RADIUS,
			colors[index]
		)
		if colors[index] == ThemeAccess.color("CELL_EMPTY"):
			var shadow_y: float = cell_position.y + Config.MENU_EMPTY_SHADOW_OFFSET_Y
			draw_line(
				Vector2(cell_position.x + Config.MENU_LOGO_CELL_RADIUS, shadow_y),
				Vector2(cell_rect.end.x - Config.MENU_LOGO_CELL_RADIUS, shadow_y),
				Color(0.0, 0.0, 0.0, Config.MENU_EMPTY_SHADOW_ALPHA),
				2.0
			)
		else:
			CellDrawing.draw_filled_cell_bevel(
				self,
				cell_rect,
				Config.MENU_LOGO_CELL_RADIUS,
				Config.MENU_LOGO_BEVEL_BAND
			)

func _build_buttons() -> void:
	_play_button = _make_button(
		"Oyna",
		Config.MENU_PLAY_POSITION,
		Config.MENU_PLAY_SIZE,
		ThemeAccess.color("ACCENT"),
		ThemeAccess.color("ON_ACCENT"),
		Config.MENU_PLAY_RADIUS,
		Config.MENU_PLAY_FONT_SIZE
	)
	_play_button.pressed.connect(_on_play_pressed)
	_settings_button = _make_button(
		"Ayarlar",
		Config.MENU_SETTINGS_POSITION,
		Config.MENU_SETTINGS_SIZE,
		ThemeAccess.color("PANEL"),
		ThemeAccess.color("TEXT"),
		Config.MENU_SETTINGS_RADIUS,
		Config.MENU_SETTINGS_FONT_SIZE
	)
	_settings_button.pressed.connect(_on_settings_pressed)

func _make_button(
	label: String,
	button_position: Vector2,
	button_size: Vector2,
	fill: Color,
	text_color: Color,
	radius: int,
	font_size: int
) -> Button:
	var button: Button = Button.new()
	button.text = label
	button.position = button_position
	button.size = button_size
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	var style: StyleBoxFlat = _make_style_box(fill, radius)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)
	add_child(button)
	ButtonFeedback.apply(button)
	return button

func _set_button_theme(button: Button, fill: Color, text_color: Color) -> void:
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	var style: StyleBoxFlat = _make_style_box(
		fill,
		Config.MENU_PLAY_RADIUS if button == _play_button else Config.MENU_SETTINGS_RADIUS
	)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)

func _fit_title_font() -> void:
	while (
		_title_font_size > Config.MENU_TITLE_MIN_FONT_SIZE
		and _title_font.get_string_size("Blokhane", HORIZONTAL_ALIGNMENT_LEFT, -1, _title_font_size).x
		> Config.MENU_TITLE_MAX_WIDTH
	):
		_title_font_size -= 1

func _draw_rounded_rect(rect_position: Vector2, rect_size: Vector2, radius: float, color: Color) -> void:
	draw_rect(Rect2(rect_position + Vector2(radius, 0.0), Vector2(rect_size.x - radius * 2.0, rect_size.y)), color)
	draw_rect(Rect2(rect_position + Vector2(0.0, radius), Vector2(rect_size.x, rect_size.y - radius * 2.0)), color)
	for corner: Vector2 in [
		rect_position + Vector2(radius, radius),
		rect_position + Vector2(rect_size.x - radius, radius),
		rect_position + rect_size - Vector2(radius, radius),
		rect_position + Vector2(radius, rect_size.y - radius)
	]:
		draw_circle(corner, radius, color)

func _make_style_box(fill: Color, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	return style

func _on_play_pressed() -> void:
	play_requested.emit()

func _on_settings_pressed() -> void:
	settings_requested.emit()
