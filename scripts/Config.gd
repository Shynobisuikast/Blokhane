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
