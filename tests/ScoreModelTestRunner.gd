# tests/ScoreModelTestRunner.gd
extends RefCounted

const BoardModelScript = preload("res://scripts/BoardModel.gd")
const ScoreModelScript = preload("res://scripts/ScoreModel.gd")

static func run(test_runner: Variant) -> void:
	var score: Variant = ScoreModelScript.new()
	score.streak = 2
	var no_lines: Dictionary = score.register_turn(3, 0)
	test_runner.check(
		"37 n=0 yalnızca yerleştirilen hücreleri verir ve seriyi sıfırlar",
		no_lines["gain"] == 3 and no_lines["streak"] == 0 and no_lines["multiplier"] == 1.0
	)

	score = ScoreModelScript.new()
	var one_line: Dictionary = score.register_turn(4, 1)
	test_runner.check(
		"38 n=1 ve 4 hücre 14 puan verir",
		one_line["gain"] == 14 and one_line["multiplier"] == 1.0 and one_line["streak"] == 1
	)

	score = ScoreModelScript.new()
	var two_lines: Dictionary = score.register_turn(6, 2)
	test_runner.check(
		"39 n=2 ve 6 hücre ilk turda 46 puan verir",
		two_lines["gain"] == 46 and two_lines["streak"] == 1
	)

	score = ScoreModelScript.new()
	score.register_turn(1, 1)
	var second_combo: Dictionary = score.register_turn(1, 1)
	test_runner.check(
		"40 ikinci temizleme x1.5 çarpanla 17 puan verir",
		second_combo["multiplier"] == 1.5
		and second_combo["gain"] == 17
		and roundi(11 * 1.5) == 17
	)

	score = ScoreModelScript.new()
	var final_combo: Dictionary = {}
	for _turn: int in range(10):
		final_combo = score.register_turn(1, 1)
	test_runner.check(
		"41 on temizleme turunda çarpan üst sınırda kalır",
		is_equal_approx(final_combo["multiplier"], Config.COMBO_MAX)
		and final_combo["streak"] == 10
	)

	score = ScoreModelScript.new()
	score.register_turn(1, 1)
	score.register_turn(1, 0)
	var restarted_combo: Dictionary = score.register_turn(1, 1)
	test_runner.check(
		"42 temizlemesiz tur seriyi kırar ve sonraki çarpanı sıfırlar",
		restarted_combo["multiplier"] == 1.0 and restarted_combo["streak"] == 1
	)

	score = ScoreModelScript.new()
	score.register_turn(10, 1)
	var saved_best: int = score.best
	score.reset()
	test_runner.check(
		"43 reset skor ve seriyi sıfırlar, best değerini korur",
		score.score == 0 and score.streak == 0 and score.best == saved_best
	)

	score = ScoreModelScript.new()
	score.register_turn(2, 1)
	score.register_turn(2, 0)
	var previous_best: int = score.best
	score.reset()
	score.register_turn(1, 0)
	test_runner.check(
		"44 best yeni rekorla artar, reset sonrası düşmez",
		previous_best == 14 and score.score == 1 and score.best == previous_best
	)

	test_runner.check("45 satır temizleme akışı temizleme öncesi renkleri saklar ve puanlar", _line_clear_scores())

static func _line_clear_scores() -> bool:
	var board: BoardModel = BoardModelScript.new()
	var dot: Array[Vector2i] = [Vector2i.ZERO]
	var target_row: int = Config.BOARD_SIZE - 1
	for column: int in range(Config.BOARD_SIZE - 1):
		board.place(dot, Vector2i(column, target_row), 1)
	if not board.place(dot, Vector2i(Config.BOARD_SIZE - 1, target_row), 2):
		return false

	var lines: Dictionary = board.find_full_lines()
	var line_count: int = lines["rows"].size() + lines["cols"].size()
	var cleared_cells: Dictionary = {}
	for row: int in lines["rows"]:
		for column: int in range(Config.BOARD_SIZE):
			var cell: Vector2i = Vector2i(column, row)
			cleared_cells[cell] = board.get_cell(cell)
	for column: int in lines["cols"]:
		for row: int in range(Config.BOARD_SIZE):
			var cell: Vector2i = Vector2i(column, row)
			cleared_cells[cell] = board.get_cell(cell)
	var cleared_lines: Dictionary = board.clear_lines()
	var score: Variant = ScoreModelScript.new()
	var result: Dictionary = score.register_turn(dot.size(), line_count)
	return (
		lines["rows"] == [target_row]
		and line_count == 1
		and cleared_cells.size() == Config.BOARD_SIZE
		and cleared_cells[Vector2i(Config.BOARD_SIZE - 1, target_row)] == 2
		and cleared_lines["rows"] == [target_row]
		and result["gain"] == Config.LINE_BONUS + dot.size()
	)
