# scripts/Hud.gd
class_name Hud
extends Control

var _pause_style: StyleBoxFlat
var _pause_bar_style: StyleBoxFlat
var _score: int = 0
var _best: int = 0
var _score_scale: float = 1.0
var _score_tween: Tween
var _combo_visible: bool = false
var _combo_scale: float = 1.0
var _combo_multiplier: float = 1.0
var _combo_gain: int = 0
var _combo_tween: Tween

func _init() -> void:
	_pause_style = _make_style_box(Config.PANEL, Config.HUD_PAUSE_RADIUS)
	_pause_bar_style = _make_style_box(Config.TEXT, Config.HUD_PAUSE_BAR_RADIUS)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func reset_score(score: int, best: int, streak: int) -> void:
	if _score_tween != null and _score_tween.is_running():
		_score_tween.kill()
	if _combo_tween != null and _combo_tween.is_running():
		_combo_tween.kill()
	_score = score
	_best = best
	_score_scale = 1.0
	_combo_visible = false
	_combo_scale = 1.0
	_combo_multiplier = 1.0
	_combo_gain = 0
	queue_redraw()

func update_score(score: int, best: int, streak: int, multiplier: float, gain: int) -> void:
	_score = score
	_best = best
	_combo_multiplier = multiplier
	_combo_gain = gain
	_combo_visible = multiplier > 1.0 and streak > 0
	if not _combo_visible:
		_combo_scale = 1.0
	queue_redraw()
	if gain > 0:
		_play_score_pop()
	if _combo_visible:
		_play_combo_pop()

func _draw() -> void:
	draw_style_box(_pause_style, Rect2(Config.HUD_PAUSE_POSITION, Config.HUD_PAUSE_SIZE))
	draw_style_box(
		_pause_bar_style,
		Rect2(Config.HUD_PAUSE_POSITION + Config.HUD_PAUSE_BAR_OFFSET_A, Config.HUD_PAUSE_BAR_SIZE)
	)
	draw_style_box(
		_pause_bar_style,
		Rect2(Config.HUD_PAUSE_POSITION + Config.HUD_PAUSE_BAR_OFFSET_B, Config.HUD_PAUSE_BAR_SIZE)
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(Config.HUD_SCORE_AREA_X, Config.HUD_SCORE_LABEL_BASELINE),
		"Skor",
		HORIZONTAL_ALIGNMENT_CENTER,
		Config.HUD_SCORE_AREA_WIDTH,
		Config.HUD_SCORE_LABEL_FONT_SIZE,
		Config.TEXT_SECONDARY
	)
	draw_set_transform(
		Vector2(Config.HUD_SCORE_CENTER_X, Config.HUD_SCORE_VALUE_BASELINE),
		0.0,
		Vector2.ONE * _score_scale
	)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(-Config.HUD_SCORE_AREA_WIDTH / 2.0, 0.0),
		str(_score),
		HORIZONTAL_ALIGNMENT_CENTER,
		Config.HUD_SCORE_AREA_WIDTH,
		Config.HUD_SCORE_FONT_SIZE,
		Config.TEXT
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(Config.HUD_BEST_AREA_X, Config.HUD_BEST_LABEL_BASELINE),
		"En yüksek",
		HORIZONTAL_ALIGNMENT_RIGHT,
		Config.HUD_BEST_AREA_WIDTH,
		Config.HUD_SCORE_LABEL_FONT_SIZE,
		Config.TEXT_SECONDARY
	)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(Config.HUD_BEST_AREA_X, Config.HUD_BEST_VALUE_BASELINE),
		str(_best),
		HORIZONTAL_ALIGNMENT_RIGHT,
		Config.HUD_BEST_AREA_WIDTH,
		Config.HUD_BEST_FONT_SIZE,
		Config.YELLOW
	)

	if _combo_visible:
		_draw_combo_pill()

func _draw_combo_pill() -> void:
	var size: Vector2 = Config.COMBO_PILL_SIZE
	var radius: float = Config.COMBO_PILL_RADIUS
	var center: Vector2 = Config.COMBO_PILL_POSITION + size / 2.0
	draw_set_transform(center, 0.0, Vector2.ONE * _combo_scale)
	draw_rect(
		Rect2(Vector2(-size.x / 2.0 + radius, -size.y / 2.0), Vector2(size.x - radius * 2.0, size.y)),
		Config.COMBO_PILL_COLOR
	)
	draw_circle(Vector2(-size.x / 2.0 + radius, 0.0), radius, Config.COMBO_PILL_COLOR)
	draw_circle(Vector2(size.x / 2.0 - radius, 0.0), radius, Config.COMBO_PILL_COLOR)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(-size.x / 2.0, Config.COMBO_TEXT_BASELINE_OFFSET),
		_combo_text(),
		HORIZONTAL_ALIGNMENT_CENTER,
		size.x,
		Config.COMBO_FONT_SIZE,
		Config.COMBO_TEXT_COLOR
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _combo_text() -> String:
	var multiplier_text: String = str(roundi(_combo_multiplier))
	if not is_equal_approx(_combo_multiplier, roundf(_combo_multiplier)):
		multiplier_text = str(_combo_multiplier)
	return "Kombo ×%s  +%d" % [multiplier_text, _combo_gain]

func _play_score_pop() -> void:
	if _score_tween != null and _score_tween.is_running():
		_score_tween.kill()
	_score_scale = 1.0
	_score_tween = create_tween()
	var half_duration: float = Config.SCORE_POP_TIME / 2.0
	_score_tween.tween_method(_set_score_scale, 1.0, Config.SCORE_POP_SCALE, half_duration)
	_score_tween.tween_method(_set_score_scale, Config.SCORE_POP_SCALE, 1.0, half_duration)

func _set_score_scale(scale: float) -> void:
	_score_scale = scale
	queue_redraw()

func _play_combo_pop() -> void:
	if _combo_tween != null and _combo_tween.is_running():
		_combo_tween.kill()
	_combo_scale = Config.COMBO_POP_START_SCALE
	_combo_tween = create_tween()
	_combo_tween.tween_method(
		_set_combo_scale,
		Config.COMBO_POP_START_SCALE,
		1.0,
		Config.COMBO_POP_TIME
	)

func _set_combo_scale(scale: float) -> void:
	_combo_scale = scale
	queue_redraw()

func _make_style_box(color: Color, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style
