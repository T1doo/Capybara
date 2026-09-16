class_name SettingsTestCases
extends RefCounted

const TEST_PATH: String = "user://capybara_tests/settings_service/settings.cfg"
const EXTENDED_RUNTIME_TESTS: Script = preload(
	"res://tests/settings_runtime_extended_test_cases.gd"
)


static func run(assert_true: Callable, assert_int_equal: Callable) -> void:
	_cleanup()
	_run_data_tests(assert_true, assert_int_equal)


static func run_runtime(
	tree: SceneTree,
	main_scene: GameBootstrap,
	assert_true: Callable,
	assert_float_approx: Callable
) -> void:
	var service := tree.root.get_node("SettingsService") as SettingsManagerService
	var original: SettingsProfile = service.current_settings.duplicate_profile()
	var candidate: SettingsProfile = original.duplicate_profile()
	candidate.master_volume = 0.5
	candidate.ui_scale = 1.25
	candidate.locale = &"en"
	candidate.camera_smoothing = true
	candidate.reduced_motion = true
	candidate.gamepad_vibration = false
	candidate.high_contrast_interactions = true
	var remapped_key := InputEventKey.new()
	remapped_key.physical_keycode = KEY_F
	candidate.set_input_binding(&"interact", [remapped_key])
	assert_true.call(
		service.replace_settings(candidate).success,
		"runtime settings accept a valid candidate"
	)
	assert_true.call(
		service.apply_current_settings(false).is_empty(),
		"runtime settings apply without changing the test window"
	)
	assert_float_approx.call(
		tree.root.content_scale_factor,
		1.25,
		"runtime settings apply UI scale"
	)
	assert_true.call(TranslationServer.get_locale() == "en", "runtime settings apply locale")
	assert_true.call(
		InputMap.action_has_event(&"interact", remapped_key),
		"runtime settings apply remapped input"
	)
	var camera := main_scene.get_node("Player/Camera2D") as Camera2D
	assert_true.call(
		not camera.position_smoothing_enabled,
		"reduced motion disables camera smoothing"
	)
	var accessibility := tree.root.get_node(
		"AccessibilityService"
	) as AccessibilityFeedbackService
	assert_true.call(accessibility.reduced_motion_enabled, "reduced motion reaches its service")
	assert_true.call(
		accessibility.high_contrast_interactions_enabled,
		"high contrast reaches its service"
	)
	var prompt := main_scene.get_node("Interface/InteractionPrompt") as InteractionPrompt
	assert_true.call(
		prompt.get_theme_color(&"font_color") == InteractionPrompt.HIGH_CONTRAST_FONT_COLOR,
		"high contrast changes the production interaction prompt"
	)
	var current_target: InteractableComponent = (
		main_scene.get_node("Player") as PlayerCharacter
	).get_current_interactable()
	assert_true.call(
		current_target != null
		and current_target.modulate == InteractionPrompt.HIGH_CONTRAST_TARGET_MODULATE,
		"high contrast highlights the selected world interaction"
	)
	var vibration_calls: Array[Dictionary] = []
	var original_dispatch: Callable = accessibility.vibration_dispatch
	accessibility.vibration_dispatch = func(
		device_id: int,
		weak: float,
		strong: float,
		duration: float
	) -> void:
		vibration_calls.append({
			"device_id": device_id,
			"weak": weak,
			"strong": strong,
			"duration": duration,
		})
	var input_device := tree.root.get_node("InputDeviceService") as InputDeviceTracker
	var joy_button := InputEventJoypadButton.new()
	joy_button.device = 5
	joy_button.button_index = JOY_BUTTON_A
	joy_button.pressed = true
	input_device.process_input_event(joy_button)
	main_scene._on_player_interaction_completed(InteractionResult.succeeded())
	assert_true.call(vibration_calls.is_empty(), "disabled vibration blocks production feedback")
	service.current_settings.gamepad_vibration = true
	service.apply_current_settings(false)
	main_scene._on_player_interaction_completed(InteractionResult.succeeded())
	assert_true.call(vibration_calls.size() == 1, "enabled vibration dispatches interaction feedback")
	assert_true.call(vibration_calls[0]["device_id"] == 5, "vibration uses the active gamepad ID")
	accessibility.vibration_dispatch = original_dispatch
	var master_index: int = AudioServer.get_bus_index(&"Master")
	assert_true.call(master_index >= 0, "runtime settings find the Master audio bus")
	assert_float_approx.call(
		db_to_linear(AudioServer.get_bus_volume_db(master_index)),
		0.5,
		"runtime settings apply master volume"
	)

	service.replace_settings(original)
	service.apply_current_settings(false)
	var keyboard_event := InputEventKey.new()
	keyboard_event.keycode = KEY_E
	keyboard_event.pressed = true
	input_device.process_input_event(keyboard_event)
	var default_interact_key := InputEventKey.new()
	default_interact_key.physical_keycode = KEY_E
	assert_true.call(
		InputMap.action_has_event(&"interact", default_interact_key),
		"clearing an override restores the default input binding"
	)
	assert_true.call(
		not InputMap.action_has_event(&"interact", remapped_key),
		"restoring defaults removes the previous custom binding"
	)

	var pause_menu := main_scene.get_node("Interface/PauseMenu") as PauseMenu
	var settings_screen := main_scene.get_node("Interface/SettingsScreen") as SettingsScreen
	pause_menu._pause_game()
	pause_menu.settings_button.pressed.emit()
	assert_true.call(
		tree.paused and settings_screen.visible and not pause_menu.visible,
		"pause menu opens settings as a paused modal"
	)
	assert_true.call(
		settings_screen.language_option.has_focus(),
		"settings screen focuses the first control"
	)
	var settings_panel := settings_screen.responsive_scroll.panel
	assert_true.call(
		settings_panel.size.y <= 800.0,
		"settings panel fits the 1280 by 800 target height"
	)
	settings_screen.controls_button.pressed.emit()
	var remap_screen := main_scene.get_node("Interface/InputRemapScreen") as InputRemapScreen
	assert_true.call(
		remap_screen.visible and not settings_screen.visible,
		"settings opens the dedicated input remap screen"
	)
	assert_true.call(
		remap_screen.keyboard_buttons[&"move_left"].has_focus(),
		"input remap screen focuses the first keyboard binding"
	)
	remap_screen.begin_capture(&"interact", true)
	var captured_key := InputEventKey.new()
	captured_key.keycode = KEY_F
	captured_key.physical_keycode = KEY_PAUSE
	captured_key.pressed = true
	remap_screen._input(captured_key)
	assert_true.call(
		settings_screen.draft_profile.input_bindings.has(&"interact"),
		"captured input updates the settings draft"
	)
	var captured_events: Array = settings_screen.draft_profile.input_bindings[&"interact"]
	assert_true.call(
		_has_key(captured_events, KEY_F),
		"keyboard capture stores the requested logical key"
	)
	assert_true.call(
		remap_screen.keyboard_buttons[&"interact"].text == "F",
		"keyboard binding display prefers the logical keycode"
	)
	assert_true.call(
		_has_gamepad_event(captured_events),
		"keyboard capture preserves the gamepad binding"
	)
	remap_screen.reset_button.pressed.emit()
	assert_true.call(
		settings_screen.draft_profile.input_bindings.is_empty(),
		"restore defaults clears every custom input override"
	)
	remap_screen.back_button.pressed.emit()
	assert_true.call(
		settings_screen.visible and settings_screen.controls_button.has_focus(),
		"input remap Back restores settings focus"
	)
	settings_screen.back_button.pressed.emit()
	assert_true.call(
		pause_menu.visible and not settings_screen.visible,
		"settings Back returns to the pause menu"
	)
	assert_true.call(
		pause_menu.settings_button.has_focus(),
		"settings Back restores pause menu focus"
	)
	pause_menu._resume_game()
	await EXTENDED_RUNTIME_TESTS.run(tree, main_scene, assert_true)


static func _has_key(events: Array, keycode: int) -> bool:
	for event in events:
		if event is InputEventKey:
			var key := event as InputEventKey
			if key.keycode == keycode or key.physical_keycode == keycode:
				return true
	return false


static func _has_gamepad_event(events: Array) -> bool:
	for event in events:
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			return true
	return false


static func _run_data_tests(assert_true: Callable, assert_int_equal: Callable) -> void:
	var profile := SettingsProfile.new()
	profile.master_volume = 0.65
	profile.music_volume = 0.4
	profile.sound_volume = 0.75
	profile.resolution = Vector2i(1280, 800)
	profile.ui_scale = 1.25
	profile.locale = &"en"
	profile.reduced_motion = true
	var interact_key := InputEventKey.new()
	interact_key.physical_keycode = KEY_F
	assert_true.call(
		profile.set_input_binding(&"interact", [interact_key]),
		"settings accepts a remappable keyboard binding"
	)
	var encoded: Dictionary = SettingsCodec.encode(profile)
	var decoded: SettingsOperationResult = SettingsCodec.decode(encoded)
	assert_true.call(decoded.success, "settings data round trip succeeds")
	assert_true.call(
		is_equal_approx(decoded.settings.master_volume, 0.65),
		"master volume survives settings round trip"
	)
	assert_true.call(
		decoded.settings.resolution == Vector2i(1280, 800),
		"resolution survives settings round trip"
	)
	assert_true.call(decoded.settings.locale == &"en", "locale survives settings round trip")
	assert_true.call(decoded.settings.reduced_motion, "accessibility flag survives round trip")
	var decoded_events: Array = decoded.settings.input_bindings[&"interact"]
	assert_int_equal.call(decoded_events.size(), 1, "input binding survives settings round trip")
	assert_true.call(
		(decoded_events[0] as InputEventKey).physical_keycode == KEY_F,
		"physical key binding survives settings round trip"
	)

	var service := SettingsManagerService.new()
	var replace_result: SettingsOperationResult = service.replace_settings(profile)
	assert_true.call(replace_result.success, "settings service accepts a valid profile")
	var save_result: SettingsOperationResult = service.save_settings(TEST_PATH)
	assert_true.call(save_result.success, "settings service atomically writes settings.cfg")
	assert_true.call(FileAccess.file_exists(TEST_PATH), "settings main file exists after save")
	assert_true.call(
		not FileAccess.file_exists(_path_with_suffix("tmp")),
		"settings save leaves no temporary file"
	)

	service.current_settings = SettingsProfile.new()
	var load_result: SettingsOperationResult = service.load_settings(TEST_PATH)
	assert_true.call(load_result.success, "settings service reloads validated data")
	assert_true.call(
		service.current_settings.resolution == Vector2i(1280, 800),
		"settings reload restores resolution"
	)
	assert_true.call(
		is_equal_approx(service.current_settings.ui_scale, 1.25),
		"settings reload restores UI scale"
	)

	var invalid := profile.duplicate_profile()
	invalid.ui_scale = 1.1
	assert_true.call(
		not service.replace_settings(invalid).success,
		"unsupported UI scale is rejected"
	)
	assert_true.call(
		is_equal_approx(service.current_settings.ui_scale, 1.25),
		"rejected settings preserve active profile"
	)

	service.current_settings.locale = &"zh_CN"
	assert_true.call(service.save_settings(TEST_PATH).success, "second settings save creates a backup")
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string("not a valid config")
	file.close()
	var recovered_result: SettingsOperationResult = service.load_settings(TEST_PATH)
	assert_true.call(recovered_result.success, "corrupt settings main recovers its backup")
	assert_true.call(recovered_result.recovered_from_backup, "settings recovery reports backup use")
	assert_true.call(service.current_settings.locale == &"en", "settings backup restores prior data")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	var missing_main_result: SettingsOperationResult = service.load_settings(TEST_PATH)
	assert_true.call(missing_main_result.success, "missing settings main recovers its backup")
	assert_true.call(missing_main_result.recovered_from_backup, "missing main reports backup recovery")
	file = FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string("not a valid config")
	file.close()
	file = FileAccess.open(_path_with_suffix("bak"), FileAccess.WRITE)
	file.store_string("not a valid backup")
	file.close()
	var before_corrupt_load: SettingsProfile = service.current_settings.duplicate_profile()
	var corrupt_result: SettingsOperationResult = service.load_settings(TEST_PATH)
	assert_true.call(not corrupt_result.success, "corrupt settings main and backup fail clearly")
	assert_true.call(
		service.current_settings.locale == before_corrupt_load.locale,
		"corrupt settings load preserves active profile"
	)
	service.free()
	_cleanup()


static func _path_with_suffix(suffix: String) -> String:
	var global_path: String = ProjectSettings.globalize_path(TEST_PATH)
	return global_path.trim_suffix(".cfg") + ".%s.cfg" % suffix


static func _cleanup() -> void:
	for path in [
		ProjectSettings.globalize_path(TEST_PATH),
		_path_with_suffix("bak"),
		_path_with_suffix("tmp"),
	]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
