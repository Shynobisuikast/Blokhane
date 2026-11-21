# scripts/AudioManager.gd
extends Node

const SaveDataScript = preload("res://scripts/SaveData.gd")

var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_started_at: Array[int] = []
var _sfx_streams: Dictionary = {}
var _music_streams: Dictionary = {}
var _warned_assets: Dictionary = {}
var _music_player: AudioStreamPlayer
var _audio_resources_loaded: bool = false
var _pending_music_request: bool = false
var _new_best_timer: Timer
var _double_clear_timer: Timer
var _double_clear_pitch: float = 1.0
var _music_tween: Tween
var _music_bus_index: int = -1
var _sfx_bus_index: int = -1
var _current_music_path: String = ""
var _transition_target_path: String = ""
var _music_enabled: bool = true
var _sfx_enabled: bool = true
var _menu_context: bool = true
var _paused: bool = false
var _game_over: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music_bus_index = _ensure_bus(Config.MUSIC_BUS_NAME, Config.MUSIC_DB)
	_sfx_bus_index = _ensure_bus(Config.SFX_BUS_NAME, Config.SFX_DB)
	_create_players()
	_load_audio_resources()
	var preferences: Dictionary = SaveDataScript.load_audio_preferences()
	_music_enabled = preferences["music_enabled"]
	_sfx_enabled = preferences["sfx_enabled"]
	_apply_bus_states()
	_request_music()

func _exit_tree() -> void:
	if _music_tween != null and _music_tween.is_running():
		_music_tween.kill()
	if _new_best_timer != null:
		_new_best_timer.stop()
	if _double_clear_timer != null:
		_double_clear_timer.stop()
	if _music_player != null:
		_music_player.stop()
		_music_player.stream = null
	for player: AudioStreamPlayer in _sfx_players:
		player.stop()
		player.stream = null
	_music_streams.clear()
	_sfx_streams.clear()

func play_sfx(sound_id: int, pitch_scale: float = 1.0) -> void:
	if not _sfx_enabled:
		return
	var stream: AudioStream = _sfx_streams.get(sound_id, null)
	if stream == null:
		return
	var player_index: int = _available_sfx_player_index()
	var player: AudioStreamPlayer = _sfx_players[player_index]
	player.stream = stream
	player.pitch_scale = pitch_scale
	player.play()
	_sfx_started_at[player_index] = Time.get_ticks_usec()

func play_clear(line_count: int, streak: int) -> void:
	var pitch: float = combo_pitch_for_streak(streak)
	play_sfx(Config.SoundId.CLEAR, pitch)
	if line_count < Config.CLEAR_DOUBLE_MIN_LINES:
		return
	_double_clear_pitch = pitch * Config.CLEAR_DOUBLE_PITCH
	_double_clear_timer.start(Config.CLEAR_DOUBLE_DELAY)

func play_game_over(is_new_best: bool) -> void:
	play_sfx(Config.SoundId.GAME_OVER)
	if is_new_best:
		_new_best_timer.start(Config.NEW_BEST_DELAY)

func set_music_enabled(enabled: bool) -> void:
	_music_enabled = enabled
	_apply_bus_states()
	_save_audio_preferences()

func set_sfx_enabled(enabled: bool) -> void:
	_sfx_enabled = enabled
	_apply_bus_states()
	_save_audio_preferences()

func is_music_enabled() -> bool:
	return _music_enabled

func is_sfx_enabled() -> bool:
	return _sfx_enabled

func set_menu_context(is_menu: bool) -> void:
	if _menu_context == is_menu:
		return
	_menu_context = is_menu
	_request_music()

func set_paused(is_paused: bool) -> void:
	if _paused == is_paused:
		return
	_paused = is_paused
	_update_music_bus()

func set_game_over(is_game_over: bool) -> void:
	if _game_over == is_game_over:
		return
	_game_over = is_game_over
	_update_music_bus()

static func combo_pitch_for_streak(streak: int) -> float:
	var combo_pitch: float = 1.0 + Config.COMBO_PITCH_STEP * float(maxi(streak - 1, 0))
	return minf(combo_pitch, Config.COMBO_PITCH_MAX)

static func configure_wav_loop(stream: AudioStream) -> bool:
	if not stream is AudioStreamWAV:
		return false
	(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	return true

static func music_start_player_db() -> float:
	return Config.MUSIC_SILENCE_DB

static func music_start_output_db() -> float:
	return music_start_player_db() + music_bus_db(false, false)

static func music_bus_db(is_paused: bool, is_game_over: bool) -> float:
	var attenuation_db: float = (
		Config.MUSIC_PAUSE_DB
		if is_paused or is_game_over
		else Config.MUSIC_UNITY_DB
	)
	return Config.MUSIC_DB + attenuation_db

static func music_bus_mute_for_enabled(enabled: bool) -> bool:
	return not enabled

static func should_restart_finished_music(
	current_path: String,
	transition_target_path: String
) -> bool:
	return not current_path.is_empty() and (
		transition_target_path.is_empty()
		or transition_target_path == current_path
	)

static func should_apply_pending_music_request(
	request_pending: bool,
	resources_loaded: bool
) -> bool:
	return request_pending and resources_loaded

func _create_players() -> void:
	for player_index: int in range(Config.SFX_PLAYER_COUNT):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = Config.SFX_BUS_NAME
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_sfx_players.append(player)
		_sfx_started_at.append(0)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = Config.MUSIC_BUS_NAME
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_music_player.finished.connect(_on_music_finished)
	add_child(_music_player)

	_new_best_timer = _make_timer(_on_new_best_timeout)
	_double_clear_timer = _make_timer(_on_double_clear_timeout)

func _make_timer(callback: Callable) -> Timer:
	var timer: Timer = Timer.new()
	timer.one_shot = true
	timer.process_mode = Node.PROCESS_MODE_ALWAYS
	timer.timeout.connect(callback)
	add_child(timer)
	return timer

func _load_audio_resources() -> void:
	for sound_id: int in Config.SOUND_PATHS:
		_sfx_streams[sound_id] = _load_stream(Config.SOUND_PATHS[sound_id], false)
	for track_id: int in Config.MUSIC_PATHS:
		_music_streams[track_id] = _load_stream(Config.MUSIC_PATHS[track_id], true)
	_audio_resources_loaded = true
	if should_apply_pending_music_request(
		_pending_music_request, _audio_resources_loaded
	):
		_pending_music_request = false
		_request_music()

func _load_stream(path: String, should_loop: bool) -> AudioStream:
	var resource: Resource = ResourceLoader.load(path)
	if resource == null:
		_warn_asset(path, "ResourceLoader.load() sonucu: null")
		return null
	if not resource is AudioStream:
		_warn_asset(path, "ResourceLoader.load() sonucu AudioStream değil: %s" % resource.get_class())
		return null
	var stream: AudioStream = resource as AudioStream
	if should_loop and not configure_wav_loop(stream):
		_warn_asset(path, "AudioStreamWAV biçiminde değil")
		return null
	return stream

func _available_sfx_player_index() -> int:
	for player_index: int in range(_sfx_players.size()):
		if not _sfx_players[player_index].playing:
			return player_index
	var oldest_index: int = 0
	for player_index: int in range(1, _sfx_players.size()):
		if _sfx_started_at[player_index] < _sfx_started_at[oldest_index]:
			oldest_index = player_index
	return oldest_index

func _request_music() -> void:
	var track_id: int = Config.MusicTrack.MENU if _menu_context else Config.MusicTrack.MAIN
	var stream: AudioStream = _music_streams.get(track_id, null)
	if stream == null and _menu_context:
		track_id = Config.MusicTrack.MAIN
		stream = _music_streams.get(track_id, null)
	var target_path: String = Config.MUSIC_PATHS.get(track_id, "") if stream != null else ""

	if stream == null and not _audio_resources_loaded:
		_pending_music_request = true
		return
	_pending_music_request = false
	if target_path == _current_music_path and _music_player.playing:
		if _music_tween != null and _music_tween.is_running():
			_music_tween.kill()
			_music_player.volume_db = Config.MUSIC_UNITY_DB
			_transition_target_path = ""
		return
	if target_path == _transition_target_path and _music_tween != null and _music_tween.is_running():
		return
	if _music_tween != null and _music_tween.is_running():
		_music_tween.kill()
	if stream == null:
		_transition_to_silence()
	elif _current_music_path.is_empty() or not _music_player.playing:
		_start_music(stream, target_path)
	else:
		_crossfade_music(stream, target_path)

func _start_music(stream: AudioStream, path: String) -> void:
	_music_player.stop()
	_music_player.stream = stream
	_music_player.volume_db = music_start_player_db()
	_music_player.play()
	_current_music_path = path
	_transition_target_path = path
	_music_tween = create_tween()
	_music_tween.tween_property(
		_music_player, "volume_db", 0.0, Config.MUSIC_CROSSFADE_SECONDS
	)
	_music_tween.finished.connect(_clear_transition_target, CONNECT_ONE_SHOT)

func _crossfade_music(stream: AudioStream, path: String) -> void:
	_transition_target_path = path
	_music_tween = create_tween()
	_music_tween.tween_property(
		_music_player,
		"volume_db",
		Config.MUSIC_SILENCE_DB,
		Config.MUSIC_CROSSFADE_HALF_SECONDS
	)
	_music_tween.tween_callback(_replace_music.bind(stream, path))
	_music_tween.tween_property(
		_music_player,
		"volume_db",
		Config.MUSIC_UNITY_DB,
		Config.MUSIC_CROSSFADE_HALF_SECONDS
	)
	_music_tween.finished.connect(_clear_transition_target, CONNECT_ONE_SHOT)

func _transition_to_silence() -> void:
	if not _music_player.playing:
		_stop_music()
		return
	_current_music_path = ""
	_transition_target_path = ""
	_music_tween = create_tween()
	_music_tween.tween_property(
		_music_player, "volume_db", Config.MUSIC_SILENCE_DB, Config.MUSIC_CROSSFADE_SECONDS
	)
	_music_tween.tween_callback(_stop_music)

func _replace_music(stream: AudioStream, path: String) -> void:
	_music_player.stop()
	_music_player.stream = stream
	_music_player.play()
	_current_music_path = path

func _stop_music() -> void:
	_music_player.stop()
	_music_player.stream = null
	_music_player.volume_db = Config.MUSIC_UNITY_DB
	_current_music_path = ""
	_transition_target_path = ""

func _clear_transition_target() -> void:
	_transition_target_path = ""

func _available_bus(bus_name: String, default_db: float) -> int:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		AudioServer.add_bus()
		bus_index = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(bus_index, bus_name)
		AudioServer.set_bus_send(bus_index, "Master")
	AudioServer.set_bus_volume_db(bus_index, default_db)
	return bus_index

func _ensure_bus(bus_name: String, default_db: float) -> int:
	return _available_bus(bus_name, default_db)

func _apply_bus_states() -> void:
	if _music_bus_index >= 0:
		AudioServer.set_bus_mute(
			_music_bus_index, music_bus_mute_for_enabled(_music_enabled)
		)
	if _sfx_bus_index >= 0:
		AudioServer.set_bus_mute(
			_sfx_bus_index, music_bus_mute_for_enabled(_sfx_enabled)
		)
	_update_music_bus()

func _update_music_bus() -> void:
	if _music_bus_index < 0:
		return
	AudioServer.set_bus_volume_db(
		_music_bus_index, music_bus_db(_paused, _game_over)
	)

func _on_music_finished() -> void:
	if _music_player.stream == null:
		return
	if not should_restart_finished_music(_current_music_path, _transition_target_path):
		return
	_music_player.play()

func _save_audio_preferences() -> void:
	SaveDataScript.save_audio_preferences(_music_enabled, _sfx_enabled)

func _on_new_best_timeout() -> void:
	play_sfx(Config.SoundId.NEW_BEST)

func _on_double_clear_timeout() -> void:
	play_sfx(Config.SoundId.CLEAR, _double_clear_pitch)

func _warn_asset(path: String, reason: String) -> void:
	if _warned_assets.has(path):
		return
	_warned_assets[path] = true
	push_warning("Ses varlığı atlandı (%s): %s." % [path, reason])
