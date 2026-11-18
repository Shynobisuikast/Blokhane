# scripts/GameRules.gd
class_name GameRules
extends RefCounted

static func is_game_over(board: BoardModel, remaining_shapes: Array) -> bool:
	if remaining_shapes.is_empty():
		return false
	for shape: Array[Vector2i] in remaining_shapes:
		if board.can_fit_anywhere(shape):
			return false
	return true
