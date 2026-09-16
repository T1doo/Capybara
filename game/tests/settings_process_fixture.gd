extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://scenes/bootstrap/main.tscn")

func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	if arguments.size() != 2:
		push_error("SETTINGS PROCESS FIXTURE: expected mode and path")
		quit(2)
		return
	var mode: String = arguments[0]
	var path: String = arguments[1]
	match mode:
		"write":
			_write_fixture(path)
		"read":
			await _read_fixture(path)
		"cleanup":
			_cleanup_fixture(path)
		_:
			push_error("SETTINGS PROCESS FIXTURE: unknown mode")
			quit(2)


func _write_fixture(path: String) -> void:
	var service := SettingsManagerService.new()
	var profile := SettingsProfile.new()
	profile.master_volume = 0.37
	profile.ui_scale = 1.25
	profile.locale = &"en"
	profile.camera_smoothing = false
	var key := InputEventKey.new()
	key.physical_keycode = KEY_F
	var button := InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_A
	button.device = -1
	profile.set_input_binding(&"interact", [key, button])
	var replace_result: SettingsOperationResult = service.replace_settings(profile)
	var save_result: SettingsOperationResult = service.save_settings(path)
	service.free()
	if not replace_result.success or not save_result.success:
		push_error("SETTINGS PROCESS FIXTURE: write failed")
		quit(3)
		return
	print("SETTINGS PROCESS WRITE PASSED")
	quit(0)


func _read_fixture(path: String) -> void:
	var service := root.get_node("SettingsService") as SettingsManagerService
	var result: SettingsOperationResult = service.load_settings(path)
	var apply_error: StringName = service.apply_current_settings(false) if result.success else &""
	var valid: bool = result.success and apply_error.is_empty()
	if valid:
		var profile: SettingsProfile = service.current_settings
		valid = (
			profile.locale == &"en"
			and is_equal_approx(profile.ui_scale, 1.25)
			and is_equal_approx(profile.master_volume, 0.37)
			and not profile.camera_smoothing
			and _has_expected_bindings(profile.input_bindings.get(&"interact", []))
			and TranslationServer.get_locale() == "en"
			and is_equal_approx(root.content_scale_factor, 1.25)
		)
	if valid:
		var main_scene := MAIN_SCENE.instantiate() as GameBootstrap
		root.add_child(main_scene)
		await process_frame
		valid = (
			not (main_scene.get_node("Player/Camera2D") as Camera2D).position_smoothing_enabled
			and InputMap.action_get_events(&"interact").size() == 2
		)
	if not valid:
		push_error("SETTINGS PROCESS FIXTURE: read verification failed")
		quit(4)
		return
	print("SETTINGS PROCESS READ PASSED")
	quit(0)


func _cleanup_fixture(path: String) -> void:
	var global_path: String = ProjectSettings.globalize_path(path)
	var base_path: String = global_path.trim_suffix(".cfg")
	for candidate in [global_path, base_path + ".bak.cfg", base_path + ".tmp.cfg"]:
		if FileAccess.file_exists(candidate):
			if DirAccess.remove_absolute(candidate) != OK or FileAccess.file_exists(candidate):
				push_error("SETTINGS PROCESS FIXTURE: cleanup failed")
				quit(5)
				return
	DirAccess.remove_absolute(global_path.get_base_dir())
	print("SETTINGS PROCESS CLEANUP PASSED")
	quit(0)


func _has_expected_bindings(events: Array) -> bool:
	var has_keyboard: bool = false
	var has_gamepad: bool = false
	for event in events:
		if event is InputEventKey:
			var key := event as InputEventKey
			has_keyboard = key.physical_keycode == KEY_F and not key.shift_pressed
		elif event is InputEventJoypadButton:
			var button := event as InputEventJoypadButton
			has_gamepad = button.button_index == JOY_BUTTON_A and button.device == -1
	return has_keyboard and has_gamepad
