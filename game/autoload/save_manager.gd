class_name SaveManagerService
extends Node

var content_registry: ContentRegistryService


func _ready() -> void:
	content_registry = get_node_or_null("/root/ContentRegistry") as ContentRegistryService


func configure_registry(registry: ContentRegistryService) -> void:
	content_registry = registry


func create_runtime_snapshot(
	inventory_service: InventoryCoordinator,
	player: PlayerCharacter,
	scene_flow: SceneFlowCoordinator,
	save_id: String = "slot_01"
) -> SaveOperationResult:
	if (
		inventory_service == null
		or player == null
		or scene_flow == null
		or scene_flow.get_current_zone_id().is_empty()
	):
		return SaveOperationResult.failed(&"SAVE_RUNTIME_NOT_READY")
	var snapshot: Dictionary = SaveDataValidator.create_snapshot(
		inventory_service.player_inventory,
		inventory_service.hotbar,
		inventory_service.storages,
		player.global_position,
		player.get_facing_id(),
		scene_flow.get_current_zone_id(),
		scene_flow.get_current_spawn_id(),
		save_id,
		scene_flow.capture_runtime_world_state()
	)
	snapshot["world"]["map_revision"] = scene_flow.current_zone.map_revision
	snapshot["world"]["navigation_layer"] = "ground"
	return SaveDataValidator.prepare(snapshot, content_registry)


func apply_runtime_snapshot(
	data: Variant,
	inventory_service: InventoryCoordinator,
	player: PlayerCharacter,
	scene_flow: SceneFlowCoordinator
) -> SaveOperationResult:
	var prepared: SaveOperationResult = SaveDataValidator.prepare(data, content_registry)
	if not prepared.success:
		return prepared
	var world := prepared.data["world"] as Dictionary
	var saved_zone_id := StringName(world["zone_id"])
	var saved_spawn_id := StringName(world["spawn_id"])
	var transition_error: StringName = scene_flow.preflight_transition(
		saved_zone_id,
		saved_spawn_id
	)
	if not transition_error.is_empty():
		return SaveOperationResult.failed(transition_error)
	var world_state_error: StringName = scene_flow.preflight_runtime_world_state(
		prepared.data["world_state"]
	)
	if not world_state_error.is_empty():
		return SaveOperationResult.failed(world_state_error)
	return SaveRuntimeTransaction.apply(prepared.data, inventory_service, player, scene_flow)


func save_game(
	base_path: String,
	data: Variant,
	runtime_flow: SceneFlowCoordinator = null
) -> SaveOperationResult:
	var prepared: SaveOperationResult = SaveDataValidator.prepare(data, content_registry)
	if not prepared.success:
		return prepared
	if runtime_flow == null and is_inside_tree():
		runtime_flow = get_node_or_null("/root/SceneFlowService") as SceneFlowCoordinator
	var runtime_error: StringName = _runtime_preflight(prepared.data, runtime_flow)
	if not runtime_error.is_empty():
		return SaveOperationResult.failed(runtime_error)
	var paths: Dictionary = _build_paths(base_path)
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(
		String(paths["main"]).get_base_dir()
	)
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		return SaveOperationResult.failed(&"SAVE_DIRECTORY_CREATE_FAILED")
	_remove_if_exists(paths["temp"])
	if not _write_text(paths["temp"], JSON.stringify(prepared.data, "\t", true)):
		return SaveOperationResult.failed(&"SAVE_TEMP_WRITE_FAILED")
	var temp_validation: SaveOperationResult = _read_validated(paths["temp"])
	if not temp_validation.success:
		_remove_if_exists(paths["temp"])
		return SaveOperationResult.failed(temp_validation.reason_key)

	if FileAccess.file_exists(paths["main"]):
		var current_main: SaveOperationResult = _read_validated(paths["main"])
		if _is_read_failure(current_main):
			_remove_if_exists(paths["temp"])
			return current_main
		var main_usable: bool = current_main.success
		if main_usable:
			main_usable = _runtime_preflight(current_main.data, runtime_flow).is_empty()
		if main_usable:
			_remove_if_exists(paths["backup"])
			if _rename_file(paths["main"], paths["backup"]) != OK:
				_remove_if_exists(paths["temp"])
				return SaveOperationResult.failed(&"SAVE_BACKUP_ROTATION_FAILED")
		else:
			if not _isolate_invalid_main(paths["main"]):
				_remove_if_exists(paths["temp"])
				return SaveOperationResult.failed(&"SAVE_INVALID_MAIN_ISOLATION_FAILED")
	if _rename_file(paths["temp"], paths["main"]) != OK:
		return SaveOperationResult.failed(&"SAVE_COMMIT_FAILED")
	return SaveOperationResult.succeeded(prepared.data, paths["main"])


func load_game(base_path: String) -> SaveOperationResult:
	var paths: Dictionary = _build_paths(base_path)
	var main_result: SaveOperationResult = _read_validated(paths["main"])
	if _is_read_failure(main_result):
		return main_result
	if main_result.success:
		main_result.source_path = paths["main"]
		return main_result
	var backup_result: SaveOperationResult = _read_validated(paths["backup"])
	if backup_result.success:
		backup_result.source_path = paths["backup"]
		backup_result.recovered_from_backup = true
		return backup_result
	return SaveOperationResult.failed(&"SAVE_MAIN_AND_BACKUP_INVALID")


func load_and_apply(
	base_path: String,
	inventory_service: InventoryCoordinator,
	player: PlayerCharacter,
	scene_flow: SceneFlowCoordinator
) -> SaveOperationResult:
	var paths: Dictionary = _build_paths(base_path)
	var main_result: SaveOperationResult = _read_validated(paths["main"])
	if _is_read_failure(main_result):
		return main_result
	if main_result.success:
		var preflight_error: StringName = _runtime_preflight(main_result.data, scene_flow)
		if preflight_error.is_empty():
			# Runtime application errors are transactional failures, not proof of corrupt data.
			var applied: SaveOperationResult = apply_runtime_snapshot(
				main_result.data, inventory_service, player, scene_flow
			)
			if applied.success:
				applied.source_path = paths["main"]
			return applied
		if preflight_error in [&"SAVE_RUNTIME_NOT_READY", &"SCENE_FLOW_NOT_CONFIGURED"]:
			return SaveOperationResult.failed(preflight_error)
	# A schema-valid but inapplicable main must never rotate over a good backup.
	# Moving it out of the rotation persists this decision across process restarts.
	if not _isolate_invalid_main(paths["main"]):
		return SaveOperationResult.failed(&"SAVE_INVALID_MAIN_ISOLATION_FAILED")
	var backup_result: SaveOperationResult = _read_validated(paths["backup"])
	if backup_result.success:
		var backup_apply: SaveOperationResult = apply_runtime_snapshot(
			backup_result.data,
			inventory_service,
			player,
			scene_flow
		)
		if backup_apply.success:
			backup_apply.source_path = paths["backup"]
			backup_apply.recovered_from_backup = true
			return backup_apply
	return SaveOperationResult.failed(&"SAVE_MAIN_AND_BACKUP_NOT_APPLICABLE")


func _runtime_preflight(data: Dictionary, flow: SceneFlowCoordinator) -> StringName:
	# Detached file-codec callers can validate structure; production saves also
	# validate applicability before deciding whether an old main may become backup.
	if flow == null:
		return &""
	var inventory := flow.get_node_or_null("/root/InventoryService") as InventoryCoordinator
	if inventory == null or inventory.player_inventory == null:
		return &"SAVE_RUNTIME_NOT_READY"
	var inventory_check: InventoryDataResult = inventory.preflight_save_sections(
		data["inventories"], data["hotbar"], data["storages"]
	)
	if not inventory_check.success:
		return inventory_check.reason_key
	var world: Dictionary = data["world"]
	var error: StringName = flow.preflight_transition(
		StringName(world["zone_id"]), StringName(world["spawn_id"])
	)
	if not error.is_empty():
		return error
	return flow.preflight_runtime_world_state(data["world_state"])


func _isolate_invalid_main(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return true
	var suffix: int = 0
	var rejected_path: String = path + ".rejected"
	while FileAccess.file_exists(rejected_path):
		suffix += 1
		rejected_path = path + ".rejected.%d" % suffix
	return _rename_file(path, rejected_path) == OK


func _rename_file(source: String, destination: String) -> Error:
	return DirAccess.rename_absolute(source, destination)


func _read_validated(path: String) -> SaveOperationResult:
	if not FileAccess.file_exists(path):
		return SaveOperationResult.failed(&"SAVE_FILE_MISSING")
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return SaveOperationResult.failed(&"SAVE_FILE_OPEN_FAILED")
	var text: String = file.get_as_text()
	if file.get_error() not in [OK, ERR_FILE_EOF]:
		return SaveOperationResult.failed(&"SAVE_FILE_READ_FAILED")
	var json := JSON.new()
	if json.parse(text) != OK:
		return SaveOperationResult.failed(&"SAVE_JSON_PARSE_FAILED")
	return SaveDataValidator.prepare(json.data, content_registry)


func _is_read_failure(result: SaveOperationResult) -> bool:
	return result.reason_key in [&"SAVE_FILE_OPEN_FAILED", &"SAVE_FILE_READ_FAILED"]


func _write_text(path: String, text: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.flush()
	return file.get_error() == OK


func _build_paths(base_path: String) -> Dictionary:
	var global_base: String = ProjectSettings.globalize_path(base_path)
	return {
		"main": global_base + ".json",
		"backup": global_base + ".bak.json",
		"temp": global_base + ".tmp.json",
	}


func _remove_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
