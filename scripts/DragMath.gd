# scripts/DragMath.gd
class_name DragMath
extends RefCounted

static func piece_top_left(
	pointer: Vector2,
	shape: Array[Vector2i],
	drag_offset_y: float
) -> Vector2:
	var shape_size: Vector2i = Pieces.size_of(shape)
	var piece_extent: Vector2 = Vector2(
		shape_size.x * Config.CELL_SIZE + maxi(shape_size.x - 1, 0) * Config.GAP,
		shape_size.y * Config.CELL_SIZE + maxi(shape_size.y - 1, 0) * Config.GAP
	)
	return Vector2(
		pointer.x - piece_extent.x / 2.0,
		pointer.y - drag_offset_y - piece_extent.y
	)

static func snap_origin(top_left: Vector2, board_view: BoardView) -> Vector2i:
	var first_cell_center: Vector2 = top_left + Vector2(
		Config.CELL_SIZE / 2.0,
		Config.CELL_SIZE / 2.0
	)
	var cell: Vector2i = board_view.local_to_cell(first_cell_center)
	if cell != Vector2i(-1, -1):
		return cell

	var grid_origin: Vector2 = board_view.cell_to_local(Vector2i.ZERO)
	var cell_step: float = float(Config.CELL_SIZE + Config.GAP)
	var relative_position: Vector2 = (first_cell_center - grid_origin) / cell_step
	return Vector2i(roundi(relative_position.x), roundi(relative_position.y))
