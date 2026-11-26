# scripts/BestScoreStore.gd
class_name BestScoreStore
extends RefCounted

var best: int = 0

var _save_path: String
var _best_at_run_start: int = 0

func _init(save_path: String = SaveData.SAVE_PATH) -> void:
	_save_path = save_path

func load_from_disk() -> void:
	best = SaveData.load_best(_save_path)

func begin_run() -> void:
	_best_at_run_start = best

func submit(score: int) -> void:
	if score <= best:
		return
	best = score
	SaveData.save_best(best, _save_path)

func is_new_best(score: int) -> bool:
	return score > _best_at_run_start

func reset() -> void:
	best = 0
	_best_at_run_start = 0
	SaveData.reset_best(_save_path)
