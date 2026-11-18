# scripts/ScoreModel.gd
class_name ScoreModel
extends RefCounted

var score: int = 0
var best: int = 0
var streak: int = 0

func register_turn(placed_cells: int, lines_cleared: int) -> Dictionary:
	var gain: int = placed_cells
	var multiplier: float = 1.0
	if lines_cleared == 0:
		streak = 0
	else:
		streak += 1
		multiplier = minf(1.0 + Config.COMBO_STEP * (streak - 1), Config.COMBO_MAX)
		gain = roundi((placed_cells + Config.LINE_BONUS * lines_cleared * lines_cleared) * multiplier)

	score += gain
	best = maxi(best, score)
	return {"gain": gain, "multiplier": multiplier, "streak": streak, "score": score}

func reset() -> void:
	score = 0
	streak = 0
