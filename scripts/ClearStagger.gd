# scripts/ClearStagger.gd
class_name ClearStagger
extends RefCounted

static func calculate_delays(
	cleared_cells: Array[Vector2i],
	placed_cells: Array[Vector2i],
	requested_stagger: float,
	clear_duration: float,
	maximum_duration: float
) -> Dictionary:
	var distances: Dictionary = {}
	var maximum_distance: int = 0
	for cell: Vector2i in cleared_cells:
		var distance: int = _nearest_manhattan_distance(cell, placed_cells)
		distances[cell] = distance
		maximum_distance = maxi(maximum_distance, distance)

	var effective_stagger: float = maxf(requested_stagger, 0.0)
	if maximum_distance > 0:
		var available_stagger_time: float = maxf(maximum_duration - clear_duration, 0.0)
		effective_stagger = minf(
			effective_stagger,
			available_stagger_time / maximum_distance
		)

	var delays: Dictionary = {}
	for cell: Vector2i in distances:
		delays[cell] = int(distances[cell]) * effective_stagger
	return delays

static func maximum_delay(delays: Dictionary) -> float:
	var result: float = 0.0
	for cell: Vector2i in delays:
		result = maxf(result, float(delays[cell]))
	return result

static func _nearest_manhattan_distance(
	cell: Vector2i,
	placed_cells: Array[Vector2i]
) -> int:
	var nearest_distance: int = 0
	var has_nearest_distance: bool = false
	for placed_cell: Vector2i in placed_cells:
		var distance: int = absi(cell.x - placed_cell.x) + absi(cell.y - placed_cell.y)
		if not has_nearest_distance or distance < nearest_distance:
			nearest_distance = distance
			has_nearest_distance = true
	return nearest_distance if has_nearest_distance else 0
