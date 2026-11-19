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

func _ready() -> void:
	background.color = ThemeAccess.color("BG")
	ThemeAccess.connect_changed(_on_theme_changed)
	game.process_mode = Node.PROCESS_MODE_PAUSABLE
	game.configure(board_view, tray, drag_layer, hud, game_over)
	game_over.restart_requested.connect(_on_restart_requested)
	game_over.menu_requested.connect(_on_menu_requested)
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

func _on_game_over(_final_score: int, _is_new_best: bool) -> void:
	if _flow.go(ScreenFlow.Screen.GAME_OVER):
		_show_screen(ScreenFlow.Screen.GAME_OVER)

func _show_screen(screen: ScreenFlow.Screen) -> void:
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
	game_over.visible = screen == ScreenFlow.Screen.GAME_OVER
	pause_screen.visible = screen == ScreenFlow.Screen.PAUSED
	menu.visible = screen == ScreenFlow.Screen.MENU
	settings.visible = screen == ScreenFlow.Screen.SETTINGS
	if screen == ScreenFlow.Screen.MENU:
		menu.refresh_best()
