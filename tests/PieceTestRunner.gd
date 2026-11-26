# tests/PieceTestRunner.gd
extends RefCounted

const PiecesScript = preload("res://scripts/Pieces.gd")
const PieceGeneratorScript = preload("res://scripts/PieceGenerator.gd")
const TrayScript = preload("res://scripts/Tray.gd")

static func run(test_runner: Variant) -> void:
	var board: Variant = test_runner._board
	var single_cell: Array[Vector2i] = [Vector2i.ZERO]
	var catalog: Array[Dictionary] = PiecesScript.all()
	test_runner.check("18 parça kataloğu", catalog.size() >= 15 and catalog.size() <= 20)
	var catalog_state: Dictionary = _catalog_state(board, catalog)
	test_runner.check("Şekillerin en küçük x ve y koordinatları sıfır", catalog_state["normalized"])
	test_runner.check("Şekillerde yinelenen hücre yok", catalog_state["unique_cells"])
	test_runner.check("Her şekil dört yönlü bağlantılı", catalog_state["connected"])
	test_runner.check("Parça id'leri benzersiz", catalog_state["unique_ids"])
	test_runner.check("Parça renk kimlikleri 1-5 aralığında", catalog_state["valid_colors"])
	test_runner.check("Her şekil boş tahtaya sığar", catalog_state["fits"])

	var generator: Variant = PieceGeneratorScript.new()
	_fill_board_except(board, single_cell, [Vector2i.ZERO])
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 3027
	test_runner.check("Tek boş hücrede 200 üretim adil", _fairness_holds(board, generator, rng))
	_fill_board_except(board, single_cell, [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.ONE])
	rng.seed = 3028
	test_runner.check("2x2 boşlukta 200 üretim adil", _fairness_holds(board, generator, rng))
	test_runner.check(
		"Üretici her zaman üç parça döndürür",
		generator.generate_triplet(board, rng).size() == Config.TRAY_SLOTS
	)

	var tray: Variant = TrayScript.new()
	tray.set_pieces([_find_piece(catalog, "v2"), _find_piece(catalog, "l"), _find_piece(catalog, "sq2")])
	test_runner.check(
		"Tepsi parçaları tasarım konumlarında ortalanır",
		tray.piece_cell_origin(0) == Vector2(75, 718)
		and tray.piece_cell_origin(1) == Vector2(208.5, 701.5)
		and tray.piece_cell_origin(2) == Vector2(358.5, 718)
	)
	tray.free()

static func _catalog_state(board: Variant, catalog: Array[Dictionary]) -> Dictionary:
	var normalized: bool = true
	var unique_cells: bool = true
	var connected: bool = true
	var unique_ids: bool = true
	var valid_colors: bool = true
	var fits: bool = true
	var ids_seen: Array[String] = []
	board.reset()
	for piece: Dictionary in catalog:
		var shape: Array[Vector2i] = piece["shape"]
		if shape.is_empty():
			normalized = false
			unique_cells = false
			connected = false
			fits = false
		else:
			var min_x: int = shape[0].x
			var min_y: int = shape[0].y
			var cells_seen: Array[Vector2i] = []
			for cell: Vector2i in shape:
				min_x = mini(min_x, cell.x)
				min_y = mini(min_y, cell.y)
				if cells_seen.has(cell):
					unique_cells = false
				cells_seen.append(cell)
			normalized = normalized and min_x == 0 and min_y == 0
			connected = connected and _is_connected(shape)
			fits = fits and board.can_fit_anywhere(shape)

		var piece_id: String = piece["id"]
		if ids_seen.has(piece_id):
			unique_ids = false
		ids_seen.append(piece_id)
		var color_id: int = piece["color_id"]
		valid_colors = valid_colors and color_id >= 1 and color_id <= 5

	return {
		"normalized": normalized,
		"unique_cells": unique_cells,
		"connected": connected,
		"unique_ids": unique_ids,
		"valid_colors": valid_colors,
		"fits": fits
	}

static func _is_connected(shape: Array[Vector2i]) -> bool:
	if shape.is_empty():
		return false
	var visited: Array[Vector2i] = [shape[0]]
	var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var index: int = 0
	while index < visited.size():
		for direction: Vector2i in directions:
			var neighbor: Vector2i = visited[index] + direction
			if shape.has(neighbor) and not visited.has(neighbor):
				visited.append(neighbor)
		index += 1
	return visited.size() == shape.size()

static func _fairness_holds(board: Variant, generator: Variant, rng: RandomNumberGenerator) -> bool:
	for _iteration: int in range(200):
		var has_fitting_piece: bool = false
		for piece: Dictionary in generator.generate_triplet(board, rng):
			if board.can_fit_anywhere(piece["shape"]):
				has_fitting_piece = true
				break
		if not has_fitting_piece:
			return false
	return true

static func _fill_board_except(
	board: Variant,
	single_cell: Array[Vector2i],
	empty_cells: Array[Vector2i]
) -> void:
	board.reset()
	for index: int in range(Config.BOARD_SIZE * Config.BOARD_SIZE):
		var cell: Vector2i = Vector2i(index % Config.BOARD_SIZE, index / Config.BOARD_SIZE)
		if not empty_cells.has(cell):
			board.place(single_cell, cell, 1)

static func _find_piece(catalog: Array[Dictionary], piece_id: String) -> Dictionary:
	for piece: Dictionary in catalog:
		if piece["id"] == piece_id:
			return piece
	return {}
