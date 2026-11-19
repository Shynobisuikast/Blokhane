# tests/smoke_test.gd
extends SceneTree

const BoardModelScript = preload("res://scripts/BoardModel.gd")
const DragMathTestRunnerScript = preload("res://tests/DragMathTestRunner.gd")
const PreviewModelTestRunnerScript = preload("res://tests/PreviewModelTestRunner.gd")
const ScoreModelTestRunnerScript = preload("res://tests/ScoreModelTestRunner.gd")
const GameOverTestRunnerScript = preload("res://tests/GameOverTestRunner.gd")
const PieceTestRunnerScript = preload("res://tests/PieceTestRunner.gd")
const ScreenFlowTestRunnerScript = preload("res://tests/ScreenFlowTestRunner.gd")
const ThemeTestRunnerScript = preload("res://tests/ThemeTestRunner.gd")

var _checks_total: int = 0
var _checks_passed: int = 0
var _board: Variant
var _single_cell: Array[Vector2i] = [Vector2i.ZERO]

func _init() -> void:
	_board = BoardModelScript.new()
	_run_tests()
	print("TOPLAM: %d/%d geçti" % [_checks_passed, _checks_total])
	quit(0 if _checks_passed == _checks_total else 1)

func _run_tests() -> void:
	_board.reset()
	check("Boş tahtaya tek hücre yerleşir", _board.place(_single_cell, Vector2i.ZERO, 1))

	check("Aynı yere ikinci parça yerleşemez", not _board.can_place(_single_cell, Vector2i.ZERO))

	_board.reset()
	var horizontal_pair: Array[Vector2i] = [Vector2i.ZERO, Vector2i.RIGHT]
	check(
		"Sağ kenardan taşan parça reddedilir",
		not _board.can_place(horizontal_pair, Vector2i(Config.BOARD_SIZE - 1, 0))
	)

	_board.reset()
	var vertical_pair: Array[Vector2i] = [Vector2i.ZERO, Vector2i.DOWN]
	check(
		"Alt kenardan taşan parça reddedilir",
		not _board.can_place(vertical_pair, Vector2i(0, Config.BOARD_SIZE - 1))
	)

	_board.reset()
	_board.place(_single_cell, Vector2i.RIGHT, 7)
	var failed_place: bool = _board.place(horizontal_pair, Vector2i.ZERO, 2)
	check(
		"Başarısız place tahtayı değiştirmez",
		not failed_place and _board.get_cell(Vector2i.ZERO) == 0 and _board.get_cell(Vector2i.RIGHT) == 7
	)

	_board.reset()
	_fill_row(3)
	var row_lines: Dictionary = _board.find_full_lines()
	check("Dolu satır bulunur", row_lines["rows"] == [3])

	_board.reset()
	_fill_column(4)
	var column_lines: Dictionary = _board.find_full_lines()
	check("Dolu sütun bulunur", column_lines["cols"] == [4])

	_board.reset()
	_fill_row(2)
	var cleared_row: Dictionary = _board.clear_lines()
	check(
		"Temizlenen satır tamamen boş olur",
		cleared_row["rows"] == [2] and _is_row_empty(2)
	)

	_board.reset()
	_fill_column(6)
	var cleared_column: Dictionary = _board.clear_lines()
	check(
		"Sütun temizliği çalışır",
		cleared_column["cols"] == [6] and _is_column_empty(6)
	)

	_board.reset()
	_fill_row(2)
	_fill_column(5)
	var cleared_cross: Dictionary = _board.clear_lines()
	check(
		"Satır ve sütun aynı anda temizlenir, kesişme bir kez sayılır",
		cleared_cross["rows"] == [2]
		and cleared_cross["cols"] == [5]
		and cleared_cross["cells_cleared"] == Config.BOARD_SIZE * 2 - 1
		and _is_board_empty()
	)

	_board.reset()
	for row_index: int in range(Config.BOARD_SIZE):
		for column_index: int in range(Config.BOARD_SIZE):
			_board.place(_single_cell, Vector2i(column_index, row_index), 1)
	check("Dolu tahtada parça sığmaz", not _board.can_fit_anywhere(_single_cell))

	_board.reset()
	check("Boş tahtada parça sığar", _board.can_fit_anywhere(_single_cell))

	var board_view: BoardView = BoardView.new()
	var all_cells_round_trip: bool = true
	for row: int in range(Config.BOARD_SIZE):
		for column: int in range(Config.BOARD_SIZE):
			var cell: Vector2i = Vector2i(column, row)
			var inside_cell: Vector2 = board_view.cell_to_local(cell) + Vector2(1.0, 1.0)
			if board_view.local_to_cell(inside_cell) != cell:
				all_cells_round_trip = false
	check("64 hücrede koordinat dönüşümü", all_cells_round_trip)

	var gap_point: Vector2 = board_view.cell_to_local(Vector2i.ZERO) + Vector2(
		Config.CELL_SIZE + Config.GAP / 2.0,
		Config.CELL_SIZE / 2.0
	)
	check("İki hücre arasındaki boşluk hücre değildir", board_view.local_to_cell(gap_point) == Vector2i(-1, -1))
	check("Panel dışındaki nokta hücre değildir", board_view.local_to_cell(Vector2.ZERO) == Vector2i(-1, -1))
	board_view.free()
	PieceTestRunnerScript.run(self)
	DragMathTestRunnerScript.run(self)
	PreviewModelTestRunnerScript.run(self)
	ScoreModelTestRunnerScript.run(self)
	GameOverTestRunnerScript.run(self)
	ScreenFlowTestRunnerScript.run(self)
	ThemeTestRunnerScript.run(self)

func check(test_name: String, condition: bool) -> void:
	_checks_total += 1
	if condition:
		_checks_passed += 1
	else:
		push_error("BAŞARISIZ: %s" % test_name)

func _fill_row(row_index: int) -> void:
	for column_index: int in range(Config.BOARD_SIZE):
		_board.place(_single_cell, Vector2i(column_index, row_index), 1)

func _fill_column(column_index: int) -> void:
	for row_index: int in range(Config.BOARD_SIZE):
		_board.place(_single_cell, Vector2i(column_index, row_index), 1)

func _is_row_empty(row_index: int) -> bool:
	for column_index: int in range(Config.BOARD_SIZE):
		if _board.get_cell(Vector2i(column_index, row_index)) != 0:
			return false
	return true

func _is_column_empty(column_index: int) -> bool:
	for row_index: int in range(Config.BOARD_SIZE):
		if _board.get_cell(Vector2i(column_index, row_index)) != 0:
			return false
	return true

func _is_board_empty() -> bool:
	for row_index: int in range(Config.BOARD_SIZE):
		if not _is_row_empty(row_index):
			return false
	return true
