# tests/BestScoreStoreTestRunner.gd
extends RefCounted

const BestScoreStoreScript = preload("res://scripts/BestScoreStore.gd")
const SaveDataScript = preload("res://scripts/SaveData.gd")

const TEST_SAVE_PATH: String = "/tmp/blokhane_best_store_test.cfg"
const UNWRITABLE_SAVE_PATH: String = "/nonexistent_dir_blokhane/x.cfg"

static func run(test_runner: Variant) -> void:
	_remove_test_file(TEST_SAVE_PATH)
	var store: Variant = BestScoreStoreScript.new(TEST_SAVE_PATH)
	store.begin_run()
	store.submit(50)
	var reloaded: Variant = BestScoreStoreScript.new(TEST_SAVE_PATH)
	reloaded.load_from_disk()
	var wrote_best: bool = reloaded.best == 50
	_remove_test_file(TEST_SAVE_PATH)
	test_runner.check("86 submit rekoru aşan skoru diske yazar", wrote_best)

	_remove_test_file(TEST_SAVE_PATH)
	SaveDataScript.save_best(50, TEST_SAVE_PATH)
	store = BestScoreStoreScript.new(TEST_SAVE_PATH)
	store.load_from_disk()
	store.begin_run()
	store.submit(50)
	var equal_score_is_not_new_best: bool = not store.is_new_best(50)
	_remove_test_file(TEST_SAVE_PATH)
	test_runner.check("87 skor rekora eşitse yeni rekor sayılmaz", equal_score_is_not_new_best)

	_remove_test_file(TEST_SAVE_PATH)
	SaveDataScript.save_best(50, TEST_SAVE_PATH)
	store = BestScoreStoreScript.new(TEST_SAVE_PATH)
	store.load_from_disk()
	store.begin_run()
	store.submit(60)
	var exceeded_record_is_new_best: bool = store.is_new_best(60)
	reloaded = BestScoreStoreScript.new(TEST_SAVE_PATH)
	reloaded.load_from_disk()
	var exceeded_record_is_persisted: bool = reloaded.best == 60
	_remove_test_file(TEST_SAVE_PATH)
	test_runner.check(
		"88 rekoru aşan skor yeni rekordur ve oyun bitmeden de kalıcıdır",
		exceeded_record_is_new_best and exceeded_record_is_persisted
	)

	_remove_test_file(TEST_SAVE_PATH)
	SaveDataScript.save_best(50, TEST_SAVE_PATH)
	store = BestScoreStoreScript.new(TEST_SAVE_PATH)
	store.load_from_disk()
	store.reset()
	var reset_memory: bool = store.best == 0
	reloaded = BestScoreStoreScript.new(TEST_SAVE_PATH)
	reloaded.load_from_disk()
	var reset_file: bool = reloaded.best == 0
	_remove_test_file(TEST_SAVE_PATH)
	test_runner.check("89 reset bellek ve dosyayı sıfırlar", reset_memory and reset_file)

	_remove_test_file(TEST_SAVE_PATH)
	store = BestScoreStoreScript.new(TEST_SAVE_PATH)
	store.reset()
	store.begin_run()
	store.submit(1)
	var first_score_is_new_best: bool = store.is_new_best(1)
	_remove_test_file(TEST_SAVE_PATH)
	test_runner.check("90 reset sonrası ilk oyunda 1 puan yeni rekordur", first_score_is_new_best)

	_remove_test_file(TEST_SAVE_PATH)
	store = BestScoreStoreScript.new(UNWRITABLE_SAVE_PATH)
	store.begin_run()
	store.submit(9)
	var unwritable_path_keeps_memory_best: bool = store.best == 9
	_remove_test_file(TEST_SAVE_PATH)
	test_runner.check(
		"91 yazılamayan yolda submit çökmez, bellekte rekor güncellenir",
		unwritable_path_keeps_memory_best
	)

static func _remove_test_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
