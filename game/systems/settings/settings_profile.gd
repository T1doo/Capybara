class_name SettingsProfile
extends RefCounted

const DISPLAY_WINDOWED: StringName = &"windowed"
const DISPLAY_FULLSCREEN: StringName = &"fullscreen"
const SUPPORTED_DISPLAY_MODES: Array[StringName] = [
	DISPLAY_WINDOWED,
	DISPLAY_FULLSCREEN,
]
const SUPPORTED_RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1280, 800),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]
const SUPPORTED_UI_SCALES: Array[float] = [1.0, 1.25, 1.5]
const SUPPORTED_LOCALES: Array[StringName] = [&"zh_CN", &"en"]
const REMAPPABLE_ACTIONS: Array[StringName] = [
	&"move_left",
	&"move_right",
	&"move_up",
	&"move_down",
	&"interact",
	&"pause_game",
	&"toggle_inventory",
	&"hotbar_previous",
	&"hotbar_next",
]

var master_volume: float = 1.0
var music_volume: float = 0.8
var sound_volume: float = 0.8
var display_mode: StringName = DISPLAY_WINDOWED
var resolution: Vector2i = Vector2i(1280, 720)
var ui_scale: float = 1.0
var camera_smoothing: bool = true
var screen_shake_intensity: float = 1.0
var text_speed: float = 1.0
var instant_text: bool = false
var gamepad_vibration: bool = true
var high_contrast_interactions: bool = false
var reduced_motion: bool = false
var locale: StringName = &"zh_CN"
var input_bindings: Dictionary[StringName, Array] = {}


func validate() -> StringName:
	for volume in [master_volume, music_volume, sound_volume]:
		if not is_finite(volume) or volume < 0.0 or volume > 1.0:
			return &"SETTINGS_INVALID_VOLUME"
	if not SUPPORTED_DISPLAY_MODES.has(display_mode):
		return &"SETTINGS_INVALID_DISPLAY_MODE"
	if not SUPPORTED_RESOLUTIONS.has(resolution):
		return &"SETTINGS_INVALID_RESOLUTION"
	if not _contains_float(SUPPORTED_UI_SCALES, ui_scale):
		return &"SETTINGS_INVALID_UI_SCALE"
	if (
		not is_finite(screen_shake_intensity)
		or screen_shake_intensity < 0.0
		or screen_shake_intensity > 1.0
	):
		return &"SETTINGS_INVALID_SCREEN_SHAKE"
	if not is_finite(text_speed) or text_speed < 0.25 or text_speed > 4.0:
		return &"SETTINGS_INVALID_TEXT_SPEED"
	if not SUPPORTED_LOCALES.has(locale):
		return &"SETTINGS_INVALID_LOCALE"
	for action in input_bindings:
		if not REMAPPABLE_ACTIONS.has(action):
			return &"SETTINGS_INVALID_INPUT_ACTION"
		var events: Array = input_bindings[action]
		if events.is_empty():
			return &"SETTINGS_EMPTY_INPUT_BINDING"
		for event in events:
			if not _is_supported_binding_event(event):
				return &"SETTINGS_INVALID_INPUT_EVENT"
	return &""


func duplicate_profile() -> SettingsProfile:
	var copy := SettingsProfile.new()
	copy.master_volume = master_volume
	copy.music_volume = music_volume
	copy.sound_volume = sound_volume
	copy.display_mode = display_mode
	copy.resolution = resolution
	copy.ui_scale = ui_scale
	copy.camera_smoothing = camera_smoothing
	copy.screen_shake_intensity = screen_shake_intensity
	copy.text_speed = text_speed
	copy.instant_text = instant_text
	copy.gamepad_vibration = gamepad_vibration
	copy.high_contrast_interactions = high_contrast_interactions
	copy.reduced_motion = reduced_motion
	copy.locale = locale
	for action in input_bindings:
		copy.input_bindings[action] = (input_bindings[action] as Array).duplicate(true)
	return copy


func set_input_binding(action: StringName, events: Array) -> bool:
	if not REMAPPABLE_ACTIONS.has(action) or events.is_empty():
		return false
	for event in events:
		if not _is_supported_binding_event(event):
			return false
	input_bindings[action] = events.duplicate(true)
	return true


static func _contains_float(values: Array[float], candidate: float) -> bool:
	for value in values:
		if is_equal_approx(value, candidate):
			return true
	return false


static func _is_supported_binding_event(event: Variant) -> bool:
	if event is InputEventKey:
		var key := event as InputEventKey
		return key.keycode != 0 or key.physical_keycode != 0
	if event is InputEventJoypadButton:
		var button := event as InputEventJoypadButton
		return button.button_index >= 0 and button.button_index < JOY_BUTTON_MAX
	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		return (
			motion.axis >= 0
			and motion.axis < JOY_AXIS_MAX
			and is_equal_approx(absf(motion.axis_value), 1.0)
		)
	return false
