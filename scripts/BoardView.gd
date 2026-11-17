# scripts/BoardView.gd
class_name BoardView
extends Control

var model: BoardModel
var _panel_style: StyleBoxFlat
var _empty_style: StyleBoxFlat
var _filled_styles: Dictionary = {}

func _init() -> void:
	_panel_style = _make_style_box(Config.PANEL, Config.PANEL_RADIUS)
	_empty_style = _make_style_box(Config.CELL_EMPTY, Config.CELL_RADIUS)

func set_model(m: BoardModel) -> void:
	model = m
	refresh()

func refresh() -> void:
	queue_redraw()

func cell_to_local(cell: Vector2i) -> Vector2:
	return _grid_origin() + Vector2(
		cell.x * (Config.CELL_SIZE + Config.GAP),
		cell.y * (Config.CELL_SIZE + Config.GAP)
	)

func local_to_cell(p: Vector2) -> Vector2i:
	var relative_position: Vector2 = p - _grid_origin()
	if relative_position.x < 0.0 or relative_position.y < 0.0:
		return Vector2i(-1, -1)

	var cell_step: int = Config.CELL_SIZE + Config.GAP
	var column: int = int(relative_position.x / cell_step)
	var row: int = int(relative_position.y / cell_step)
	if column >= Config.BOARD_SIZE or row >= Config.BOARD_SIZE:
		return Vector2i(-1, -1)

	var within_cell_x: float = relative_position.x - column * cell_step
	var within_cell_y: float = relative_position.y - row * cell_step
	if within_cell_x >= Config.CELL_SIZE or within_cell_y >= Config.CELL_SIZE:
		return Vector2i(-1, -1)
	return Vector2i(column, row)

func _draw() -> void:
	draw_style_box(_panel_style, Rect2(Config.BOARD_PANEL_ORIGIN, _panel_size()))
	if model == null:
		return

	for row: int in range(Config.BOARD_SIZE):
		for column: int in range(Config.BOARD_SIZE):
			var cell: Vector2i = Vector2i(column, row)
			var cell_rect: Rect2 = Rect2(
				cell_to_local(cell),
				Vector2(Config.CELL_SIZE, Config.CELL_SIZE)
			)
			var color_id: int = model.get_cell(cell)
			if color_id == 0:
				draw_style_box(_empty_style, cell_rect)
				_draw_empty_cell_shadow(cell_rect)
			else:
				draw_style_box(_style_for_color(color_id), cell_rect)
				_draw_filled_cell_bevel(cell_rect)

func _grid_origin() -> Vector2:
	return Config.BOARD_PANEL_ORIGIN + Vector2(Config.PANEL_PADDING, Config.PANEL_PADDING)

func _panel_size() -> Vector2:
	var grid_extent: float = float(
		Config.BOARD_SIZE * Config.CELL_SIZE
		+ (Config.BOARD_SIZE - 1) * Config.GAP
	)
	return Vector2(
		grid_extent + Config.PANEL_PADDING + Config.PANEL_PADDING,
		grid_extent + Config.PANEL_PADDING + Config.PANEL_PADDING
	)

func _make_style_box(color: Color, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style

func _style_for_color(color_id: int) -> StyleBoxFlat:
	if not _filled_styles.has(color_id):
		_filled_styles[color_id] = _make_style_box(
			Config.color_for(color_id),
			Config.CELL_RADIUS
		)
	return _filled_styles[color_id] as StyleBoxFlat

func _draw_empty_cell_shadow(rect: Rect2) -> void:
	var y: float = rect.position.y + 2.0
	var inset: float = Config.CELL_RADIUS
	draw_line(
		Vector2(rect.position.x + inset, y),
		Vector2(rect.end.x - inset, y),
		Color(0.0, 0.0, 0.0, 0.22),
		2.0
	)

func _draw_filled_cell_bevel(rect: Rect2) -> void:
	var inset: float = Config.CELL_RADIUS
	var left: float = rect.position.x + inset
	var right: float = rect.end.x - inset
	draw_line(
		Vector2(left, rect.position.y + 1.5),
		Vector2(right, rect.position.y + 1.5),
		Color(1.0, 1.0, 1.0, 0.38),
		3.0
	)
	draw_line(
		Vector2(left, rect.end.y - 1.5),
		Vector2(right, rect.end.y - 1.5),
		Color(0.0, 0.0, 0.0, 0.30),
		3.0
	)
