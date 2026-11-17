# scripts/PieceGenerator.gd
class_name PieceGenerator
extends RefCounted

func generate_triplet(board: BoardModel, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var catalog: Array[Dictionary] = Pieces.all()
	var fitting: Array[Dictionary] = []
	for piece: Dictionary in catalog:
		var shape: Array[Vector2i] = piece["shape"]
		if board.can_fit_anywhere(shape):
			fitting.append(piece)

	var triplet: Array[Dictionary] = []
	if fitting.is_empty():
		for _slot: int in range(Config.TRAY_SLOTS):
			triplet.append(_random_piece(catalog, rng))
		return triplet

	var guaranteed_piece: Dictionary = _random_piece(fitting, rng)
	var guaranteed_slot: int = rng.randi_range(0, Config.TRAY_SLOTS - 1)
	for slot: int in range(Config.TRAY_SLOTS):
		if slot == guaranteed_slot:
			triplet.append(guaranteed_piece)
		else:
			triplet.append(_random_piece(catalog, rng))
	return triplet

func _random_piece(candidates: Array[Dictionary], rng: RandomNumberGenerator) -> Dictionary:
	var index: int = rng.randi_range(0, candidates.size() - 1)
	return candidates[index].duplicate(true)
