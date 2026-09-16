extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://scenes/bootstrap/main.tscn")
const SAVED_POSITION: Vector2 = Vector2(222.0, -111.0)


class FaultySaveManager extends SaveManagerService:
	var fault: String = ""

	func _write_text(path: String, text: String) -> bool:
		if fault == "write":
			return false
		return super._write_text(path, text)

	func _rename_file(source: String, destination: String) -> Error:
		if fault == "rotate" and destination.ends_with(".bak.json"):
			return ERR_FILE_CANT_WRITE
		if fault == "commit" and source.ends_with(".tmp.json"):
			return ERR_FILE_CANT_WRITE
		if fault == "isolate" and destination.contains(".rejected"):
			return ERR_FILE_CANT_WRITE
		return super._rename_file(source, destination)


var failures: int = 0


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	if arguments.size() != 2:
		quit(2)
		return
	var base_path: String = arguments[1]
	if arguments[0] == "cleanup":
		_cleanup(base_path)
		quit(0)
		return
	var main := MAIN_SCENE.instantiate() as GameBootstrap
	root.add_child(main)
	await process_frame
	var inventory := root.get_node("InventoryService") as InventoryCoordinator
	var flow := root.get_node("SceneFlowService") as SceneFlowCoordinator
	var manager := root.get_node("SaveManager") as SaveManagerService
	var player := main.get_node("Player") as PlayerCharacter
	match arguments[0]:
		"seed", "seed_capacity":
			player.restore_runtime_state(SAVED_POSITION, &"up")
			var snapshot: SaveOperationResult = manager.create_runtime_snapshot(inventory, player, flow)
			_check(manager.save_game(base_path, snapshot.data, flow).success, "save A")
			snapshot.data["player"]["position"]["x"] = 333.0
			_check(manager.save_game(base_path, snapshot.data, flow).success, "save B")
			if arguments[0] == "seed_capacity":
				snapshot.data["inventories"]["player"]["capacity"] = 25
				snapshot.data["inventories"]["player"]["slots"].append({})
			else:
				snapshot.data["world"]["zone_id"] = "zone_removed_after_update"
			_write_raw(base_path + ".json", JSON.stringify(snapshot.data))
		"recover", "verify":
			var loaded: SaveOperationResult = manager.load_and_apply(base_path, inventory, player, flow)
			_check(loaded.success and loaded.recovered_from_backup, "recover from backup")
			_check(player.global_position.is_equal_approx(SAVED_POSITION), "recover A position")
			_check(not FileAccess.file_exists(base_path + ".json"), "bad main removed from rotation")
		"isolate_fail":
			var faulty := FaultySaveManager.new()
			faulty.configure_registry(root.get_node("ContentRegistry") as ContentRegistryService)
			faulty.fault = "isolate"
			_check(not faulty.load_and_apply(base_path, inventory, player, flow).success, "isolation fails")
			_check(FileAccess.file_exists(base_path + ".json"), "failed isolation retains main")
			faulty.free()
		"save":
			# Deliberately do not load: isolation must survive a fresh manager/process.
			var snapshot: SaveOperationResult = manager.create_runtime_snapshot(inventory, player, flow)
			_check(manager.save_game(base_path, snapshot.data, flow).success, "save after process restart")
			_write_raw(base_path + ".json", "second damaged main")
		"faults":
			_run_faults(base_path, inventory, player, flow)
		_:
			_check(false, "unknown mode")
	print("SAVE RECOVERY %s: %s" % [arguments[0], "PASS" if failures == 0 else "FAIL"])
	quit(0 if failures == 0 else 1)


func _run_faults(
	base_path: String,
	inventory: InventoryCoordinator,
	player: PlayerCharacter,
	flow: SceneFlowCoordinator
) -> void:
	var manager := FaultySaveManager.new()
	manager.configure_registry(root.get_node("ContentRegistry") as ContentRegistryService)
	player.restore_runtime_state(SAVED_POSITION, &"up")
	var snapshot: SaveOperationResult = manager.create_runtime_snapshot(inventory, player, flow)
	for mode in ["write", "rotate", "commit"]:
		_cleanup(base_path)
		manager.fault = ""
		_check(manager.save_game(base_path, snapshot.data, flow).success, "fault fixture save A")
		var second: Dictionary = snapshot.data.duplicate(true)
		second["player"]["position"]["x"] = 333.0
		_check(manager.save_game(base_path, second, flow).success, "fault fixture save B")
		manager.fault = mode
		_check(not manager.save_game(base_path, snapshot.data, flow).success, mode + " must fail")
		manager.fault = ""
		_check(manager.load_and_apply(base_path, inventory, player, flow).success, mode + " preserves recovery")
		_check(player.global_position == Vector2(333.0, -111.0), mode + " preserves B state")
	# Failure to isolate must not apply a backup or overwrite the only good backup.
	_cleanup(base_path)
	_check(manager.save_game(base_path, snapshot.data, flow).success, "isolation fixture save A")
	_check(manager.save_game(base_path, snapshot.data, flow).success, "isolation fixture save B")
	var invalid: Dictionary = snapshot.data.duplicate(true)
	invalid["world"]["zone_id"] = "removed_zone"
	_write_raw(base_path + ".json", JSON.stringify(invalid))
	player.restore_runtime_state(Vector2(100.0, 100.0), &"down")
	manager.fault = "isolate"
	_check(not manager.load_and_apply(base_path, inventory, player, flow).success, "isolation failure reported")
	_check(player.global_position == Vector2(100.0, 100.0), "isolation failure leaves runtime intact")
	_check(not manager.save_game(base_path, snapshot.data, flow).success, "save also refuses failed isolation")
	# No intervening successful load: save must preflight old main independently.
	manager.fault = "rotate"
	_check(manager.save_game(base_path, snapshot.data, flow).success, "bad main bypasses backup rotation")
	_write_raw(base_path + ".json", "broken after direct save")
	manager.fault = ""
	_check(manager.load_and_apply(base_path, inventory, player, flow).success, "isolation retry recovers A")
	# With the rejected main absent, write/commit failures cannot erase the sole good backup.
	for mode in ["write", "commit"]:
		manager.fault = mode
		_check(not manager.save_game(base_path, snapshot.data, flow).success, "recovered " + mode + " fails")
		manager.fault = ""
		_check(manager.load_and_apply(base_path, inventory, player, flow).success, "sole backup survives " + mode)
	manager.free()


func _write_raw(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _cleanup(base_path: String) -> void:
	var directory: String = ProjectSettings.globalize_path(base_path).get_base_dir()
	if not DirAccess.dir_exists_absolute(directory):
		return
	for file_name in DirAccess.get_files_at(directory):
		if file_name.begins_with(base_path.get_file() + "."):
			DirAccess.remove_absolute(directory.path_join(file_name))
	DirAccess.remove_absolute(directory)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		print("FAIL: " + message)
