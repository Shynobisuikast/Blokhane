# scripts/ButtonFeedback.gd
class_name ButtonFeedback
extends RefCounted

const TWEEN_META: StringName = &"button_feedback_tween"
const INSTALLED_META: StringName = &"button_feedback_installed"

static func apply(control: Control) -> void:
	if control == null or control.has_meta(INSTALLED_META):
		return
	control.pivot_offset = control.size / 2.0
	control.scale = Vector2.ONE
	control.set_meta(INSTALLED_META, true)
	if control is BaseButton:
		var button: BaseButton = control as BaseButton
		button.button_down.connect(_on_button_down.bind(control))
		button.button_up.connect(_on_interaction_ended.bind(control))
	control.mouse_exited.connect(_on_interaction_ended.bind(control))

static func scale_for_pressed(pressed: bool) -> float:
	return Config.PRESS_SCALE if pressed else 1.0

static func _on_button_down(control: Control) -> void:
	_animate_scale(control, scale_for_pressed(true))

static func _on_interaction_ended(control: Control) -> void:
	_animate_scale(control, scale_for_pressed(false))

static func _animate_scale(control: Control, target_scale: float) -> void:
	if not is_instance_valid(control):
		return
	var previous_tween: Variant = control.get_meta(TWEEN_META, null)
	if previous_tween is Tween and (previous_tween as Tween).is_running():
		(previous_tween as Tween).kill()
	var tween: Tween = control.create_tween()
	control.set_meta(TWEEN_META, tween)
	tween.tween_property(
		control,
		"scale",
		Vector2.ONE * target_scale,
		Config.PRESS_TIME
	)
