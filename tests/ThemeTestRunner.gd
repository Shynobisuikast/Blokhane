# tests/ThemeTestRunner.gd
extends RefCounted

const ThemePalettesScript = preload("res://scripts/ThemePalettes.gd")
const SaveDataScript = preload("res://scripts/SaveData.gd")

const TEST_SAVE_PATH: String = "/tmp/blokhane_theme_smoke_test.cfg"

static func run(test_runner: Variant) -> void:
	var dark: Dictionary = ThemePalettesScript.get_palette(ThemePalettesScript.ThemeId.DARK)
	var light: Dictionary = ThemePalettesScript.get_palette(ThemePalettesScript.ThemeId.LIGHT)
	var palettes_valid: bool = dark.size() == light.size()
	for key: String in dark:
		palettes_valid = palettes_valid and light.has(key) and typeof(dark[key]) == TYPE_COLOR
	for key: String in light:
		palettes_valid = palettes_valid and typeof(light[key]) == TYPE_COLOR
	test_runner.check("60 palet anahtarları eşit, bütün değerler Color", palettes_valid)

	test_runner.check(
		"61 koyu temada TEXT-BG parlaklık farkı 0.4'ten büyük",
		_brightness_difference(ThemePalettesScript.ThemeId.DARK) > 0.4
	)
	test_runner.check(
		"62 açık temada TEXT-BG parlaklık farkı 0.4'ten büyük",
		_brightness_difference(ThemePalettesScript.ThemeId.LIGHT) > 0.4
	)
	test_runner.check(
		"63 koyu palet dark.svg renkleriyle eşleşir",
		_palette_matches_svg(ThemePalettesScript.ThemeId.DARK, "res://templates/dark.svg")
	)
	test_runner.check(
		"64 açık palet light.svg renkleriyle eşleşir",
		_palette_matches_svg(ThemePalettesScript.ThemeId.LIGHT, "res://templates/light.svg")
	)

	_remove_test_file(TEST_SAVE_PATH)
	SaveDataScript.save_theme(ThemePalettesScript.ThemeId.LIGHT, TEST_SAVE_PATH)
	var saved_theme: ThemePalettesScript.ThemeId = SaveDataScript.load_theme(TEST_SAVE_PATH)
	_remove_test_file(TEST_SAVE_PATH)
	test_runner.check("65 SaveData tema kaydet-yükle gidiş-dönüşü", saved_theme == ThemePalettesScript.ThemeId.LIGHT)

	_remove_test_file(TEST_SAVE_PATH)
	var missing_theme: ThemePalettesScript.ThemeId = SaveDataScript.load_theme(TEST_SAVE_PATH)
	test_runner.check("66 tema dosyası yoksa DARK döner", missing_theme == ThemePalettesScript.ThemeId.DARK)

	var corrupt_file: FileAccess = FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	var corrupt_written: bool = corrupt_file != null
	if corrupt_file != null:
		corrupt_file.store_string("[settings]\ntheme = bozuk")
		corrupt_file.close()
	var corrupt_theme: ThemePalettesScript.ThemeId = SaveDataScript.load_theme(TEST_SAVE_PATH)
	_remove_test_file(TEST_SAVE_PATH)
	test_runner.check(
		"67 bozuk tema kaydı çökmeden DARK döner",
		corrupt_written and corrupt_theme == ThemePalettesScript.ThemeId.DARK
	)

	_remove_test_file(TEST_SAVE_PATH)
	SaveDataScript.save_best(230, TEST_SAVE_PATH)
	SaveDataScript.save_theme(ThemePalettesScript.ThemeId.LIGHT, TEST_SAVE_PATH)
	SaveDataScript.save_best(0, TEST_SAVE_PATH)
	var reset_best: int = SaveDataScript.load_best(TEST_SAVE_PATH)
	var preserved_theme: ThemePalettesScript.ThemeId = SaveDataScript.load_theme(TEST_SAVE_PATH)
	_remove_test_file(TEST_SAVE_PATH)
	test_runner.check(
		"68 en yüksek skor sıfırlanır, kayıtlı tema korunur",
		reset_best == 0 and preserved_theme == ThemePalettesScript.ThemeId.LIGHT
	)

static func _brightness_difference(id: ThemePalettesScript.ThemeId) -> float:
	var palette: Dictionary = ThemePalettesScript.get_palette(id)
	var text_color: Color = palette["TEXT"]
	var background_color: Color = palette["BG"]
	return absf(_luminance(text_color) - _luminance(background_color))

static func _luminance(color: Color) -> float:
	return (
		0.2126 * _linear_channel(color.r)
		+ 0.7152 * _linear_channel(color.g)
		+ 0.0722 * _linear_channel(color.b)
	)

static func _linear_channel(channel: float) -> float:
	if channel <= 0.04045:
		return channel / 12.92
	return pow((channel + 0.055) / 1.055, 2.4)

static func _palette_matches_svg(id: ThemePalettesScript.ThemeId, path: String) -> bool:
	var svg: String = FileAccess.get_file_as_string(path)
	if svg.is_empty():
		return false
	var expression: RegEx = RegEx.new()
	if expression.compile("#[0-9A-Fa-f]{6}") != OK:
		return false
	var svg_colors: Dictionary = {}
	for match_result: RegExMatch in expression.search_all(svg):
		svg_colors[match_result.get_string().to_upper()] = true
	var palette: Dictionary = ThemePalettesScript.get_palette(id)
	for key: String in palette:
		var palette_color: Color = palette[key]
		var hex_color: String = "#" + palette_color.to_html(false).to_upper()
		if svg_colors.has(hex_color):
			continue
		if palette_color == Color.WHITE and svg.contains("fill=\"white\""):
			continue
		return false
	return true

static func _remove_test_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
