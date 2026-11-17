# scripts/DragLayer.gd
class_name DragLayer
extends Control

var _piece: Dictionary = {}
var top_left: Vector2 = Vector2.ZERO
var cell_size: float = Config.CELL_SIZE
var gap: float = Config.GAP
var corner_radius: float = Config.CELL_RADIUS
var _styles: Dictionary = {}

func show_piece(piece: Dictionary, origin: Vector2) -> void:
	_piece = piece.duplicate(true)
	cell_size = Config.CELL_SIZE
	gap = Config.GAP
	corner_radius = Config.CELL_RADIUS
	set_top_left(origin)
	queue_redraw()

func set_top_left(origin: Vector2) -> void:
	if top_left == origin:
		return
	top_left = origin
	queue_redraw()

func set_cell_size(value: float) -> void:
	if is_equal_approx(cell_size, value):
		return
	cell_size = value
	queue_redraw()

func set_gap(value: float) -> void:
	if is_equal_approx(gap, value):
		return
	gap = value
	queue_redraw()

func set_corner_radius(value: float) -> void:
	if is_equal_approx(corner_radius, value):
		return
	corner_radius = value
	queue_redraw()

func clear_piece() -> void:
	_piece.clear()
	queue_redraw()

func _draw() -> void:
	if _piece.is_empty():
		return
	var shape: Array[Vector2i] = _piece["shape"]
	var color_id: int = _piece["color_id"]
	for cell: Vector2i in shape:
		var cell_position: Vector2 = top_left + Vector2(
			cell.x * (cell_size + gap),
			cell.y * (cell_size + gap)
		)
		var cell_rect: Rect2 = Rect2(cell_position, Vector2(cell_size, cell_size))
		draw_style_box(_style_for_color(color_id), cell_rect)
		CellDrawing.draw_filled_cell_bevel(self, cell_rect, corner_radius)

func _style_for_color(color_id: int) -> StyleBoxFlat:
	if not _styles.has(color_id):
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Config.color_for(color_id)
		_styles[color_id] = style
	var result: StyleBoxFlat = _styles[color_id]
	result.set_corner_radius_all(roundi(corner_radius))
	return result
