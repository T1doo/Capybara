extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://scenes/bootstrap/main.tscn")
const SAVE_BASE_PATH := "user://capybara_tests/save_ui_visual/slot"


func _init() -> void:
	call_deferred(&"_show_pause_menu")


func _finalize() -> void:
	_cleanup_fixture_files()


func _show_pause_menu() -> void:
	var main_scene := MAIN_SCENE.instantiate() as GameBootstrap
	root.add_child(main_scene)
	await process_frame
	var pause_menu := main_scene.get_node("Interface/PauseMenu") as PauseMenu
	pause_menu.save_base_path = SAVE_BASE_PATH
	pause_menu._pause_game()


func _cleanup_fixture_files() -> void:
	for suffix in [".json", ".bak.json", ".tmp.json"]:
		var path: String = SAVE_BASE_PATH + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
