# scripts/Main.gd
extends Control

@onready var background: ColorRect = $Background
@onready var board_view: BoardView = $BoardView
@onready var tray: Tray = $Tray
@onready var drag_layer: DragLayer = $DragLayer
@onready var hud: Control = $Hud
@onready var game: Game = $Game
@onready var game_over: Control = $GameOver

func _ready() -> void:
	background.color = Config.BG
	game.configure(board_view, tray, drag_layer, hud, game_over)
	game.start_game()
