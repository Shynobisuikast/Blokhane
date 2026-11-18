# scripts/Config.gd
class_name Config
extends RefCounted

const BOARD_SIZE: int = 8
const CELL_SIZE: int = 48
const GAP: int = 4
const SCREEN_SIZE: Vector2i = Vector2i(480, 860)

const BG: Color = Color("#0D1A38")
const PANEL: Color = Color("#14264F")
const CELL_EMPTY: Color = Color("#22407F")
const BLUE: Color = Color("#3F6BFF")
const TEAL: Color = Color("#1FB8A8")
const YELLOW: Color = Color("#F2B632")
const RED: Color = Color("#E8553E")
const GREEN: Color = Color("#3FA66B")
const TEXT: Color = Color("#F2EEE4")
const TEXT_SECONDARY: Color = Color("#9FB0D4")

const PANEL_RADIUS: int = 22
const CELL_RADIUS: int = 7
const GHOST_ALPHA: float = 0.40
const GHOST_SHADOW_ALPHA: float = 0.30
const GHOST_SHADOW_OFFSET_Y: float = 3.0
const LINE_HIGHLIGHT: Color = Color(1.0, 1.0, 1.0, 0.18)

const LINE_BONUS: int = 10
const COMBO_STEP: float = 0.5
const COMBO_MAX: float = 3.0
const CLEAR_TWEEN_TIME: float = 0.25
const SCORE_POP_TIME: float = 0.12
const SCORE_POP_SCALE: float = 1.15
const COMBO_POP_TIME: float = 0.12
const COMBO_POP_START_SCALE: float = 0.9
const COMBO_PILL_COLOR: Color = YELLOW
const COMBO_TEXT_COLOR: Color = BG
const COMBO_FONT_SIZE: int = 18
const COMBO_PILL_POSITION: Vector2 = Vector2(164, 154.5)
const COMBO_PILL_SIZE: Vector2 = Vector2(152, 35)
const COMBO_PILL_RADIUS: float = 17.5
const COMBO_TEXT_BASELINE_OFFSET: float = 5.5

const GAME_OVER_TITLE_POSITION: Vector2 = Vector2(22, 191.2)
const GAME_OVER_TITLE_SIZE: Vector2 = Vector2(436, 40)

const GAME_OVER_TITLE_FONT_SIZE: int = 54
const GAME_OVER_CARD_POSITION: Vector2 = Vector2(22, 215.5)
const GAME_OVER_CARD_SIZE: Vector2 = Vector2(436, 224)
const GAME_OVER_CARD_RADIUS: int = 22
const GAME_OVER_SCORE_LABEL_POSITION: Vector2 = Vector2(22, 255)
const GAME_OVER_SCORE_LABEL_SIZE: Vector2 = Vector2(436, 18)

const GAME_OVER_SCORE_VALUE_POSITION: Vector2 = Vector2(22, 348.5)
const GAME_OVER_SCORE_VALUE_SIZE: Vector2 = Vector2(436, 60)

const GAME_OVER_LABEL_FONT_SIZE: int = 18
const GAME_OVER_SCORE_FONT_SIZE: int = 80
const GAME_OVER_RECORD_POSITION: Vector2 = Vector2(187, 380.5)
const GAME_OVER_RECORD_SIZE: Vector2 = Vector2(106, 35)
const GAME_OVER_RECORD_RADIUS: float = 17.5
const GAME_OVER_RECORD_TEXT_BASELINE: float = 403.5
const GAME_OVER_RECORD_FONT_SIZE: int = 16
const GAME_OVER_STATS_LEFT_POSITION: Vector2 = Vector2(22, 459.5)
const GAME_OVER_STATS_RIGHT_POSITION: Vector2 = Vector2(246, 459.5)
const GAME_OVER_STATS_CARD_SIZE: Vector2 = Vector2(212, 96)
const GAME_OVER_STATS_CARD_RADIUS: int = 18
const GAME_OVER_STATS_LABEL_LEFT_BASELINE: Vector2 = Vector2(38, 488.5)
const GAME_OVER_STATS_LABEL_RIGHT_BASELINE: Vector2 = Vector2(262, 488.5)
const GAME_OVER_STATS_VALUE_LEFT_BASELINE: Vector2 = Vector2(38, 530)
const GAME_OVER_STATS_VALUE_RIGHT_BASELINE: Vector2 = Vector2(262, 530)
const GAME_OVER_STATS_TEXT_WIDTH: float = 180
const GAME_OVER_STATS_VALUE_FONT_SIZE: int = 46
const GAME_OVER_RESTART_POSITION: Vector2 = Vector2(22, 575.5)
const GAME_OVER_RESTART_SIZE: Vector2 = Vector2(436, 68)
const GAME_OVER_RESTART_RADIUS: int = 18
const GAME_OVER_RESTART_FONT_SIZE: int = 28
const GAME_OVER_MENU_POSITION: Vector2 = Vector2(22, 657.5)
const GAME_OVER_MENU_SIZE: Vector2 = Vector2(436, 60)
const GAME_OVER_MENU_RADIUS: int = 18
const GAME_OVER_MENU_FONT_SIZE: int = 20

const HUD_PAUSE_POSITION: Vector2 = Vector2(22, 60.5)
const HUD_PAUSE_SIZE: Vector2 = Vector2(48, 48)
const HUD_PAUSE_RADIUS: int = 14
const HUD_PAUSE_BAR_SIZE: Vector2 = Vector2(6, 20)
const HUD_PAUSE_BAR_RADIUS: int = 3
const HUD_PAUSE_BAR_OFFSET_A: Vector2 = Vector2(15, 14)
const HUD_PAUSE_BAR_OFFSET_B: Vector2 = Vector2(27, 14)
const HUD_SCORE_AREA_X: float = 164.0
const HUD_SCORE_AREA_WIDTH: float = 152.0
const HUD_SCORE_CENTER_X: float = 240.0
const HUD_SCORE_LABEL_BASELINE: float = 56.0
const HUD_SCORE_VALUE_BASELINE: float = 111.5
const HUD_SCORE_LABEL_FONT_SIZE: int = 18
const HUD_SCORE_FONT_SIZE: int = 52
const HUD_BEST_AREA_X: float = 350.0
const HUD_BEST_AREA_WIDTH: float = 108.0
const HUD_BEST_LABEL_BASELINE: float = 77.0
const HUD_BEST_VALUE_BASELINE: float = 101.5
const HUD_BEST_FONT_SIZE: int = 24
const PANEL_PADDING: int = 12
const BOARD_PANEL_ORIGIN: Vector2 = Vector2(22, 217.5)

const TRAY_CARD_SIZE: int = 136
const TRAY_CARD_RADIUS: int = 20
const TRAY_Y: float = 681.5
const TRAY_CARD_X: Array[int] = [22, 172, 322]
const TRAY_CELL: int = 30
const TRAY_GAP: int = 3
const TRAY_CELL_RADIUS: int = 5
const TRAY_SLOTS: int = 3
const DRAG_OFFSET_Y: int = 0
const RETURN_TWEEN_TIME: float = 0.15

static func color_for(id: int) -> Color:
	match id:
		1:
			return BLUE
		2:
			return TEAL
		3:
			return YELLOW
		4:
			return RED
		5:
			return GREEN
		_:
			return CELL_EMPTY
