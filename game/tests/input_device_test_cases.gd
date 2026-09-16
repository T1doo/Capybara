class_name InputDeviceTestCases
extends RefCounted

const SERVICE_SCRIPT: Script = preload("res://autoload/input_device_service.gd")


static func run(assert_true: Callable, assert_int_equal: Callable) -> void:
	var service: InputDeviceTracker = SERVICE_SCRIPT.new()
	assert_int_equal.call(
		service.current_device,
		InputDeviceTracker.DeviceType.KEYBOARD_MOUSE,
		"input device starts as keyboard and mouse"
	)

	var small_motion := InputEventJoypadMotion.new()
	small_motion.axis_value = 0.1
	assert_true.call(
		not service.process_input_event(small_motion),
		"joypad motion inside the deadzone does not switch devices"
	)

	var joy_button := InputEventJoypadButton.new()
	joy_button.button_index = JOY_BUTTON_A
	joy_button.device = 3
	assert_true.call(
		not service.process_input_event(joy_button),
		"joypad button release does not switch devices"
	)
	joy_button.pressed = true
	assert_true.call(service.process_input_event(joy_button), "joypad button switches to gamepad")
	assert_true.call(service.get_device_id() == &"gamepad", "gamepad has a stable device ID")
	assert_int_equal.call(service.get_gamepad_id(), 3, "gamepad keeps its concrete device ID")
	assert_true.call(
		service.get_action_prompt_key(&"interact") == &"INPUT_PROMPT_INTERACT_GAMEPAD",
		"gamepad interaction prompt key is selected"
	)
	assert_true.call(
		not service.process_input_event(joy_button),
		"repeated input from the same device emits no change"
	)
	assert_true.call(
		not service.process_joy_connection_change(false, 1, 3, 7),
		"disconnect keeps gamepad mode when another controller remains"
	)
	assert_int_equal.call(service.get_gamepad_id(), 7, "disconnect selects a connected fallback gamepad")
	service.process_input_event(joy_button)

	var key_event := InputEventKey.new()
	key_event.keycode = KEY_E
	assert_true.call(
		not service.process_input_event(key_event),
		"key release does not switch devices"
	)
	key_event.pressed = true
	key_event.echo = true
	assert_true.call(
		not service.process_input_event(key_event),
		"echo key press does not switch devices"
	)
	key_event.echo = false
	assert_true.call(service.process_input_event(key_event), "keyboard input switches back")
	assert_true.call(
		service.get_action_prompt_key(&"interact") == &"INPUT_PROMPT_INTERACT_KEYBOARD",
		"keyboard interaction prompt key is selected"
	)
	assert_true.call(
		service.get_action_prompt_key(&"unknown_action") == &"INPUT_PROMPT_UNKNOWN",
		"unknown action returns a stable fallback prompt key"
	)
	service.process_input_event(joy_button)
	assert_true.call(
		service.process_joy_connection_change(false, 0),
		"last gamepad disconnect falls back to keyboard and mouse"
	)
	assert_true.call(service.get_device_id() == &"keyboard_mouse", "disconnect fallback ID is stable")
	assert_int_equal.call(service.get_gamepad_id(), -1, "disconnect clears the gamepad device ID")
	service.free()
