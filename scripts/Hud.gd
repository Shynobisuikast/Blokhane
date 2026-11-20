# scripts/Hud.gd
class_name Hud
extends Control

signal pause_requested

var _pause_style: StyleBoxFlat
var _pause_bar_style: StyleBoxFlat
var _pause_pressed_style: StyleBoxFlat
var _pause_hit_target: Button
var _pause_background: Panel
var _pause_pressed_overlay: Panel
var _pause_bars: Array[Panel] = []
var _score: int = 0
var _best: int = 0
var _score_scale: float = 1.0
var _score_tween: Tween
var _combo_visible: bool = false
var _combo_scale: float = 1.0
var _combo_multiplier: float = 1.0
var _combo_gain: int = 0
var _combo_tween: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_theme()
	_build_pause_hit_target()
	ThemeAccess.connect_changed(_on_theme_changed)

func _on_theme_changed() -> void:
	_apply_theme()
	queue_redraw()

func _apply_theme() -> void:
	_pause_style = _make_style_box(ThemeAccess.color("PANEL"), Config.HUD_PAUSE_RADIUS)
	_pause_bar_style = _make_style_box(ThemeAccess.color("TEXT"), Config.HUD_PAUSE_BAR_RADIUS)
	_pause_pressed_style = _make_style_box(
		Color(1.0, 1.0, 1.0, Config.HUD_PAUSE_PRESSED_ALPHA),
		Config.HUD_PAUSE_RADIUS
	)
	if _pause_background != null:
		_pause_background.add_theme_stylebox_override("panel", _pause_style)
	if _pause_pressed_overlay != null:
		_pause_pressed_overlay.add_theme_stylebox_override("panel", _pause_pressed_style)
	for pause_bar: Panel in _pause_bars:
		pause_bar.add_theme_stylebox_override("panel", _pause_bar_style)


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

func _build_pause_hit_target() -> void:
	_pause_hit_target = Button.new()
	_pause_hit_target.size = Config.HUD_PAUSE_HIT_TARGET_SIZE
	_pause_hit_target.position = (
		Config.HUD_PAUSE_POSITION
		+ (Config.HUD_PAUSE_SIZE - Config.HUD_PAUSE_HIT_TARGET_SIZE) / 2.0
	)
	_pause_hit_target.focus_mode = Control.FOCUS_NONE
	_pause_hit_target.mouse_filter = Control.MOUSE_FILTER_STOP
	var empty_style: StyleBoxEmpty = StyleBoxEmpty.new()
	_pause_hit_target.add_theme_stylebox_override("normal", empty_style)
	_pause_hit_target.add_theme_stylebox_override("hover", empty_style)
	_pause_hit_target.add_theme_stylebox_override("pressed", empty_style)
	_pause_hit_target.add_theme_stylebox_override("focus", empty_style)
	_pause_hit_target.pressed.connect(_on_pause_pressed)
	_pause_hit_target.button_down.connect(_set_pause_pressed.bind(true))
	_pause_hit_target.button_up.connect(_set_pause_pressed.bind(false))
	_pause_hit_target.mouse_exited.connect(_set_pause_pressed.bind(false))
	add_child(_pause_hit_target)
	var visual_origin: Vector2 = (
		Config.HUD_PAUSE_HIT_TARGET_SIZE - Config.HUD_PAUSE_SIZE
	) / 2.0
	_pause_background = _make_pause_panel(
		visual_origin,
		Config.HUD_PAUSE_SIZE,
		_pause_style
	)
	_pause_bars.append(_make_pause_panel(
		visual_origin + Config.HUD_PAUSE_BAR_OFFSET_A,
		Config.HUD_PAUSE_BAR_SIZE,
		_pause_bar_style
	))
	_pause_bars.append(_make_pause_panel(
		visual_origin + Config.HUD_PAUSE_BAR_OFFSET_B,
		Config.HUD_PAUSE_BAR_SIZE,
		_pause_bar_style
	))
	_pause_pressed_overlay = _make_pause_panel(
		visual_origin,
		Config.HUD_PAUSE_SIZE,
		_pause_pressed_style
	)
	_pause_pressed_overlay.visible = false
	ButtonFeedback.apply(_pause_hit_target)

func _make_pause_panel(position: Vector2, panel_size: Vector2, style: StyleBoxFlat) -> Panel:
	var panel: Panel = Panel.new()
	panel.position = position
	panel.size = panel_size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", style)
	_pause_hit_target.add_child(panel)
	return panel

func _set_pause_pressed(pressed: bool) -> void:
	if _pause_pressed_overlay != null:
		_pause_pressed_overlay.visible = pressed

func _draw() -> void:
	draw_string(
		ThemeDB.fallback_font,
		Vector2(Config.HUD_SCORE_AREA_X, Config.HUD_SCORE_LABEL_BASELINE),
		"Skor",
		HORIZONTAL_ALIGNMENT_CENTER,
		Config.HUD_SCORE_AREA_WIDTH,
		Config.HUD_SCORE_LABEL_FONT_SIZE,
		ThemeAccess.color("TEXT_SECONDARY")
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
		ThemeAccess.color("TEXT")
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(Config.HUD_BEST_AREA_X, Config.HUD_BEST_LABEL_BASELINE),
		"En yüksek",
		HORIZONTAL_ALIGNMENT_RIGHT,
		Config.HUD_BEST_AREA_WIDTH,
		Config.HUD_SCORE_LABEL_FONT_SIZE,
		ThemeAccess.color("TEXT_SECONDARY")
	)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(Config.HUD_BEST_AREA_X, Config.HUD_BEST_VALUE_BASELINE),
		str(_best),
		HORIZONTAL_ALIGNMENT_RIGHT,
		Config.HUD_BEST_AREA_WIDTH,
		Config.HUD_BEST_FONT_SIZE,
		ThemeAccess.color("ACCENT")
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
		ThemeAccess.color("ACCENT")
	)
	draw_circle(Vector2(-size.x / 2.0 + radius, 0.0), radius, ThemeAccess.color("ACCENT"))
	draw_circle(Vector2(size.x / 2.0 - radius, 0.0), radius, ThemeAccess.color("ACCENT"))
	draw_string(
		ThemeDB.fallback_font,
		Vector2(-size.x / 2.0, Config.COMBO_TEXT_BASELINE_OFFSET),
		_combo_text(),
		HORIZONTAL_ALIGNMENT_CENTER,
		size.x,
		Config.COMBO_FONT_SIZE,
		ThemeAccess.color("ON_ACCENT")
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

func _on_pause_pressed() -> void:
	pause_requested.emit()

func _make_style_box(color: Color, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style
