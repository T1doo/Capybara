class_name InputSetup
extends RefCounted

const DEFAULT_DEADZONE: float = 0.2


static func ensure_default_actions() -> void:
	# Godot's built-in UI actions do not guarantee controller events at runtime.
	_ensure_joy_button(&"ui_accept", JOY_BUTTON_A)
	_ensure_joy_button(&"ui_cancel", JOY_BUTTON_B)
	_ensure_joy_button(&"ui_left", JOY_BUTTON_DPAD_LEFT)
	_ensure_joy_button(&"ui_right", JOY_BUTTON_DPAD_RIGHT)
	_ensure_joy_button(&"ui_up", JOY_BUTTON_DPAD_UP)
	_ensure_joy_button(&"ui_down", JOY_BUTTON_DPAD_DOWN)
	_ensure_joy_axis(&"ui_left", JOY_AXIS_LEFT_X, -1.0)
	_ensure_joy_axis(&"ui_right", JOY_AXIS_LEFT_X, 1.0)
	_ensure_joy_axis(&"ui_up", JOY_AXIS_LEFT_Y, -1.0)
	_ensure_joy_axis(&"ui_down", JOY_AXIS_LEFT_Y, 1.0)

	_ensure_key(&"move_left", KEY_A)
	_ensure_key(&"move_left", KEY_LEFT)
	_ensure_joy_axis(&"move_left", JOY_AXIS_LEFT_X, -1.0)
	_ensure_joy_button(&"move_left", JOY_BUTTON_DPAD_LEFT)

	_ensure_key(&"move_right", KEY_D)
	_ensure_key(&"move_right", KEY_RIGHT)
	_ensure_joy_axis(&"move_right", JOY_AXIS_LEFT_X, 1.0)
	_ensure_joy_button(&"move_right", JOY_BUTTON_DPAD_RIGHT)

	_ensure_key(&"move_up", KEY_W)
	_ensure_key(&"move_up", KEY_UP)
	_ensure_joy_axis(&"move_up", JOY_AXIS_LEFT_Y, -1.0)
	_ensure_joy_button(&"move_up", JOY_BUTTON_DPAD_UP)

	_ensure_key(&"move_down", KEY_S)
	_ensure_key(&"move_down", KEY_DOWN)
	_ensure_joy_axis(&"move_down", JOY_AXIS_LEFT_Y, 1.0)
	_ensure_joy_button(&"move_down", JOY_BUTTON_DPAD_DOWN)

	_ensure_key(&"pause_game", KEY_ESCAPE)
	_ensure_joy_button(&"pause_game", JOY_BUTTON_START)

	_ensure_key(&"interact", KEY_E)
	_ensure_joy_button(&"interact", JOY_BUTTON_A)

	_ensure_key(&"toggle_debug_overlay", KEY_F3)

	_ensure_key(&"toggle_inventory", KEY_TAB)
	_ensure_joy_button(&"toggle_inventory", JOY_BUTTON_BACK)

	_ensure_key(&"hotbar_previous", KEY_Q)
	_ensure_joy_button(&"hotbar_previous", JOY_BUTTON_LEFT_SHOULDER)
	_ensure_key(&"hotbar_next", KEY_R)
	_ensure_joy_button(&"hotbar_next", JOY_BUTTON_RIGHT_SHOULDER)


static func reset_action_to_defaults(action: StringName) -> bool:
	if not SettingsProfile.REMAPPABLE_ACTIONS.has(action):
		return false
	if InputMap.has_action(action):
		InputMap.action_erase_events(action)
	match action:
		&"move_left":
			_ensure_key(action, KEY_A)
			_ensure_key(action, KEY_LEFT)
			_ensure_joy_axis(action, JOY_AXIS_LEFT_X, -1.0)
			_ensure_joy_button(action, JOY_BUTTON_DPAD_LEFT)
		&"move_right":
			_ensure_key(action, KEY_D)
			_ensure_key(action, KEY_RIGHT)
			_ensure_joy_axis(action, JOY_AXIS_LEFT_X, 1.0)
			_ensure_joy_button(action, JOY_BUTTON_DPAD_RIGHT)
		&"move_up":
			_ensure_key(action, KEY_W)
			_ensure_key(action, KEY_UP)
			_ensure_joy_axis(action, JOY_AXIS_LEFT_Y, -1.0)
			_ensure_joy_button(action, JOY_BUTTON_DPAD_UP)
		&"move_down":
			_ensure_key(action, KEY_S)
			_ensure_key(action, KEY_DOWN)
			_ensure_joy_axis(action, JOY_AXIS_LEFT_Y, 1.0)
			_ensure_joy_button(action, JOY_BUTTON_DPAD_DOWN)
		&"pause_game":
			_ensure_key(action, KEY_ESCAPE)
			_ensure_joy_button(action, JOY_BUTTON_START)
		&"interact":
			_ensure_key(action, KEY_E)
			_ensure_joy_button(action, JOY_BUTTON_A)
		&"toggle_inventory":
			_ensure_key(action, KEY_TAB)
			_ensure_joy_button(action, JOY_BUTTON_BACK)
		&"hotbar_previous":
			_ensure_key(action, KEY_Q)
			_ensure_joy_button(action, JOY_BUTTON_LEFT_SHOULDER)
		&"hotbar_next":
			_ensure_key(action, KEY_R)
			_ensure_joy_button(action, JOY_BUTTON_RIGHT_SHOULDER)
	return true


static func get_default_events(action: StringName) -> Array:
	var previous_events: Array = []
	if InputMap.has_action(action):
		for event in InputMap.action_get_events(action):
			previous_events.append((event as InputEvent).duplicate())
	reset_action_to_defaults(action)
	var defaults: Array = []
	for event in InputMap.action_get_events(action):
		defaults.append((event as InputEvent).duplicate())
	InputMap.action_erase_events(action)
	for event in previous_events:
		InputMap.action_add_event(action, event)
	return defaults


static func _ensure_action(action: StringName) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, DEFAULT_DEADZONE)


static func _ensure_key(action: StringName, keycode: int) -> void:
	_ensure_action(action)
	var physical_event := InputEventKey.new()
	physical_event.physical_keycode = keycode
	if not InputMap.action_has_event(action, physical_event):
		InputMap.action_add_event(action, physical_event)

	var logical_event := InputEventKey.new()
	logical_event.keycode = keycode
	if not InputMap.action_has_event(action, logical_event):
		InputMap.action_add_event(action, logical_event)


static func _ensure_joy_axis(action: StringName, axis: int, axis_value: float) -> void:
	_ensure_action(action)
	var input_event := InputEventJoypadMotion.new()
	input_event.device = -1
	input_event.axis = axis
	input_event.axis_value = axis_value
	if not InputMap.action_has_event(action, input_event):
		InputMap.action_add_event(action, input_event)


static func _ensure_joy_button(action: StringName, button_index: int) -> void:
	_ensure_action(action)
	var input_event := InputEventJoypadButton.new()
	input_event.device = -1
	input_event.button_index = button_index
	if not InputMap.action_has_event(action, input_event):
		InputMap.action_add_event(action, input_event)
