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
	var previous_inventories: Dictionary = {
		"player": InventoryDataCodec.encode_inventory(inventory_service.player_inventory),
	}
	var previous_hotbar: Dictionary = InventoryDataCodec.encode_hotbar(inventory_service.hotbar)
	var previous_storages: Dictionary = {}
	for storage_id in inventory_service.storages:
		previous_storages[String(storage_id)] = InventoryDataCodec.encode_storage(
			inventory_service.storages[storage_id]
		)
	var inventory_result: InventoryDataResult = inventory_service.apply_save_sections(
		prepared.data["inventories"],
		prepared.data["hotbar"],
		prepared.data["storages"]
	)
	if not inventory_result.success:
		return SaveOperationResult.failed(inventory_result.reason_key)
	var player_data := prepared.data["player"] as Dictionary
	var position_data := player_data["position"] as Dictionary
	var restored_position := Vector2(position_data["x"], position_data["y"])
	if not scene_flow.transition_to_saved_position(
		saved_zone_id,
		saved_spawn_id,
		restored_position
	):
		inventory_service.apply_save_sections(
			previous_inventories,
			previous_hotbar,
			previous_storages
		)
		return SaveOperationResult.failed(&"SAVE_RUNTIME_ZONE_RESTORE_FAILED")
	if not player.restore_runtime_state(
		restored_position,
		StringName(player_data["facing_id"])
	):
		return SaveOperationResult.failed(&"SAVE_RUNTIME_PLAYER_RESTORE_FAILED")
	if not scene_flow.apply_runtime_world_state(prepared.data["world_state"]):
		return SaveOperationResult.failed(&"SAVE_RUNTIME_WORLD_STATE_RESTORE_FAILED")
	return SaveOperationResult.succeeded(prepared.data)


func save_game(base_path: String, data: Variant) -> SaveOperationResult:
	var prepared: SaveOperationResult = SaveDataValidator.prepare(data, content_registry)
	if not prepared.success:
		return prepared
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
		if current_main.success:
			_remove_if_exists(paths["backup"])
			if DirAccess.rename_absolute(paths["main"], paths["backup"]) != OK:
				_remove_if_exists(paths["temp"])
				return SaveOperationResult.failed(&"SAVE_BACKUP_ROTATION_FAILED")
		else:
			_remove_if_exists(paths["main"])
	if DirAccess.rename_absolute(paths["temp"], paths["main"]) != OK:
		return SaveOperationResult.failed(&"SAVE_COMMIT_FAILED")
	return SaveOperationResult.succeeded(prepared.data, paths["main"])


func load_game(base_path: String) -> SaveOperationResult:
	var paths: Dictionary = _build_paths(base_path)
	var main_result: SaveOperationResult = _read_validated(paths["main"])
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
	if main_result.success:
		var main_apply: SaveOperationResult = apply_runtime_snapshot(
			main_result.data,
			inventory_service,
			player,
			scene_flow
		)
		if main_apply.success:
			main_apply.source_path = paths["main"]
			return main_apply
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


func _read_validated(path: String) -> SaveOperationResult:
	if not FileAccess.file_exists(path):
		return SaveOperationResult.failed(&"SAVE_FILE_MISSING")
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return SaveOperationResult.failed(&"SAVE_FILE_OPEN_FAILED")
	var text: String = file.get_as_text()
	var json := JSON.new()
	if json.parse(text) != OK:
		return SaveOperationResult.failed(&"SAVE_JSON_PARSE_FAILED")
	return SaveDataValidator.prepare(json.data, content_registry)


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
