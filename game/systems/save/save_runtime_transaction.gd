class_name SaveRuntimeTransaction
extends RefCounted


static func apply(
	data: Dictionary, inventory: InventoryCoordinator,
	player: PlayerCharacter, flow: SceneFlowCoordinator
) -> SaveOperationResult:
	var inventory_check: InventoryDataResult = inventory.preflight_save_sections(
		data["inventories"], data["hotbar"], data["storages"]
	)
	if not inventory_check.success:
		return SaveOperationResult.failed(inventory_check.reason_key)
	var checkpoint: Dictionary = _capture(inventory, player, flow)
	var signal_sources: Array[Object] = [inventory, flow, player, player.state_machine]
	var signal_flags: Array[bool] = []
	for source in signal_sources:
		signal_flags.append(source.is_blocking_signals())
		source.set_block_signals(true)
	var result: SaveOperationResult = _apply_steps(data, inventory, player, flow)
	if not result.success:
		_restore(checkpoint, inventory, player, flow)
	for index in signal_sources.size():
		signal_sources[index].set_block_signals(signal_flags[index])
	if result.success:
		inventory.models_replaced.emit()
		var previous_zone := checkpoint["current"] as WorldZone
		var previous_zone_id: StringName = previous_zone.zone_id if previous_zone != null else &""
		flow.zone_changed.emit(previous_zone_id, flow.get_current_zone_id(), flow.current_spawn_id)
		if checkpoint["state"] != player.get_state():
			player.state_machine.state_changed.emit(checkpoint["state"], player.get_state())
	return result


static func _apply_steps(
	data: Dictionary, inventory: InventoryCoordinator,
	player: PlayerCharacter, flow: SceneFlowCoordinator
) -> SaveOperationResult:
	var inventory_result: InventoryDataResult = inventory.apply_save_sections(
		data["inventories"], data["hotbar"], data["storages"]
	)
	if not inventory_result.success:
		return SaveOperationResult.failed(inventory_result.reason_key)
	var world: Dictionary = data["world"]
	var saved_position: Dictionary = data["player"]["position"]
	var requested := Vector2(saved_position["x"], saved_position["y"])
	if not flow.transition_to_saved_position(
		StringName(world["zone_id"]), StringName(world["spawn_id"]), requested, world
	):
		return SaveOperationResult.failed(&"SAVE_RUNTIME_ZONE_RESTORE_FAILED")
	# The transition resolves unsafe coordinates; never overwrite its safe result with raw JSON.
	var resolved_position: Vector2 = player.global_position
	if not player.restore_runtime_state(resolved_position, StringName(data["player"]["facing_id"])):
		return SaveOperationResult.failed(&"SAVE_RUNTIME_PLAYER_RESTORE_FAILED")
	if not flow.apply_runtime_world_state(data["world_state"]):
		return SaveOperationResult.failed(&"SAVE_RUNTIME_WORLD_STATE_RESTORE_FAILED")
	var applied_data: Dictionary = data.duplicate(true)
	applied_data["player"]["position"] = {"x": resolved_position.x, "y": resolved_position.y}
	applied_data["world"]["spawn_id"] = String(flow.current_spawn_id)
	var result: SaveOperationResult = SaveOperationResult.succeeded(applied_data)
	if not resolved_position.is_equal_approx(requested):
		result.reason_key = &"SAVE_POSITION_RECOVERED"
	return result


static func _capture(
	inventory: InventoryCoordinator, player: PlayerCharacter, flow: SceneFlowCoordinator
) -> Dictionary:
	var zone_states: Dictionary = {}
	var zones: Array = flow.cached_zones.values()
	if flow.current_zone != null:
		zones.append(flow.current_zone)
	for zone: WorldZone in zones:
		zone_states[zone] = zone.capture_load_checkpoint()
	return {
		"inventory": inventory.player_inventory, "hotbar": inventory.hotbar,
		"storages": inventory.storages, "position": player.global_position,
		"facing": player.facing, "direction": player.last_move_direction,
		"velocity": player.velocity, "state": player.state_machine.current_state,
		"task": player.active_task_id, "current": flow.current_zone,
		"cached": flow.cached_zones.duplicate(), "spawn": flow.current_spawn_id,
		"pending_zone": flow.pending_zone_id, "pending_spawn": flow.pending_spawn_id,
		"processing": flow.is_processing(), "error": flow.last_error_key,
		"zones": zone_states,
	}


static func _restore(
	checkpoint: Dictionary, inventory: InventoryCoordinator,
	player: PlayerCharacter, flow: SceneFlowCoordinator
) -> void:
	var failed_zone_id: StringName = flow.get_current_zone_id()
	var old_zones: Dictionary = checkpoint["zones"]
	var current_zones: Array = flow.cached_zones.values()
	if flow.current_zone != null and not current_zones.has(flow.current_zone):
		current_zones.append(flow.current_zone)
	for zone: WorldZone in current_zones:
		if zone.get_parent() == flow.world_container:
			flow.world_container.remove_child(zone)
		if not old_zones.has(zone):
			zone.free()
	flow.current_zone = checkpoint["current"]
	flow.cached_zones = checkpoint["cached"]
	for zone: WorldZone in old_zones:
		zone.restore_load_checkpoint(old_zones[zone])
	if flow.current_zone != null and flow.current_zone.get_parent() == null:
		flow.world_container.add_child(flow.current_zone)
	flow.current_spawn_id = checkpoint["spawn"]
	flow.pending_zone_id = checkpoint["pending_zone"]
	flow.pending_spawn_id = checkpoint["pending_spawn"]
	flow.last_error_key = checkpoint["error"]
	flow.set_process(checkpoint["processing"])
	inventory.player_inventory = checkpoint["inventory"]
	inventory.hotbar = checkpoint["hotbar"]
	inventory.storages = checkpoint["storages"]
	player.global_position = checkpoint["position"]
	player.facing = checkpoint["facing"]
	player.last_move_direction = checkpoint["direction"]
	player.velocity = checkpoint["velocity"]
	var changed_state: int = player.state_machine.current_state
	player.state_machine.current_state = checkpoint["state"]
	if changed_state != player.state_machine.current_state:
		player.state_machine.state_changed.emit(changed_state, player.state_machine.current_state)
	player.set_active_task_id(checkpoint["task"])
	inventory.models_replaced.emit()
	player._update_facing_marker()
	player._refresh_interaction_sensor()
	flow.zone_changed.emit(failed_zone_id, flow.get_current_zone_id(), flow.current_spawn_id)
