extends SceneTree

const MAIN: PackedScene = preload("res://scenes/bootstrap/main.tscn")
const PLAYER: PackedScene = preload("res://scenes/player/player.tscn")
const BLOCKOUT: PackedScene = preload("res://scenes/visual_prototypes/home_visual_blockout.tscn")

class FailingFlow extends SceneFlowCoordinator:
	var fault: String = "world"
	func transition_to_saved_position(zone: StringName, spawn: StringName, point: Vector2, context: Dictionary = {}) -> bool:
		var applied: bool = super.transition_to_saved_position(zone, spawn, point, context)
		return applied and fault != "zone"
	func apply_runtime_world_state(state: Dictionary) -> bool:
		super.apply_runtime_world_state(state)
		return fault != "world"

class FailingInventory extends InventoryCoordinator:
	func apply_save_sections(inventories: Variant, hotbar_data: Variant, storage_data: Variant) -> InventoryDataResult:
		super.apply_save_sections(inventories, hotbar_data, storage_data)
		return InventoryDataResult.failed(&"INJECTED_INVENTORY_FAILURE")

class FailingPlayer extends PlayerCharacter:
	func restore_runtime_state(point: Vector2, direction: StringName) -> bool:
		super.restore_runtime_state(point, direction)
		return false

class UnreadableSaveManager extends SaveManagerService:
	var io_failure: StringName = &"SAVE_FILE_OPEN_FAILED"
	func _read_validated(path: String) -> SaveOperationResult:
		if path.ends_with("slot.json"):
			return SaveOperationResult.failed(io_failure)
		return super._read_validated(path)

var failures: int = 0
var checks: int = 0

func _init() -> void:
	call_deferred(&"_run")

func _run() -> void:
	var main := MAIN.instantiate() as GameBootstrap
	root.add_child(main)
	await process_frame
	var manager := root.get_node("SaveManager") as SaveManagerService
	var inventory := root.get_node("InventoryService") as InventoryCoordinator
	var flow := root.get_node("SceneFlowService") as SceneFlowCoordinator
	var player := main.get_node("Player") as PlayerCharacter
	paused = true
	var snapshot: SaveOperationResult = manager.create_runtime_snapshot(inventory, player, flow)
	var outside: Dictionary = snapshot.data.duplicate(true)
	outside["player"]["position"] = {"x": 999999.0, "y": 999999.0}
	_check(manager.apply_runtime_snapshot(outside, inventory, player, flow).success, "unsafe position recovers")
	_check(player.global_position.length() < 1500.0, "out of bounds position returns to reachable map")
	_check(SafeLandingResolver.is_safe(flow.current_zone, player, player.global_position, flow.current_zone.walkable_bounds), "fallback player shape clears collision")
	var wall: Dictionary = snapshot.data.duplicate(true)
	wall["player"]["position"] = {"x": 944.0, "y": 0.0}
	var wall_result: SaveOperationResult = manager.apply_runtime_snapshot(wall, inventory, player, flow)
	_check(wall_result.success and wall_result.reason_key == &"SAVE_POSITION_RECOVERED", "wall recovery gives feedback")
	_check(SafeLandingResolver.is_safe(flow.current_zone, player, player.global_position, flow.current_zone.walkable_bounds), "wall fallback clears actual shape")
	for context in [{"map_revision": 0}, {"navigation_layer": "under_bridge"}, {"chunk_id": "not_supported"}]:
		var old_map: Dictionary = snapshot.data.duplicate(true)
		old_map["world"].merge(context, true)
		old_map["player"]["position"] = {"x": 400.0, "y": 300.0}
		var recovered: SaveOperationResult = manager.apply_runtime_snapshot(old_map, inventory, player, flow)
		_check(recovered.success and player.global_position == Vector2.ZERO, "unsupported topology returns to named spawn")
	var legacy: Dictionary = snapshot.data.duplicate(true)
	legacy["world"].erase("map_revision")
	legacy["world"].erase("navigation_layer")
	_check(manager.apply_runtime_snapshot(legacy, inventory, player, flow).success, "legacy world metadata defaults")
	_test_visual_collision(player)
	_test_enclosed_landing(player)
	var observed_positions: Array[Vector2] = []
	var observer: Callable = func(_a: StringName, _b: StringName, _c: StringName) -> void:
		observed_positions.append(player.global_position)
	flow.zone_changed.connect(observer)
	_check(flow.transition_to_saved_position(&"zone_home_placeholder", &"spawn_home_start", Vector2(144, -72)), "public saved transition succeeds")
	_check(observed_positions == [Vector2(144, -72)], "public transition emits exactly once at final position")
	observed_positions.clear()
	_check(flow.transition_to_saved_position(&"zone_home_placeholder", &"spawn_home_start", Vector2(944, 0)), "public saved transition resolves collision")
	_check(observed_positions == [player.global_position], "public recovery emits exactly once at safe final position")
	flow.zone_changed.disconnect(observer)
	var spawn_blocker: StaticBody2D = _wall(Vector2.ZERO, Vector2(64, 64))
	flow.current_zone.add_child(spawn_blocker)
	_check(manager.apply_runtime_snapshot(outside, inventory, player, flow).success, "blocked preferred spawn uses another named spawn")
	_check(player.global_position == Vector2(-140, -120), "alternate spawn selection is deterministic")
	spawn_blocker.free()
	manager.apply_runtime_snapshot(snapshot.data, inventory, player, flow)
	var faulty := FailingFlow.new()
	root.add_child(faulty)
	faulty.world_container = flow.world_container
	faulty.player = player
	faulty.zone_scenes = flow.zone_scenes
	faulty.current_zone = flow.current_zone
	faulty.cached_zones = flow.cached_zones.duplicate()
	faulty.current_spawn_id = flow.current_spawn_id
	faulty.pending_zone_id = &"zone_grove_placeholder"
	faulty.pending_spawn_id = &"spawn_from_home"
	var old_position: Vector2 = player.global_position
	var old_inventory: InventoryModel = inventory.player_inventory
	var old_zone: WorldZone = faulty.current_zone
	var changed: Dictionary = snapshot.data.duplicate(true)
	changed["world"] = {"zone_id": "zone_grove_placeholder", "spawn_id": "spawn_from_home"}
	changed["player"]["position"] = {"x": 400.0, "y": 300.0}
	changed["inventories"]["player"]["slots"][0] = {"item_id": "item_branch", "quantity": 3}
	changed["world_state"]["zone_home_placeholder"]["pickup_branch_placeholder"]["quantity"] = 0
	var original_world: Dictionary = flow.capture_runtime_world_state()
	for fault in ["zone", "world"]:
		faulty.fault = fault
		var result: SaveOperationResult = manager.apply_runtime_snapshot(changed, inventory, player, faulty)
		_check(not result.success, "injected " + fault + " apply failure rejected")
		_check(player.global_position == old_position, fault + " player rollback")
		_check(inventory.player_inventory == old_inventory, fault + " inventory identity rollback")
		_check(faulty.current_zone == old_zone, fault + " zone rollback")
		_check(faulty.pending_zone_id == &"zone_grove_placeholder", fault + " pending transition rollback")
		_check(faulty.capture_runtime_world_state() == original_world, fault + " complete world rollback")
		_check(paused, "pause ownership preserved")
	_test_inventory_failure(manager, inventory, player, flow, changed)
	_test_player_failure(manager, inventory, flow, changed)
	var slot: String = "user://capybara_tests/transaction_%d/slot" % Time.get_ticks_usec()
	_check(manager.save_game(slot, changed, flow).success, "temporary failure fixture saves valid main")
	_check(not manager.load_and_apply(slot, inventory, player, faulty).success, "runtime load failure remains failure")
	_check(FileAccess.file_exists(slot + ".json"), "temporary apply failure does not quarantine valid main")
	_test_read_failure(manager, inventory, player, flow, snapshot.data, slot)
	_test_empty_world_load(manager, inventory, player, flow, snapshot.data)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(slot + ".json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(slot).get_base_dir())
	faulty.free()
	print("SAVE TRANSACTION: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_read_failure(manager: SaveManagerService, inventory: InventoryCoordinator, player: PlayerCharacter, flow: SceneFlowCoordinator, data: Dictionary, slot: String) -> void:
	_check(manager.save_game(slot, data, flow).success, "IO fixture creates main and backup")
	var main_bytes: PackedByteArray = FileAccess.get_file_as_bytes(slot + ".json")
	var backup_bytes: PackedByteArray = FileAccess.get_file_as_bytes(slot + ".bak.json")
	var faulty := UnreadableSaveManager.new()
	faulty.configure_registry(inventory.content_registry)
	for reason in [&"SAVE_FILE_OPEN_FAILED", &"SAVE_FILE_READ_FAILED"]:
		faulty.io_failure = reason
		var before: InventoryModel = inventory.player_inventory
		_check(faulty.load_and_apply(slot, inventory, player, flow).reason_key == reason, "IO load fails without fallback or isolation")
		_check(inventory.player_inventory == before, "IO load does not apply backup")
		_check(faulty.save_game(slot, data, flow).reason_key == reason, "IO save refuses destructive rotation")
		_check(FileAccess.get_file_as_bytes(slot + ".json") == main_bytes, "IO preserves main name and bytes")
		_check(FileAccess.get_file_as_bytes(slot + ".bak.json") == backup_bytes, "IO preserves backup name and bytes")
		_check(not FileAccess.file_exists(slot + ".tmp.json"), "IO failure removes temporary write")
		_check(not FileAccess.file_exists(slot + ".json.rejected"), "IO failure does not quarantine valid main")
	faulty.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(slot + ".bak.json"))

func _test_empty_world_load(manager: SaveManagerService, inventory: InventoryCoordinator, player: PlayerCharacter, flow: SceneFlowCoordinator, data: Dictionary) -> void:
	var empty_flow := SceneFlowCoordinator.new()
	var container := Node2D.new()
	root.add_child(container)
	root.add_child(empty_flow)
	empty_flow.configure(container, player)
	empty_flow.zone_scenes = flow.zone_scenes
	var old_position: Vector2 = player.global_position
	_check(manager.apply_runtime_snapshot(data, inventory, player, empty_flow).success, "initial load without previous zone commits safely")
	empty_flow.unconfigure(container)
	empty_flow.free()
	container.free()
	player.global_position = old_position

func _test_inventory_failure(manager: SaveManagerService, inventory: InventoryCoordinator, player: PlayerCharacter, flow: SceneFlowCoordinator, data: Dictionary) -> void:
	var faulty := FailingInventory.new()
	faulty.content_registry = inventory.content_registry
	faulty.player_inventory = inventory.player_inventory
	faulty.hotbar = inventory.hotbar
	faulty.storages = inventory.storages
	var previous: InventoryModel = faulty.player_inventory
	_check(not manager.apply_runtime_snapshot(data, faulty, player, flow).success, "inventory mutation failure rejected")
	_check(faulty.player_inventory == previous, "inventory failure restores original model")
	faulty.free()

func _test_player_failure(manager: SaveManagerService, inventory: InventoryCoordinator, flow: SceneFlowCoordinator, data: Dictionary) -> void:
	var faulty := PLAYER.instantiate() as PlayerCharacter
	faulty.set_script(FailingPlayer)
	root.add_child(faulty)
	faulty.global_position = Vector2(-300, 200)
	faulty.velocity = Vector2(7, 9)
	faulty.state_machine.current_state = PlayerStateMachine.State.MOVE
	var previous_player: Node2D = flow.player
	var previous_zone: WorldZone = flow.current_zone
	flow.player = faulty
	_check(not manager.apply_runtime_snapshot(data, inventory, faulty, flow).success, "player mutation failure rejected")
	_check(faulty.global_position == Vector2(-300, 200) and faulty.velocity == Vector2(7, 9), "player position and velocity rollback")
	_check(faulty.get_state() == PlayerStateMachine.State.MOVE, "player state rollback")
	_check(flow.current_zone == previous_zone, "player failure restores zone")
	flow.player = previous_player
	faulty.free()

func _test_visual_collision(player: PlayerCharacter) -> void:
	var wrapper := WorldZone.new()
	var blockout: Node2D = BLOCKOUT.instantiate()
	wrapper.add_child(blockout)
	root.add_child(wrapper)
	var bounds: Rect2 = wrapper.walkable_bounds
	_check(not SafeLandingResolver.is_safe(wrapper, player, Vector2(384, -300), bounds), "deep water polygon blocks full player shape")
	_check(SafeLandingResolver.is_safe(wrapper, player, Vector2(384, 0), bounds), "bridge deck is walkable current ground layer")
	_check(not SafeLandingResolver.is_safe(wrapper, player, Vector2(384, 100), bounds), "bridge rail rejects landing")
	var foundation := blockout.get_node("CottagePrototype/FoundationBody/Footprint") as CollisionPolygon2D
	var center := Vector2.ZERO
	for point in foundation.polygon:
		center += point
	center /= foundation.polygon.size()
	_check(not SafeLandingResolver.is_safe(wrapper, player, foundation.to_global(center), bounds), "house foundation polygon rejects landing")
	var landing: Dictionary = SafeLandingResolver.resolve(wrapper, player, Vector2(384, -300), Vector2(-256, 0), bounds)
	_check(landing["success"] and SafeLandingResolver.is_safe(wrapper, player, landing["position"], bounds), "deep water deterministic recovery to reachable shore")
	wrapper.free()

func _test_enclosed_landing(player: PlayerCharacter) -> void:
	var zone := WorldZone.new()
	root.add_child(zone)
	for wall in [
		_wall(Vector2(200, 0), Vector2(20, 420)), _wall(Vector2(600, 0), Vector2(20, 420)),
		_wall(Vector2(400, -200), Vector2(420, 20)), _wall(Vector2(400, 200), Vector2(420, 20)),
	]:
		zone.add_child(wall)
	_check(SafeLandingResolver.is_safe(zone, player, Vector2(400, 0), zone.walkable_bounds), "enclosed point passes collision-only check")
	var result: Dictionary = SafeLandingResolver.resolve(zone, player, Vector2(400, 0), Vector2.ZERO, zone.walkable_bounds)
	_check(result["success"] and result["position"] == Vector2.ZERO, "unreachable enclosed point returns to connected spawn")
	zone.free()

func _wall(point: Vector2, size: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 2
	body.position = point
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	return body

func _check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		print("FAIL: " + message)
