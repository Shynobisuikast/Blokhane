# scripts/Settings.gd
class_name Settings
extends Control

signal menu_requested

const SaveDataScript = preload("res://scripts/SaveData.gd")

# Onay ve tamamlanma mesajı süreleri Config'te tutulur.
enum ResetPhase { IDLE, CONFIRM, DONE }

var _dark_button: Button
var _light_button: Button
var _reset_button: Button
var _back_button: Button
var _reset_timer: Timer
var _reset_phase: ResetPhase = ResetPhase.IDLE

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_reset_timer = Timer.new()
	_reset_timer.one_shot = true
	_reset_timer.timeout.connect(_on_reset_timer_timeout)
	add_child(_reset_timer)
	_build_buttons()
	ThemeAccess.connect_changed(_on_theme_changed)
	_apply_theme()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Config.SCREEN_SIZE), ThemeAccess.color("BG"))
	draw_string(
		ThemeDB.fallback_font,
		Config.SETTINGS_TITLE_POSITION,
		"Ayarlar",
		HORIZONTAL_ALIGNMENT_CENTER,
		Config.SETTINGS_TITLE_SIZE.x,
		Config.SETTINGS_TITLE_FONT_SIZE,
		ThemeAccess.color("TEXT")
	)
	draw_string(
		ThemeDB.fallback_font,
		Config.SETTINGS_THEME_LABEL_POSITION,
		"Tema",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		Config.SETTINGS_THEME_LABEL_FONT_SIZE,
		ThemeAccess.color("TEXT_SECONDARY")
	)

func _build_buttons() -> void:
	_dark_button = _make_button(
		"Koyu",
		Config.SETTINGS_DARK_POSITION,
		Config.SETTINGS_THEME_OPTION_SIZE,
		Config.SETTINGS_THEME_OPTION_FONT_SIZE
	)
	_dark_button.pressed.connect(_on_dark_pressed)
	_light_button = _make_button(
		"Açık",
		Config.SETTINGS_LIGHT_POSITION,
		Config.SETTINGS_THEME_OPTION_SIZE,
		Config.SETTINGS_THEME_OPTION_FONT_SIZE
	)
	_light_button.pressed.connect(_on_light_pressed)
	_reset_button = _make_button(
		"Verileri sıfırla",
		Config.SETTINGS_RESET_POSITION,
		Config.SETTINGS_RESET_SIZE,
		Config.SETTINGS_RESET_FONT_SIZE
	)
	_reset_button.pressed.connect(_on_reset_pressed)
	_back_button = _make_button(
		"Geri",
		Config.SETTINGS_BACK_POSITION,
		Config.SETTINGS_BACK_SIZE,
		Config.SETTINGS_BACK_FONT_SIZE
	)
	_back_button.pressed.connect(_on_back_pressed)

func _make_button(
	label: String,
	button_position: Vector2,
	button_size: Vector2,
	font_size: int
) -> Button:
	var button: Button = Button.new()
	button.text = label
	button.position = button_position
	button.size = button_size
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_font_size_override("font_size", font_size)
	add_child(button)
	ButtonFeedback.apply(button)
	return button

func _on_theme_changed() -> void:
	_apply_theme()
	queue_redraw()

func _apply_theme() -> void:
	var selected_id: ThemePalettes.ThemeId = ThemeAccess.current()
	_set_button_theme(
		_dark_button,
		selected_id == ThemePalettes.ThemeId.DARK,
		Config.SETTINGS_THEME_OPTION_RADIUS
	)
	_set_button_theme(
		_light_button,
		selected_id == ThemePalettes.ThemeId.LIGHT,
		Config.SETTINGS_THEME_OPTION_RADIUS
	)
	_set_button_theme(_reset_button, false, Config.SETTINGS_RESET_RADIUS)
	_set_button_theme(_back_button, false, Config.SETTINGS_BACK_RADIUS)

func _set_button_theme(button: Button, selected: bool, radius: int) -> void:
	var fill: Color = ThemeAccess.color("PANEL")
	var text_color: Color = ThemeAccess.color("TEXT")
	if selected:
		fill = ThemeAccess.color("ACCENT")
		text_color = ThemeAccess.color("ON_ACCENT")
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)

func _on_dark_pressed() -> void:
	ThemeAccess.set_theme(ThemePalettes.ThemeId.DARK)

func _on_light_pressed() -> void:
	ThemeAccess.set_theme(ThemePalettes.ThemeId.LIGHT)

func _on_reset_pressed() -> void:
	match _reset_phase:
		ResetPhase.IDLE:
			_reset_phase = ResetPhase.CONFIRM
			_reset_button.text = "Emin misin?"
			_reset_timer.start(Config.SETTINGS_RESET_CONFIRM_SECONDS)
		ResetPhase.CONFIRM:
			_reset_timer.stop()
			SaveDataScript.save_best(0)
			_reset_phase = ResetPhase.DONE
			_reset_button.text = "Sıfırlandı"
			_reset_timer.start(Config.SETTINGS_RESET_DONE_SECONDS)

func _on_reset_timer_timeout() -> void:
	_reset_phase = ResetPhase.IDLE
	_reset_button.text = "Verileri sıfırla"

func cancel_pending_confirmation() -> void:
	if _reset_timer != null:
		_reset_timer.stop()
	_reset_phase = ResetPhase.IDLE
	if _reset_button != null:
		_reset_button.text = "Verileri sıfırla"

func _on_back_pressed() -> void:
	cancel_pending_confirmation()
	menu_requested.emit()
