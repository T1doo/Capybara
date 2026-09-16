class_name AccessibilityFeedbackService
extends Node

signal vibration_requested(device_id: int, weak: float, strong: float, duration: float)
signal accessibility_changed(
	reduced_motion: bool,
	gamepad_vibration: bool,
	high_contrast_interactions: bool
)

var reduced_motion_enabled: bool = false
var gamepad_vibration_enabled: bool = true
var high_contrast_interactions_enabled: bool = false
var vibration_dispatch: Callable


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	vibration_dispatch = _dispatch_platform_vibration
	var settings_service := get_node_or_null("/root/SettingsService") as SettingsManagerService
	if settings_service == null:
		return
	settings_service.settings_changed.connect(apply_settings)
	apply_settings(settings_service.current_settings)


func apply_settings(settings: SettingsProfile) -> void:
	if settings == null:
		return
	reduced_motion_enabled = settings.reduced_motion
	gamepad_vibration_enabled = settings.gamepad_vibration
	high_contrast_interactions_enabled = settings.high_contrast_interactions
	accessibility_changed.emit(
		reduced_motion_enabled,
		gamepad_vibration_enabled,
		high_contrast_interactions_enabled
	)


func request_gamepad_vibration(
	device_id: int,
	weak: float = 0.15,
	strong: float = 0.3,
	duration: float = 0.08
) -> bool:
	if (
		not gamepad_vibration_enabled
		or device_id < 0
		or not is_finite(weak)
		or not is_finite(strong)
		or not is_finite(duration)
		or weak < 0.0
		or weak > 1.0
		or strong < 0.0
		or strong > 1.0
		or duration <= 0.0
		or not vibration_dispatch.is_valid()
	):
		return false
	vibration_requested.emit(device_id, weak, strong, duration)
	vibration_dispatch.call(device_id, weak, strong, duration)
	return true


func _dispatch_platform_vibration(
	device_id: int,
	weak: float,
	strong: float,
	duration: float
) -> void:
	Input.start_joy_vibration(device_id, weak, strong, duration)
