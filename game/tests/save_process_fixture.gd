extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://scenes/bootstrap/main.tscn")
const EXPECTED_POSITION: Vector2 = Vector2(321.0, -123.0)


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	if arguments.size() != 2:
		_fail("expected mode and base path", 2)
		return
	match arguments[0]:
		"write":
			await _write_fixture(arguments[1])
		"read":
			await _read_fixture(arguments[1])
		"cleanup":
			_cleanup_fixture(arguments[1])
		_:
			_fail("unknown mode", 2)


func _create_main() -> GameBootstrap:
	var main_scene := MAIN_SCENE.instantiate() as GameBootstrap
	root.add_child(main_scene)
	await process_frame
	return main_scene


func _write_fixture(base_path: String) -> void:
	var main_scene: GameBootstrap = await _create_main()
	var inventory_service := root.get_node("InventoryService") as InventoryCoordinator
	var save_manager := root.get_node("SaveManager") as SaveManagerService
	var scene_flow := root.get_node("SceneFlowService") as SceneFlowCoordinator
	var player := main_scene.get_node("Player") as PlayerCharacter
	var home_zone: WorldZone = scene_flow.current_zone
	var pickup := home_zone.get_node("PickupPlaceholder") as PickupInteractable
	var tool_pickup := home_zone.get_node("ReedSpadePickup") as PickupInteractable
	var resource := home_zone.get_node("ResourcePlaceholder") as ResourceInteractable
	var context := InteractionContext.new(player, player.global_position, Vector2.RIGHT)
	main_scene._on_player_interaction_completed(pickup.interact(context))
	main_scene._on_player_interaction_completed(tool_pickup.interact(context))
	var tool_slot: int = _find_item_slot(inventory_service.player_inventory, &"item_reed_spade")
	inventory_service.hotbar.assign(5, tool_slot)
	inventory_service.hotbar.select(5)
	context.equipped_tool_id = player.get_equipped_tool_id()
	main_scene._on_player_interaction_completed(resource.interact(context))
	inventory_service.player_inventory.add_item(&"item_branch", 7)
	var storage := inventory_service.create_storage(&"storage_process_test", 8)
	storage.add_item(&"item_reed_fiber", 6)
	player.restore_runtime_state(EXPECTED_POSITION, &"up_left")
	var snapshot: SaveOperationResult = save_manager.create_runtime_snapshot(
		inventory_service,
		player,
		scene_flow,
		"process_test"
	)
	if not snapshot.success:
		_fail("snapshot creation failed", 3)
		return
	var save_result: SaveOperationResult = save_manager.save_game(base_path, snapshot.data)
	if not save_result.success:
		_fail("write failed", 3)
		return
	print("SAVE PROCESS WRITE PASSED")
	quit(0)


func _read_fixture(base_path: String) -> void:
	var main_scene: GameBootstrap = await _create_main()
	var inventory_service := root.get_node("InventoryService") as InventoryCoordinator
	var save_manager := root.get_node("SaveManager") as SaveManagerService
	var scene_flow := root.get_node("SceneFlowService") as SceneFlowCoordinator
	var player := main_scene.get_node("Player") as PlayerCharacter
	if not scene_flow.transition_to(&"zone_grove_placeholder", &"spawn_from_home"):
		_fail("pre-load transition failed", 4)
		return
	inventory_service.player_inventory.add_item(&"item_reed_fiber", 1)
	player.restore_runtime_state(Vector2.ZERO, &"down")
	var load_result: SaveOperationResult = save_manager.load_game(base_path)
	var apply_result := SaveOperationResult.failed(&"SAVE_PROCESS_NOT_APPLIED")
	if load_result.success:
		apply_result = save_manager.apply_runtime_snapshot(
			load_result.data,
			inventory_service,
			player,
			scene_flow
		)
	var storage: StorageInventory = inventory_service.storages.get(
		&"storage_process_test"
	) as StorageInventory
	var home_zone: WorldZone = scene_flow.current_zone
	var pickup := home_zone.get_node("PickupPlaceholder") as PickupInteractable
	var tool_pickup := home_zone.get_node("ReedSpadePickup") as PickupInteractable
	var resource := home_zone.get_node("ResourcePlaceholder") as ResourceInteractable
	var valid: bool = (
		load_result.success
		and apply_result.success
		and scene_flow.get_current_zone_id() == &"zone_home_placeholder"
		and scene_flow.get_current_spawn_id() == &"spawn_home_start"
		and player.global_position.is_equal_approx(EXPECTED_POSITION)
		and player.get_facing_id() == &"up_left"
		and inventory_service.player_inventory.count_item(&"item_branch") == 9
		and inventory_service.player_inventory.count_item(&"item_reed_fiber") == 0
		and inventory_service.player_inventory.count_item(&"item_reed_spade") == 1
		and inventory_service.hotbar.selected_index == 5
		and inventory_service.hotbar.assignments[5] >= 0
		and player.get_equipped_tool_id() == &"item_reed_spade"
		and storage != null
		and storage.count_item(&"item_reed_fiber") == 6
		and pickup.quantity == 0
		and not pickup.interaction_enabled
		and tool_pickup.quantity == 0
		and not tool_pickup.interaction_enabled
		and resource.remaining_uses == 2
	)
	if not valid:
		_fail("read verification failed", 5)
		return
	print("SAVE PROCESS READ PASSED")
	quit(0)


func _cleanup_fixture(base_path: String) -> void:
	var global_base: String = ProjectSettings.globalize_path(base_path)
	for path in [global_base + ".json", global_base + ".bak.json", global_base + ".tmp.json"]:
		if FileAccess.file_exists(path):
			if DirAccess.remove_absolute(path) != OK or FileAccess.file_exists(path):
				_fail("cleanup failed", 6)
				return
	DirAccess.remove_absolute(global_base.get_base_dir())
	print("SAVE PROCESS CLEANUP PASSED")
	quit(0)


func _find_item_slot(inventory: InventoryModel, item_id: StringName) -> int:
	for index in range(inventory.slots.size()):
		if inventory.slots[index].item_id == item_id:
			return index
	return -1


func _fail(message: String, exit_code: int) -> void:
	push_error("SAVE PROCESS FIXTURE: %s" % message)
	quit(exit_code)
