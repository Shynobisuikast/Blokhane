# scripts/ScreenFlow.gd
class_name ScreenFlow
extends RefCounted

enum Screen { MENU, PLAYING, PAUSED, GAME_OVER, SETTINGS }

var current: Screen = Screen.MENU

func can_go(to: Screen) -> bool:
	match current:
		Screen.MENU:
			return to == Screen.PLAYING or to == Screen.SETTINGS
		Screen.PLAYING:
			return to == Screen.PAUSED or to == Screen.GAME_OVER
		Screen.PAUSED:
			return to == Screen.PLAYING or to == Screen.MENU
		Screen.GAME_OVER:
			return to == Screen.PLAYING or to == Screen.MENU
		Screen.SETTINGS:
			return to == Screen.MENU
	return false

func go(to: Screen) -> bool:
	if not can_go(to):
		return false
	current = to
	return true
