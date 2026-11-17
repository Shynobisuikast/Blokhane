# scripts/CellDrawing.gd
class_name CellDrawing
extends RefCounted

static func draw_filled_cell_bevel(canvas: CanvasItem, rect: Rect2, radius: float) -> void:
	var left: float = rect.position.x + radius
	var right: float = rect.end.x - radius
	canvas.draw_line(
		Vector2(left, rect.position.y + 1.5),
		Vector2(right, rect.position.y + 1.5),
		Color(1.0, 1.0, 1.0, 0.38),
		3.0
	)
	canvas.draw_line(
		Vector2(left, rect.end.y - 1.5),
		Vector2(right, rect.end.y - 1.5),
		Color(0.0, 0.0, 0.0, 0.30),
		3.0
	)
