# scripts/CellDrawing.gd
class_name CellDrawing
extends RefCounted

static var _clear_styles: Dictionary = {}

static func draw_clear_cell(canvas: CanvasItem, original_rect: Rect2, color_id: int, progress: float) -> void:
	var scale: float = 1.0 - progress
	if scale <= 0.0:
		return
	if not _clear_styles.has(color_id):
		_clear_styles[color_id] = StyleBoxFlat.new()
	var style: StyleBoxFlat = _clear_styles[color_id]
	var tint: Color = Config.color_for(color_id)
	tint.a = scale
	style.bg_color = tint
	style.set_corner_radius_all(roundi(Config.CELL_RADIUS * scale))
	var size: Vector2 = original_rect.size * scale
	var rect: Rect2 = Rect2(original_rect.get_center() - size / 2.0, size)
	canvas.draw_style_box(style, rect)

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
