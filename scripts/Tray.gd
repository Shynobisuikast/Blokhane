# scripts/Tray.gd
class_name Tray
extends Control

var pieces: Array = []
var _panel_style: StyleBoxFlat
var _piece_styles: Dictionary = {}

func _init() -> void:
	_panel_style = _make_style_box(Config.PANEL, Config.TRAY_CARD_RADIUS)

func set_pieces(p: Array) -> void:
	pieces.clear()
	for slot: int in range(Config.TRAY_SLOTS):
		if slot < p.size() and p[slot] is Dictionary:
			pieces.append((p[slot] as Dictionary).duplicate(true))
		else:
			pieces.append(null)
	queue_redraw()

func remove_piece(slot: int) -> void:
	if slot < 0 or slot >= pieces.size():
		return
	pieces[slot] = null
	queue_redraw()

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
		draw_style_box(_panel_style, slot_rect(slot))
		if slot < pieces.size() and pieces[slot] != null:
			_draw_piece(slot, pieces[slot] as Dictionary)

func _draw_piece(slot: int, piece: Dictionary) -> void:
	var shape: Array[Vector2i] = piece["shape"]
	var origin: Vector2 = piece_cell_origin(slot)
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
			Config.color_for(color_id),
			Config.TRAY_CELL_RADIUS
		)
	return _piece_styles[color_id] as StyleBoxFlat
