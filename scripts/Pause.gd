# scripts/Pause.gd
class_name Pause
extends Control

signal resume_requested
signal menu_requested

var _resume_button: Button
var _menu_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_buttons()
	ThemeAccess.connect_changed(_on_theme_changed)
	_apply_theme()

func _on_theme_changed() -> void:
	_apply_theme()
	queue_redraw()

func _apply_theme() -> void:
	_set_button_theme(_resume_button, ThemeAccess.color("ACCENT"), ThemeAccess.color("ON_ACCENT"), Config.PAUSE_RESUME_RADIUS)
	_set_button_theme(_menu_button, ThemeAccess.color("PANEL"), ThemeAccess.color("TEXT"), Config.PAUSE_MENU_RADIUS)

func _draw() -> void:
	var overlay_color: Color = ThemeAccess.color("BG")
	overlay_color.a = Config.PAUSE_OVERLAY_ALPHA
	draw_rect(Rect2(Vector2.ZERO, Config.SCREEN_SIZE), overlay_color)
	draw_string(
		ThemeDB.fallback_font,
		Config.PAUSE_TITLE_POSITION,
		"Duraklatıldı",
		HORIZONTAL_ALIGNMENT_CENTER,
		Config.PAUSE_TITLE_SIZE.x,
		Config.PAUSE_TITLE_FONT_SIZE,
		ThemeAccess.color("TEXT")
	)

func _build_buttons() -> void:
	_resume_button = _make_button(
		"Devam et",
		Config.PAUSE_RESUME_POSITION,
		Config.PAUSE_RESUME_SIZE,
		ThemeAccess.color("ACCENT"),
		ThemeAccess.color("ON_ACCENT"),
		Config.PAUSE_RESUME_RADIUS,
		Config.PAUSE_RESUME_FONT_SIZE
	)
	_resume_button.pressed.connect(_on_resume_pressed)
	_menu_button = _make_button(
		"Ana menü",
		Config.PAUSE_MENU_POSITION,
		Config.PAUSE_MENU_SIZE,
		ThemeAccess.color("PANEL"),
		ThemeAccess.color("TEXT"),
		Config.PAUSE_MENU_RADIUS,
		Config.PAUSE_MENU_FONT_SIZE
	)
	_menu_button.pressed.connect(_on_menu_pressed)

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
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)
	add_child(button)
	ButtonFeedback.apply(button)
	return button

func _set_button_theme(button: Button, fill: Color, text_color: Color, radius: int) -> void:
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)

func _on_resume_pressed() -> void:
	resume_requested.emit()

func _on_menu_pressed() -> void:
	menu_requested.emit()
