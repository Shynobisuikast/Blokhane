# tests/GameOverTestRunner.gd
extends RefCounted

const BoardModelScript = preload("res://scripts/BoardModel.gd")
const GameRulesScript = preload("res://scripts/GameRules.gd")
const SaveDataScript = preload("res://scripts/SaveData.gd")

const TEST_SAVE_PATH: String = "/tmp/blokhane_game_over_smoke_test.cfg"

static func run(test_runner: Variant) -> void:
	var board: BoardModel = BoardModelScript.new()
	var single_cell: Array[Vector2i] = [Vector2i.ZERO]
	test_runner.check(
		"46 boş tahta ve tek hücre parça oyun sonu değildir",
		not GameRulesScript.is_game_over(board, [single_cell])
	)

	for row: int in range(Config.BOARD_SIZE):
		for column: int in range(Config.BOARD_SIZE):
			board.place(single_cell, Vector2i(column, row), 1)
	test_runner.check(
		"47 tamamen dolu tahta tek hücre parça için oyun sonudur",
		GameRulesScript.is_game_over(board, [single_cell])
	)
	test_runner.check(
		"48 boş kalan parça listesi oyun sonu değildir",
		not GameRulesScript.is_game_over(board, [])
	)

	board.reset()
	var isolated_empty_cells: Array[Vector2i] = [
		Vector2i.ZERO,
		Vector2i(Config.BOARD_SIZE - 1, Config.BOARD_SIZE - 1)
	]
	_fill_board_except(board, isolated_empty_cells, single_cell)
	var pair: Array[Vector2i] = [Vector2i.ZERO, Vector2i.RIGHT]
	test_runner.check(
		"49 kalan parçalardan biri sığıyorsa oyun sürer, hiçbiri sığmıyorsa biter",
		not GameRulesScript.is_game_over(board, [pair, single_cell])
		and GameRulesScript.is_game_over(board, [pair])
	)

	_remove_test_file(TEST_SAVE_PATH)
	SaveDataScript.save_best(120, TEST_SAVE_PATH)
	var saved_best: int = SaveDataScript.load_best(TEST_SAVE_PATH)
	_remove_test_file(TEST_SAVE_PATH)
	test_runner.check("50 SaveData ayrı test dosyasına en yüksek skoru yazar ve okur", saved_best == 120)

	_remove_test_file(TEST_SAVE_PATH)
	test_runner.check("51 bulunmayan kayıt dosyası sıfır döndürür", SaveDataScript.load_best(TEST_SAVE_PATH) == 0)

	var corrupt_file: FileAccess = FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	var corrupt_written: bool = corrupt_file != null
	if corrupt_file != null:
		corrupt_file.store_string("[scores]\nbest = [broken")
		corrupt_file.close()
	var corrupt_best: int = SaveDataScript.load_best(TEST_SAVE_PATH)
	_remove_test_file(TEST_SAVE_PATH)
	test_runner.check("52 bozuk kayıt dosyası çökmeden sıfır döndürür", corrupt_written and corrupt_best == 0)


static func _fill_board_except(
	board: BoardModel,
	empty_cells: Array[Vector2i],
	single_cell: Array[Vector2i]
) -> void:
	board.reset()
	for row: int in range(Config.BOARD_SIZE):
		for column: int in range(Config.BOARD_SIZE):
			var cell: Vector2i = Vector2i(column, row)
			if not empty_cells.has(cell):
				board.place(single_cell, cell, 1)

static func _remove_test_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
