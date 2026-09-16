class_name WorldZone
extends Node2D

@export var zone_id: StringName = &""


func find_spawn_point(target_spawn_id: StringName) -> WorldSpawnPoint:
	if target_spawn_id.is_empty():
		return null
	var nodes_to_visit: Array[Node] = [self]
	while not nodes_to_visit.is_empty():
		var current: Node = nodes_to_visit.pop_back()
		for child in current.get_children():
			if child is WorldSpawnPoint and child.spawn_id == target_spawn_id:
				return child as WorldSpawnPoint
			nodes_to_visit.append(child)
	return null


func contains_player_node() -> bool:
	var nodes_to_visit: Array[Node] = [self]
	while not nodes_to_visit.is_empty():
		var current: Node = nodes_to_visit.pop_back()
		for child in current.get_children():
			if child.is_in_group(&"player"):
				return true
			nodes_to_visit.append(child)
	return false


func find_transition_doors() -> Array[DoorInteractable]:
	var doors: Array[DoorInteractable] = []
	var nodes_to_visit: Array[Node] = [self]
	while not nodes_to_visit.is_empty():
		var current: Node = nodes_to_visit.pop_back()
		for child in current.get_children():
			if child is DoorInteractable:
				doors.append(child as DoorInteractable)
			nodes_to_visit.append(child)
	return doors


func find_interactable(target_id: StringName) -> InteractableComponent:
	if target_id.is_empty():
		return null
	var nodes_to_visit: Array[Node] = [self]
	while not nodes_to_visit.is_empty():
		var current: Node = nodes_to_visit.pop_back()
		for child in current.get_children():
			if child is InteractableComponent and child.interaction_id == target_id:
				return child as InteractableComponent
			nodes_to_visit.append(child)
	return null


func capture_runtime_state() -> Dictionary:
	var state: Dictionary = {}
	for interactable in _find_all_interactables():
		if interactable is PickupInteractable:
			state[String(interactable.interaction_id)] = {
				"type": WorldStateCodec.TYPE_PICKUP,
				"quantity": (interactable as PickupInteractable).quantity,
			}
		elif interactable is ResourceInteractable:
			state[String(interactable.interaction_id)] = {
				"type": WorldStateCodec.TYPE_RESOURCE,
				"remaining_uses": (interactable as ResourceInteractable).remaining_uses,
			}
	return state


func validate_runtime_state(state: Variant) -> StringName:
	if not state is Dictionary:
		return &"SAVE_INVALID_WORLD_STATE_ZONE"
	var mutable_interactables: Dictionary[StringName, InteractableComponent] = {}
	for interactable in _find_all_interactables():
		if interactable is PickupInteractable or interactable is ResourceInteractable:
			mutable_interactables[interactable.interaction_id] = interactable
	for raw_id in state:
		if not raw_id is String or not state[raw_id] is Dictionary:
			return &"SAVE_INVALID_WORLD_STATE_INTERACTION"
		var interaction_id := StringName(raw_id)
		if not mutable_interactables.has(interaction_id):
			return &"SAVE_UNKNOWN_WORLD_INTERACTION"
		var entry := state[raw_id] as Dictionary
		var interactable: InteractableComponent = mutable_interactables[interaction_id]
		if (
			interactable is PickupInteractable
			and entry.get("type") != WorldStateCodec.TYPE_PICKUP
		) or (
			interactable is ResourceInteractable
			and entry.get("type") != WorldStateCodec.TYPE_RESOURCE
		):
			return &"SAVE_WORLD_INTERACTION_TYPE_MISMATCH"
	return &""


func apply_runtime_state(state: Dictionary) -> bool:
	if not validate_runtime_state(state).is_empty():
		return false
	for raw_id in state:
		var interactable: InteractableComponent = find_interactable(StringName(raw_id))
		var entry := state[raw_id] as Dictionary
		if interactable is PickupInteractable:
			var pickup := interactable as PickupInteractable
			pickup.quantity = entry["quantity"]
			pickup.interaction_enabled = pickup.quantity > 0
		elif interactable is ResourceInteractable:
			var resource := interactable as ResourceInteractable
			resource.remaining_uses = entry["remaining_uses"]
			resource.interaction_enabled = resource.remaining_uses > 0
	return true


func _find_all_interactables() -> Array[InteractableComponent]:
	var interactables: Array[InteractableComponent] = []
	var nodes_to_visit: Array[Node] = [self]
	while not nodes_to_visit.is_empty():
		var current: Node = nodes_to_visit.pop_back()
		for child in current.get_children():
			if child is InteractableComponent:
				interactables.append(child as InteractableComponent)
			nodes_to_visit.append(child)
	return interactables


func validate_content() -> StringName:
	if contains_player_node():
		return &"SCENE_FLOW_INVALID_ZONE_CONTENT"
	var spawn_ids: Dictionary[StringName, bool] = {}
	var interaction_ids: Dictionary[StringName, bool] = {}
	var nodes_to_visit: Array[Node] = [self]
	while not nodes_to_visit.is_empty():
		var current: Node = nodes_to_visit.pop_back()
		for child in current.get_children():
			if child is WorldSpawnPoint:
				var spawn := child as WorldSpawnPoint
				if spawn.spawn_id.is_empty():
					return &"SCENE_FLOW_INVALID_SPAWN_ID"
				if spawn_ids.has(spawn.spawn_id):
					return &"SCENE_FLOW_DUPLICATE_SPAWN_ID"
				spawn_ids[spawn.spawn_id] = true
			elif child is InteractableComponent:
				var interactable := child as InteractableComponent
				if interactable.interaction_id.is_empty():
					return &"SCENE_FLOW_INVALID_INTERACTION_ID"
				if interaction_ids.has(interactable.interaction_id):
					return &"SCENE_FLOW_DUPLICATE_INTERACTION_ID"
				interaction_ids[interactable.interaction_id] = true
			nodes_to_visit.append(child)
	return &""
