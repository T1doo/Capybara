class_name SettingsManagerService
extends Node

signal settings_changed(settings: SettingsProfile)

const DEFAULT_PATH: String = "user://settings.cfg"

var current_settings := SettingsProfile.new()
var last_error_key: StringName = &""
var window_mode_dispatch: Callable
var window_size_dispatch: Callable
var window_environment_check: Callable


func _ready() -> void:
	window_mode_dispatch = _dispatch_window_mode
	window_size_dispatch = _dispatch_window_size
	window_environment_check = func() -> bool:
		return DisplayServer.get_name().to_lower() != "headless"
	InputSetup.ensure_default_actions()
	var result: SettingsOperationResult = load_settings()
	if not result.success:
		last_error_key = result.reason_key
	apply_current_settings()
	call_deferred(&"_apply_input_bindings")


func replace_settings(profile: SettingsProfile) -> SettingsOperationResult:
	if profile == null:
		return SettingsOperationResult.failed(&"SETTINGS_PROFILE_MISSING")
	var validation_error: StringName = profile.validate()
	if not validation_error.is_empty():
		return SettingsOperationResult.failed(validation_error)
	current_settings = profile.duplicate_profile()
	last_error_key = &""
	settings_changed.emit(current_settings.duplicate_profile())
	return SettingsOperationResult.succeeded(current_settings.duplicate_profile())


func apply_current_settings(apply_window: bool = true) -> StringName:
	var validation_error: StringName = current_settings.validate()
	if not validation_error.is_empty():
		return validation_error
	_ensure_audio_bus(&"Music")
	_ensure_audio_bus(&"SFX")
	_apply_bus_volume(&"Master", current_settings.master_volume)
	_apply_bus_volume(&"Music", current_settings.music_volume)
	_apply_bus_volume(&"SFX", current_settings.sound_volume)
	TranslationServer.set_locale(String(current_settings.locale))
	get_tree().root.content_scale_factor = current_settings.ui_scale
	_apply_input_bindings()
	if apply_window and window_environment_check.call():
		_apply_window_settings()
	settings_changed.emit(current_settings.duplicate_profile())
	return &""


func save_settings(path: String = DEFAULT_PATH) -> SettingsOperationResult:
	var validation_error: StringName = current_settings.validate()
	if not validation_error.is_empty():
		return SettingsOperationResult.failed(validation_error)
	var paths: Dictionary = _build_paths(path)
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(
		String(paths["main"]).get_base_dir()
	)
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		return SettingsOperationResult.failed(&"SETTINGS_DIRECTORY_CREATE_FAILED")
	_remove_if_exists(paths["temp"])
	var config := ConfigFile.new()
	config.set_value(
		"settings",
		"payload",
		JSON.stringify(SettingsCodec.encode(current_settings), "\t", true)
	)
	if config.save(paths["temp"]) != OK:
		return SettingsOperationResult.failed(&"SETTINGS_TEMP_WRITE_FAILED")
	var temp_result: SettingsOperationResult = _read_validated(paths["temp"])
	if not temp_result.success:
		_remove_if_exists(paths["temp"])
		return temp_result
	if FileAccess.file_exists(paths["main"]):
		var current_main: SettingsOperationResult = _read_validated(paths["main"])
		if current_main.success:
			_remove_if_exists(paths["backup"])
			if DirAccess.rename_absolute(paths["main"], paths["backup"]) != OK:
				_remove_if_exists(paths["temp"])
				return SettingsOperationResult.failed(&"SETTINGS_BACKUP_ROTATION_FAILED")
		else:
			_remove_if_exists(paths["main"])
	if DirAccess.rename_absolute(paths["temp"], paths["main"]) != OK:
		return SettingsOperationResult.failed(&"SETTINGS_COMMIT_FAILED")
	return SettingsOperationResult.succeeded(
		current_settings.duplicate_profile(),
		paths["main"]
	)


func load_settings(path: String = DEFAULT_PATH) -> SettingsOperationResult:
	var paths: Dictionary = _build_paths(path)
	if (
		not FileAccess.file_exists(paths["main"])
		and not FileAccess.file_exists(paths["backup"])
	):
		current_settings = SettingsProfile.new()
		last_error_key = &""
		return SettingsOperationResult.succeeded(current_settings.duplicate_profile())
	var result: SettingsOperationResult = _read_validated(paths["main"])
	if not result.success:
		var backup_result: SettingsOperationResult = _read_validated(paths["backup"])
		if not backup_result.success:
			last_error_key = result.reason_key
			return result
		result = backup_result
		result.recovered_from_backup = true
	current_settings = result.settings.duplicate_profile()
	last_error_key = &""
	result.settings = current_settings.duplicate_profile()
	result.source_path = paths["backup"] if result.recovered_from_backup else paths["main"]
	settings_changed.emit(current_settings.duplicate_profile())
	return result


func _read_validated(path: String) -> SettingsOperationResult:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return SettingsOperationResult.failed(&"SETTINGS_FILE_PARSE_FAILED")
	if not config.has_section_key("settings", "payload"):
		return SettingsOperationResult.failed(&"SETTINGS_PAYLOAD_MISSING")
	var payload: Variant = config.get_value("settings", "payload")
	if not payload is String:
		return SettingsOperationResult.failed(&"SETTINGS_PAYLOAD_MISSING")
	var json := JSON.new()
	if json.parse(payload) != OK:
		return SettingsOperationResult.failed(&"SETTINGS_JSON_PARSE_FAILED")
	return SettingsCodec.decode(json.data)


func _build_paths(path: String) -> Dictionary:
	var global_path: String = ProjectSettings.globalize_path(path)
	var extension: String = global_path.get_extension()
	var base_path: String = global_path.trim_suffix(".%s" % extension)
	return {
		"main": global_path,
		"backup": "%s.bak.%s" % [base_path, extension],
		"temp": "%s.tmp.%s" % [base_path, extension],
	}


func _remove_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _ensure_audio_bus(bus_name: StringName) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)


func _apply_bus_volume(bus_name: StringName, linear_volume: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	AudioServer.set_bus_mute(bus_index, is_zero_approx(linear_volume))
	if not is_zero_approx(linear_volume):
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(linear_volume))


func _apply_input_bindings() -> void:
	for action in SettingsProfile.REMAPPABLE_ACTIONS:
		if not current_settings.input_bindings.has(action):
			InputSetup.reset_action_to_defaults(action)
			continue
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		for event in current_settings.input_bindings[action]:
			InputMap.action_add_event(action, (event as InputEvent).duplicate())


func _apply_window_settings() -> void:
	if current_settings.display_mode == SettingsProfile.DISPLAY_FULLSCREEN:
		window_mode_dispatch.call(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	window_mode_dispatch.call(DisplayServer.WINDOW_MODE_WINDOWED)
	window_size_dispatch.call(current_settings.resolution)


func _dispatch_window_mode(mode: DisplayServer.WindowMode) -> void:
	DisplayServer.window_set_mode(mode)


func _dispatch_window_size(size: Vector2i) -> void:
	DisplayServer.window_set_size(size)
