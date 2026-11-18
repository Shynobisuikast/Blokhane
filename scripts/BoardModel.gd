# scripts/BoardModel.gd
class_name BoardModel
extends RefCounted

var _cells: Array[Array] = []

func _init() -> void:
	reset()

func reset() -> void:
	_cells.clear()
	for _row_index: int in range(Config.BOARD_SIZE):
		var row: Array[int] = []
		for _column_index: int in range(Config.BOARD_SIZE):
			row.append(0)
		_cells.append(row)

func get_cell(pos: Vector2i) -> int:
	if pos.x < 0 or pos.y < 0 or pos.x >= Config.BOARD_SIZE or pos.y >= Config.BOARD_SIZE:
		return -1
	return _cells[pos.y][pos.x]

func can_place(shape: Array[Vector2i], origin: Vector2i) -> bool:
	for offset: Vector2i in shape:
		var target: Vector2i = origin + offset
		if get_cell(target) != 0:
			return false
	return true

func place(shape: Array[Vector2i], origin: Vector2i, color_id: int) -> bool:
	if color_id <= 0 or not can_place(shape, origin):
		return false
	for offset: Vector2i in shape:
		var target: Vector2i = origin + offset
		_cells[target.y][target.x] = color_id
	return true

func find_full_lines() -> Dictionary:
	var full_rows: Array[int] = []
	var full_columns: Array[int] = []

	for row_index: int in range(Config.BOARD_SIZE):
		var is_full: bool = true
		for column_index: int in range(Config.BOARD_SIZE):
			if _cells[row_index][column_index] == 0:
				is_full = false
				break
		if is_full:
			full_rows.append(row_index)

	for column_index: int in range(Config.BOARD_SIZE):
		var is_full: bool = true
		for row_index: int in range(Config.BOARD_SIZE):
			if _cells[row_index][column_index] == 0:
				is_full = false
				break
		if is_full:
			full_columns.append(column_index)

	return {"rows": full_rows, "cols": full_columns}

func clear_lines() -> Dictionary:
	var lines: Dictionary = find_full_lines()
	var rows: Array[int] = lines["rows"]
	var columns: Array[int] = lines["cols"]
	var cells_cleared: int = 0

	for row_index: int in range(Config.BOARD_SIZE):
		for column_index: int in range(Config.BOARD_SIZE):
			if rows.has(row_index) or columns.has(column_index):
				if _cells[row_index][column_index] != 0:
					cells_cleared += 1
				_cells[row_index][column_index] = 0

	return {"rows": rows, "cols": columns, "cells_cleared": cells_cleared}

func can_fit_anywhere(shape: Array[Vector2i]) -> bool:
	for row_index: int in range(Config.BOARD_SIZE):
		for column_index: int in range(Config.BOARD_SIZE):
			if can_place(shape, Vector2i(column_index, row_index)):
				return true
	return false

func preview_complete_lines(shape: Array[Vector2i], origin: Vector2i) -> Dictionary:
	var empty_result: Dictionary = {"rows": [], "cols": []}
	if not can_place(shape, origin):
		return empty_result

	var placed_cells: Dictionary = {}
	for offset: Vector2i in shape:
		placed_cells[origin + offset] = true

	var complete_rows: Array[int] = []
	var complete_columns: Array[int] = []
	for row_index: int in range(Config.BOARD_SIZE):
		var row_is_complete: bool = true
		for column_index: int in range(Config.BOARD_SIZE):
			var cell: Vector2i = Vector2i(column_index, row_index)
			if _cells[row_index][column_index] == 0 and not placed_cells.has(cell):
				row_is_complete = false
				break
		if row_is_complete:
			complete_rows.append(row_index)

	for column_index: int in range(Config.BOARD_SIZE):
		var column_is_complete: bool = true
		for row_index: int in range(Config.BOARD_SIZE):
			var cell: Vector2i = Vector2i(column_index, row_index)
			if _cells[row_index][column_index] == 0 and not placed_cells.has(cell):
				column_is_complete = false
				break
		if column_is_complete:
			complete_columns.append(column_index)

	return {"rows": complete_rows, "cols": complete_columns}
