# scripts/GameSession.gd
class_name GameSession
extends RefCounted

const ScoreModelScript = preload("res://scripts/ScoreModel.gd")
const GameRulesScript = preload("res://scripts/GameRules.gd")
const SaveDataScript = preload("res://scripts/SaveData.gd")

var score_model: Variant = ScoreModelScript.new()
var _board_model: BoardModel
var _tray: Tray
var _board_view: BoardView
var _drag_layer: DragLayer
var _hud: Control
var _game_over_screen: Control
var _piece_generator: PieceGenerator
var _rng: RandomNumberGenerator
var _record_before_run: int = 0

func configure(
	board_model: BoardModel,
	tray: Tray,
	board_view: BoardView,
	drag_layer: DragLayer,
	hud: Control,
	game_over_screen: Control,
	piece_generator: PieceGenerator,
	rng: RandomNumberGenerator
) -> void:
	_board_model = board_model
	_tray = tray
	_board_view = board_view
	_drag_layer = drag_layer
	_hud = hud
	_game_over_screen = game_over_screen
	_piece_generator = piece_generator
	_rng = rng

func start() -> void:
	score_model.best = SaveDataScript.load_best()
	_record_before_run = score_model.best
	restart()

func restart() -> void:
	_record_before_run = score_model.best
	_board_model.reset()
	_tray.set_pieces([])
	_board_view.clear_preview()
	_board_view.refresh()
	_drag_layer.clear_piece()
	score_model.reset()

	_hud.call("reset_score", score_model.score, score_model.best, score_model.streak)
	_game_over_screen.hide()
	_tray.set_pieces(_piece_generator.generate_triplet(_board_model, _rng))

func refill_if_empty() -> bool:
	for piece: Variant in _tray.pieces:
		if piece != null:
			return false
	_tray.set_pieces(_piece_generator.generate_triplet(_board_model, _rng))
	return true


func check_game_over() -> Dictionary:
	var remaining_shapes: Array = []
	for piece: Variant in _tray.pieces:
		if piece != null:
			remaining_shapes.append(piece["shape"])
	if not GameRulesScript.is_game_over(_board_model, remaining_shapes):
		return {}

	var is_new_best: bool = score_model.score > _record_before_run
	if is_new_best:
		score_model.best = score_model.score
		_record_before_run = score_model.score
		SaveDataScript.save_best(score_model.best)
	_hud.call("update_score", score_model.score, score_model.best, score_model.streak, 1.0, 0)
	_game_over_screen.call("show_result", score_model.score, is_new_best)
	return {"is_new_best": is_new_best, "final_score": score_model.score}
