# scripts/Game.gd
class_name Game
extends Control

signal piece_placed(cells: int)
signal triplet_refilled

enum DragState { IDLE, DRAGGING, RETURNING }

var _board_model: BoardModel
var _piece_generator: PieceGenerator = PieceGenerator.new()
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _board_view: BoardView
var _tray: Tray
var _drag_layer: DragLayer
var _dragged_piece: Dictionary = {}
var _dragged_slot: int = -1
var _drag_state: int = DragState.IDLE

func _ready() -> void:
	Input.emulate_mouse_from_touch = true

func configure(board_view: BoardView, tray: Tray, drag_layer: DragLayer) -> void:
	_board_view = board_view
	_tray = tray
	_drag_layer = drag_layer
	_board_model = BoardModel.new()
	_board_view.set_model(_board_model)

func start_game() -> void:
	_rng.randomize()
	_tray.set_pieces(_piece_generator.generate_triplet(_board_model, _rng))

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
	_drag_state = DragState.DRAGGING
	_tray.set_slot_hidden(slot, true)
	_drag_layer.show_piece(_dragged_piece, Vector2.ZERO)
	_move_drag(pointer)

func _move_drag(pointer: Vector2) -> void:
	if _drag_state != DragState.DRAGGING:
		return
	var layer_pointer: Vector2 = _convert_position(self, _drag_layer, pointer)
	var shape: Array[Vector2i] = _dragged_piece["shape"]
	_drag_layer.set_top_left(DragMath.piece_top_left(layer_pointer, shape))

func _drop_piece(pointer: Vector2) -> void:
	_move_drag(pointer)
	var board_top_left: Vector2 = _convert_position(_drag_layer, _board_view, _drag_layer.top_left)
	var shape: Array[Vector2i] = _dragged_piece["shape"]
	var origin: Vector2i = DragMath.snap_origin(board_top_left, _board_view)
	var color_id: int = _dragged_piece["color_id"]
	if not _board_model.place(shape, origin, color_id):
		_begin_return()
		return

	var placed_cells: int = shape.size()
	_tray.remove_piece(_dragged_slot)
	_board_view.refresh()
	_drag_layer.clear_piece()
	_clear_drag_state()
	piece_placed.emit(placed_cells)
	_refill_if_empty()

func _begin_return() -> void:
	if _drag_state != DragState.DRAGGING:
		return
	_drag_state = DragState.RETURNING
	var target: Vector2 = _convert_position(_tray, _drag_layer, _tray.piece_cell_origin(_dragged_slot))
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_method(_drag_layer.set_top_left, _drag_layer.top_left, target, Config.RETURN_TWEEN_TIME)
	tween.tween_method(_drag_layer.set_cell_size, Config.CELL_SIZE, Config.TRAY_CELL, Config.RETURN_TWEEN_TIME)
	tween.tween_method(_drag_layer.set_gap, Config.GAP, Config.TRAY_GAP, Config.RETURN_TWEEN_TIME)
	tween.tween_method(_drag_layer.set_corner_radius, Config.CELL_RADIUS, Config.TRAY_CELL_RADIUS, Config.RETURN_TWEEN_TIME)
	tween.finished.connect(_finish_return.bind(_dragged_slot), CONNECT_ONE_SHOT)

func _finish_return(slot: int) -> void:
	if _drag_state != DragState.RETURNING or slot != _dragged_slot:
		return
	_tray.set_slot_hidden(slot, false)
	_drag_layer.clear_piece()
	_clear_drag_state()

func _clear_drag_state() -> void:
	_drag_state = DragState.IDLE
	_dragged_slot = -1
	_dragged_piece.clear()

func _refill_if_empty() -> void:
	for piece: Variant in _tray.pieces:
		if piece != null:
			return
	_tray.set_pieces(_piece_generator.generate_triplet(_board_model, _rng))
	triplet_refilled.emit()

func _convert_position(source: Control, target: Control, local_position: Vector2) -> Vector2:
	var canvas_position: Vector2 = source.get_global_transform_with_canvas() * local_position
	return target.get_global_transform_with_canvas().affine_inverse() * canvas_position
