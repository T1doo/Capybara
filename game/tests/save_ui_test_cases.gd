class_name SaveUiTestCases
extends RefCounted


static func run(
	tree: SceneTree,
	main_scene: GameBootstrap,
	assert_true: Callable,
	assert_int_equal: Callable,
	assert_vector_approx: Callable
) -> void:
	var base_path: String = "user://capybara_tests/save_ui_%d/slot" % Time.get_ticks_usec()
	var pause_menu := main_scene.get_node("Interface/PauseMenu") as PauseMenu
	var inventory_service := tree.root.get_node("InventoryService") as InventoryCoordinator
	var scene_flow := tree.root.get_node("SceneFlowService") as SceneFlowCoordinator
	var player := main_scene.get_node("Player") as PlayerCharacter
	pause_menu.save_base_path = base_path
	var baseline_branch_count: int = inventory_service.player_inventory.count_item(&"item_branch")
	var baseline_position := Vector2(222.0, -111.0)
	player.restore_runtime_state(baseline_position, &"up")
	pause_menu._pause_game()
	pause_menu._save_game()
	assert_true.call(
		pause_menu.save_status_label.text == pause_menu.tr(&"UI_SAVE_SUCCESS"),
		"pause menu production save reports success"
	)
	assert_true.call(
		FileAccess.file_exists(base_path + ".json"),
		"pause menu production save writes the main slot"
	)

	player.restore_runtime_state(Vector2(333.0, 44.0), &"right")
	inventory_service.player_inventory.add_item(&"item_reed_fiber", 1)
	pause_menu._save_game()
	assert_true.call(
		FileAccess.file_exists(base_path + ".bak.json"),
		"second pause menu save rotates a backup"
	)
	_make_main_semantically_invalid(base_path)
	scene_flow.transition_to(&"zone_grove_placeholder", &"spawn_from_home", true)
	inventory_service.player_inventory.add_item(&"item_branch", 2)
	pause_menu._load_game()
	assert_true.call(
		pause_menu.save_status_label.text == pause_menu.tr(&"UI_LOAD_RECOVERED_BACKUP"),
		"semantic main failure shows localized backup recovery"
	)
	assert_true.call(
		scene_flow.get_current_zone_id() == &"zone_home_placeholder",
		"production load applies the usable backup zone"
	)
	assert_vector_approx.call(
		player.global_position,
		baseline_position,
		"production backup load restores the prior player position"
	)
	assert_int_equal.call(
		inventory_service.player_inventory.count_item(&"item_branch"),
		baseline_branch_count,
		"production backup load restores prior inventory"
	)
	assert_true.call(tree.paused, "production load preserves pause menu ownership")
	# A recovered slot must remain recoverable after saving and another damaged main.
	pause_menu._save_game()
	assert_true.call(
		pause_menu.save_status_label.text == pause_menu.tr(&"UI_SAVE_SUCCESS"),
		"save after backup recovery succeeds"
	)
	_write_raw(base_path + ".json", "broken main after recovery and save")
	pause_menu._load_game()
	assert_true.call(
		pause_menu.save_status_label.text == pause_menu.tr(&"UI_LOAD_RECOVERED_BACKUP"),
		"saving after semantic recovery preserves a usable backup"
	)
	assert_vector_approx.call(
		player.global_position,
		baseline_position,
		"second recovery restores the last known usable position"
	)

	_write_raw(base_path + ".json", "broken main")
	_write_raw(base_path + ".bak.json", "broken backup")
	var position_before_failure: Vector2 = player.global_position
	var count_before_failure: int = inventory_service.player_inventory.count_item(&"item_branch")
	pause_menu._load_game()
	assert_true.call(
		pause_menu.save_status_label.text == pause_menu.tr(&"UI_LOAD_FAILED"),
		"double corruption shows localized load failure"
	)
	assert_vector_approx.call(
		player.global_position,
		position_before_failure,
		"failed production load preserves player position"
	)
	assert_int_equal.call(
		inventory_service.player_inventory.count_item(&"item_branch"),
		count_before_failure,
		"failed production load preserves inventory"
	)
	pause_menu._resume_game()
	_cleanup(base_path)


static func _make_main_semantically_invalid(base_path: String) -> void:
	var file := FileAccess.open(base_path + ".json", FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	data["world"]["zone_id"] = "zone_removed_after_update"
	_write_raw(base_path + ".json", JSON.stringify(data, "\t", true))


static func _write_raw(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(content)
	file.close()


static func _cleanup(base_path: String) -> void:
	for path in [base_path + ".json", base_path + ".bak.json", base_path + ".tmp.json"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var directory: String = ProjectSettings.globalize_path(base_path).get_base_dir()
	for file_name in DirAccess.get_files_at(directory):
		if file_name.begins_with(base_path.get_file() + ".json.rejected"):
			DirAccess.remove_absolute(directory.path_join(file_name))
