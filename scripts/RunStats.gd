# scripts/RunStats.gd
class_name RunStats
extends RefCounted

var lines_cleared_total: int = 0
var max_streak: int = 0

func register_turn(lines_cleared: int, streak: int) -> void:
	lines_cleared_total += lines_cleared
	max_streak = maxi(max_streak, streak)

func reset() -> void:
	lines_cleared_total = 0
	max_streak = 0
