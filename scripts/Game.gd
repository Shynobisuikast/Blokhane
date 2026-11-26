# scripts/Game.gd
class_name Game
extends Control

signal piece_placed(cells: int)
signal triplet_refilled
signal lines_cleared(count: int, gain: int, multiplier: float)
signal game_over(final_score: int, is_new_best: bool)

const GameSessionScript = preload("res://scripts/GameSession.gd")
const ClearFlowScript = preload("res://scripts/ClearFlow.gd")

enum DragState { IDLE, DRAGGING, RETURNING, CLEARING, GAME_OVER }

var _board_model: BoardModel
var _piece_generator: PieceGenerator = PieceGenerator.new()
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _board_view: BoardView
var _tray: Tray
var _drag_layer: DragLayer
var _hud: Variant
var _game_over_screen: Control
var _session: Variant = GameSessionScript.new()
var _clear_flow: Variant = ClearFlowScript.new()
var _dragged_piece: Dictionary = {}
var _dragged_slot: int = -1
var _drag_state: int = DragState.IDLE
var _preview_origin: Vector2i = Vector2i.ZERO
var _has_preview_origin: bool = false
var _touch_contact_active: bool = false
var _drag_started_touch: bool = false
var _return_tween: Tween
var _run_id: int = 0

func _ready() -> void:
	Input.emulate_mouse_from_touch = true

func configure(
	board_view: BoardView,
	tray: Tray,
	drag_layer: DragLayer,
	hud: Control,
	game_over_screen: Control
) -> void:
	_board_view = board_view
	_tray = tray
	_drag_layer = drag_layer
	_hud = hud
	_game_over_screen = game_over_screen
	_board_model = BoardModel.new()
	_board_view.set_model(_board_model)
	_session.configure(
		_board_model, _tray, _board_view, _drag_layer, _hud,
		_game_over_screen, _piece_generator, _rng
	)

func start_game() -> void:
	_rng.randomize()
	_session.start()

func restart() -> void:
	_run_id += 1
	_session.restart()
	_clear_drag_state()

func abandon_run() -> void:
	_run_id += 1
	cancel_drag()
	_clear_drag_state()

func reset_best() -> void:
	_session.reset_best()

func combo_streak() -> int:
	return int(_session.score_model.streak)

func cancel_drag() -> void:
	if _drag_state == DragState.DRAGGING:
		_tray.set_slot_hidden(_dragged_slot, false)
		_drag_layer.clear_piece()
		_clear_drag_state()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_touch_contact_active = event.pressed

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		if event.pressed:
			_begin_drag(event.position)
		elif _drag_state == DragState.DRAGGING:
			_drop_piece(event.position)
		accept_event()
	elif event is InputEventMouseMotion and _drag_state == DragState.DRAGGING:
		_move_drag(event.position)
		accept_event()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_MOUSE_EXIT:
		if _drag_state == DragState.DRAGGING:
			_begin_return()

func _begin_drag(pointer: Vector2) -> void:
	if _drag_state != DragState.IDLE:
		return
	var tray_position: Vector2 = _convert_position(self, _tray, pointer)
	var slot: int = _tray.slot_at(tray_position)
	if slot < 0 or slot >= _tray.pieces.size() or _tray.pieces[slot] == null:
		return
	_dragged_slot = slot
	_dragged_piece = (_tray.pieces[slot] as Dictionary).duplicate(true)
	_drag_started_touch = _touch_contact_active
	_drag_state = DragState.DRAGGING
	Audio.play_sfx(Config.SoundId.PICK)
	_has_preview_origin = false
	_tray.set_slot_hidden(slot, true)
	_drag_layer.show_piece(_dragged_piece, Vector2.ZERO)
	_move_drag(pointer)

func _move_drag(pointer: Vector2) -> void:
	if _drag_state != DragState.DRAGGING:
		return
	var layer_pointer: Vector2 = _convert_position(self, _drag_layer, pointer)
	var shape: Array[Vector2i] = _dragged_piece["shape"]
	var drag_offset_y: float = Config.DRAG_OFFSET_Y_TOUCH if _drag_started_touch else Config.DRAG_OFFSET_Y_MOUSE
	_drag_layer.set_top_left(DragMath.piece_top_left(layer_pointer, shape, drag_offset_y))
	var board_top_left: Vector2 = _convert_position(_drag_layer, _board_view, _drag_layer.top_left)
	var target_origin: Vector2i = DragMath.snap_origin(board_top_left, _board_view)
	if _has_preview_origin and target_origin == _preview_origin:
		return
	_preview_origin = target_origin
	_has_preview_origin = true
	if not _board_model.can_place(shape, target_origin):
		_board_view.clear_preview()
		return

	var preview_cells: Array[Vector2i] = []
	for offset: Vector2i in shape:
		preview_cells.append(target_origin + offset)
	var complete_lines: Dictionary = _board_model.preview_complete_lines(shape, target_origin)
	var color_id: int = _dragged_piece["color_id"]
	var rows: Array[int] = complete_lines["rows"]
	var columns: Array[int] = complete_lines["cols"]
	_board_view.set_preview(preview_cells, color_id, rows, columns)

func _drop_piece(pointer: Vector2) -> void:
	var run_id: int = _run_id
	_move_drag(pointer)
	var board_top_left: Vector2 = _convert_position(_drag_layer, _board_view, _drag_layer.top_left)
	var shape: Array[Vector2i] = _dragged_piece["shape"]
	var origin: Vector2i = DragMath.snap_origin(board_top_left, _board_view)
	var color_id: int = _dragged_piece["color_id"]
	if not _board_model.place(shape, origin, color_id):
		_tray.play_return_shake(_dragged_slot)
		_begin_return()
		return

	var placed_cells: Array[Vector2i] = []
	for offset: Vector2i in shape:
		placed_cells.append(origin + offset)
	_board_view.play_place(shape, origin, color_id)
	var placed_cell_count: int = shape.size()
	var lines: Dictionary = _board_model.find_full_lines()
	var line_count: int = lines["rows"].size() + lines["cols"].size()
	var cleared_cells: Dictionary = {}
	if line_count > 0:
		cleared_cells = _clear_flow.capture_and_clear(_board_model, lines)

	var score_result: Dictionary = _session.score_model.register_turn(placed_cell_count, line_count)
	_session.record_turn()

	var gain: int = score_result["gain"]
	var multiplier: float = score_result["multiplier"]
	_hud.update_score(
		_session.score_model.score,
		_session.score_model.best,
		score_result["streak"],
		multiplier,
		gain
	)

	_tray.remove_piece(_dragged_slot)
	_board_view.refresh()
	_drag_layer.clear_piece()
	_clear_drag_state()
	if line_count > 0:
		_drag_state = DragState.CLEARING
	piece_placed.emit(placed_cell_count)
	if line_count > 0:
		lines_cleared.emit(line_count, gain, multiplier)
		await _board_view.play_clear(cleared_cells, Config.CLEAR_TWEEN_TIME, placed_cells)
		if run_id != _run_id:
			return
		_drag_state = DragState.IDLE
	if _session.refill_if_empty():
		triplet_refilled.emit()
	var game_over_result: Dictionary = _session.check_game_over()
	if not game_over_result.is_empty():
		_drag_state = DragState.GAME_OVER
		game_over.emit(game_over_result["final_score"], game_over_result["is_new_best"])

func _begin_return() -> void:
	if _drag_state != DragState.DRAGGING:
		return
	_board_view.clear_preview()
	_drag_state = DragState.RETURNING
	Audio.play_sfx(Config.SoundId.INVALID)
	var target: Vector2 = _convert_position(_tray, _drag_layer, _tray.piece_cell_origin(_dragged_slot))
	if _return_tween != null and _return_tween.is_running():
		_return_tween.kill()
	_return_tween = create_tween().set_parallel(true)
	_return_tween.tween_method(_drag_layer.set_top_left, _drag_layer.top_left, target, Config.RETURN_TWEEN_TIME)
	_return_tween.tween_method(_drag_layer.set_cell_size, Config.CELL_SIZE, Config.TRAY_CELL, Config.RETURN_TWEEN_TIME)
	_return_tween.tween_method(_drag_layer.set_gap, Config.GAP, Config.TRAY_GAP, Config.RETURN_TWEEN_TIME)
	_return_tween.tween_method(_drag_layer.set_corner_radius, Config.CELL_RADIUS, Config.TRAY_CELL_RADIUS, Config.RETURN_TWEEN_TIME)
	_return_tween.finished.connect(_finish_return.bind(_dragged_slot), CONNECT_ONE_SHOT)

func _finish_return(slot: int) -> void:
	if _drag_state != DragState.RETURNING or slot != _dragged_slot:
		return
	_tray.set_slot_hidden(slot, false)
	_drag_layer.clear_piece()
	_clear_drag_state()

func _clear_drag_state() -> void:
	_board_view.clear_preview()
	_has_preview_origin = false
	_drag_state = DragState.IDLE
	_dragged_slot = -1
	_dragged_piece.clear()
	_drag_started_touch = false
	_touch_contact_active = false

func _convert_position(source: Control, target: Control, local_position: Vector2) -> Vector2:
	var canvas_position: Vector2 = source.get_global_transform_with_canvas() * local_position
	return target.get_global_transform_with_canvas().affine_inverse() * canvas_position
