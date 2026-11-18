# tests/PreviewModelTestRunner.gd
extends RefCounted

const BoardModelScript = preload("res://scripts/BoardModel.gd")

static func run(test_runner: Variant) -> void:
	var board: BoardModel = BoardModelScript.new()
	var single_cell: Array[Vector2i] = [Vector2i.ZERO]

	board.place(single_cell, Vector2i(2, 2), 1)
	var board_before: Array[int] = _snapshot(board)
	board.preview_complete_lines(single_cell, Vector2i.ZERO)
	test_runner.check("29 preview geçerli durumda tahtayı değiştirmez", _snapshot(board) == board_before)

	board = BoardModelScript.new()
	_fill_bottom_row_except(board, 4, single_cell)
	var bottom_row_preview: Dictionary = board.preview_complete_lines(single_cell, Vector2i(4, 7))
	test_runner.check(
		"30 dark.svg tek hücre satır 7'yi tamamlar",
		bottom_row_preview["rows"] == [7] and bottom_row_preview["cols"] == []
	)

	var vertical_pair: Array[Vector2i] = [Vector2i.ZERO, Vector2i.DOWN]
	var vertical_preview: Dictionary = board.preview_complete_lines(vertical_pair, Vector2i(4, 6))
	test_runner.check("31 dikey ikili satır 7'yi tamamlar", vertical_preview["rows"] == [7])

	board = BoardModelScript.new()
	var incomplete_preview: Dictionary = board.preview_complete_lines(single_cell, Vector2i.ZERO)
	test_runner.check(
		"32 tamamlanmayan yerleşimde çizgi listeleri boştur",
		incomplete_preview["rows"] == [] and incomplete_preview["cols"] == []
	)

	board = BoardModelScript.new()
	for column: int in range(Config.BOARD_SIZE):
		if column != 5:
			board.place(single_cell, Vector2i(column, 3), 1)
	for row: int in range(Config.BOARD_SIZE):
		if row != 3:
			board.place(single_cell, Vector2i(5, row), 1)
	var crossing_preview: Dictionary = board.preview_complete_lines(single_cell, Vector2i(5, 3))
	test_runner.check(
		"33 aynı yerleşim satır ve sütunu tamamlar",
		crossing_preview["rows"] == [3] and crossing_preview["cols"] == [5]
	)

	board = BoardModelScript.new()
	board.place(single_cell, Vector2i.ZERO, 1)
	var occupied_preview: Dictionary = board.preview_complete_lines(single_cell, Vector2i.ZERO)
	test_runner.check(
		"34 dolu hücreye geçersiz yerleşim boş sonuç döndürür",
		occupied_preview["rows"] == [] and occupied_preview["cols"] == []
	)

	var outside_preview: Dictionary = board.preview_complete_lines(single_cell, Vector2i(-1, 0))
	test_runner.check(
		"35 tahta dışı geçersiz yerleşim boş sonuç döndürür",
		outside_preview["rows"] == [] and outside_preview["cols"] == []
	)

	test_runner.check("36 sabit seed ile 50 rastgele sonuç place/find_full_lines ile eşleşir", _random_results_match())

static func _fill_bottom_row_except(board: BoardModel, empty_column: int, single_cell: Array[Vector2i]) -> void:
	for column: int in range(Config.BOARD_SIZE):
		if column != empty_column:
			board.place(single_cell, Vector2i(column, Config.BOARD_SIZE - 1), 1)

static func _snapshot(board: BoardModel) -> Array[int]:
	var cells: Array[int] = []
	for row: int in range(Config.BOARD_SIZE):
		for column: int in range(Config.BOARD_SIZE):
			cells.append(board.get_cell(Vector2i(column, row)))
	return cells

static func _random_results_match() -> bool:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 5036
	var shape_count: int = 4
	var single_cell: Array[Vector2i] = [Vector2i.ZERO]

	for _iteration: int in range(50):
		var board: BoardModel = BoardModelScript.new()
		for row: int in range(Config.BOARD_SIZE):
			for column: int in range(Config.BOARD_SIZE):
				if rng.randf() < 0.55:
					board.place(single_cell, Vector2i(column, row), 1)

		var shape: Array[Vector2i] = []
		match rng.randi_range(0, shape_count - 1):
			0:
				shape = [Vector2i.ZERO]
			1:
				shape = [Vector2i.ZERO, Vector2i.RIGHT]
			2:
				shape = [Vector2i.ZERO, Vector2i.DOWN]
			_:
				shape = [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN]
		var origin: Vector2i = Vector2i(
			rng.randi_range(-1, Config.BOARD_SIZE),
			rng.randi_range(-1, Config.BOARD_SIZE)
		)
		var preview: Dictionary = board.preview_complete_lines(shape, origin)
		var expected: Dictionary = {"rows": [], "cols": []}
		if board.can_place(shape, origin):
			if not board.place(shape, origin, 2):
				return false
			expected = board.find_full_lines()
		if preview["rows"] != expected["rows"] or preview["cols"] != expected["cols"]:
			return false
	return true
