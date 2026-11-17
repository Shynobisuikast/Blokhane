# scripts/Main.gd
extends Control

@onready var background: ColorRect = $Background

func _ready() -> void:
	background.color = Config.BG
