class_name SettingsCodec
extends RefCounted

const CURRENT_SCHEMA_VERSION: int = 1


static func encode(profile: SettingsProfile) -> Dictionary:
	var encoded_bindings: Dictionary = {}
	for action in profile.input_bindings:
		var encoded_events: Array[Dictionary] = []
		for event in profile.input_bindings[action]:
			encoded_events.append(_encode_event(event))
		encoded_bindings[String(action)] = encoded_events
	return {
		"schema_version": CURRENT_SCHEMA_VERSION,
		"audio": {
			"master": profile.master_volume,
			"music": profile.music_volume,
			"sound": profile.sound_volume,
		},
		"display": {
			"mode": String(profile.display_mode),
			"width": profile.resolution.x,
			"height": profile.resolution.y,
			"ui_scale": profile.ui_scale,
		},
		"accessibility": {
			"camera_smoothing": profile.camera_smoothing,
			"screen_shake_intensity": profile.screen_shake_intensity,
			"text_speed": profile.text_speed,
			"instant_text": profile.instant_text,
			"gamepad_vibration": profile.gamepad_vibration,
			"high_contrast_interactions": profile.high_contrast_interactions,
			"reduced_motion": profile.reduced_motion,
		},
		"locale": String(profile.locale),
		"input_bindings": encoded_bindings,
	}


static func decode(data: Variant) -> SettingsOperationResult:
	if not data is Dictionary:
		return SettingsOperationResult.failed(&"SETTINGS_DATA_NOT_DICTIONARY")
	var root := data as Dictionary
	var schema_result: Array = _coerce_integer(root.get("schema_version"))
	if not schema_result[0] or schema_result[1] != CURRENT_SCHEMA_VERSION:
		return SettingsOperationResult.failed(&"SETTINGS_UNSUPPORTED_SCHEMA")
	if (
		not root.get("audio") is Dictionary
		or not root.get("display") is Dictionary
		or not root.get("accessibility") is Dictionary
		or not root.get("input_bindings", {}) is Dictionary
	):
		return SettingsOperationResult.failed(&"SETTINGS_INVALID_SECTION")
	var profile := SettingsProfile.new()
	var audio := root["audio"] as Dictionary
	var display := root["display"] as Dictionary
	var accessibility := root["accessibility"] as Dictionary
	var numeric_error: StringName = _decode_numeric_fields(
		profile,
		audio,
		display,
		accessibility
	)
	if not numeric_error.is_empty():
		return SettingsOperationResult.failed(numeric_error)
	var scalar_error: StringName = _decode_scalar_fields(
		profile,
		root,
		display,
		accessibility
	)
	if not scalar_error.is_empty():
		return SettingsOperationResult.failed(scalar_error)
	var binding_error: StringName = _decode_bindings(profile, root["input_bindings"])
	if not binding_error.is_empty():
		return SettingsOperationResult.failed(binding_error)
	var validation_error: StringName = profile.validate()
	if not validation_error.is_empty():
		return SettingsOperationResult.failed(validation_error)
	return SettingsOperationResult.succeeded(profile)


static func _decode_numeric_fields(
	profile: SettingsProfile,
	audio: Dictionary,
	display: Dictionary,
	accessibility: Dictionary
) -> StringName:
	for value in [audio.get("master"), audio.get("music"), audio.get("sound")]:
		if not _is_number(value):
			return &"SETTINGS_INVALID_VOLUME"
	profile.master_volume = float(audio["master"])
	profile.music_volume = float(audio["music"])
	profile.sound_volume = float(audio["sound"])
	var width_result: Array = _coerce_integer(display.get("width"))
	var height_result: Array = _coerce_integer(display.get("height"))
	if not width_result[0] or not height_result[0] or not _is_number(display.get("ui_scale")):
		return &"SETTINGS_INVALID_DISPLAY_NUMBER"
	profile.resolution = Vector2i(width_result[1], height_result[1])
	profile.ui_scale = float(display["ui_scale"])
	if (
		not _is_number(accessibility.get("screen_shake_intensity"))
		or not _is_number(accessibility.get("text_speed"))
	):
		return &"SETTINGS_INVALID_ACCESSIBILITY_NUMBER"
	profile.screen_shake_intensity = float(accessibility["screen_shake_intensity"])
	profile.text_speed = float(accessibility["text_speed"])
	return &""


static func _decode_scalar_fields(
	profile: SettingsProfile,
	root: Dictionary,
	display: Dictionary,
	accessibility: Dictionary
) -> StringName:
	if not display.get("mode") is String or not root.get("locale") is String:
		return &"SETTINGS_INVALID_TEXT_VALUE"
	profile.display_mode = StringName(display["mode"])
	profile.locale = StringName(root["locale"])
	var boolean_fields: Array[String] = [
		"camera_smoothing",
		"instant_text",
		"gamepad_vibration",
		"high_contrast_interactions",
		"reduced_motion",
	]
	for field in boolean_fields:
		if not accessibility.get(field) is bool:
			return &"SETTINGS_INVALID_BOOLEAN"
	profile.camera_smoothing = accessibility["camera_smoothing"]
	profile.instant_text = accessibility["instant_text"]
	profile.gamepad_vibration = accessibility["gamepad_vibration"]
	profile.high_contrast_interactions = accessibility["high_contrast_interactions"]
	profile.reduced_motion = accessibility["reduced_motion"]
	return &""


static func _decode_bindings(profile: SettingsProfile, data: Dictionary) -> StringName:
	for raw_action in data:
		if not raw_action is String:
			return &"SETTINGS_INVALID_INPUT_ACTION"
		var action := StringName(raw_action)
		if not SettingsProfile.REMAPPABLE_ACTIONS.has(action):
			return &"SETTINGS_INVALID_INPUT_ACTION"
		var raw_events: Variant = data[raw_action]
		if not raw_events is Array or raw_events.is_empty():
			return &"SETTINGS_EMPTY_INPUT_BINDING"
		var events: Array = []
		for raw_event in raw_events:
			var event: InputEvent = _decode_event(raw_event)
			if event == null:
				return &"SETTINGS_INVALID_INPUT_EVENT"
			events.append(event)
		profile.input_bindings[action] = events
	return &""


static func _encode_event(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		var key := event as InputEventKey
		return {
			"type": "key",
			"keycode": key.keycode,
			"physical_keycode": key.physical_keycode,
			"shift": key.shift_pressed,
			"ctrl": key.ctrl_pressed,
			"alt": key.alt_pressed,
			"meta": key.meta_pressed,
			"device": key.device,
		}
	if event is InputEventJoypadButton:
		var button := event as InputEventJoypadButton
		return {
			"type": "joy_button",
			"button_index": button.button_index,
			"device": button.device,
		}
	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		return {
			"type": "joy_motion",
			"axis": motion.axis,
			"axis_value": motion.axis_value,
			"device": motion.device,
		}
	return {}


static func _decode_event(data: Variant) -> InputEvent:
	if not data is Dictionary:
		return null
	var event_data := data as Dictionary
	if not event_data.get("type") is String:
		return null
	match String(event_data["type"]):
		"key":
			var keycode_result: Array = _coerce_integer(event_data.get("keycode"))
			var physical_result: Array = _coerce_integer(event_data.get("physical_keycode"))
			if not keycode_result[0] or not physical_result[0]:
				return null
			var key := InputEventKey.new()
			key.keycode = keycode_result[1]
			key.physical_keycode = physical_result[1]
			if not _decode_modifiers(key, event_data):
				return null
			key.device = _decode_device(event_data)
			if key.keycode == 0 and key.physical_keycode == 0:
				return null
			return key
		"joy_button":
			var button_result: Array = _coerce_integer(event_data.get("button_index"))
			if (
				not button_result[0]
				or button_result[1] < 0
				or button_result[1] >= JOY_BUTTON_MAX
			):
				return null
			var button := InputEventJoypadButton.new()
			button.button_index = button_result[1]
			button.device = _decode_device(event_data)
			return button
		"joy_motion":
			var axis_result: Array = _coerce_integer(event_data.get("axis"))
			var axis_value: Variant = event_data.get("axis_value")
			if (
				not axis_result[0]
				or axis_result[1] < 0
				or axis_result[1] >= JOY_AXIS_MAX
				or not _is_number(axis_value)
			):
				return null
			var motion := InputEventJoypadMotion.new()
			motion.axis = axis_result[1]
			motion.axis_value = float(axis_value)
			motion.device = _decode_device(event_data)
			if not is_equal_approx(absf(motion.axis_value), 1.0):
				return null
			return motion
	return null


static func _decode_modifiers(key: InputEventKey, data: Dictionary) -> bool:
	for field in ["shift", "ctrl", "alt", "meta"]:
		if data.has(field) and not data[field] is bool:
			return false
	key.shift_pressed = bool(data.get("shift", false))
	key.ctrl_pressed = bool(data.get("ctrl", false))
	key.alt_pressed = bool(data.get("alt", false))
	key.meta_pressed = bool(data.get("meta", false))
	return true


static func _decode_device(data: Dictionary) -> int:
	var result: Array = _coerce_integer(data.get("device", -1))
	return result[1] if result[0] and result[1] >= -1 else -1


static func _coerce_integer(value: Variant) -> Array:
	if value is int:
		return [true, value]
	if value is float and is_finite(value) and is_equal_approx(value, roundf(value)):
		return [true, int(value)]
	return [false, 0]


static func _is_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))
