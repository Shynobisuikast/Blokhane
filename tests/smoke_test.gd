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
const ButtonFeedbackScript = preload("res://scripts/ButtonFeedback.gd")
const ClearStaggerScript = preload("res://scripts/ClearStagger.gd")

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
	_test_polish_constants()

func _test_polish_constants() -> void:
	var animation_times: Array[float] = [
		Config.PRESS_TIME,
		Config.PLACE_POP_TIME,
		Config.CLEAR_TWEEN_TIME,
		Config.CLEAR_STAGGER,
		Config.SCREEN_FADE_TIME,
		Config.SCORE_COUNT_TIME,
		Config.RETURN_SHAKE_TIME,
		Config.RETURN_TWEEN_TIME,
		Config.SCORE_POP_TIME,
		Config.COMBO_POP_TIME
	]
	var positive_times: bool = true
	for animation_time: float in animation_times:
		positive_times = positive_times and animation_time > 0.0
	var clear_total_bound: float = (
		Config.CLEAR_STAGGER * Config.BOARD_SIZE + Config.CLEAR_TWEEN_TIME
	)
	check(
		"69 animasyon sabitleri pozitif, temizleme süresi üst sınırı aşmıyor",
		positive_times
		and Config.PRESS_SCALE > 0.0
		and Config.PRESS_SCALE < 1.0
		and Config.PLACE_POP_SCALE > 1.0
		and Config.RETURN_SHAKE_DISTANCE > 0.0
		and Config.RETURN_SHAKE_CYCLES > 0
		and clear_total_bound <= Config.CLEAR_MAX_DURATION
	)
	check(
		"70 ButtonFeedback basılı/bırakılmış ölçekleri doğru",
		is_equal_approx(ButtonFeedbackScript.scale_for_pressed(true), Config.PRESS_SCALE)
		and is_equal_approx(ButtonFeedbackScript.scale_for_pressed(false), 1.0)
	)
	_test_clear_stagger()

func _test_clear_stagger() -> void:
	var placed_cells: Array[Vector2i] = [Vector2i(2, 3), Vector2i(3, 3)]
	var cleared_cells: Array[Vector2i] = [
		Vector2i(2, 3), Vector2i(3, 3), Vector2i(5, 4)
	]
	var delays: Dictionary = ClearStaggerScript.calculate_delays(
		cleared_cells,
		placed_cells,
		Config.CLEAR_STAGGER,
		Config.CLEAR_TWEEN_TIME,
		Config.CLEAR_MAX_DURATION
	)
	check(
		"71 bırakılan hücreler gecikmesiz temizlenir",
		is_equal_approx(float(delays[placed_cells[0]]), 0.0)
		and is_equal_approx(float(delays[placed_cells[1]]), 0.0)
	)
	var expected_distance: int = abs(5 - 3) + abs(4 - 3)
	check(
		"72 uzak hücre gecikmesi Manhattan mesafesiyle hesaplanır",
		is_equal_approx(
			float(delays[Vector2i(5, 4)]),
			float(expected_distance) * Config.CLEAR_STAGGER
		)
	)

	var farthest_cell: Vector2i = Vector2i(Config.BOARD_SIZE - 1, Config.BOARD_SIZE - 1)
	var farthest_delays: Dictionary = ClearStaggerScript.calculate_delays(
		[farthest_cell],
		[Vector2i.ZERO],
		Config.CLEAR_STAGGER,
		Config.CLEAR_TWEEN_TIME,
		Config.CLEAR_MAX_DURATION
	)
	var total_clear_time: float = (
		Config.CLEAR_TWEEN_TIME
		+ ClearStaggerScript.maximum_delay(farthest_delays)
	)
	check(
		"73 en büyük gecikme temizleme üst sınırını aşmaz",
		total_clear_time <= Config.CLEAR_MAX_DURATION
	)

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
