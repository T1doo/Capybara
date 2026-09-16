extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://scenes/bootstrap/main.tscn")
const SETTINGS_PATH := "user://capybara_tests/display_visual/settings.cfg"


func _init() -> void:
	call_deferred(&"_show_settings")


func _finalize() -> void:
	var global_path: String = ProjectSettings.globalize_path(SETTINGS_PATH)
	var base_path: String = global_path.trim_suffix(".cfg")
	for path in [global_path, base_path + ".bak.cfg", base_path + ".tmp.cfg"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


func _show_settings() -> void:
	var resolution := Vector2i(1280, 720)
	var ui_scale: float = 1.5
	var screen_name: String = "settings"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--resolution="):
			var parts := argument.trim_prefix("--resolution=").split("x")
			if parts.size() == 2:
				resolution = Vector2i(int(parts[0]), int(parts[1]))
		elif argument.begins_with("--scale="):
			ui_scale = float(argument.trim_prefix("--scale="))
		elif argument.begins_with("--screen="):
			screen_name = argument.trim_prefix("--screen=")
	if DisplayServer.get_name().to_lower() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(resolution)
	root.content_scale_factor = ui_scale
	var main_scene := MAIN_SCENE.instantiate() as GameBootstrap
	root.add_child(main_scene)
	await process_frame
	if screen_name == "contrast":
		_show_high_contrast_prompt(main_scene)
		return
	var pause_menu := main_scene.get_node("Interface/PauseMenu") as PauseMenu
	if screen_name == "inventory":
		(main_scene.get_node("Interface/InventoryScreen") as InventoryScreen).open_inventory()
	elif screen_name == "storage":
		var inventory_service := root.get_node("InventoryService") as InventoryCoordinator
		var storage := inventory_service.create_storage(&"storage_visual_matrix")
		var storage_screen := main_scene.get_node("Interface/StorageScreen") as StorageScreen
		storage_screen.configure(inventory_service.player_inventory, storage)
		storage_screen.open_screen()
	else:
		pause_menu._pause_game()
		if screen_name == "settings" or screen_name == "remap":
			var settings_screen := main_scene.get_node("Interface/SettingsScreen") as SettingsScreen
			settings_screen.settings_path = SETTINGS_PATH
			pause_menu.settings_button.pressed.emit()
		if screen_name == "remap":
			var settings := main_scene.get_node("Interface/SettingsScreen") as SettingsScreen
			settings.controls_button.pressed.emit()


func _show_high_contrast_prompt(main_scene: GameBootstrap) -> void:
	var settings_service := root.get_node("SettingsService") as SettingsManagerService
	var profile: SettingsProfile = settings_service.current_settings.duplicate_profile()
	profile.high_contrast_interactions = true
	profile.reduced_motion = true
	settings_service.replace_settings(profile)
	settings_service.apply_current_settings(false)
	var player := main_scene.get_node("Player") as PlayerCharacter
	player.global_position = Vector2(56.0, 0.0)
