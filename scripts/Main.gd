# scripts/Main.gd
extends Control

@onready var background: ColorRect = $Background
@onready var board_view: BoardView = $BoardView
@onready var tray: Tray = $Tray
@onready var drag_layer: DragLayer = $DragLayer
@onready var game: Game = $Game

func _ready() -> void:
	background.color = Config.BG
	game.configure(board_view, tray, drag_layer)
	game.start_game()
