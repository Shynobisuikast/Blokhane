# scripts/Main.gd
extends Control

const ScreenFlowScript = preload("res://scripts/ScreenFlow.gd")

@onready var background: ColorRect = $Background
@onready var board_view: BoardView = $BoardView
@onready var tray: Tray = $Tray
@onready var drag_layer: DragLayer = $DragLayer
@onready var hud: Hud = $Hud
@onready var game: Game = $Game
@onready var game_over: GameOver = $GameOver
@onready var pause_screen: Pause = $Pause
@onready var menu: Menu = $Menu
@onready var settings: Settings = $Settings

var _flow: ScreenFlow = ScreenFlowScript.new()
var _screen_fade_tween: Tween

func _ready() -> void:
	background.color = ThemeAccess.color("BG")
	ThemeAccess.connect_changed(_on_theme_changed)
	game.process_mode = Node.PROCESS_MODE_PAUSABLE
	game.configure(board_view, tray, drag_layer, hud, game_over)
	game_over.restart_requested.connect(_on_restart_requested)
	game_over.menu_requested.connect(_on_menu_requested)
	game.piece_placed.connect(_on_piece_placed)
	game.lines_cleared.connect(_on_lines_cleared)
	game.triplet_refilled.connect(_on_triplet_refilled)
	game.game_over.connect(_on_game_over)
	hud.pause_requested.connect(_on_pause_requested)
	pause_screen.resume_requested.connect(_on_resume_requested)
	pause_screen.menu_requested.connect(_on_menu_requested)
	menu.play_requested.connect(_on_play_requested)
	menu.settings_requested.connect(_on_settings_requested)
	settings.menu_requested.connect(_on_settings_menu_requested)
	game.start_game()
	_show_screen(ScreenFlow.Screen.MENU)

func _on_play_requested() -> void:
	if not _flow.go(ScreenFlow.Screen.PLAYING):
		return
	game.restart()
	_show_screen(ScreenFlow.Screen.PLAYING)

func _on_settings_requested() -> void:
	if _flow.go(ScreenFlow.Screen.SETTINGS):
		_show_screen(ScreenFlow.Screen.SETTINGS)

func _on_settings_menu_requested() -> void:
	if _flow.go(ScreenFlow.Screen.MENU):
		_show_screen(ScreenFlow.Screen.MENU)

func _on_theme_changed() -> void:
	background.color = ThemeAccess.color("BG")
	background.queue_redraw()

func _on_pause_requested() -> void:
	if not _flow.can_go(ScreenFlow.Screen.PAUSED):
		return
	game.cancel_drag()
	if _flow.go(ScreenFlow.Screen.PAUSED):
		_show_screen(ScreenFlow.Screen.PAUSED)
		get_tree().paused = true

func _on_resume_requested() -> void:
	if _flow.current != ScreenFlow.Screen.PAUSED:
		return
	get_tree().paused = false
	if _flow.go(ScreenFlow.Screen.PLAYING):
		_show_screen(ScreenFlow.Screen.PLAYING)

func _on_menu_requested() -> void:
	if _flow.current == ScreenFlow.Screen.PAUSED:
		get_tree().paused = false
	if not _flow.go(ScreenFlow.Screen.MENU):
		return
	_show_screen(ScreenFlow.Screen.MENU)

func _on_restart_requested() -> void:
	if not _flow.go(ScreenFlow.Screen.PLAYING):
		return
	game.restart()
	_show_screen(ScreenFlow.Screen.PLAYING)

func _on_piece_placed(_cells: int) -> void:
	Audio.play_sfx(Config.SoundId.PLACE)

func _on_lines_cleared(count: int, _gain: int, _multiplier: float) -> void:
	Audio.play_clear(count, game.combo_streak())

func _on_triplet_refilled() -> void:
	Audio.play_sfx(Config.SoundId.TRAY_REFILL)

func _on_game_over(_final_score: int, is_new_best: bool) -> void:
	Audio.play_game_over(is_new_best)
	if _flow.go(ScreenFlow.Screen.GAME_OVER):
		_show_screen(ScreenFlow.Screen.GAME_OVER)

func _show_screen(screen: ScreenFlow.Screen) -> void:
	Audio.set_menu_context(
		screen == ScreenFlow.Screen.MENU or screen == ScreenFlow.Screen.SETTINGS
	)
	Audio.set_paused(screen == ScreenFlow.Screen.PAUSED)
	Audio.set_game_over(screen == ScreenFlow.Screen.GAME_OVER)
	if screen != ScreenFlow.Screen.SETTINGS:
		settings.cancel_pending_confirmation()
	var gameplay_visible: bool = (
		screen == ScreenFlow.Screen.PLAYING
		or screen == ScreenFlow.Screen.PAUSED
		or screen == ScreenFlow.Screen.GAME_OVER
	)
	board_view.visible = gameplay_visible
	tray.visible = gameplay_visible
	game.visible = gameplay_visible
	hud.visible = gameplay_visible
	drag_layer.visible = gameplay_visible
	_stop_screen_fade()
	var overlay_screens: Array[Control] = [game_over, pause_screen, menu, settings]
	for overlay_screen: Control in overlay_screens:
		overlay_screen.visible = false
		overlay_screen.modulate.a = 1.0

	var opening_screen: Control
	match screen:
		ScreenFlow.Screen.GAME_OVER:
			opening_screen = game_over
		ScreenFlow.Screen.PAUSED:
			opening_screen = pause_screen
		ScreenFlow.Screen.MENU:
			opening_screen = menu
		ScreenFlow.Screen.SETTINGS:
			opening_screen = settings
	if opening_screen != null:
		opening_screen.visible = true
		_fade_in_screen(opening_screen)
	if screen == ScreenFlow.Screen.MENU:
		menu.refresh_best()

func _fade_in_screen(screen: Control) -> void:
	screen.modulate.a = 0.0
	_screen_fade_tween = create_tween()
	_screen_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_screen_fade_tween.tween_property(
		screen,
		"modulate:a",
		1.0,
		Config.SCREEN_FADE_TIME
	)

func _stop_screen_fade() -> void:
	if _screen_fade_tween != null and _screen_fade_tween.is_running():
		_screen_fade_tween.kill()
	_screen_fade_tween = null
