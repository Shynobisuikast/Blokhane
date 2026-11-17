# scripts/Pieces.gd
class_name Pieces
extends RefCounted

static var _catalog: Array[Dictionary] = []

static func all() -> Array[Dictionary]:
	if _catalog.is_empty():
		_catalog = _build_catalog()
	var copies: Array[Dictionary] = []
	for piece: Dictionary in _catalog:
		copies.append(piece.duplicate(true))
	return copies

static func size_of(shape: Array[Vector2i]) -> Vector2i:
	if shape.is_empty():
		return Vector2i.ZERO
	var min_x: int = shape[0].x
	var min_y: int = shape[0].y
	var max_x: int = shape[0].x
	var max_y: int = shape[0].y
	for cell: Vector2i in shape:
		min_x = mini(min_x, cell.x)
		min_y = mini(min_y, cell.y)
		max_x = maxi(max_x, cell.x)
		max_y = maxi(max_y, cell.y)
	return Vector2i(max_x - min_x + 1, max_y - min_y + 1)

static func _build_catalog() -> Array[Dictionary]:
	var catalog: Array[Dictionary] = []
	catalog.append(_piece("dot", [Vector2i(0, 0)], 1))
	catalog.append(_piece("h2", [Vector2i(0, 0), Vector2i(1, 0)], 4))
	catalog.append(_piece("v2", [Vector2i(0, 0), Vector2i(0, 1)], 3))
	catalog.append(_piece("h3", [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], 2))
	catalog.append(_piece("v3", [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)], 5))
	catalog.append(_piece("h4", [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)], 4))
	catalog.append(_piece("v4", [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)], 1))
	catalog.append(_piece("sq2", [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)], 2))
	catalog.append(_piece("sq3", [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1),
		Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2),
	], 5))
	catalog.append(_piece("c1", [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)], 3))
	catalog.append(_piece("c2", [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)], 3))
	catalog.append(_piece("c3", [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)], 3))
	catalog.append(_piece("c4", [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)], 3))
	catalog.append(_piece("l", [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)], 1))
	catalog.append(_piece("j", [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(0, 2)], 2))
	catalog.append(_piece("t", [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)], 4))
	catalog.append(_piece("z", [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)], 5))
	catalog.append(_piece("s", [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)], 3))
	return catalog

static func _piece(piece_id: String, shape: Array[Vector2i], color_id: int) -> Dictionary:
	return {"id": piece_id, "shape": shape, "color_id": color_id}
