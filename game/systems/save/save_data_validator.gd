class_name SaveDataValidator
extends RefCounted

const CURRENT_SCHEMA_VERSION: int = 1
const GAME_VERSION: String = "0.1.0-dev"


static func create_snapshot(
	inventory: InventoryModel,
	hotbar: HotbarModel,
	storages: Dictionary[StringName, StorageInventory],
	player_position: Vector2,
	facing_id: StringName,
	zone_id: StringName,
	spawn_id: StringName,
	save_id: String = "slot_01",
	world_state: Dictionary = {}
) -> Dictionary:
	var storage_data: Dictionary = {}
	for storage_id in storages:
		storage_data[String(storage_id)] = InventoryDataCodec.encode_storage(storages[storage_id])
	return {
		"schema_version": CURRENT_SCHEMA_VERSION,
		"game_version": GAME_VERSION,
		"save_id": save_id,
		"saved_at_utc": Time.get_datetime_string_from_system(true),
		"play_time_seconds": 0,
		"player": {
			"position": {"x": player_position.x, "y": player_position.y},
			"facing_id": String(facing_id),
		},
		"inventories": {"player": InventoryDataCodec.encode_inventory(inventory)},
		"hotbar": InventoryDataCodec.encode_hotbar(hotbar),
		"storages": storage_data,
		"world": {
			"zone_id": String(zone_id),
			"spawn_id": String(spawn_id),
		},
		"world_state": world_state.duplicate(true),
		"quests": {},
		"relationships": {},
		"settings_snapshot": {},
	}


static func prepare(data: Variant, registry: ContentRegistryService) -> SaveOperationResult:
	if not data is Dictionary:
		return SaveOperationResult.failed(&"SAVE_DATA_NOT_DICTIONARY")
	var prepared: Dictionary = (data as Dictionary).duplicate(true)
	var schema_result: Array = _coerce_integer(prepared.get("schema_version", 0))
	if not schema_result[0]:
		return SaveOperationResult.failed(&"SAVE_INVALID_SCHEMA_VERSION")
	var schema_version: int = schema_result[1]
	prepared["schema_version"] = schema_version
	if schema_version == 0:
		prepared = _migrate_v0_to_v1(prepared)
	elif schema_version != CURRENT_SCHEMA_VERSION:
		return SaveOperationResult.failed(&"SAVE_UNSUPPORTED_SCHEMA_VERSION")
	_apply_optional_defaults(prepared)
	var normalization_error: StringName = _normalize_integer_fields(prepared)
	if not normalization_error.is_empty():
		return SaveOperationResult.failed(normalization_error)
	var error_key: StringName = _validate_current(prepared, registry)
	if not error_key.is_empty():
		return SaveOperationResult.failed(error_key)
	return SaveOperationResult.succeeded(prepared)


static func _migrate_v0_to_v1(legacy: Dictionary) -> Dictionary:
	return {
		"schema_version": CURRENT_SCHEMA_VERSION,
		"game_version": legacy.get("game_version", "0.0.0"),
		"save_id": legacy.get("save_id", "migrated_v0"),
		"saved_at_utc": legacy.get("saved_at_utc", "1970-01-01T00:00:00Z"),
		"play_time_seconds": legacy.get("play_time_seconds", 0),
		"player": {
			"position": legacy.get("player_position", {"x": 0.0, "y": 0.0}),
			"facing_id": legacy.get("facing_id", "down"),
		},
		"inventories": {"player": legacy.get("inventory", {})},
		"hotbar": legacy.get("hotbar", {}),
		"storages": legacy.get("storages", {}),
		"world": {
			"zone_id": legacy.get("zone_id", "zone_home_placeholder"),
			"spawn_id": legacy.get("spawn_id", "spawn_home_start"),
		},
		"world_state": legacy.get("world_state", {}),
		"quests": legacy.get("quests", {}),
		"relationships": legacy.get("relationships", {}),
		"settings_snapshot": legacy.get("settings_snapshot", {}),
	}


static func _apply_optional_defaults(data: Dictionary) -> void:
	if not data.has("play_time_seconds"):
		data["play_time_seconds"] = 0
	for key in ["storages", "world_state", "quests", "relationships", "settings_snapshot"]:
		if not data.has(key):
			data[key] = {}


static func _normalize_integer_fields(data: Dictionary) -> StringName:
	var play_time_error: StringName = _normalize_dictionary_integer(
		data,
		"play_time_seconds",
		&"SAVE_INVALID_PLAY_TIME"
	)
	if not play_time_error.is_empty():
		return play_time_error
	if not data.get("inventories") is Dictionary:
		return &"SAVE_INVALID_INVENTORIES"
	var inventories := data["inventories"] as Dictionary
	var inventory_error: StringName = _normalize_inventory_data(inventories.get("player"))
	if not inventory_error.is_empty():
		return inventory_error
	var hotbar_error: StringName = _normalize_hotbar_data(data.get("hotbar"))
	if not hotbar_error.is_empty():
		return hotbar_error
	if not data.get("storages") is Dictionary:
		return &"SAVE_INVALID_STORAGES"
	var storages := data["storages"] as Dictionary
	for storage_id in storages:
		var storage_data: Variant = storages[storage_id]
		if not storage_data is Dictionary:
			return &"SAVE_INVALID_STORAGE"
		var storage := storage_data as Dictionary
		var storage_schema_error: StringName = _normalize_dictionary_integer(
			storage,
			"schema_version",
			&"STORAGE_DATA_UNSUPPORTED_SCHEMA"
		)
		if not storage_schema_error.is_empty():
			return storage_schema_error
		var storage_inventory_error: StringName = _normalize_inventory_data(
			storage.get("inventory")
		)
		if not storage_inventory_error.is_empty():
			return storage_inventory_error
	return &""


static func _normalize_inventory_data(inventory_data: Variant) -> StringName:
	if not inventory_data is Dictionary:
		return &"SAVE_INVALID_PLAYER_INVENTORY"
	var inventory := inventory_data as Dictionary
	for field in ["schema_version", "capacity"]:
		var field_error: StringName = _normalize_dictionary_integer(
			inventory,
			field,
			&"SAVE_INVALID_PLAYER_INVENTORY"
		)
		if not field_error.is_empty():
			return field_error
	if not inventory.get("slots") is Array:
		return &"INVENTORY_DATA_INVALID_SLOTS"
	var slots := inventory["slots"] as Array
	for slot_entry in slots:
		if not slot_entry is Dictionary:
			return &"INVENTORY_DATA_INVALID_SLOT"
		var slot := slot_entry as Dictionary
		if slot.is_empty():
			continue
		var quantity_error: StringName = _normalize_dictionary_integer(
			slot,
			"quantity",
			&"INVENTORY_DATA_INVALID_QUANTITY"
		)
		if not quantity_error.is_empty():
			return quantity_error
	return &""


static func _normalize_hotbar_data(hotbar_data: Variant) -> StringName:
	if not hotbar_data is Dictionary:
		return &"SAVE_INVALID_HOTBAR"
	var hotbar := hotbar_data as Dictionary
	for field in ["schema_version", "selected_index"]:
		var field_error: StringName = _normalize_dictionary_integer(
			hotbar,
			field,
			&"SAVE_INVALID_HOTBAR"
		)
		if not field_error.is_empty():
			return field_error
	if not hotbar.get("assignments") is Array:
		return &"HOTBAR_DATA_INVALID_ASSIGNMENTS"
	var assignments := hotbar["assignments"] as Array
	for index in range(assignments.size()):
		var assignment_result: Array = _coerce_integer(assignments[index])
		if not assignment_result[0]:
			return &"HOTBAR_DATA_INVALID_ASSIGNMENT"
		assignments[index] = assignment_result[1]
	return &""


static func _normalize_dictionary_integer(
	dictionary: Dictionary,
	key: String,
	error_key: StringName
) -> StringName:
	var result: Array = _coerce_integer(dictionary.get(key))
	if not result[0]:
		return error_key
	dictionary[key] = result[1]
	return &""


static func _coerce_integer(value: Variant) -> Array:
	if value is int:
		return [true, value]
	if value is float and is_finite(value) and is_equal_approx(value, roundf(value)):
		return [true, int(value)]
	return [false, 0]


static func _validate_current(
	data: Dictionary,
	registry: ContentRegistryService
) -> StringName:
	if registry == null:
		return &"SAVE_MISSING_CONTENT_REGISTRY"
	if not data.get("game_version") is String:
		return &"SAVE_INVALID_GAME_VERSION"
	if not data.get("save_id") is String or String(data["save_id"]).is_empty():
		return &"SAVE_INVALID_SAVE_ID"
	if not data.get("saved_at_utc") is String:
		return &"SAVE_INVALID_TIMESTAMP"
	if not data.get("play_time_seconds") is int or data["play_time_seconds"] < 0:
		return &"SAVE_INVALID_PLAY_TIME"
	var player_error: StringName = _validate_player(data.get("player"))
	if not player_error.is_empty():
		return player_error
	if not data.get("inventories") is Dictionary:
		return &"SAVE_INVALID_INVENTORIES"
	var inventories := data["inventories"] as Dictionary
	var inventory_error: StringName = _validate_inventory_data(inventories.get("player"), registry)
	if not inventory_error.is_empty():
		return inventory_error
	var hotbar_error: StringName = _validate_hotbar_data(data.get("hotbar"), inventories["player"], registry)
	if not hotbar_error.is_empty():
		return hotbar_error
	var storage_error: StringName = _validate_storages(data.get("storages"), registry)
	if not storage_error.is_empty():
		return storage_error
	if not data.get("world") is Dictionary:
		return &"SAVE_INVALID_WORLD"
	var world := data["world"] as Dictionary
	if not world.get("zone_id") is String or String(world["zone_id"]).is_empty():
		return &"SAVE_INVALID_ZONE_ID"
	if not world.get("spawn_id") is String or String(world["spawn_id"]).is_empty():
		return &"SAVE_INVALID_SPAWN_ID"
	var world_state_error: StringName = WorldStateCodec.normalize_and_validate(
		data.get("world_state")
	)
	if not world_state_error.is_empty():
		return world_state_error
	for key in ["quests", "relationships", "settings_snapshot"]:
		if not data.get(key) is Dictionary:
			return &"SAVE_INVALID_OPTIONAL_SECTION"
	return &""


static func _validate_player(player_data: Variant) -> StringName:
	if not player_data is Dictionary:
		return &"SAVE_INVALID_PLAYER"
	var player := player_data as Dictionary
	if not player.get("position") is Dictionary:
		return &"SAVE_INVALID_PLAYER_POSITION"
	var position := player["position"] as Dictionary
	if not _is_number(position.get("x")) or not _is_number(position.get("y")):
		return &"SAVE_INVALID_PLAYER_POSITION"
	if not player.get("facing_id") is String or String(player["facing_id"]).is_empty():
		return &"SAVE_INVALID_PLAYER_FACING"
	if not Direction8.DIRECTION_IDS.has(StringName(player["facing_id"])):
		return &"SAVE_INVALID_PLAYER_FACING"
	return &""


static func _validate_inventory_data(
	inventory_data: Variant,
	registry: ContentRegistryService
) -> StringName:
	if not inventory_data is Dictionary:
		return &"SAVE_INVALID_PLAYER_INVENTORY"
	var capacity: Variant = (inventory_data as Dictionary).get("capacity")
	if not capacity is int or capacity < 1 or capacity > 256:
		return &"SAVE_INVALID_PLAYER_INVENTORY"
	var inventory := InventoryModel.new(registry, capacity)
	var result: InventoryDataResult = InventoryDataCodec.decode_inventory(inventory, inventory_data)
	return &"" if result.success else result.reason_key


static func _validate_hotbar_data(
	hotbar_data: Variant,
	inventory_data: Dictionary,
	registry: ContentRegistryService
) -> StringName:
	if not hotbar_data is Dictionary:
		return &"SAVE_INVALID_HOTBAR"
	var assignments: Variant = (hotbar_data as Dictionary).get("assignments")
	if not assignments is Array or assignments.size() != HotbarModel.DEFAULT_SIZE:
		return &"SAVE_INVALID_HOTBAR"
	var inventory := InventoryModel.new(registry, inventory_data["capacity"])
	var hotbar := HotbarModel.new(inventory, assignments.size())
	var result: InventoryDataResult = InventoryDataCodec.decode_hotbar(hotbar, hotbar_data)
	return &"" if result.success else result.reason_key


static func _validate_storages(
	storages_data: Variant,
	registry: ContentRegistryService
) -> StringName:
	if not storages_data is Dictionary:
		return &"SAVE_INVALID_STORAGES"
	var storages := storages_data as Dictionary
	for storage_id in storages:
		var storage_data: Variant = storages[storage_id]
		if not storage_data is Dictionary:
			return &"SAVE_INVALID_STORAGE"
		var inventory_data: Variant = (storage_data as Dictionary).get("inventory")
		if not inventory_data is Dictionary:
			return &"SAVE_INVALID_STORAGE"
		var capacity: Variant = (inventory_data as Dictionary).get("capacity")
		if not capacity is int or capacity < 1 or capacity > 256:
			return &"SAVE_INVALID_STORAGE"
		var storage := StorageInventory.new(registry, StringName(storage_id), capacity)
		var result: InventoryDataResult = InventoryDataCodec.decode_storage(storage, storage_data)
		if not result.success:
			return result.reason_key
	return &""


static func _is_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))
