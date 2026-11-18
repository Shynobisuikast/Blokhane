# scripts/GameOver.gd
class_name GameOver
extends Control

signal restart_requested

var _final_score: int = 0
var _lines_cleared_total: int = 0
var _max_streak: int = 0
var _is_new_best: bool = false
var _restart_button: Button
var _menu_button: Button

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_buttons()

func show_result(final_score: int, lines_cleared_total: int, max_streak: int, is_new_best: bool) -> void:
	_final_score = final_score
	_lines_cleared_total = lines_cleared_total
	_max_streak = max_streak
	_is_new_best = is_new_best
	visible = true
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Config.SCREEN_SIZE), Config.BG)
	_draw_rounded_rect(
		Config.GAME_OVER_CARD_POSITION,
		Config.GAME_OVER_CARD_SIZE,
		Config.GAME_OVER_CARD_RADIUS,
		Config.PANEL
	)
	_draw_rounded_rect(
		Config.GAME_OVER_STATS_LEFT_POSITION,
		Config.GAME_OVER_STATS_CARD_SIZE,
		Config.GAME_OVER_STATS_CARD_RADIUS,
		Config.PANEL
	)
	_draw_rounded_rect(
		Config.GAME_OVER_STATS_RIGHT_POSITION,
		Config.GAME_OVER_STATS_CARD_SIZE,
		Config.GAME_OVER_STATS_CARD_RADIUS,
		Config.PANEL
	)
	if _is_new_best:
		_draw_rounded_rect(
			Config.GAME_OVER_RECORD_POSITION,
			Config.GAME_OVER_RECORD_SIZE,
			Config.GAME_OVER_RECORD_RADIUS,
			Config.YELLOW
		)

	draw_string(
		ThemeDB.fallback_font,
		Config.GAME_OVER_TITLE_POSITION,
		"Oyun bitti",
		HORIZONTAL_ALIGNMENT_CENTER,
		Config.GAME_OVER_TITLE_SIZE.x,
		Config.GAME_OVER_TITLE_FONT_SIZE,
		Config.TEXT
	)
	draw_string(
		ThemeDB.fallback_font,
		Config.GAME_OVER_SCORE_LABEL_POSITION,
		"Skor",
		HORIZONTAL_ALIGNMENT_CENTER,
		Config.GAME_OVER_SCORE_LABEL_SIZE.x,
		Config.GAME_OVER_LABEL_FONT_SIZE,
		Config.TEXT_SECONDARY
	)
	draw_string(
		ThemeDB.fallback_font,
		Config.GAME_OVER_SCORE_VALUE_POSITION,
		str(_final_score),
		HORIZONTAL_ALIGNMENT_CENTER,
		Config.GAME_OVER_SCORE_VALUE_SIZE.x,
		Config.GAME_OVER_SCORE_FONT_SIZE,
		Config.TEXT
	)
	if _is_new_best:
		draw_string(
			ThemeDB.fallback_font,
			Vector2(Config.GAME_OVER_RECORD_POSITION.x, Config.GAME_OVER_RECORD_TEXT_BASELINE),
			"Yeni rekor",
			HORIZONTAL_ALIGNMENT_CENTER,
			Config.GAME_OVER_RECORD_SIZE.x,
			Config.GAME_OVER_RECORD_FONT_SIZE,
			Config.BG
		)
	draw_string(
		ThemeDB.fallback_font,
		Config.GAME_OVER_STATS_LABEL_LEFT_BASELINE,
		"Temizlenen satır",
		HORIZONTAL_ALIGNMENT_LEFT,
		Config.GAME_OVER_STATS_TEXT_WIDTH,
		Config.GAME_OVER_LABEL_FONT_SIZE,
		Config.TEXT_SECONDARY
	)
	draw_string(
		ThemeDB.fallback_font,
		Config.GAME_OVER_STATS_VALUE_LEFT_BASELINE,
		str(_lines_cleared_total),
		HORIZONTAL_ALIGNMENT_LEFT,
		Config.GAME_OVER_STATS_TEXT_WIDTH,
		Config.GAME_OVER_STATS_VALUE_FONT_SIZE,
		Config.TEXT
	)
	draw_string(
		ThemeDB.fallback_font,
		Config.GAME_OVER_STATS_LABEL_RIGHT_BASELINE,
		"Maks kombo",
		HORIZONTAL_ALIGNMENT_LEFT,
		Config.GAME_OVER_STATS_TEXT_WIDTH,
		Config.GAME_OVER_LABEL_FONT_SIZE,
		Config.TEXT_SECONDARY
	)
	draw_string(
		ThemeDB.fallback_font,
		Config.GAME_OVER_STATS_VALUE_RIGHT_BASELINE,
		str(_max_streak),
		HORIZONTAL_ALIGNMENT_LEFT,
		Config.GAME_OVER_STATS_TEXT_WIDTH,
		Config.GAME_OVER_STATS_VALUE_FONT_SIZE,
		Config.TEXT
	)

func _build_buttons() -> void:
	_restart_button = _make_button(
		"Tekrar oyna",
		Config.GAME_OVER_RESTART_POSITION,
		Config.GAME_OVER_RESTART_SIZE,
		Config.YELLOW,
		Config.BG,
		Config.GAME_OVER_RESTART_RADIUS,
		Config.GAME_OVER_RESTART_FONT_SIZE
	)
	_restart_button.pressed.connect(_on_restart_pressed)
	_menu_button = _make_button(
		"Ana menü",
		Config.GAME_OVER_MENU_POSITION,
		Config.GAME_OVER_MENU_SIZE,
		Config.PANEL,
		Config.TEXT,
		Config.GAME_OVER_MENU_RADIUS,
		Config.GAME_OVER_MENU_FONT_SIZE
	)
	# Ana menü düğmesi Faz 8'e kadar işlevsizdir.

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
	button.add_theme_stylebox_override("normal", _make_style_box(fill, radius))
	button.add_theme_stylebox_override("hover", _make_style_box(fill, radius))
	button.add_theme_stylebox_override("pressed", _make_style_box(fill, radius))
	button.add_theme_stylebox_override("focus", _make_style_box(fill, radius))
	add_child(button)
	return button

func _draw_rounded_rect(position: Vector2, rect_size: Vector2, radius: float, color: Color) -> void:
	draw_rect(Rect2(position + Vector2(radius, 0.0), Vector2(rect_size.x - radius * 2.0, rect_size.y)), color)
	draw_rect(Rect2(position + Vector2(0.0, radius), Vector2(rect_size.x, rect_size.y - radius * 2.0)), color)
	for corner: Vector2 in [
		position + Vector2(radius, radius),
		position + Vector2(rect_size.x - radius, radius),
		position + rect_size - Vector2(radius, radius),
		position + Vector2(radius, rect_size.y - radius)
	]:
		draw_circle(corner, radius, color)

func _make_style_box(fill: Color, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	return style

func _on_restart_pressed() -> void:
	restart_requested.emit()
