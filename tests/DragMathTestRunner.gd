# tests/DragMathTestRunner.gd
extends RefCounted

const BoardModelScript = preload("res://scripts/BoardModel.gd")
const BoardViewScript = preload("res://scripts/BoardView.gd")
const DragMathScript = preload("res://scripts/DragMath.gd")
const PiecesScript = preload("res://scripts/Pieces.gd")

static func run(test_runner: Variant) -> void:
	var dot: Array[Vector2i] = [Vector2i.ZERO]
	var pointer: Vector2 = Vector2(240, 500)
	var dot_top_left: Vector2 = DragMathScript.piece_top_left(pointer, dot)
	var expected_bottom: float = pointer.y - Config.DRAG_OFFSET_Y
	test_runner.check(
		"23 tek hücre imlece yatay ortalı ve offset kadar yukarıda",
		is_equal_approx(dot_top_left.x, pointer.x - Config.CELL_SIZE / 2.0)
		and is_equal_approx(dot_top_left.y + Config.CELL_SIZE, expected_bottom)
	)

	var h3: Array[Vector2i] = [Vector2i.ZERO, Vector2i.RIGHT, Vector2i(2, 0)]
	var v3: Array[Vector2i] = [Vector2i.ZERO, Vector2i.DOWN, Vector2i(0, 2)]
	var h3_top_left: Vector2 = DragMathScript.piece_top_left(pointer, h3)
	var v3_top_left: Vector2 = DragMathScript.piece_top_left(pointer, v3)
	test_runner.check(
		"24 yatay üçlü daha solda, dikey üçlü daha yukarıda başlar",
		h3_top_left.x < v3_top_left.x and h3_top_left.y > v3_top_left.y
	)

	var board_view: Variant = BoardViewScript.new()
	var all_centers_match: bool = true
	for row: int in range(Config.BOARD_SIZE):
		for column: int in range(Config.BOARD_SIZE):
			var cell: Vector2i = Vector2i(column, row)
			if DragMathScript.snap_origin(board_view.cell_to_local(cell), board_view) != cell:
				all_centers_match = false
	test_runner.check("25 64 hücrenin merkezleri aynı hücreye yapışır", all_centers_match)

	var gap_top_left: Vector2 = board_view.cell_to_local(Vector2i.ZERO) + Vector2(
		Config.CELL_SIZE + Config.GAP / 2.0 - Config.CELL_SIZE / 2.0,
		0.0
	)
	var gap_origin: Vector2i = DragMathScript.snap_origin(gap_top_left, board_view)
	test_runner.check("26 hücre arası boşluk en yakın hücreye yapışır", gap_origin == Vector2i(1, 0))

	var grid_origin: Vector2 = board_view.cell_to_local(Vector2i.ZERO)
	var left_origin: Vector2i = DragMathScript.snap_origin(
		grid_origin - Vector2(Config.CELL_SIZE * 2, 0), board_view
	)
	var right_origin: Vector2i = DragMathScript.snap_origin(
		board_view.cell_to_local(Vector2i(Config.BOARD_SIZE - 1, 0))
		+ Vector2(Config.CELL_SIZE * 2, 0),
		board_view
	)
	test_runner.check(
		"27 tahta dışındaki koordinatlar sınırlanmadan döner",
		left_origin.x < 0 and right_origin.x >= Config.BOARD_SIZE
	)

	var board: Variant = BoardModelScript.new()
	var valid_origin: Vector2i = Vector2i(2, 2)
	var snapped_origin: Vector2i = DragMathScript.snap_origin(
		board_view.cell_to_local(valid_origin), board_view
	)
	var placed: bool = board.place(dot, snapped_origin, 1)
	var occupied_rejected: bool = not board.can_place(dot, snapped_origin)
	var outside: Vector2i = DragMathScript.snap_origin(
		grid_origin - Vector2(Config.CELL_SIZE * 2, 0), board_view
	)
	test_runner.check(
		"28 snap sonrası geçerli yerleşme, çakışma ve taşma doğrulanır",
		placed and occupied_rejected and not board.can_place(dot, outside)
	)
	board_view.free()
