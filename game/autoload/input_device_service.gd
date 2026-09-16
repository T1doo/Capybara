class_name InputDeviceTracker
extends Node

signal device_changed(previous_device: int, current_device: int)

enum DeviceType {
	KEYBOARD_MOUSE,
	GAMEPAD,
}

const JOYPAD_MOTION_DEADZONE: float = 0.25

var current_device: int = DeviceType.KEYBOARD_MOUSE
var current_gamepad_id: int = -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func _input(event: InputEvent) -> void:
	process_input_event(event)


func process_input_event(event: InputEvent) -> bool:
	var detected_device := classify_event(event)
	if detected_device == DeviceType.GAMEPAD:
		current_gamepad_id = event.device
	if detected_device < 0 or detected_device == current_device:
		return false

	return _set_current_device(detected_device)


func classify_event(event: InputEvent) -> int:
	if event is InputEventJoypadButton:
		var joy_button := event as InputEventJoypadButton
		return DeviceType.GAMEPAD if joy_button.pressed else -1
	if event is InputEventJoypadMotion:
		var motion_event := event as InputEventJoypadMotion
		if absf(motion_event.axis_value) >= JOYPAD_MOTION_DEADZONE:
			return DeviceType.GAMEPAD
		return -1
	if event is InputEventKey:
		var key_event := event as InputEventKey
		return DeviceType.KEYBOARD_MOUSE if key_event.pressed and not key_event.echo else -1
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		return DeviceType.KEYBOARD_MOUSE if mouse_button.pressed else -1
	if event is InputEventMouseMotion:
		var mouse_motion := event as InputEventMouseMotion
		return DeviceType.KEYBOARD_MOUSE if not mouse_motion.relative.is_zero_approx() else -1
	return -1


func get_device_id() -> StringName:
	return &"gamepad" if current_device == DeviceType.GAMEPAD else &"keyboard_mouse"


func get_gamepad_id() -> int:
	return current_gamepad_id if current_device == DeviceType.GAMEPAD else -1


func get_action_prompt_key(action: StringName) -> StringName:
	match action:
		&"interact":
			return (
				&"INPUT_PROMPT_INTERACT_GAMEPAD"
				if current_device == DeviceType.GAMEPAD
				else &"INPUT_PROMPT_INTERACT_KEYBOARD"
			)
		&"pause_game":
			return (
				&"INPUT_PROMPT_PAUSE_GAMEPAD"
				if current_device == DeviceType.GAMEPAD
				else &"INPUT_PROMPT_PAUSE_KEYBOARD"
			)
	return &"INPUT_PROMPT_UNKNOWN"


func get_action_prompt_text(action: StringName) -> String:
	for event in InputMap.action_get_events(action):
		if current_device == DeviceType.KEYBOARD_MOUSE and event is InputEventKey:
			var key := event as InputEventKey
			return InputBindingFormatter.format_key(key)
		if current_device == DeviceType.GAMEPAD and event is InputEventJoypadButton:
			return _joy_button_text((event as InputEventJoypadButton).button_index)
		if current_device == DeviceType.GAMEPAD and event is InputEventJoypadMotion:
			var motion := event as InputEventJoypadMotion
			var direction: String = "+" if motion.axis_value > 0.0 else "−"
			return tr(&"INPUT_PROMPT_GAMEPAD_AXIS") % [motion.axis, direction]
	return tr(get_action_prompt_key(action))


func _joy_button_text(button_index: int) -> String:
	match button_index:
		JOY_BUTTON_A:
			return "A"
		JOY_BUTTON_B:
			return "B"
		JOY_BUTTON_X:
			return "X"
		JOY_BUTTON_Y:
			return "Y"
		JOY_BUTTON_LEFT_SHOULDER:
			return "LB"
		JOY_BUTTON_RIGHT_SHOULDER:
			return "RB"
	return tr(&"INPUT_PROMPT_GAMEPAD_BUTTON") % (button_index + 1)


func process_joy_connection_change(
	connected: bool,
	connected_gamepad_count: int,
	disconnected_device: int = -1,
	fallback_device: int = -1
) -> bool:
	if connected or current_device != DeviceType.GAMEPAD:
		return false
	if disconnected_device >= 0 and disconnected_device != current_gamepad_id:
		return false
	if connected_gamepad_count > 0:
		current_gamepad_id = fallback_device
		return false
	current_gamepad_id = -1
	return _set_current_device(DeviceType.KEYBOARD_MOUSE)


func _set_current_device(next_device: int) -> bool:
	if next_device < 0 or next_device == current_device:
		return false
	var previous_device: int = current_device
	current_device = next_device
	device_changed.emit(previous_device, current_device)
	return true


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	var connected_devices: Array[int] = Input.get_connected_joypads()
	var fallback_device: int = connected_devices[0] if not connected_devices.is_empty() else -1
	process_joy_connection_change(connected, connected_devices.size(), device, fallback_device)
