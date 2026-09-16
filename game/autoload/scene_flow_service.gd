class_name SceneFlowCoordinator
extends Node

signal zone_changed(
	previous_zone_id: StringName,
	current_zone_id: StringName,
	spawn_id: StringName
)
signal transition_failed(
	zone_id: StringName,
	spawn_id: StringName,
	reason_key: StringName
)

var zone_scenes: Dictionary[StringName, PackedScene] = {}
var world_container: Node2D
var player: Node2D
var current_zone: WorldZone
var current_spawn_id: StringName = &""
var cached_zones: Dictionary[StringName, WorldZone] = {}
var last_error_key: StringName = &""
var pending_zone_id: StringName = &""
var pending_spawn_id: StringName = &""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)


func _process(_delta: float) -> void:
	if has_pending_transition() and not get_tree().paused:
		_execute_pending_transition()


func configure(container: Node2D, persistent_player: Node2D) -> bool:
	if not is_instance_valid(container) or not is_instance_valid(persistent_player):
		last_error_key = &"SCENE_FLOW_INVALID_CONFIGURATION"
		return false
	if _is_configured():
		if world_container == container and player == persistent_player:
			return true
		last_error_key = &"SCENE_FLOW_ALREADY_CONFIGURED"
		return false
	_release_cached_zones()
	world_container = container
	player = persistent_player
	current_zone = null
	current_spawn_id = &""
	last_error_key = &""
	return true


func unconfigure(container: Node2D) -> bool:
	if world_container != container:
		return false
	if is_instance_valid(current_zone):
		if current_zone.get_parent() != null:
			current_zone.get_parent().remove_child(current_zone)
		current_zone.free()
	current_zone = null
	current_spawn_id = &""
	_release_cached_zones()
	world_container = null
	player = null
	_clear_pending_transition()
	last_error_key = &""
	return true


func register_zone_scene(zone_id: StringName, zone_scene: PackedScene) -> bool:
	if zone_id.is_empty() or zone_scene == null or zone_scenes.has(zone_id):
		return false
	zone_scenes[zone_id] = zone_scene
	return true


func transition_to(
	zone_id: StringName,
	spawn_id: StringName,
	allow_while_paused: bool = false,
	restored_position: Variant = null
) -> bool:
	if is_inside_tree() and get_tree().paused and not allow_while_paused:
		return _fail(zone_id, spawn_id, &"SCENE_FLOW_PAUSED")
	if not _is_configured():
		return _fail(zone_id, spawn_id, &"SCENE_FLOW_NOT_CONFIGURED")
	if not zone_scenes.has(zone_id):
		return _fail(zone_id, spawn_id, &"SCENE_FLOW_UNKNOWN_ZONE")

	if current_zone != null and current_zone.zone_id == zone_id:
		var existing_spawn := current_zone.find_spawn_point(spawn_id)
		if existing_spawn == null:
			return _fail(zone_id, spawn_id, &"SCENE_FLOW_UNKNOWN_SPAWN")
		player.global_position = (
			restored_position if restored_position is Vector2 else existing_spawn.global_position
		)
		current_spawn_id = spawn_id
		last_error_key = &""
		zone_changed.emit(zone_id, zone_id, spawn_id)
		return true

	var next_zone: WorldZone
	var is_cached_zone: bool = cached_zones.has(zone_id)
	if is_cached_zone:
		next_zone = cached_zones[zone_id]
	else:
		var packed_zone_scene: PackedScene = zone_scenes[zone_id]
		if packed_zone_scene.get_state().get_node_count() == 0:
			return _fail(zone_id, spawn_id, &"SCENE_FLOW_INVALID_ZONE_SCENE")
		var raw_instance: Node = packed_zone_scene.instantiate()
		if raw_instance == null:
			return _fail(zone_id, spawn_id, &"SCENE_FLOW_INVALID_ZONE_SCENE")
		next_zone = raw_instance as WorldZone
		if next_zone == null:
			raw_instance.free()
	if next_zone == null:
		return _fail(zone_id, spawn_id, &"SCENE_FLOW_INVALID_ZONE_SCENE")
	if next_zone.zone_id != zone_id:
		if not is_cached_zone:
			next_zone.free()
		return _fail(zone_id, spawn_id, &"SCENE_FLOW_INVALID_ZONE_CONTENT")
	var content_error_key: StringName = next_zone.validate_content()
	if not content_error_key.is_empty():
		if not is_cached_zone:
			next_zone.free()
		return _fail(zone_id, spawn_id, content_error_key)

	var next_spawn := next_zone.find_spawn_point(spawn_id)
	if next_spawn == null:
		if not is_cached_zone:
			next_zone.free()
		return _fail(zone_id, spawn_id, &"SCENE_FLOW_UNKNOWN_SPAWN")

	var previous_zone_id: StringName = &""
	if current_zone != null:
		previous_zone_id = current_zone.zone_id
		world_container.remove_child(current_zone)
		cached_zones[previous_zone_id] = current_zone
	if is_cached_zone:
		cached_zones.erase(zone_id)
	current_zone = next_zone
	world_container.add_child(current_zone)
	_connect_transition_doors(current_zone)
	player.global_position = restored_position if restored_position is Vector2 else next_spawn.global_position
	current_spawn_id = spawn_id
	last_error_key = &""
	zone_changed.emit(previous_zone_id, current_zone.zone_id, spawn_id)
	return true


func request_transition(zone_id: StringName, spawn_id: StringName) -> void:
	if has_pending_transition():
		return
	pending_zone_id = zone_id
	pending_spawn_id = spawn_id
	set_process(true)
	call_deferred(&"_execute_pending_transition")


func get_current_zone_id() -> StringName:
	return current_zone.zone_id if current_zone != null else &""


func get_current_spawn_id() -> StringName:
	return current_spawn_id


func capture_runtime_world_state() -> Dictionary:
	return WorldStateRuntime.capture(zone_scenes, current_zone, cached_zones)


func preflight_runtime_world_state(state: Variant) -> StringName:
	return WorldStateRuntime.prepare_complete(state, zone_scenes)[2]


func apply_runtime_world_state(state: Dictionary) -> bool:
	var prepared: Array = WorldStateRuntime.prepare_complete(state, zone_scenes)
	if not prepared[0]:
		return false
	var complete := prepared[1] as Dictionary
	for raw_zone_id in complete:
		var zone_id := StringName(raw_zone_id)
		var inspected: Array = _inspect_world_state_zone(zone_id)
		var zone := inspected[0] as WorldZone
		if inspected[1]:
			cached_zones[zone_id] = zone
		if not zone.apply_runtime_state(complete[raw_zone_id]):
			return false
	return true


func _inspect_world_state_zone(zone_id: StringName) -> Array:
	if not zone_scenes.has(zone_id):
		return [null, false, &"SCENE_FLOW_UNKNOWN_ZONE"]
	if is_instance_valid(current_zone) and current_zone.zone_id == zone_id:
		return [current_zone, false, &""]
	if cached_zones.has(zone_id) and is_instance_valid(cached_zones[zone_id]):
		return [cached_zones[zone_id], false, &""]
	var raw_instance: Node = zone_scenes[zone_id].instantiate()
	var zone := raw_instance as WorldZone
	if zone == null:
		if raw_instance != null:
			raw_instance.free()
		return [null, false, &"SCENE_FLOW_INVALID_ZONE_SCENE"]
	var error: StringName = zone.validate_content()
	if zone.zone_id != zone_id:
		error = &"SCENE_FLOW_INVALID_ZONE_CONTENT"
	if not error.is_empty():
		zone.free()
		return [null, false, error]
	return [zone, true, &""]


func preflight_transition(zone_id: StringName, spawn_id: StringName) -> StringName:
	if not _is_configured():
		return &"SCENE_FLOW_NOT_CONFIGURED"
	if not zone_scenes.has(zone_id):
		return &"SCENE_FLOW_UNKNOWN_ZONE"
	var inspected_zone: WorldZone = null
	var should_free: bool = false
	if current_zone != null and current_zone.zone_id == zone_id:
		inspected_zone = current_zone
	elif cached_zones.has(zone_id):
		inspected_zone = cached_zones[zone_id]
	else:
		var packed_zone_scene: PackedScene = zone_scenes[zone_id]
		if packed_zone_scene.get_state().get_node_count() == 0:
			return &"SCENE_FLOW_INVALID_ZONE_SCENE"
		var raw_instance: Node = packed_zone_scene.instantiate()
		if raw_instance == null:
			return &"SCENE_FLOW_INVALID_ZONE_SCENE"
		inspected_zone = raw_instance as WorldZone
		if inspected_zone == null:
			raw_instance.free()
			return &"SCENE_FLOW_INVALID_ZONE_SCENE"
		should_free = true
	var error_key: StringName = &""
	if inspected_zone.zone_id != zone_id:
		error_key = &"SCENE_FLOW_INVALID_ZONE_CONTENT"
	else:
		error_key = inspected_zone.validate_content()
	if error_key.is_empty() and inspected_zone.find_spawn_point(spawn_id) == null:
		error_key = &"SCENE_FLOW_UNKNOWN_SPAWN"
	if should_free:
		inspected_zone.free()
	return error_key


func transition_to_saved_position(
	zone_id: StringName,
	spawn_id: StringName,
	restored_position: Vector2,
	landing_context: Dictionary = {}
) -> bool:
	var error_key: StringName = preflight_transition(zone_id, spawn_id)
	if not error_key.is_empty():
		return _fail(zone_id, spawn_id, error_key)
	_clear_pending_transition()
	var previous_zone_id: StringName = get_current_zone_id()
	var signals_were_blocked: bool = is_blocking_signals()
	set_block_signals(true)
	var transitioned: bool = transition_to(zone_id, spawn_id, true)
	set_block_signals(signals_were_blocked)
	if not transitioned:
		return _fail(zone_id, spawn_id, last_error_key)
	var spawn: WorldSpawnPoint = current_zone.find_spawn_point(spawn_id)
	var requested: Vector2 = restored_position
	# These maps have one walking layer and no chunks. Unsupported topology returns
	# to the named spawn; actual streamed-chunk resolution belongs to Stage 4.
	if landing_context.get("navigation_layer", "ground") != "ground" or landing_context.has("chunk_id"):
		requested = spawn.global_position
	if landing_context.get("map_revision", current_zone.map_revision) != current_zone.map_revision:
		requested = spawn.global_position
	var landing: Dictionary = {"success": false}
	for candidate in current_zone.landing_spawns(spawn_id):
		landing = SafeLandingResolver.resolve(
			current_zone, player as CharacterBody2D, requested,
			candidate.global_position, current_zone.walkable_bounds
		)
		if landing["success"]:
			current_spawn_id = candidate.spawn_id
			break
	if not landing["success"]:
		return _fail(zone_id, spawn_id, &"SAVE_NO_SAFE_LANDING")
	player.global_position = landing["position"]
	zone_changed.emit(previous_zone_id, zone_id, current_spawn_id)
	return true


func has_registered_zone(zone_id: StringName) -> bool:
	return zone_scenes.has(zone_id)


func has_pending_transition() -> bool:
	return not pending_zone_id.is_empty()


func _is_configured() -> bool:
	return is_instance_valid(world_container) and is_instance_valid(player)


func _fail(zone_id: StringName, spawn_id: StringName, reason_key: StringName) -> bool:
	last_error_key = reason_key
	transition_failed.emit(zone_id, spawn_id, reason_key)
	return false


func _connect_transition_doors(zone: WorldZone) -> void:
	var transition_callable := Callable(self, &"request_transition")
	for door in zone.find_transition_doors():
		if not door.transition_requested.is_connected(transition_callable):
			door.transition_requested.connect(transition_callable)


func _release_cached_zones() -> void:
	for zone in cached_zones.values():
		if is_instance_valid(zone):
			zone.free()
	cached_zones.clear()


func _execute_pending_transition() -> void:
	if not has_pending_transition() or get_tree().paused:
		return
	var zone_id: StringName = pending_zone_id
	var spawn_id: StringName = pending_spawn_id
	_clear_pending_transition()
	transition_to(zone_id, spawn_id)


func _clear_pending_transition() -> void:
	pending_zone_id = &""
	pending_spawn_id = &""
	set_process(false)
