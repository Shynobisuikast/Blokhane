# tests/ScreenFlowTestRunner.gd
extends RefCounted

const ScreenFlowScript = preload("res://scripts/ScreenFlow.gd")

static func run(test_runner: Variant) -> void:
	var initial: Variant = ScreenFlowScript.new()
	test_runner.check("53 ekran akışı MENU ile başlar", initial.current == ScreenFlowScript.Screen.MENU)

	var menu_to_playing: Variant = ScreenFlowScript.new()
	var menu_valid: bool = menu_to_playing.go(ScreenFlowScript.Screen.PLAYING)
	var menu_to_settings: Variant = ScreenFlowScript.new()
	var settings_valid: bool = menu_to_settings.go(ScreenFlowScript.Screen.SETTINGS)
	var menu_invalid: Variant = ScreenFlowScript.new()
	var pause_rejected: bool = not menu_invalid.go(ScreenFlowScript.Screen.PAUSED)
	var menu_still_menu: bool = menu_invalid.current == ScreenFlowScript.Screen.MENU
	var game_over_rejected: bool = not menu_invalid.go(ScreenFlowScript.Screen.GAME_OVER)
	test_runner.check(
		"54 MENU yalnızca PLAYING ve SETTINGS'e geçebilir",
		menu_valid and menu_to_playing.current == ScreenFlowScript.Screen.PLAYING
		and settings_valid and menu_to_settings.current == ScreenFlowScript.Screen.SETTINGS
		and pause_rejected and game_over_rejected and menu_still_menu
	)

	var pause_resume: Variant = ScreenFlowScript.new()
	var pause_resume_valid: bool = pause_resume.go(ScreenFlowScript.Screen.PLAYING)
	pause_resume_valid = pause_resume_valid and pause_resume.go(ScreenFlowScript.Screen.PAUSED)
	pause_resume_valid = pause_resume_valid and pause_resume.go(ScreenFlowScript.Screen.PLAYING)
	test_runner.check("55 PLAYING-PAUSED-PLAYING geçişleri geçerlidir", pause_resume_valid)

	var pause_menu: Variant = ScreenFlowScript.new()
	pause_menu.current = ScreenFlowScript.Screen.PAUSED
	var pause_menu_valid: bool = pause_menu.go(ScreenFlowScript.Screen.MENU)
	var pause_game_over: Variant = ScreenFlowScript.new()
	pause_game_over.current = ScreenFlowScript.Screen.PAUSED
	var pause_game_over_rejected: bool = not pause_game_over.go(ScreenFlowScript.Screen.GAME_OVER)
	test_runner.check(
		"56 PAUSED-MENU geçerli, PAUSED-GAME_OVER geçersizdir",
		pause_menu_valid and pause_menu.current == ScreenFlowScript.Screen.MENU
		and pause_game_over_rejected and pause_game_over.current == ScreenFlowScript.Screen.PAUSED
	)

	var game_over_flow: Variant = ScreenFlowScript.new()
	var game_over_valid: bool = game_over_flow.go(ScreenFlowScript.Screen.PLAYING)
	game_over_valid = game_over_valid and game_over_flow.go(ScreenFlowScript.Screen.GAME_OVER)
	game_over_valid = game_over_valid and game_over_flow.go(ScreenFlowScript.Screen.PLAYING)
	var game_over_menu: Variant = ScreenFlowScript.new()
	game_over_menu.current = ScreenFlowScript.Screen.GAME_OVER
	var game_over_menu_valid: bool = game_over_menu.go(ScreenFlowScript.Screen.MENU)
	test_runner.check(
		"57 GAME_OVER-PLAYING ve GAME_OVER-MENU geçerlidir",
		game_over_valid and game_over_menu_valid
		and game_over_menu.current == ScreenFlowScript.Screen.MENU
	)

	var matrix_valid: bool = _transition_matrix_holds()
	test_runner.check("58 tüm geçiş matrisi geçerli listeyle eşleşir", matrix_valid)

	var settings_flow: Variant = ScreenFlowScript.new()
	settings_flow.current = ScreenFlowScript.Screen.SETTINGS
	var settings_to_menu: bool = settings_flow.go(ScreenFlowScript.Screen.MENU)
	var settings_invalid: Variant = ScreenFlowScript.new()
	settings_invalid.current = ScreenFlowScript.Screen.SETTINGS
	var invalid_settings_targets: bool = true
	for target: int in [
		ScreenFlowScript.Screen.PLAYING,
		ScreenFlowScript.Screen.PAUSED,
		ScreenFlowScript.Screen.GAME_OVER
	]:
		invalid_settings_targets = invalid_settings_targets and not settings_invalid.go(target)
	test_runner.check(
		"59 SETTINGS yalnızca MENU'ye döner",
		settings_to_menu and settings_flow.current == ScreenFlowScript.Screen.MENU
		and invalid_settings_targets and settings_invalid.current == ScreenFlowScript.Screen.SETTINGS
	)

static func _transition_matrix_holds() -> bool:
	var screens: Array[int] = [
		ScreenFlowScript.Screen.MENU,
		ScreenFlowScript.Screen.PLAYING,
		ScreenFlowScript.Screen.PAUSED,
		ScreenFlowScript.Screen.GAME_OVER,
		ScreenFlowScript.Screen.SETTINGS
	]
	for from_screen: int in screens:
		for to_screen: int in screens:
			var flow: Variant = ScreenFlowScript.new()
			flow.set("current", from_screen)
			var allowed: bool = _is_allowed(from_screen, to_screen)
			var accepted: bool = flow.call("go", to_screen)
			if accepted != allowed:
				return false
			if allowed and flow.current != to_screen:
				return false
			if not allowed and flow.current != from_screen:
				return false
	return true

static func _is_allowed(from_screen: int, to_screen: int) -> bool:
	match from_screen:
		ScreenFlowScript.Screen.MENU:
			return to_screen == ScreenFlowScript.Screen.PLAYING or to_screen == ScreenFlowScript.Screen.SETTINGS
		ScreenFlowScript.Screen.PLAYING:
			return to_screen == ScreenFlowScript.Screen.PAUSED or to_screen == ScreenFlowScript.Screen.GAME_OVER
		ScreenFlowScript.Screen.PAUSED:
			return to_screen == ScreenFlowScript.Screen.PLAYING or to_screen == ScreenFlowScript.Screen.MENU
		ScreenFlowScript.Screen.GAME_OVER:
			return to_screen == ScreenFlowScript.Screen.PLAYING or to_screen == ScreenFlowScript.Screen.MENU
		ScreenFlowScript.Screen.SETTINGS:
			return to_screen == ScreenFlowScript.Screen.MENU
	return false
