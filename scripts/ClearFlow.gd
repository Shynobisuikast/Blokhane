# scripts/ClearFlow.gd
class_name ClearFlow
extends RefCounted

func capture_and_clear(model: BoardModel, lines: Dictionary) -> Dictionary:
	var cleared_cells: Dictionary = {}
	var rows: Array[int] = lines["rows"]
	var columns: Array[int] = lines["cols"]

	for row: int in rows:
		for column: int in range(Config.BOARD_SIZE):
			var cell: Vector2i = Vector2i(column, row)
			cleared_cells[cell] = model.get_cell(cell)
	for column: int in columns:
		for row: int in range(Config.BOARD_SIZE):
			var cell: Vector2i = Vector2i(column, row)
			cleared_cells[cell] = model.get_cell(cell)

	if not cleared_cells.is_empty():
		model.clear_lines()
	return cleared_cells
