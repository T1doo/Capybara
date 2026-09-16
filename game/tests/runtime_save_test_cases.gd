class_name RuntimeSaveTestCases
extends RefCounted


static func run(
	tree: SceneTree,
	main_scene: Node,
	assert_true: Callable,
	assert_int_equal: Callable,
	assert_vector_approx: Callable
) -> void:
	var save_manager := tree.root.get_node("SaveManager") as SaveManagerService
	var inventory_service := tree.root.get_node("InventoryService") as InventoryCoordinator
	var scene_flow := tree.root.get_node("SceneFlowService") as SceneFlowCoordinator
	var player := main_scene.get_node("Player") as PlayerCharacter
	var inventory_screen := main_scene.get_node("Interface/InventoryScreen") as InventoryScreen
	var storage_screen := main_scene.get_node("Interface/StorageScreen") as StorageScreen
	inventory_service.player_inventory.add_item(&"item_branch", 4)
	inventory_service.hotbar.assign(0, 0)
	inventory_service.hotbar.select(3)
	var storage: StorageInventory = inventory_service.create_storage(&"storage_runtime_test", 4)
	storage.add_item(&"item_reed_fiber", 2)
	storage_screen.configure(inventory_service.player_inventory, storage)
	player.global_position = Vector2(144.0, -72.0)
	player.facing = Direction8.Value.RIGHT
	player.last_move_direction = Vector2.RIGHT
	var snapshot_result: SaveOperationResult = save_manager.create_runtime_snapshot(
		inventory_service,
		player,
		scene_flow,
		"runtime_test"
	)
	assert_true.call(snapshot_result.success, "runtime snapshot creation succeeds")

	assert_true.call(
		scene_flow.transition_to(&"zone_grove_placeholder", &"spawn_from_home"),
		"runtime test moves to a different zone before load"
	)
	var grove_resource := scene_flow.current_zone.get_node(
		"ResourcePlaceholder"
	) as ResourceInteractable
	grove_resource.remaining_uses = 1
	inventory_service.player_inventory.remove_item(&"item_branch", 4)
	inventory_service.hotbar.select(0)
	storage.remove_item(&"item_reed_fiber", 2)
	player.global_position = Vector2.ZERO
	tree.paused = true
	scene_flow.request_transition(&"zone_grove_placeholder", &"spawn_from_home")
	assert_true.call(scene_flow.has_pending_transition(), "paused load fixture queues stale travel")
	var observed_zone_position: Dictionary = {"value": Vector2.INF}
	var observe_zone_change := func(
		_previous_zone_id: StringName,
		_current_zone_id: StringName,
		_spawn_id: StringName
	) -> void:
		observed_zone_position["value"] = player.global_position
	scene_flow.zone_changed.connect(observe_zone_change)
	var apply_result: SaveOperationResult = save_manager.apply_runtime_snapshot(
		snapshot_result.data,
		inventory_service,
		player,
		scene_flow
	)
	scene_flow.zone_changed.disconnect(observe_zone_change)
	assert_true.call(apply_result.success, "runtime snapshot applies while the pause menu owns pause")
	assert_true.call(tree.paused, "runtime load preserves the caller's paused state")
	assert_true.call(not scene_flow.has_pending_transition(), "runtime load cancels stale queued travel")
	tree.paused = false
	assert_true.call(
		scene_flow.get_current_zone_id() == &"zone_home_placeholder",
		"runtime load restores the saved zone"
	)
	assert_int_equal.call(
		inventory_service.player_inventory.count_item(&"item_branch"),
		4,
		"runtime load restores player inventory"
	)
	assert_int_equal.call(inventory_service.hotbar.selected_index, 3, "runtime load restores hotbar selection")
	assert_int_equal.call(
		inventory_service.storages[&"storage_runtime_test"].count_item(&"item_reed_fiber"),
		2,
		"runtime load restores storage inventory"
	)
	assert_vector_approx.call(player.global_position, Vector2(144.0, -72.0), "runtime load restores player position")
	assert_vector_approx.call(
		observed_zone_position["value"],
		Vector2(144.0, -72.0),
		"zone change listeners observe the final restored position"
	)
	assert_true.call(player.get_facing_id() == &"right", "runtime load restores player facing")
	assert_true.call(
		inventory_screen.inventory == inventory_service.player_inventory,
		"runtime load rebinds inventory UI to replaced models"
	)
	assert_true.call(
		storage_screen.player_inventory == inventory_service.player_inventory
		and storage_screen.storage == inventory_service.storages[&"storage_runtime_test"],
		"runtime load rebinds storage UI to replaced models"
	)
	var restored_grove := scene_flow.cached_zones[&"zone_grove_placeholder"] as WorldZone
	assert_true.call(
		(restored_grove.get_node("ResourcePlaceholder") as ResourceInteractable).remaining_uses == 3,
		"load resets a post-save visited zone to its saved default state"
	)

	var wrong_zone_data: Dictionary = snapshot_result.data.duplicate(true)
	wrong_zone_data["world"]["zone_id"] = "zone_missing"
	var inventory_before: int = inventory_service.player_inventory.count_item(&"item_branch")
	assert_true.call(
		not save_manager.apply_runtime_snapshot(
			wrong_zone_data,
			inventory_service,
			player,
			scene_flow
		).success,
		"unknown runtime zone is rejected during preflight"
	)
	assert_int_equal.call(
		inventory_service.player_inventory.count_item(&"item_branch"),
		inventory_before,
		"rejected zone preflight preserves runtime inventory"
	)
	var wrong_interaction_data: Dictionary = snapshot_result.data.duplicate(true)
	wrong_interaction_data["world_state"]["zone_home_placeholder"]["removed_pickup"] = {
		"type": WorldStateCodec.TYPE_PICKUP,
		"quantity": 0,
	}
	assert_true.call(
		not save_manager.apply_runtime_snapshot(
			wrong_interaction_data, inventory_service, player, scene_flow
		).success,
		"unknown world interaction is rejected before runtime mutation"
	)
	assert_int_equal.call(
		inventory_service.player_inventory.count_item(&"item_branch"),
		inventory_before,
		"rejected world state preserves runtime inventory"
	)
	var partial_world_data: Dictionary = snapshot_result.data.duplicate(true)
	partial_world_data["world_state"]["zone_home_placeholder"].erase(
		"pickup_branch_placeholder"
	)
	var home_pickup := scene_flow.current_zone.get_node("PickupPlaceholder") as PickupInteractable
	home_pickup.quantity = 0
	home_pickup.interaction_enabled = false
	assert_true.call(
		save_manager.apply_runtime_snapshot(
			partial_world_data, inventory_service, player, scene_flow
		).success,
		"missing interaction entries restore from the fresh scene default"
	)
	assert_true.call(
		home_pickup.quantity == 1 and home_pickup.interaction_enabled,
		"missing pickup state does not preserve post-save mutation"
	)
