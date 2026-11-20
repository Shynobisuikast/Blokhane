# scripts/Tray.gd
class_name Tray
extends Control

var pieces: Array = []
var _hidden_slots: Array[bool] = []
var _panel_style: StyleBoxFlat
var _piece_styles: Dictionary = {}
var _shake_tween: Tween
var _shaking_slot: int = -1
var _shake_offset: float = 0.0

func _ready() -> void:
	ThemeAccess.connect_changed(_on_theme_changed)
	_apply_theme()

func _on_theme_changed() -> void:
	_apply_theme()
	queue_redraw()

func _apply_theme() -> void:
	_panel_style = _make_style_box(ThemeAccess.color("PANEL"), Config.TRAY_CARD_RADIUS)
	_piece_styles.clear()

func set_pieces(p: Array) -> void:
	pieces.clear()
	_hidden_slots.clear()
	for slot: int in range(Config.TRAY_SLOTS):
		_hidden_slots.append(false)
		if slot < p.size() and p[slot] is Dictionary:
			pieces.append((p[slot] as Dictionary).duplicate(true))
		else:
			pieces.append(null)
	queue_redraw()

func remove_piece(slot: int) -> void:
	if slot < 0 or slot >= pieces.size():
		return
	pieces[slot] = null
	_hidden_slots[slot] = false
	queue_redraw()

func set_slot_hidden(slot: int, should_hide: bool) -> void:
	if slot < 0 or slot >= _hidden_slots.size() or _hidden_slots[slot] == should_hide:
		return
	_hidden_slots[slot] = should_hide
	queue_redraw()

func play_return_shake(slot: int) -> void:
	if slot < 0 or slot >= Config.TRAY_SLOTS:
		return
	if _shake_tween != null and _shake_tween.is_running():
		_shake_tween.kill()
	_shaking_slot = slot
	_shake_offset = 0.0
	_shake_tween = create_tween()
	_shake_tween.tween_method(
		_set_shake_progress.bind(slot),
		0.0,
		1.0,
		Config.RETURN_SHAKE_TIME
	)
	_shake_tween.finished.connect(_finish_return_shake.bind(slot), CONNECT_ONE_SHOT)

func _set_shake_progress(progress: float, slot: int) -> void:
	if slot != _shaking_slot:
		return
	var phase: float = progress * Config.RETURN_SHAKE_CYCLES * TAU
	_shake_offset = sin(phase) * Config.RETURN_SHAKE_DISTANCE
	queue_redraw()

func _finish_return_shake(slot: int) -> void:
	if slot != _shaking_slot:
		return
	_shaking_slot = -1
	_shake_offset = 0.0
	_shake_tween = null
	queue_redraw()

func slot_at(pos: Vector2) -> int:
	for slot: int in range(Config.TRAY_SLOTS):
		if slot_rect(slot).has_point(pos):
			return slot
	return -1

func slot_rect(slot: int) -> Rect2:
	if slot < 0 or slot >= Config.TRAY_SLOTS:
		return Rect2()
	return Rect2(
		Vector2(Config.TRAY_CARD_X[slot], Config.TRAY_Y),
		Vector2(Config.TRAY_CARD_SIZE, Config.TRAY_CARD_SIZE)
	)

func piece_cell_origin(slot: int) -> Vector2:
	if slot < 0 or slot >= pieces.size() or pieces[slot] == null:
		return Vector2.ZERO
	var shape: Array[Vector2i] = pieces[slot]["shape"]
	var shape_size: Vector2i = Pieces.size_of(shape)
	var extent: Vector2 = Vector2(
		shape_size.x * Config.TRAY_CELL + maxi(shape_size.x - 1, 0) * Config.TRAY_GAP,
		shape_size.y * Config.TRAY_CELL + maxi(shape_size.y - 1, 0) * Config.TRAY_GAP
	)
	var card: Rect2 = slot_rect(slot)
	return card.position + (card.size - extent) / 2.0

func _draw() -> void:
	for slot: int in range(Config.TRAY_SLOTS):
		var card_rect: Rect2 = slot_rect(slot)
		card_rect.position += _slot_draw_offset(slot)
		draw_style_box(_panel_style, card_rect)
		if slot < pieces.size() and pieces[slot] != null and not _hidden_slots[slot]:
			_draw_piece(slot, pieces[slot] as Dictionary)

func _slot_draw_offset(slot: int) -> Vector2:
	if slot != _shaking_slot:
		return Vector2.ZERO
	return Vector2(_shake_offset, 0.0)

func _draw_piece(slot: int, piece: Dictionary) -> void:
	var shape: Array[Vector2i] = piece["shape"]
	var origin: Vector2 = piece_cell_origin(slot) + _slot_draw_offset(slot)
	var color_id: int = piece["color_id"]
	for cell: Vector2i in shape:
		var cell_position: Vector2 = origin + Vector2(
			cell.x * (Config.TRAY_CELL + Config.TRAY_GAP),
			cell.y * (Config.TRAY_CELL + Config.TRAY_GAP)
		)
		var cell_rect: Rect2 = Rect2(cell_position, Vector2(Config.TRAY_CELL, Config.TRAY_CELL))
		draw_style_box(_style_for_color(color_id), cell_rect)
		CellDrawing.draw_filled_cell_bevel(self, cell_rect, Config.TRAY_CELL_RADIUS)

func _make_style_box(color: Color, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style

func _style_for_color(color_id: int) -> StyleBoxFlat:
	if not _piece_styles.has(color_id):
		_piece_styles[color_id] = _make_style_box(
			ThemeAccess.color_for(color_id),
			Config.TRAY_CELL_RADIUS
		)
	return _piece_styles[color_id] as StyleBoxFlat
