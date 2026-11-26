# tests/SaveDataTestRunner.gd
extends RefCounted

const SaveDataScript = preload("res://scripts/SaveData.gd")
const ThemePalettesScript = preload("res://scripts/ThemePalettes.gd")

const TEST_SAVE_PATH: String = "/tmp/blokhane_save_data_test.cfg"
const TEST_TMP_PATH: String = TEST_SAVE_PATH + ".tmp"

static func run(test_runner: Variant) -> void:
	_remove_test_files()
	var unknown_key_file: FileAccess = FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	var unknown_key_written: bool = unknown_key_file != null
	if unknown_key_file != null:
		unknown_key_file.store_string("[scores]\nbest=5\nfuture_key=1\n")
		unknown_key_file.close()
	var unknown_key_preserves_best: bool = SaveDataScript.load_best(TEST_SAVE_PATH) == 5
	_remove_test_files()
	test_runner.check(
		"92 bilinmeyen anahtar rekoru bozmaz",
		unknown_key_written and unknown_key_preserves_best
	)

	_remove_test_files()
	var theme_file: FileAccess = FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	var theme_file_written: bool = theme_file != null
	if theme_file != null:
		theme_file.store_string("[scores]\nbest=5\nfuture_key=1\n")
		theme_file.close()
	SaveDataScript.save_theme(ThemePalettesScript.ThemeId.LIGHT, TEST_SAVE_PATH)
	var best_after_theme_save: int = SaveDataScript.load_best(TEST_SAVE_PATH)
	var theme_after_save: ThemePalettesScript.ThemeId = SaveDataScript.load_theme(TEST_SAVE_PATH)
	_remove_test_files()
	test_runner.check(
		"93 bilinmeyen anahtarlı dosyada save_theme rekoru korur",
		theme_file_written
		and best_after_theme_save == 5
		and theme_after_save == ThemePalettesScript.ThemeId.LIGHT
	)

	_remove_test_files()
	SaveDataScript.save_best(3, TEST_SAVE_PATH)
	var no_tmp_after_save: bool = not FileAccess.file_exists(TEST_TMP_PATH)
	var saved_best: int = SaveDataScript.load_best(TEST_SAVE_PATH)
	_remove_test_files()
	test_runner.check(
		"94 başarılı kayıttan sonra .tmp dosyası kalmaz",
		no_tmp_after_save and saved_best == 3
	)

	_remove_test_files()
	SaveDataScript.save_best(7, TEST_SAVE_PATH)
	var partial_file: FileAccess = FileAccess.open(TEST_TMP_PATH, FileAccess.WRITE)
	var partial_file_written: bool = partial_file != null
	if partial_file != null:
		partial_file.store_string("[scores]\nbest = [br")
		partial_file.close()
	var best_ignores_partial_tmp: int = SaveDataScript.load_best(TEST_SAVE_PATH)
	_remove_test_files()
	test_runner.check(
		"95 yarım kalmış .tmp dosyası asıl dosyayı etkilemez",
		partial_file_written and best_ignores_partial_tmp == 7
	)

	_remove_test_files()
	var future_audio_file: FileAccess = FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	var future_audio_written: bool = future_audio_file != null
	if future_audio_file != null:
		future_audio_file.store_string(
			"[audio]\nfuture_enabled=false\nsfx_enabled=true\n"
		)
		future_audio_file.close()
	SaveDataScript.save_audio_preferences(false, TEST_SAVE_PATH)
	var updated_config: ConfigFile = ConfigFile.new()
	var updated_config_loaded: bool = updated_config.load(TEST_SAVE_PATH) == OK
	var future_audio_preserved: bool = (
		updated_config_loaded
		and updated_config.get_value("audio", "future_enabled", true) == false
		and updated_config.get_value("audio", "sfx_enabled", true) == false
	)
	_remove_test_files()
	test_runner.check(
		"96 sfx tercihi kaydı bilinmeyen ses anahtarını korur",
		future_audio_written and future_audio_preserved
	)

static func _remove_test_files() -> void:
	_remove_file(TEST_SAVE_PATH)
	_remove_file(TEST_TMP_PATH)

static func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
