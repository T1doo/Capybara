class_name StageOneSoakProbe
extends RefCounted


static func prepare(tree: SceneTree, player: PlayerCharacter, flow: SceneFlowCoordinator) -> Dictionary:
	var pickup := flow.current_zone.get_node("PickupPlaceholder") as PickupInteractable
	var resource := flow.current_zone.get_node("ResourcePlaceholder") as ResourceInteractable
	var chest := flow.current_zone.get_node("ChestPlaceholder") as ChestInteractable
	var tool := flow.current_zone.get_node("ReedSpadePickup") as PickupInteractable
	var inventory := tree.root.get_node("InventoryService") as InventoryCoordinator
	var initial_uses: int = resource.remaining_uses
	if not await _interact(tree, player, pickup, false) or pickup.interaction_enabled:
		return {"success": false, "reason": "pickup input did not commit the state probe"}
	if not await _interact(tree, player, tool, true) or tool.interaction_enabled:
		return {"success": false, "reason": "tool pickup input did not commit"}
	var tool_slot: int = -1
	for index in inventory.player_inventory.slots.size():
		if inventory.player_inventory.slots[index].item_id == resource.required_tool_id:
			tool_slot = index
			break
	if tool_slot < 0 or not inventory.hotbar.assign(0, tool_slot):
		return {"success": false, "reason": "harvest tool was not acquired"}
	inventory.hotbar.select(0)
	var before_quantity: int = inventory.player_inventory.count_item(resource.resource_id)
	if not await _interact(tree, player, resource, false):
		return {"success": false, "reason": "equipped resource input did not complete"}
	if resource.remaining_uses != initial_uses - 1 or (
		inventory.player_inventory.count_item(resource.resource_id) != before_quantity + resource.yield_quantity
	):
		return {"success": false, "reason": "resource probe did not commit both sides exactly once"}
	# Chest persistence is a controlled cache-state probe, not a storage UI claim.
	var context := InteractionContext.new(player, player.global_position, Vector2.RIGHT)
	if not chest.interact(context).is_success() or not chest.is_open:
		return {"success": false, "reason": "failed to initialize chest state probe"}
	return {"success": true, "pickup": pickup, "resource": resource,
		"chest": chest, "resource_uses": resource.remaining_uses}


static func _interact(
	tree: SceneTree, player: PlayerCharacter, target: InteractableComponent, use_gamepad: bool
) -> bool:
	player.restore_runtime_state(target.global_position, &"down")
	for _frame in range(3):
		await tree.physics_frame
	if player.get_current_interactable() != target:
		return false
	var completed: Array[InteractionResult] = []
	var listener: Callable = func(result: InteractionResult) -> void: completed.append(result)
	player.interaction_completed.connect(listener)
	var event: InputEvent
	if use_gamepad:
		var button := InputEventJoypadButton.new()
		button.button_index = JOY_BUTTON_A
		button.pressed = true
		event = button
	else:
		var key := InputEventKey.new()
		key.keycode = KEY_E
		key.physical_keycode = KEY_E
		key.pressed = true
		event = key
	Input.parse_input_event(event)
	await tree.process_frame
	event = event.duplicate()
	if event is InputEventKey:
		(event as InputEventKey).pressed = false
	else:
		(event as InputEventJoypadButton).pressed = false
	Input.parse_input_event(event)
	await tree.process_frame
	player.interaction_completed.disconnect(listener)
	return completed.size() == 1 and completed[0].is_success()
