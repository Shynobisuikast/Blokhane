# scripts/BoardView.gd
class_name BoardView
extends Control

const CellDrawingScript = preload("res://scripts/CellDrawing.gd")

var model: BoardModel
var _panel_style: StyleBoxFlat
var _empty_style: StyleBoxFlat
var _highlight_style: StyleBoxFlat
var _ghost_shadow_style: StyleBoxFlat
var _filled_styles: Dictionary = {}
var _ghost_styles: Dictionary = {}
var _preview_cells: Array[Vector2i] = []
var _preview_color_id: int = 0
var _preview_rows: Array[int] = []
var _preview_columns: Array[int] = []
var _clear_cells: Dictionary = {}
var _clear_progress: float = 1.0

func _ready() -> void:
	ThemeAccess.connect_changed(_on_theme_changed)
	_apply_theme()

func _on_theme_changed() -> void:
	_apply_theme()
	queue_redraw()

func _apply_theme() -> void:
	_panel_style = _make_style_box(ThemeAccess.color("PANEL"), Config.PANEL_RADIUS)
	_empty_style = _make_style_box(ThemeAccess.color("CELL_EMPTY"), Config.CELL_RADIUS)
	_highlight_style = _make_style_box(Config.LINE_HIGHLIGHT, Config.CELL_RADIUS)
	_ghost_shadow_style = _make_style_box(
		Color(0.0, 0.0, 0.0, Config.GHOST_SHADOW_ALPHA),
		Config.CELL_RADIUS
	)
	_filled_styles.clear()
	_ghost_styles.clear()

func set_model(m: BoardModel) -> void:
	model = m
	refresh()

func refresh() -> void:
	queue_redraw()

func set_preview(cells: Array[Vector2i], color_id: int, rows: Array[int], cols: Array[int]) -> void:
	if (
		_preview_cells == cells
		and _preview_color_id == color_id
		and _preview_rows == rows
		and _preview_columns == cols
	):
		return
	_preview_cells = cells.duplicate()
	_preview_color_id = color_id
	_preview_rows = rows.duplicate()
	_preview_columns = cols.duplicate()
	queue_redraw()

func clear_preview() -> void:
	if (
		_preview_cells.is_empty()
		and _preview_color_id == 0
		and _preview_rows.is_empty()
		and _preview_columns.is_empty()
	):
		return
	_preview_cells.clear()
	_preview_color_id = 0
	_preview_rows.clear()
	_preview_columns.clear()
	queue_redraw()

func play_clear(cells: Dictionary, duration: float) -> void:
	if cells.is_empty():
		return
	_clear_cells = cells.duplicate()
	_clear_progress = 0.0
	queue_redraw()
	var tween: Tween = create_tween()
	tween.tween_method(_set_clear_progress, 0.0, 1.0, duration)
	await tween.finished
	_clear_cells.clear()
	_clear_progress = 1.0
	queue_redraw()

func _set_clear_progress(progress: float) -> void:
	_clear_progress = progress
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
				CellDrawingScript.draw_filled_cell_bevel(self, cell_rect, Config.CELL_RADIUS)

	for cell: Vector2i in _clear_cells:
		var cell_rect: Rect2 = Rect2(
			cell_to_local(cell),
			Vector2(Config.CELL_SIZE, Config.CELL_SIZE)
		)
		CellDrawingScript.draw_clear_cell(self, cell_rect, _clear_cells[cell], _clear_progress)

	for cell: Vector2i in _preview_cells:
		var shadow_rect: Rect2 = Rect2(
			cell_to_local(cell) + Vector2(0.0, Config.GHOST_SHADOW_OFFSET_Y),
			Vector2(Config.CELL_SIZE, Config.CELL_SIZE)
		)
		draw_style_box(_ghost_shadow_style, shadow_rect)

	if not _preview_cells.is_empty():
		var ghost_style: StyleBoxFlat = _style_for_ghost_color(_preview_color_id)
		for cell: Vector2i in _preview_cells:
			var ghost_rect: Rect2 = Rect2(
				cell_to_local(cell),
				Vector2(Config.CELL_SIZE, Config.CELL_SIZE)
			)
			draw_style_box(ghost_style, ghost_rect)

	for row: int in range(Config.BOARD_SIZE):
		for column: int in range(Config.BOARD_SIZE):
			if _preview_rows.has(row) or _preview_columns.has(column):
				var highlight_rect: Rect2 = Rect2(
					cell_to_local(Vector2i(column, row)),
					Vector2(Config.CELL_SIZE, Config.CELL_SIZE)
				)
				draw_style_box(_highlight_style, highlight_rect)

func _style_for_ghost_color(color_id: int) -> StyleBoxFlat:
	if not _ghost_styles.has(color_id):
		var ghost_color: Color = ThemeAccess.color_for(color_id)
		ghost_color.a = Config.GHOST_ALPHA
		_ghost_styles[color_id] = _make_style_box(ghost_color, Config.CELL_RADIUS)
	return _ghost_styles[color_id] as StyleBoxFlat

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
			ThemeAccess.color_for(color_id),
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
