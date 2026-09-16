class_name WorldStateRuntime
extends RefCounted


static func capture(
	zone_scenes: Dictionary[StringName, PackedScene],
	current_zone: WorldZone,
	cached_zones: Dictionary[StringName, WorldZone]
) -> Dictionary:
	var state: Dictionary = {}
	for zone_id in zone_scenes:
		var zone: WorldZone = null
		var should_free: bool = false
		if is_instance_valid(current_zone) and current_zone.zone_id == zone_id:
			zone = current_zone
		elif cached_zones.has(zone_id) and is_instance_valid(cached_zones[zone_id]):
			zone = cached_zones[zone_id]
		else:
			var instance_result: Array = _instantiate_zone(zone_id, zone_scenes)
			zone = instance_result[0]
			should_free = zone != null
		if zone != null:
			state[String(zone_id)] = zone.capture_runtime_state()
		if should_free:
			zone.free()
	return state


static func prepare_complete(
	state: Variant,
	zone_scenes: Dictionary[StringName, PackedScene]
) -> Array:
	if not state is Dictionary:
		return [false, {}, &"SAVE_INVALID_WORLD_STATE"]
	for raw_zone_id in state:
		if not raw_zone_id is String or not zone_scenes.has(StringName(raw_zone_id)):
			return [false, {}, &"SCENE_FLOW_UNKNOWN_ZONE"]
	var complete: Dictionary = {}
	for zone_id in zone_scenes:
		var instance_result: Array = _instantiate_zone(zone_id, zone_scenes)
		var zone := instance_result[0] as WorldZone
		var error: StringName = instance_result[1]
		if zone == null:
			return [false, {}, error]
		var zone_state: Dictionary = zone.capture_runtime_state()
		var raw_key: String = String(zone_id)
		if (state as Dictionary).has(raw_key):
			var overrides: Variant = (state as Dictionary)[raw_key]
			if not overrides is Dictionary:
				zone.free()
				return [false, {}, &"SAVE_INVALID_WORLD_STATE_ZONE"]
			for interaction_id in overrides:
				zone_state[interaction_id] = overrides[interaction_id]
		error = zone.validate_runtime_state(zone_state)
		zone.free()
		if not error.is_empty():
			return [false, {}, error]
		complete[raw_key] = zone_state
	return [true, complete, &""]


static func _instantiate_zone(
	zone_id: StringName,
	zone_scenes: Dictionary[StringName, PackedScene]
) -> Array:
	if not zone_scenes.has(zone_id):
		return [null, &"SCENE_FLOW_UNKNOWN_ZONE"]
	var raw_instance: Node = zone_scenes[zone_id].instantiate()
	var zone := raw_instance as WorldZone
	if zone == null:
		if raw_instance != null:
			raw_instance.free()
		return [null, &"SCENE_FLOW_INVALID_ZONE_SCENE"]
	var error: StringName = zone.validate_content()
	if zone.zone_id != zone_id:
		error = &"SCENE_FLOW_INVALID_ZONE_CONTENT"
	if not error.is_empty():
		zone.free()
		return [null, error]
	return [zone, &""]
