# scripts/Main.gd
extends Control

# GEÇİCİ, Faz 4'te silinecek (dark.svg örnek dizilimi)
const DEMO_CELLS: Dictionary = {
	4: [Vector2i(2, 3), Vector2i(3, 3), Vector2i(2, 4), Vector2i(3, 4)],
	3: [Vector2i(5, 4), Vector2i(5, 5), Vector2i(6, 5)],
	1: [Vector2i(0, 5), Vector2i(0, 6), Vector2i(1, 6), Vector2i(0, 7), Vector2i(1, 7)],
	2: [Vector2i(3, 6), Vector2i(2, 7), Vector2i(3, 7)],
	5: [Vector2i(5, 6), Vector2i(6, 6), Vector2i(5, 7), Vector2i(6, 7), Vector2i(7, 7)],
}

@onready var background: ColorRect = $Background
@onready var board_view: BoardView = $BoardView
@onready var tray: Tray = $Tray

var board_model: BoardModel

func _ready() -> void:
	background.color = Config.BG
	board_model = BoardModel.new()
	board_view.set_model(board_model)
	_fill_demo()
	board_view.refresh()
	_fill_tray_demo()

func _fill_tray_demo() -> void:
	# GEÇİCİ, Faz 4'te güncellenecek.
	var pieces_by_id: Dictionary = {}
	for piece: Dictionary in Pieces.all():
		pieces_by_id[piece["id"]] = piece
	var demo_pieces: Array[Dictionary] = []
	for piece_id: String in ["v2", "l", "sq2"]:
		if pieces_by_id.has(piece_id):
			demo_pieces.append(pieces_by_id[piece_id])
	tray.set_pieces(demo_pieces)

func _fill_demo() -> void:
	var single_cell: Array[Vector2i] = [Vector2i.ZERO]
	for color_id: int in DEMO_CELLS:
		for cell: Vector2i in DEMO_CELLS[color_id]:
			board_model.place(single_cell, cell, color_id)
