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
	var wav_stream: AudioStreamWAV = AudioStreamWAV.new()
	var loop_configured: bool = AudioManagerScript.configure_wav_loop(wav_stream)
	test_runner.check(
		"75 Godot 4.7 AudioStreamWAV döngüsü kodla kurulur",
		loop_configured and wav_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD
	)

	var paths_valid: bool = _paths_are_valid(Config.SOUND_PATHS)
	paths_valid = paths_valid and _paths_are_valid(Config.MUSIC_PATHS)
	test_runner.check(
		"76 ses tablosundaki tüm yollar SOUND_DIR ile başlar ve WAV'dır",
		paths_valid
	)

	_remove_test_file(TEST_SAVE_PATH)
	var missing_preferences: Dictionary = SaveDataScript.load_audio_preferences(TEST_SAVE_PATH)
	test_runner.check(
		"77 ses tercihi dosyası yoksa müzik ve efektler varsayılan açık",
		missing_preferences["music_enabled"] and missing_preferences["sfx_enabled"]
	)

	SaveDataScript.save_best(325, TEST_SAVE_PATH)
	SaveDataScript.save_audio_preferences(false, true, TEST_SAVE_PATH)
	var saved_preferences: Dictionary = SaveDataScript.load_audio_preferences(TEST_SAVE_PATH)
	test_runner.check(
		"78 ses tercihleri kaydet-yükle gidiş-dönüşü",
		not saved_preferences["music_enabled"] and saved_preferences["sfx_enabled"]
	)

	SaveDataScript.reset_best(TEST_SAVE_PATH)
	var reset_preferences: Dictionary = SaveDataScript.load_audio_preferences(TEST_SAVE_PATH)
	test_runner.check(
		"79 verileri sıfırlama ses tercihlerini değiştirmez",
		SaveDataScript.load_best(TEST_SAVE_PATH) == 0
		and not reset_preferences["music_enabled"]
		and reset_preferences["sfx_enabled"]
	)

	var corrupt_file: FileAccess = FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	var corrupt_written: bool = corrupt_file != null
	if corrupt_file != null:
		corrupt_file.store_string("[audio]\nmusic_enabled = bozuk\nsfx_enabled = true\n")
		corrupt_file.close()
	var corrupt_preferences: Dictionary = SaveDataScript.load_audio_preferences(TEST_SAVE_PATH)
	_remove_test_file(TEST_SAVE_PATH)
	test_runner.check(
		"80 bozuk ses tercihi dosyası çökmeden iki seçeneği de açık döndürür",
		corrupt_written
		and corrupt_preferences["music_enabled"]
		and corrupt_preferences["sfx_enabled"]
	)

	var startup_output_db: float = AudioManagerScript.music_start_output_db()
	test_runner.check(
		"81 başlangıç müzik seviyesi player ve Music bus dB toplamını kullanır",
		is_equal_approx(
			AudioManagerScript.music_start_player_db(), Config.MUSIC_SILENCE_DB
		)
		and is_equal_approx(
			AudioManagerScript.music_bus_db(false, false), Config.MUSIC_DB
		)
		and is_equal_approx(
			startup_output_db, Config.MUSIC_SILENCE_DB + Config.MUSIC_DB
		)
	)
	test_runner.check(
		"82 müzik tercihi mute durumuna doğru çevrilir",
		not AudioManagerScript.music_bus_mute_for_enabled(true)
		and AudioManagerScript.music_bus_mute_for_enabled(false)
	)
	test_runner.check(
		"83 pause ve oyun sonu Music bus seviyesini azaltır",
		is_equal_approx(
			AudioManagerScript.music_bus_db(true, false),
			Config.MUSIC_DB + Config.MUSIC_PAUSE_DB
		)
		and is_equal_approx(
			AudioManagerScript.music_bus_db(false, true),
			Config.MUSIC_DB + Config.MUSIC_PAUSE_DB
		)
	)
	test_runner.check(
		"84 yalnızca etkin müzik akışı bitince yeniden başlatılır",
		AudioManagerScript.should_restart_finished_music(
			Config.MUSIC_PATHS[Config.MusicTrack.MENU], ""
		)
		and AudioManagerScript.should_restart_finished_music(
			Config.MUSIC_PATHS[Config.MusicTrack.MAIN],
			Config.MUSIC_PATHS[Config.MusicTrack.MAIN]
		)
		and not AudioManagerScript.should_restart_finished_music(
			Config.MUSIC_PATHS[Config.MusicTrack.MENU],
			Config.MUSIC_PATHS[Config.MusicTrack.MAIN]
		)
		and not AudioManagerScript.should_restart_finished_music("", "")
	)
	var music_request_pending: bool = true
	var request_waits_for_stream: bool = not AudioManagerScript.should_apply_pending_music_request(
		music_request_pending, false
	)
	var request_applies_after_load: bool = AudioManagerScript.should_apply_pending_music_request(
		music_request_pending, true
	)
	test_runner.check(
		"85 stream yüklenmeden gelen müzik isteği yükleme sonrası uygulanır",
		request_waits_for_stream and request_applies_after_load
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
