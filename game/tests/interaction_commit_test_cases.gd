class_name InteractionCommitTestCases
extends RefCounted


static func run(tree: SceneTree, main: GameBootstrap, check: Callable) -> void:
	var service := tree.root.get_node("InventoryService") as InventoryCoordinator
	var flow := tree.root.get_node("SceneFlowService") as SceneFlowCoordinator
	var player: PlayerCharacter = main.player
	var inventory: InventoryModel = service.player_inventory
	var saved_inventory: Dictionary = InventoryDataCodec.encode_inventory(inventory)
	var saved_hotbar: Dictionary = InventoryDataCodec.encode_hotbar(service.hotbar)
	var resource := flow.current_zone.get_node("ResourcePlaceholder") as ResourceInteractable
	var saved_uses: int = resource.remaining_uses
	var saved_yield: int = resource.yield_quantity
	var pickup := flow.current_zone.get_node("PickupPlaceholder") as PickupInteractable
	var saved_quantity: int = pickup.quantity
	var saved_pickup_enabled: bool = pickup.interaction_enabled
	var accessibility := tree.root.get_node("AccessibilityService") as AccessibilityFeedbackService
	var input_device := tree.root.get_node("InputDeviceService") as InputDeviceTracker
	var original_dispatch: Callable = accessibility.vibration_dispatch
	var original_enabled: bool = accessibility.gamepad_vibration_enabled
	var original_device: int = input_device.current_device
	var original_gamepad: int = input_device.current_gamepad_id
	var vibration_calls: Array[int] = []
	var completed: Array[InteractionResult] = []
	var observed_state: Array[Vector2i] = []
	var listener: Callable = func(result: InteractionResult) -> void:
		completed.append(result)
		observed_state.append(Vector2i(inventory.count_item(&"item_branch"), resource.remaining_uses))
	player.interaction_completed.connect(listener)
	accessibility.gamepad_vibration_enabled = true
	accessibility.vibration_dispatch = func(_id: int, _weak: float, _strong: float, _duration: float) -> void: vibration_calls.append(1)
	input_device.current_device = InputDeviceTracker.DeviceType.GAMEPAD
	input_device.current_gamepad_id = 7
	for slot in inventory.create_snapshot():
		if not slot.is_empty():
			inventory.remove_item(slot.item_id, slot.quantity)
	inventory.add_item(&"item_reed_spade", 999)
	service.hotbar.assign(0, 0)
	service.hotbar.select(0)
	resource.yield_quantity = 2
	resource.remaining_uses = 3
	resource.interaction_enabled = true
	var context := InteractionContext.new(player, player.global_position, Vector2.RIGHT)
	context.equipped_tool_id = player.get_equipped_tool_id()
	var request: InteractionResult = resource.interact(context)
	check.call(not request.is_success(), "resource request is not a completed success")
	_resolve(main, request)
	check.call(vibration_calls.is_empty(), "full inventory never vibrates successful harvest")
	check.call(inventory.count_item(&"item_branch") == 0 and resource.remaining_uses == 3, "full inventory preserves inventory and resource")
	check.call(completed.size() == 1 and not completed[0].is_success(), "full inventory publishes one final failure")
	inventory.take_from_slot(0, 1)
	inventory.add_item(&"item_branch", 98)
	service.hotbar.assign(0, 1)
	_resolve(main, resource.interact(context))
	check.call(inventory.count_item(&"item_branch") == 98 and resource.remaining_uses == 3, "partial capacity rejects whole resource yield")
	check.call(vibration_calls.is_empty() and not completed.back().is_success(), "partial-capacity resource emits failure without vibration")
	pickup.quantity = 3
	pickup.interaction_enabled = true
	request = pickup.interact(context)
	_resolve(main, request)
	check.call(inventory.count_item(&"item_branch") == 99 and pickup.quantity == 2, "pickup transfers available partial quantity only")
	check.call(completed.back().is_success() and completed.back().payload.get(&"quantity") == 1, "partial pickup success reports committed quantity")
	check.call(completed.back().payload.get(&"requested_quantity") == 3, "partial pickup preserves requested amount separately")
	check.call(vibration_calls.size() == 1, "partial pickup vibrates once after commit")
	var final_count: int = completed.size()
	_resolve(main, request)
	check.call(completed.size() == final_count and vibration_calls.size() == 1, "replayed request emits no duplicate completion or feedback")
	check.call(inventory.count_item(&"item_branch") == 99 and pickup.quantity == 2, "replayed pickup cannot duplicate reward")
	inventory.remove_item(&"item_branch", 2)
	request = resource.interact(context)
	_resolve(main, request)
	check.call(resource.remaining_uses == 2 and inventory.count_item(&"item_branch") == 99, "resource success commits full yield and one use")
	check.call(completed.back().is_success() and completed.back().payload.get(&"quantity") == 2, "resource final success reports committed yield")
	check.call(observed_state.back() == Vector2i(99, 2), "completion listeners observe both inventory and resource already committed")
	check.call(vibration_calls.size() == 2, "successful harvest vibrates exactly once")
	inventory.remove_item(&"item_branch", 10)
	final_count = completed.size()
	request = resource.interact(context)
	request.call(&"cancel")
	_resolve(main, request)
	check.call(completed.size() == final_count and resource.remaining_uses == 2, "cancelled request neither commits nor publishes success")
	check.call(inventory.count_item(&"item_branch") == 89 and vibration_calls.size() == 2, "cancelled request changes no inventory or feedback")
	context.equipped_tool_id = &""
	_resolve(main, resource.interact(context))
	check.call(not completed.back().is_success() and resource.remaining_uses == 2, "wrong tool yields final failure with no resource consumption")
	check.call(vibration_calls.size() == 2, "wrong tool never vibrates success")
	context.equipped_tool_id = player.get_equipped_tool_id()
	request = resource.interact(context)
	service.hotbar.assign(0, 0)
	_resolve(main, request)
	check.call(not completed.back().is_success() and resource.remaining_uses == 2, "tool switched after request is revalidated before commit")
	service.hotbar.assign(0, 1)
	request = resource.interact(context)
	tree.paused = true
	_resolve(main, request)
	tree.paused = false
	check.call(not completed.back().is_success() and resource.remaining_uses == 2, "paused pending request cannot commit")
	request = resource.interact(context)
	player.set_disabled(true)
	_resolve(main, request)
	player.set_disabled(false)
	check.call(not completed.back().is_success() and resource.remaining_uses == 2, "disabled pending request cannot commit")
	check.call(vibration_calls.size() == 2 and inventory.count_item(&"item_branch") == 89, "invalidated contexts never reward or vibrate")
	var before_restore: Dictionary = flow.capture_runtime_world_state()
	request = resource.interact(context)
	var pickup_before_restore: InteractionResult = pickup.interact(context)
	final_count = completed.size()
	check.call(flow.apply_runtime_world_state(before_restore), "same-value world state restore succeeds")
	_resolve(main, request)
	_resolve(main, pickup_before_restore)
	check.call(completed.size() == final_count and inventory.count_item(&"item_branch") == 89, "world restore invalidates old resource and pickup requests even with unchanged values")
	check.call(resource.remaining_uses == 2 and pickup.quantity == 2 and vibration_calls.size() == 2, "stale requests after restore consume nothing and produce no feedback")
	request = resource.interact(context)
	var newer: InteractionResult = resource.interact(context)
	_resolve(main, request)
	check.call(not completed.back().is_success() and inventory.count_item(&"item_branch") == 89, "superseded pending request cannot commit")
	_resolve(main, newer)
	check.call(completed.back().is_success() and resource.remaining_uses == 1, "latest pending request commits once")
	var ghost := PickupInteractable.new()
	ghost.interaction_id = pickup.interaction_id
	ghost.item_id = pickup.item_id
	ghost.quantity = pickup.quantity
	_resolve(main, ghost.interact(context))
	check.call(not completed.back().is_success() and pickup.quantity == 2, "same stable ID from another node cannot replay against live source")
	ghost.free()
	request = pickup.interact(context)
	request.payload[&"quantity"] = 100
	_resolve(main, request)
	check.call(not completed.back().is_success() and inventory.count_item(&"item_branch") == 91, "mutated payload cannot mint extra items")
	_test_input_and_target(main, resource, pickup, context, completed, vibration_calls, check)
	InventoryDataCodec.decode_inventory(inventory, saved_inventory)
	InventoryDataCodec.decode_hotbar(service.hotbar, saved_hotbar)
	resource.remaining_uses = saved_uses
	resource.yield_quantity = saved_yield
	resource.interaction_enabled = saved_uses > 0
	pickup.quantity = saved_quantity
	pickup.interaction_enabled = saved_pickup_enabled
	player.interaction_completed.disconnect(listener)
	accessibility.vibration_dispatch = original_dispatch
	accessibility.gamepad_vibration_enabled = original_enabled
	input_device.current_device = original_device
	input_device.current_gamepad_id = original_gamepad


static func _test_input_and_target(
	main: GameBootstrap, resource: ResourceInteractable, pickup: PickupInteractable,
	context: InteractionContext, completed: Array[InteractionResult], vibration_calls: Array[int], check: Callable
) -> void:
	var player: PlayerCharacter = main.player
	var saved_position: Vector2 = player.global_position
	var sensor: InteractionSensor = player.interaction_sensor
	var saved_candidates: Array[InteractableComponent] = sensor.candidates.duplicate()
	sensor.candidates = [resource]
	player.global_position = resource.global_position
	sensor.refresh_context(player, Vector2.RIGHT, player.get_equipped_tool_id())
	check.call(player.get_current_interactable() == resource, "fixture selects resource while a different pickup request resolves")
	_resolve(main, pickup.interact(context))
	check.call(pickup.quantity == 0 and resource.remaining_uses == 1, "stable request ID wins over current selection")
	var event := InputEventAction.new()
	event.action = &"interact"
	event.pressed = true
	var previous_count: int = completed.size()
	var previous_feedback: int = vibration_calls.size()
	player.set_disabled(true)
	player._unhandled_input(event)
	check.call(completed.size() == previous_count and resource.remaining_uses == 1, "disabled player cancels input before request")
	player.set_disabled(false)
	player._unhandled_input(event)
	player._unhandled_input(event)
	player._unhandled_input(event)
	check.call(resource.remaining_uses == 0 and not resource.interaction_enabled, "rapid repeated input never harvests past depletion")
	check.call(completed.size() == previous_count + 1 and completed.back().is_success(), "rapid depletion publishes exactly one committed success")
	check.call(vibration_calls.size() == previous_feedback + 1, "rapid depletion feedback matches committed harvest count")
	sensor.candidates = saved_candidates
	player.global_position = saved_position
	sensor.refresh_context(player, Vector2.DOWN, player.get_equipped_tool_id())


static func _resolve(main: GameBootstrap, result: InteractionResult) -> void:
	main._on_player_interaction_requested(result)
