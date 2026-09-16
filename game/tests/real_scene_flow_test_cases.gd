class_name RealSceneFlowTestCases
extends RefCounted

const MAIN_SCENE: PackedScene = preload("res://scenes/bootstrap/main.tscn")


static func run(
	tree: SceneTree,
	main_scene: Node,
	player: CharacterBody2D,
	assert_true: Callable,
	assert_int_equal: Callable,
	assert_vector_approx: Callable
) -> void:
	var scene_flow := tree.root.get_node("SceneFlowService") as SceneFlowCoordinator
	var world_container := main_scene.get_node("WorldContainer") as Node2D
	assert_true.call(
		scene_flow.get_current_zone_id() == &"zone_home_placeholder",
		"real scene starts in the home zone"
	)
	assert_int_equal.call(world_container.get_child_count(), 1, "real scene starts with one active zone")
	assert_int_equal.call(
		tree.get_nodes_in_group(&"player").size(),
		1,
		"real scene starts with one persistent player"
	)

	var context := InteractionContext.new(player, player.position, Vector2.LEFT)
	var home_zone: WorldZone = scene_flow.current_zone
	var pickup := home_zone.get_node("PickupPlaceholder") as PickupInteractable
	var tool_pickup := home_zone.get_node("ReedSpadePickup") as PickupInteractable
	var resource := home_zone.get_node("ResourcePlaceholder") as ResourceInteractable
	var chest := home_zone.get_node("ChestPlaceholder") as ChestInteractable
	var inventory_service := tree.root.get_node("InventoryService") as InventoryCoordinator
	var branch_count_before_pickup: int = inventory_service.player_inventory.count_item(
		&"item_branch"
	)
	var pickup_result: InteractionResult = pickup.interact(context)
	assert_true.call(pickup_result.is_requested(), "home pickup emits a typed request")
	main_scene.call(&"_on_player_interaction_requested", pickup_result)
	assert_true.call(
		inventory_service.player_inventory.count_item(&"item_branch")
		== branch_count_before_pickup + 1,
		"home pickup enters the production inventory"
	)
	var tool_pickup_result: InteractionResult = tool_pickup.interact(context)
	main_scene.call(&"_on_player_interaction_requested", tool_pickup_result)
	assert_true.call(
		inventory_service.player_inventory.count_item(&"item_reed_spade") == 1
		and not tool_pickup.interaction_enabled,
		"reed spade pickup commits into the production inventory"
	)
	var tool_slot: int = _find_item_slot(
		inventory_service.player_inventory,
		&"item_reed_spade"
	)
	inventory_service.hotbar.assign(0, tool_slot)
	inventory_service.hotbar.assign(1, 0)
	inventory_service.hotbar.select(0)
	assert_true.call(
		(player as PlayerCharacter).get_equipped_tool_id() == &"item_reed_spade",
		"selected hotbar tool becomes the player's equipped tool"
	)
	var next_hotbar_event := InputEventAction.new()
	next_hotbar_event.action = &"hotbar_next"
	next_hotbar_event.pressed = true
	(player as PlayerCharacter)._unhandled_input(next_hotbar_event)
	assert_true.call(
		inventory_service.hotbar.selected_index == 1
		and (player as PlayerCharacter).get_equipped_tool_id().is_empty(),
		"world hotbar next input changes the equipped context"
	)
	var previous_hotbar_event := InputEventAction.new()
	previous_hotbar_event.action = &"hotbar_previous"
	previous_hotbar_event.pressed = true
	(player as PlayerCharacter)._unhandled_input(previous_hotbar_event)
	assert_true.call(
		inventory_service.hotbar.selected_index == 0
		and (player as PlayerCharacter).get_equipped_tool_id() == &"item_reed_spade",
		"world hotbar previous input restores the equipped tool"
	)
	context.equipped_tool_id = (player as PlayerCharacter).get_equipped_tool_id()
	var gather_result: InteractionResult = resource.interact(context)
	var branch_count_before_gather: int = inventory_service.player_inventory.count_item(
		&"item_branch"
	)
	main_scene.call(&"_on_player_interaction_requested", gather_result)
	assert_true.call(
		gather_result.is_requested()
		and gather_result.payload[&"tool_id"] == &"item_reed_spade"
		and inventory_service.player_inventory.count_item(&"item_branch")
		== branch_count_before_gather + 1,
		"home resource consumes the equipped tool context"
	)
	var uses_before_full_inventory: int = resource.remaining_uses
	resource.yield_quantity = 5
	var branch_slot: int = _find_item_slot(inventory_service.player_inventory, &"item_branch")
	var branch_room_to_leave: int = 98 - inventory_service.player_inventory.slots[branch_slot].quantity
	if branch_room_to_leave > 0:
		inventory_service.player_inventory.add_item(&"item_branch", branch_room_to_leave)
	inventory_service.player_inventory.add_item(&"item_reed_spade", 999)
	var branch_before_rejected_harvest: int = inventory_service.player_inventory.count_item(
		&"item_branch"
	)
	assert_true.call(
		inventory_service.player_inventory.add_item(&"item_branch", 5, true).transferred == 1,
		"multi-yield fixture exposes exactly one unit of partial capacity"
	)
	main_scene.call(&"_on_player_interaction_requested", resource.interact(context))
	assert_true.call(
		inventory_service.player_inventory.count_item(&"item_branch")
		== branch_before_rejected_harvest,
		"partial-capacity harvest does not discard unpaid yield"
	)
	assert_true.call(
		resource.remaining_uses == uses_before_full_inventory,
		"partial-capacity harvest does not consume a resource use"
	)
	inventory_service.player_inventory.remove_item(&"item_reed_spade", 5)
	inventory_service.hotbar.assign(0, _find_item_slot(inventory_service.player_inventory, &"item_reed_spade"))
	var branch_before_full_harvest: int = inventory_service.player_inventory.count_item(
		&"item_branch"
	)
	main_scene.call(&"_on_player_interaction_requested", resource.interact(context))
	assert_true.call(
		inventory_service.player_inventory.count_item(&"item_branch")
		== branch_before_full_harvest + 5,
		"full-capacity harvest transfers the complete configured yield"
	)
	assert_true.call(
		resource.remaining_uses == uses_before_full_inventory - 1,
		"complete multi-yield harvest consumes exactly one resource use"
	)
	resource.yield_quantity = 1
	assert_true.call(chest.interact(context).is_success(), "home chest changes runtime state")
	var resource_uses_after_gather: int = resource.remaining_uses
	var home_door: DoorInteractable = home_zone.find_transition_doors()[0]
	assert_true.call(home_door.interact(context).is_success(), "home door emits a transition request")
	var pause_menu := main_scene.get_node("Interface/PauseMenu") as PauseMenu
	var position_before_pause: Vector2 = player.position
	pause_menu.call(&"_pause_game")
	assert_true.call(home_door.interact(context).is_success(), "duplicate paused door request is harmless")
	assert_true.call(scene_flow.has_pending_transition(), "paused transition remains queued")
	for _frame_index in range(3):
		await tree.process_frame
	assert_true.call(
		scene_flow.get_current_zone_id() == &"zone_home_placeholder",
		"queued transition does not execute while paused"
	)
	assert_vector_approx.call(
		player.position,
		position_before_pause,
		"queued transition preserves player position while paused"
	)
	pause_menu.call(&"_resume_game")
	await tree.process_frame
	assert_true.call(
		scene_flow.get_current_zone_id() == &"zone_grove_placeholder",
		"queued transition executes once after resume"
	)
	assert_vector_approx.call(player.position, Vector2(160.0, 96.0), "grove entry spawn is applied")
	assert_int_equal.call(world_container.get_child_count(), 1, "grove transition keeps one active zone")

	var grove_door: DoorInteractable = scene_flow.current_zone.find_transition_doors()[0]
	context.actor_position = player.position
	context.facing_direction = Vector2.RIGHT
	assert_true.call(grove_door.interact(context).is_success(), "grove door emits a return request")
	await tree.process_frame
	assert_true.call(
		scene_flow.get_current_zone_id() == &"zone_home_placeholder",
		"grove door transitions back to the home zone"
	)
	assert_vector_approx.call(player.position, Vector2(-140.0, -120.0), "home return spawn is applied")
	assert_int_equal.call(world_container.get_child_count(), 1, "return transition keeps one active zone")
	assert_true.call(scene_flow.current_zone == home_zone, "round trip reuses the home zone instance")
	assert_true.call(not pickup.interaction_enabled, "round trip preserves pickup state")
	assert_int_equal.call(
		resource.remaining_uses,
		resource_uses_after_gather,
		"round trip preserves resource uses"
	)
	assert_true.call(chest.is_open, "round trip preserves chest state")
	assert_int_equal.call(
		tree.get_nodes_in_group(&"player").size(),
		1,
		"round trip preserves one persistent player"
	)
	await _test_real_player_task_context(tree, player, home_zone, assert_true)
	await _test_duplicate_bootstrap(tree, scene_flow, world_container, assert_true, assert_int_equal)


static func _find_item_slot(inventory: InventoryModel, item_id: StringName) -> int:
	for index in range(inventory.slots.size()):
		if inventory.slots[index].item_id == item_id:
			return index
	return -1


static func _test_real_player_task_context(
	tree: SceneTree,
	player: PlayerCharacter,
	home_zone: WorldZone,
	assert_true: Callable
) -> void:
	var task_target := InteractableComponent.new()
	task_target.interaction_id = &"integration_task_target"
	task_target.task_id = &"task_integration_priority"
	task_target.interaction_priority = InteractableComponent.Priority.GROUND
	task_target.position = player.position + Vector2.LEFT * 20.0
	home_zone.add_child(task_target)
	var high_priority_target := InteractableComponent.new()
	high_priority_target.interaction_id = &"integration_npc_target"
	high_priority_target.interaction_priority = InteractableComponent.Priority.NPC
	high_priority_target.position = player.position + Vector2.RIGHT * 20.0
	home_zone.add_child(high_priority_target)
	player.interaction_sensor.register_candidate(high_priority_target)
	player.interaction_sensor.register_candidate(task_target)
	player.set_active_task_id(&"task_integration_priority")
	for _frame_index in range(3):
		await tree.physics_frame
	assert_true.call(
		player.get_current_interactable() == task_target,
		"real player preserves active task priority across physics frames"
	)
	player.set_active_task_id(&"")
	await tree.physics_frame
	assert_true.call(
		player.get_current_interactable() == high_priority_target,
		"real player restores type priority after clearing active task"
	)
	player.interaction_sensor.unregister_candidate(task_target)
	player.interaction_sensor.unregister_candidate(high_priority_target)
	task_target.free()
	high_priority_target.free()


static func _test_duplicate_bootstrap(
	tree: SceneTree,
	scene_flow: SceneFlowCoordinator,
	world_container: Node2D,
	assert_true: Callable,
	assert_int_equal: Callable
) -> void:
	var duplicate_main := MAIN_SCENE.instantiate()
	var duplicate_reference: WeakRef = weakref(duplicate_main)
	tree.root.add_child(duplicate_main)
	for _frame_index in range(2):
		await tree.process_frame
	assert_true.call(
		duplicate_reference.get_ref() == null,
		"duplicate bootstrap removes itself without replacing the live world"
	)
	assert_true.call(
		scene_flow.world_container == world_container,
		"duplicate bootstrap preserves the original SceneFlow configuration"
	)
	assert_int_equal.call(
		tree.get_nodes_in_group(&"player").size(),
		1,
		"duplicate bootstrap cleanup preserves one player"
	)
