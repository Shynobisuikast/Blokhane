# scripts/AudioManager.gd
extends Node

const SaveDataScript = preload("res://scripts/SaveData.gd")

var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_started_at: Array[int] = []
var _sfx_streams: Dictionary = {}
var _warned_assets: Dictionary = {}
var _new_best_timer: Timer
var _double_clear_timer: Timer
var _double_clear_pitch: float = 1.0
var _sfx_bus_index: int = -1
var _sfx_enabled: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_sfx_bus_index = _ensure_bus(Config.SFX_BUS_NAME, Config.SFX_DB)
	_create_players()
	_load_audio_resources()
	var preferences: Dictionary = SaveDataScript.load_audio_preferences()
	_sfx_enabled = preferences["sfx_enabled"]
	_apply_bus_states()

func _exit_tree() -> void:
	if _new_best_timer != null:
		_new_best_timer.stop()
	if _double_clear_timer != null:
		_double_clear_timer.stop()
	for player: AudioStreamPlayer in _sfx_players:
		player.stop()
		player.stream = null
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

func set_sfx_enabled(enabled: bool) -> void:
	_sfx_enabled = enabled
	_apply_bus_states()
	_save_audio_preferences()

func is_sfx_enabled() -> bool:
	return _sfx_enabled

static func combo_pitch_for_streak(streak: int) -> float:
	var combo_pitch: float = 1.0 + Config.COMBO_PITCH_STEP * float(maxi(streak - 1, 0))
	return minf(combo_pitch, Config.COMBO_PITCH_MAX)

static func bus_mute_for_enabled(enabled: bool) -> bool:
	return not enabled

func _create_players() -> void:
	for player_index: int in range(Config.SFX_PLAYER_COUNT):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = Config.SFX_BUS_NAME
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_sfx_players.append(player)
		_sfx_started_at.append(0)

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
		_sfx_streams[sound_id] = _load_stream(Config.SOUND_PATHS[sound_id])

func _load_stream(path: String) -> AudioStream:
	var resource: Resource = ResourceLoader.load(path)
	if resource == null:
		_warn_asset(path, "ResourceLoader.load() sonucu: null")
		return null
	if not resource is AudioStream:
		_warn_asset(path, "ResourceLoader.load() sonucu AudioStream değil: %s" % resource.get_class())
		return null
	return resource as AudioStream

func _available_sfx_player_index() -> int:
	for player_index: int in range(_sfx_players.size()):
		if not _sfx_players[player_index].playing:
			return player_index
	var oldest_index: int = 0
	for player_index: int in range(1, _sfx_players.size()):
		if _sfx_started_at[player_index] < _sfx_started_at[oldest_index]:
			oldest_index = player_index
	return oldest_index

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
	if _sfx_bus_index >= 0:
		AudioServer.set_bus_mute(
			_sfx_bus_index, bus_mute_for_enabled(_sfx_enabled)
		)

func _save_audio_preferences() -> void:
	SaveDataScript.save_audio_preferences(_sfx_enabled)

func _on_new_best_timeout() -> void:
	play_sfx(Config.SoundId.NEW_BEST)

func _on_double_clear_timeout() -> void:
	play_sfx(Config.SoundId.CLEAR, _double_clear_pitch)

func _warn_asset(path: String, reason: String) -> void:
	if _warned_assets.has(path):
		return
	_warned_assets[path] = true
	push_warning("Ses varlığı atlandı (%s): %s." % [path, reason])
