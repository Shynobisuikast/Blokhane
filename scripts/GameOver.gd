# scripts/GameOver.gd
class_name GameOver
extends Control

signal restart_requested
signal menu_requested

var _final_score: int = 0

var _is_new_best: bool = false
var _restart_button: Button
var _menu_button: Button

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_buttons()
	ThemeAccess.connect_changed(_on_theme_changed)
	_apply_theme()

func _on_theme_changed() -> void:
	_apply_theme()
	queue_redraw()

func _apply_theme() -> void:
	_set_button_theme(_restart_button, ThemeAccess.color("ACCENT"), ThemeAccess.color("ON_ACCENT"), Config.GAME_OVER_RESTART_RADIUS)
	_set_button_theme(_menu_button, ThemeAccess.color("PANEL"), ThemeAccess.color("TEXT"), Config.GAME_OVER_MENU_RADIUS)

func show_result(final_score: int, is_new_best: bool) -> void:
	_final_score = final_score
	_is_new_best = is_new_best
	visible = true
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Config.SCREEN_SIZE), ThemeAccess.color("BG"))
	_draw_rounded_rect(
		Config.GAME_OVER_CARD_POSITION,
		Config.GAME_OVER_CARD_SIZE,
		Config.GAME_OVER_CARD_RADIUS,
		ThemeAccess.color("PANEL")
	)

	if _is_new_best:
		_draw_rounded_rect(
			Config.GAME_OVER_RECORD_POSITION,
			Config.GAME_OVER_RECORD_SIZE,
			Config.GAME_OVER_RECORD_RADIUS,
			ThemeAccess.color("ACCENT")
		)

	draw_string(
		ThemeDB.fallback_font,
		Config.GAME_OVER_TITLE_POSITION,
		"Oyun bitti",
		HORIZONTAL_ALIGNMENT_CENTER,
		Config.GAME_OVER_TITLE_SIZE.x,
		Config.GAME_OVER_TITLE_FONT_SIZE,
		ThemeAccess.color("TEXT")
	)
	draw_string(
		ThemeDB.fallback_font,
		Config.GAME_OVER_SCORE_LABEL_POSITION,
		"Skorun",
		HORIZONTAL_ALIGNMENT_CENTER,
		Config.GAME_OVER_SCORE_LABEL_SIZE.x,
		Config.GAME_OVER_LABEL_FONT_SIZE,
		ThemeAccess.color("TEXT_SECONDARY")
	)
	draw_string(
		ThemeDB.fallback_font,
		Config.GAME_OVER_SCORE_VALUE_POSITION,
		str(_final_score),
		HORIZONTAL_ALIGNMENT_CENTER,
		Config.GAME_OVER_SCORE_VALUE_SIZE.x,
		Config.GAME_OVER_SCORE_FONT_SIZE,
		ThemeAccess.color("TEXT")
	)
	if _is_new_best:
		draw_string(
			ThemeDB.fallback_font,
			Vector2(Config.GAME_OVER_RECORD_POSITION.x, Config.GAME_OVER_RECORD_TEXT_BASELINE),
			"Yeni rekor",
			HORIZONTAL_ALIGNMENT_CENTER,
			Config.GAME_OVER_RECORD_SIZE.x,
			Config.GAME_OVER_RECORD_FONT_SIZE,
			ThemeAccess.color("ON_ACCENT")
		)

func _build_buttons() -> void:
	_restart_button = _make_button(
		"Tekrar oyna",
		Config.GAME_OVER_RESTART_POSITION,
		Config.GAME_OVER_RESTART_SIZE,
		ThemeAccess.color("ACCENT"),
		ThemeAccess.color("ON_ACCENT"),
		Config.GAME_OVER_RESTART_RADIUS,
		Config.GAME_OVER_RESTART_FONT_SIZE
	)
	_restart_button.pressed.connect(_on_restart_pressed)
	_menu_button = _make_button(
		"Ana menü",
		Config.GAME_OVER_MENU_POSITION,
		Config.GAME_OVER_MENU_SIZE,
		ThemeAccess.color("PANEL"),
		ThemeAccess.color("TEXT"),
		Config.GAME_OVER_MENU_RADIUS,
		Config.GAME_OVER_MENU_FONT_SIZE
	)
	_menu_button.pressed.connect(_on_menu_pressed)

func _make_button(
	label: String,
	button_origin: Vector2,
	button_size: Vector2,
	fill: Color,
	text_color: Color,
	radius: int,
	font_size: int
) -> Button:
	var button: Button = Button.new()
	button.text = label
	button.position = button_origin
	button.size = button_size
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_stylebox_override("normal", _make_style_box(fill, radius))
	button.add_theme_stylebox_override("hover", _make_style_box(fill, radius))
	button.add_theme_stylebox_override("pressed", _make_style_box(fill, radius))
	button.add_theme_stylebox_override("focus", _make_style_box(fill, radius))
	add_child(button)
	return button

func _set_button_theme(button: Button, fill: Color, text_color: Color, radius: int) -> void:
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	var style: StyleBoxFlat = _make_style_box(fill, radius)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)

func _draw_rounded_rect(rect_origin: Vector2, rect_size: Vector2, radius: float, color: Color) -> void:
	draw_rect(Rect2(rect_origin + Vector2(radius, 0.0), Vector2(rect_size.x - radius * 2.0, rect_size.y)), color)
	draw_rect(Rect2(rect_origin + Vector2(0.0, radius), Vector2(rect_size.x, rect_size.y - radius * 2.0)), color)
	for corner: Vector2 in [
		rect_origin + Vector2(radius, radius),
		rect_origin + Vector2(rect_size.x - radius, radius),
		rect_origin + rect_size - Vector2(radius, radius),
		rect_origin + Vector2(radius, rect_size.y - radius)
	]:
		draw_circle(corner, radius, color)

func _make_style_box(fill: Color, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	return style

func _on_restart_pressed() -> void:
	restart_requested.emit()

func _on_menu_pressed() -> void:
	menu_requested.emit()
