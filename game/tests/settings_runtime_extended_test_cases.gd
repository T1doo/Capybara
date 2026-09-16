class_name SettingsRuntimeExtendedTestCases
extends RefCounted

const DISPLAY_TEST_PATH := "user://capybara_tests/settings_display/settings.cfg"


static func run(tree: SceneTree, main_scene: GameBootstrap, assert_true: Callable) -> void:
	var service := tree.root.get_node("SettingsService") as SettingsManagerService
	var input_device := tree.root.get_node("InputDeviceService") as InputDeviceTracker
	var settings_screen := main_scene.get_node("Interface/SettingsScreen") as SettingsScreen
	var remap_screen := main_scene.get_node("Interface/InputRemapScreen") as InputRemapScreen
	var prompt := main_scene.get_node("Interface/InteractionPrompt") as InteractionPrompt
	var original: SettingsProfile = service.current_settings.duplicate_profile()
	var original_mode_dispatch: Callable = service.window_mode_dispatch
	var original_size_dispatch: Callable = service.window_size_dispatch
	var original_environment_check: Callable = service.window_environment_check
	var display_calls: Array[Dictionary] = []
	service.window_mode_dispatch = func(mode: int) -> void:
		display_calls.append({"kind": "mode", "value": mode})
	service.window_size_dispatch = func(size: Vector2i) -> void:
		display_calls.append({"kind": "size", "value": size})
	service.window_environment_check = func() -> bool:
		return true
	settings_screen.settings_path = DISPLAY_TEST_PATH
	settings_screen.open_screen()
	_select_metadata(settings_screen.display_option, SettingsProfile.DISPLAY_FULLSCREEN)
	settings_screen._apply_settings()
	assert_true.call(
		_has_call(display_calls, "mode", DisplayServer.WINDOW_MODE_FULLSCREEN),
		"settings UI requests fullscreen through the production display path"
	)
	_select_metadata(settings_screen.display_option, SettingsProfile.DISPLAY_WINDOWED)
	_select_metadata(settings_screen.resolution_option, Vector2i(1920, 1080))
	settings_screen._apply_settings()
	assert_true.call(
		_has_call(display_calls, "mode", DisplayServer.WINDOW_MODE_WINDOWED)
		and _has_call(display_calls, "size", Vector2i(1920, 1080)),
		"settings UI requests the selected windowed resolution"
	)
	assert_true.call(FileAccess.file_exists(DISPLAY_TEST_PATH), "display settings use an isolated save path")
	settings_screen.hide()
	_cleanup_display_fixture()

	var remap_profile := SettingsProfile.new()
	remap_screen.open_screen(remap_profile)
	remap_screen.begin_capture(&"hotbar_next", false)
	var partial_axis := InputEventJoypadMotion.new()
	partial_axis.axis = JOY_AXIS_RIGHT_X
	partial_axis.axis_value = 0.62
	remap_screen._input(partial_axis)
	var hotbar_events: Array = remap_profile.input_bindings[&"hotbar_next"]
	var normalized_axis: InputEventJoypadMotion = _find_joy_motion(hotbar_events)
	assert_true.call(
		normalized_axis != null and is_equal_approx(normalized_axis.axis_value, 1.0),
		"partial stick capture normalizes to a restart-safe direction"
	)
	assert_true.call(
		SettingsCodec.decode(SettingsCodec.encode(remap_profile)).success,
		"captured stick binding round trips through settings codec"
	)
	var modifier_profile := SettingsProfile.new()
	var modified_key := InputEventKey.new()
	modified_key.keycode = KEY_F
	modified_key.ctrl_pressed = true
	modified_key.device = -1
	assert_true.call(
		modifier_profile.set_input_binding(&"interact", [modified_key]),
		"settings profile accepts a supported modified key"
	)
	var modifier_round_trip: SettingsOperationResult = SettingsCodec.decode(
		SettingsCodec.encode(modifier_profile)
	)
	var restored_key: InputEventKey = null
	if modifier_round_trip.success:
		restored_key = modifier_round_trip.settings.input_bindings[&"interact"][0] as InputEventKey
	assert_true.call(
		modifier_round_trip.success
		and restored_key != null
		and restored_key.ctrl_pressed
		and restored_key.keycode == KEY_F,
		"key modifiers survive settings round trip"
	)
	service.replace_settings(modifier_round_trip.settings)
	service.apply_current_settings(false)
	input_device.process_input_event(InputEventKey.new())
	assert_true.call(
		input_device.get_action_prompt_text(&"interact").contains("Ctrl")
		and input_device.get_action_prompt_text(&"interact").contains("F"),
		"modified key prompts show the required modifier"
	)
	assert_true.call(
		not modifier_profile.set_input_binding(&"interact", [InputEventMouseButton.new()]),
		"settings profile rejects events the codec cannot encode"
	)
	remap_screen.reset_button.pressed.emit()
	assert_true.call(
		remap_screen.keyboard_buttons[&"hotbar_next"].text == "R",
		"restore defaults immediately previews the real hotbar default"
	)
	remap_screen.close_screen()

	var prompt_profile: SettingsProfile = original.duplicate_profile()
	var key := InputEventKey.new()
	key.keycode = KEY_F
	var button := InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_X
	prompt_profile.set_input_binding(&"interact", [key, button])
	service.replace_settings(prompt_profile)
	service.apply_current_settings(false)
	var keyboard := InputEventKey.new()
	keyboard.keycode = KEY_F
	keyboard.pressed = true
	input_device.process_input_event(keyboard)
	prompt._refresh_prompt()
	assert_true.call(prompt.text.ends_with("[F]"), "keyboard prompt follows the remapped interact key")
	var gamepad := InputEventJoypadButton.new()
	gamepad.device = 2
	gamepad.button_index = JOY_BUTTON_X
	gamepad.pressed = true
	input_device.process_input_event(gamepad)
	prompt._refresh_prompt()
	assert_true.call(prompt.text.ends_with("[X]"), "gamepad prompt follows the remapped interact button")

	service.window_mode_dispatch = original_mode_dispatch
	service.window_size_dispatch = original_size_dispatch
	service.window_environment_check = original_environment_check
	settings_screen.settings_path = SettingsScreen.DEFAULT_SETTINGS_PATH
	service.replace_settings(original)
	service.apply_current_settings(false)
	input_device.process_input_event(keyboard)


static func _select_metadata(option: OptionButton, target: Variant) -> void:
	for index in range(option.item_count):
		if option.get_item_metadata(index) == target:
			option.select(index)
			return


static func _has_call(calls: Array[Dictionary], kind: String, value: Variant) -> bool:
	for call in calls:
		if call["kind"] == kind and call["value"] == value:
			return true
	return false


static func _find_joy_motion(events: Array) -> InputEventJoypadMotion:
	for event in events:
		if event is InputEventJoypadMotion:
			return event as InputEventJoypadMotion
	return null


static func _cleanup_display_fixture() -> void:
	var global_path: String = ProjectSettings.globalize_path(DISPLAY_TEST_PATH)
	var base_path: String = global_path.trim_suffix(".cfg")
	for path in [global_path, base_path + ".bak.cfg", base_path + ".tmp.cfg"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
