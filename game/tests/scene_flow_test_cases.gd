class_name SceneFlowTestCases
extends RefCounted

const FLOW_SCRIPT: Script = preload("res://autoload/scene_flow_service.gd")
const INTERACTABLE_SCRIPT: Script = preload("res://systems/interaction/interactable_component.gd")
const SPAWN_SCRIPT: Script = preload("res://systems/world/world_spawn_point.gd")
const ZONE_SCRIPT: Script = preload("res://systems/world/world_zone.gd")


static func run(root: Node, assert_true: Callable, assert_int_equal: Callable) -> void:
	var service: SceneFlowCoordinator = FLOW_SCRIPT.new()
	var container := Node2D.new()
	var player := Node2D.new()
	player.add_to_group(&"player")
	root.add_child(service)
	root.add_child(container)
	root.add_child(player)

	assert_true.call(service.configure(container, player), "scene flow accepts a valid configuration")
	var home_scene := _make_zone_scene(
		&"zone_home_test",
		{&"spawn_start": Vector2(12.0, 20.0), &"spawn_return": Vector2(-30.0, 8.0)}
	)
	var grove_scene := _make_zone_scene(
		&"zone_grove_test",
		{&"spawn_entry": Vector2(90.0, -10.0)}
	)
	assert_true.call(service.register_zone_scene(&"zone_home_test", home_scene), "home zone registers")
	assert_true.call(service.register_zone_scene(&"zone_grove_test", grove_scene), "grove zone registers")
	assert_true.call(
		not service.register_zone_scene(&"zone_home_test", home_scene),
		"duplicate zone ID is rejected"
	)
	var second_container := Node2D.new()
	var second_player := Node2D.new()
	root.add_child(second_container)
	root.add_child(second_player)
	assert_true.call(
		not service.configure(second_container, second_player),
		"second live bootstrap configuration is rejected"
	)
	assert_true.call(
		service.last_error_key == &"SCENE_FLOW_ALREADY_CONFIGURED",
		"duplicate bootstrap returns a stable reason"
	)
	second_container.free()
	second_player.free()

	assert_true.call(
		service.transition_to(&"zone_home_test", &"spawn_start"),
		"initial zone transition succeeds"
	)
	assert_true.call(player.position.is_equal_approx(Vector2(12.0, 20.0)), "initial spawn is applied")
	assert_int_equal.call(container.get_child_count(), 1, "only one zone is active")
	var first_zone := service.current_zone
	assert_true.call(
		not service.transition_to(&"zone_grove_test", &"missing_spawn"),
		"missing spawn rejects transition"
	)
	assert_true.call(service.current_zone == first_zone, "failed transition preserves current zone")

	assert_true.call(
		service.transition_to(&"zone_grove_test", &"spawn_entry"),
		"second zone transition succeeds"
	)
	assert_true.call(player.position.is_equal_approx(Vector2(90.0, -10.0)), "second spawn is applied")
	assert_int_equal.call(container.get_child_count(), 1, "zone replacement leaves one active zone")
	assert_int_equal.call(
		root.get_tree().get_nodes_in_group(&"player").size(),
		1,
		"zone transitions preserve one persistent player"
	)

	assert_true.call(
		service.transition_to(&"zone_grove_test", &"spawn_entry"),
		"same-zone transition repositions without reload"
	)
	assert_int_equal.call(container.get_child_count(), 1, "same-zone spawn keeps one zone")
	assert_true.call(
		service.transition_to(&"zone_home_test", &"spawn_return"),
		"return transition succeeds"
	)
	assert_true.call(service.current_zone == first_zone, "return transition reuses the home zone")
	assert_true.call(player.position.is_equal_approx(Vector2(-30.0, 8.0)), "return spawn is applied")

	var invalid_scene := _make_zone_scene(
		&"zone_invalid_test",
		{&"spawn_invalid": Vector2.ZERO},
		true
	)
	service.register_zone_scene(&"zone_invalid_test", invalid_scene)
	assert_true.call(
		not service.transition_to(&"zone_invalid_test", &"spawn_invalid"),
		"zone containing a duplicate player is rejected"
	)
	assert_true.call(
		service.last_error_key == &"SCENE_FLOW_INVALID_ZONE_CONTENT",
		"invalid zone returns a stable localized reason key"
	)
	var invalid_root_scene := _make_invalid_root_scene()
	service.register_zone_scene(&"zone_invalid_root_test", invalid_root_scene)
	assert_true.call(
		not service.transition_to(&"zone_invalid_root_test", &"spawn_invalid"),
		"scene with a non-WorldZone root is rejected"
	)
	assert_true.call(
		service.last_error_key == &"SCENE_FLOW_INVALID_ZONE_SCENE",
		"invalid root returns a stable reason"
	)
	var empty_scene := PackedScene.new()
	service.register_zone_scene(&"zone_empty_scene_test", empty_scene)
	assert_true.call(
		not service.transition_to(&"zone_empty_scene_test", &"spawn_empty"),
		"unpacked empty scene is rejected"
	)
	assert_true.call(
		service.last_error_key == &"SCENE_FLOW_INVALID_ZONE_SCENE",
		"empty scene returns a stable reason"
	)
	var duplicate_spawn_scene := _make_duplicate_content_scene(true)
	service.register_zone_scene(&"zone_duplicate_spawn_test", duplicate_spawn_scene)
	assert_true.call(
		not service.transition_to(&"zone_duplicate_spawn_test", &"spawn_duplicate"),
		"duplicate spawn IDs are rejected"
	)
	assert_true.call(
		service.last_error_key == &"SCENE_FLOW_DUPLICATE_SPAWN_ID",
		"duplicate spawn returns a stable reason"
	)
	var duplicate_interaction_scene := _make_duplicate_content_scene(false)
	service.register_zone_scene(&"zone_duplicate_interaction_test", duplicate_interaction_scene)
	assert_true.call(
		not service.transition_to(&"zone_duplicate_interaction_test", &"spawn_valid"),
		"duplicate interaction IDs are rejected"
	)
	assert_true.call(
		service.last_error_key == &"SCENE_FLOW_DUPLICATE_INTERACTION_ID",
		"duplicate interaction returns a stable reason"
	)

	service.unconfigure(container)
	container.free()
	player.free()
	service.free()


static func _make_zone_scene(
	zone_id: StringName,
	spawn_positions: Dictionary,
	include_player: bool = false
) -> PackedScene:
	var zone: WorldZone = ZONE_SCRIPT.new()
	zone.zone_id = zone_id
	for spawn_id in spawn_positions:
		var spawn: WorldSpawnPoint = SPAWN_SCRIPT.new()
		spawn.spawn_id = spawn_id
		spawn.position = spawn_positions[spawn_id]
		zone.add_child(spawn)
		spawn.owner = zone
	if include_player:
		var duplicate_player := Node2D.new()
		duplicate_player.add_to_group(&"player", true)
		zone.add_child(duplicate_player)
		duplicate_player.owner = zone

	var packed_scene := PackedScene.new()
	var pack_error := packed_scene.pack(zone)
	zone.free()
	if pack_error != OK:
		return null
	return packed_scene


static func _make_invalid_root_scene() -> PackedScene:
	var root_node := Node2D.new()
	var packed_scene := PackedScene.new()
	packed_scene.pack(root_node)
	root_node.free()
	return packed_scene


static func _make_duplicate_content_scene(duplicate_spawns: bool) -> PackedScene:
	var zone: WorldZone = ZONE_SCRIPT.new()
	zone.zone_id = (
		&"zone_duplicate_spawn_test"
		if duplicate_spawns
		else &"zone_duplicate_interaction_test"
	)
	var first_spawn: WorldSpawnPoint = SPAWN_SCRIPT.new()
	first_spawn.spawn_id = &"spawn_duplicate" if duplicate_spawns else &"spawn_valid"
	zone.add_child(first_spawn)
	first_spawn.owner = zone
	if duplicate_spawns:
		var second_spawn: WorldSpawnPoint = SPAWN_SCRIPT.new()
		second_spawn.spawn_id = &"spawn_duplicate"
		zone.add_child(second_spawn)
		second_spawn.owner = zone
	else:
		for _index in range(2):
			var interactable: InteractableComponent = INTERACTABLE_SCRIPT.new()
			interactable.interaction_id = &"duplicate_interaction"
			zone.add_child(interactable)
			interactable.owner = zone
	var packed_scene := PackedScene.new()
	packed_scene.pack(zone)
	zone.free()
	return packed_scene
