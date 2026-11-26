# tests/AudioTestRunner.gd
extends RefCounted

const AudioManagerScript = preload("res://scripts/AudioManager.gd")
const SaveDataScript = preload("res://scripts/SaveData.gd")

const TEST_SAVE_PATH: String = "/tmp/blokhane_audio_smoke_test.cfg"

static func run(test_runner: Variant) -> void:
	var pitch_one: float = AudioManagerScript.combo_pitch_for_streak(1)
	var pitch_two: float = AudioManagerScript.combo_pitch_for_streak(2)
	var pitch_twenty: float = AudioManagerScript.combo_pitch_for_streak(20)
	test_runner.check(
		"74 kombo ses tonu 1, 2 ve 20 seride doğru, üst sınır uygulanır",
		is_equal_approx(pitch_one, 1.0)
		and is_equal_approx(pitch_two, 1.06)
		and is_equal_approx(pitch_twenty, 1.5)
	)

	var paths_valid: bool = _paths_are_valid(Config.SOUND_PATHS)
	test_runner.check(
		"76 ses tablosundaki tüm yollar SOUND_DIR ile başlar ve WAV'dır",
		paths_valid
	)

	_remove_test_file(TEST_SAVE_PATH)
	var missing_preferences: Dictionary = SaveDataScript.load_audio_preferences(TEST_SAVE_PATH)
	test_runner.check(
		"77 ses tercihi dosyası yoksa efektler varsayılan açık",
		missing_preferences["sfx_enabled"]
	)

	SaveDataScript.save_best(325, TEST_SAVE_PATH)
	SaveDataScript.save_audio_preferences(false, TEST_SAVE_PATH)
	var saved_preferences: Dictionary = SaveDataScript.load_audio_preferences(TEST_SAVE_PATH)
	test_runner.check(
		"78 ses efekti tercihi kaydet-yükle gidiş-dönüşü",
		not saved_preferences["sfx_enabled"]
	)

	SaveDataScript.reset_best(TEST_SAVE_PATH)
	var reset_preferences: Dictionary = SaveDataScript.load_audio_preferences(TEST_SAVE_PATH)
	test_runner.check(
		"79 verileri sıfırlama ses tercihini değiştirmez",
		SaveDataScript.load_best(TEST_SAVE_PATH) == 0
		and not reset_preferences["sfx_enabled"]
	)

	var corrupt_file: FileAccess = FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	var corrupt_written: bool = corrupt_file != null
	if corrupt_file != null:
		corrupt_file.store_string("[audio]\nsfx_enabled = bozuk\n")
		corrupt_file.close()
	var corrupt_preferences: Dictionary = SaveDataScript.load_audio_preferences(TEST_SAVE_PATH)
	_remove_test_file(TEST_SAVE_PATH)
	test_runner.check(
		"80 bozuk efekt tercihi dosyası çökmeden varsayılanı açık döndürür",
		corrupt_written and corrupt_preferences["sfx_enabled"]
	)

	test_runner.check(
		"82 tercih mute durumuna doğru çevrilir",
		not AudioManagerScript.bus_mute_for_enabled(true)
		and AudioManagerScript.bus_mute_for_enabled(false)
	)

static func _paths_are_valid(paths: Dictionary) -> bool:
	for path_variant: Variant in paths.values():
		if typeof(path_variant) != TYPE_STRING:
			return false
		var path: String = path_variant
		if not path.begins_with(Config.SOUND_DIR) or not path.ends_with(".wav"):
			return false
	return not paths.is_empty()

static func _remove_test_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
