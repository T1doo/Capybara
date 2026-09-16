class_name SaveManagerTestCases
extends RefCounted

const REGISTRY_SCRIPT: Script = preload("res://autoload/content_registry.gd")
const SAVE_MANAGER_SCRIPT: Script = preload("res://autoload/save_manager.gd")


static func run(assert_true: Callable, assert_int_equal: Callable) -> void:
	var registry := _make_registry()
	var manager: SaveManagerService = SAVE_MANAGER_SCRIPT.new()
	manager.configure_registry(registry)
	var base_path: String = "user://capybara_tests/save_manager_%d/slot_01" % Time.get_ticks_usec()
	var first_snapshot: Dictionary = _make_snapshot(registry, 3)
	var first_save: SaveOperationResult = manager.save_game(base_path, first_snapshot)
	assert_true.call(first_save.success, "first save writes a validated main file")
	if not first_save.success:
		print("SAVE TEST FIRST FAILURE: %s" % first_save.reason_key)
		_cleanup_test_files(base_path)
		manager.free()
		registry.free()
		return
	var first_load: SaveOperationResult = manager.load_game(base_path)
	assert_true.call(first_load.success, "fresh main save loads")
	assert_true.call(not first_load.recovered_from_backup, "fresh load uses the main file")
	assert_int_equal.call(_saved_branch_count(first_load.data), 3, "fresh load preserves inventory")

	var second_snapshot: Dictionary = _make_snapshot(registry, 5)
	assert_true.call(manager.save_game(base_path, second_snapshot).success, "second save rotates a backup")
	assert_true.call(
		not FileAccess.file_exists(base_path + ".tmp.json"),
		"successful save leaves no temporary file"
	)
	var invalid_snapshot: Dictionary = second_snapshot.duplicate(true)
	invalid_snapshot["inventories"]["player"]["slots"][0]["item_id"] = "item_missing"
	assert_true.call(
		not manager.save_game(base_path, invalid_snapshot).success,
		"invalid snapshot is rejected before replacing main"
	)
	assert_int_equal.call(
		_saved_branch_count(manager.load_game(base_path).data),
		5,
		"invalid save attempt preserves current main"
	)
	_write_raw(base_path + ".json", "{broken-json")
	var recovered: SaveOperationResult = manager.load_game(base_path)
	assert_true.call(recovered.success and recovered.recovered_from_backup, "corrupt main recovers the valid backup")
	assert_int_equal.call(_saved_branch_count(recovered.data), 3, "backup contains previous valid save")

	_write_raw(base_path + ".bak.json", "also-broken")
	var both_corrupt: SaveOperationResult = manager.load_game(base_path)
	assert_true.call(not both_corrupt.success, "corrupt main and backup fail clearly")
	assert_true.call(
		both_corrupt.reason_key == &"SAVE_MAIN_AND_BACKUP_INVALID",
		"double corruption returns a stable reason"
	)

	var v0_snapshot: Dictionary = _make_v0_snapshot(registry)
	var migrated: SaveOperationResult = SaveDataValidator.prepare(v0_snapshot, registry)
	assert_true.call(migrated.success, "v0 fixture migrates to current schema")
	assert_int_equal.call(migrated.data["schema_version"], 1, "migration updates schema version")
	assert_true.call(migrated.data["quests"] is Dictionary, "migration adds optional defaults")
	migrated.data["future_section"] = {"ignored": true}
	assert_true.call(
		SaveDataValidator.prepare(migrated.data, registry).success,
		"unknown future fields are tolerated"
	)
	var missing_optional: Dictionary = _make_snapshot(registry, 1)
	missing_optional.erase("quests")
	missing_optional.erase("relationships")
	missing_optional.erase("settings_snapshot")
	missing_optional.erase("world_state")
	var defaulted: SaveOperationResult = SaveDataValidator.prepare(missing_optional, registry)
	assert_true.call(defaulted.success, "missing optional current fields use defaults")
	assert_true.call(defaulted.data["quests"] is Dictionary, "current defaults include quests")
	assert_true.call(defaulted.data["world_state"] is Dictionary, "current defaults include world state")
	var future_schema: Dictionary = migrated.data.duplicate(true)
	future_schema["schema_version"] = 99
	assert_true.call(
		not SaveDataValidator.prepare(future_schema, registry).success,
		"unsupported future schema is rejected"
	)
	var non_finite_position: Dictionary = _make_snapshot(registry, 1)
	non_finite_position["player"]["position"]["x"] = INF
	assert_true.call(
		not SaveDataValidator.prepare(non_finite_position, registry).success,
		"non-finite player coordinates are rejected"
	)
	var invalid_hotbar_size: Dictionary = _make_snapshot(registry, 1)
	invalid_hotbar_size["hotbar"]["assignments"] = [0]
	assert_true.call(
		not SaveDataValidator.prepare(invalid_hotbar_size, registry).success,
		"save schema rejects a non-eight-slot hotbar"
	)

	_cleanup_test_files(base_path)
	manager.free()
	registry.free()


static func _make_snapshot(
	registry: ContentRegistryService,
	branch_quantity: int
) -> Dictionary:
	var inventory := InventoryModel.new(registry, 24)
	inventory.add_item(&"item_save_branch", branch_quantity)
	var hotbar := HotbarModel.new(inventory, 8)
	var storage := StorageInventory.new(registry, &"storage_save_test", 4)
	storage.add_item(&"item_save_branch", 1)
	var storages: Dictionary[StringName, StorageInventory] = {
		&"storage_save_test": storage,
	}
	return SaveDataValidator.create_snapshot(
		inventory,
		hotbar,
		storages,
		Vector2(12.0, 34.0),
		&"down",
		&"zone_home_placeholder",
		&"spawn_home_start"
	)


static func _make_v0_snapshot(registry: ContentRegistryService) -> Dictionary:
	var inventory := InventoryModel.new(registry, 24)
	inventory.add_item(&"item_save_branch", 2)
	var hotbar := HotbarModel.new(inventory, 8)
	return {
		"schema_version": 0,
		"save_id": "legacy_slot",
		"inventory": InventoryDataCodec.encode_inventory(inventory),
		"hotbar": InventoryDataCodec.encode_hotbar(hotbar),
		"player_position": {"x": 1.0, "y": 2.0},
		"zone_id": "zone_home_placeholder",
		"spawn_id": "spawn_home_start",
	}


static func _saved_branch_count(data: Dictionary) -> int:
	var inventory_data := data["inventories"]["player"] as Dictionary
	var total: int = 0
	for slot in inventory_data["slots"]:
		if slot is Dictionary and slot.get("item_id", "") == "item_save_branch":
			total += slot["quantity"]
	return total


static func _make_registry() -> ContentRegistryService:
	var registry: ContentRegistryService = REGISTRY_SCRIPT.new()
	var definition := ItemDefinition.new()
	definition.id = &"item_save_branch"
	definition.name_key = &"ITEM_SAVE_NAME"
	definition.description_key = &"ITEM_SAVE_DESCRIPTION"
	definition.category = ItemDefinition.Category.MATERIAL
	definition.max_stack = 99
	var definitions: Array[ItemDefinition] = [definition]
	registry.load_item_definitions(definitions)
	return registry


static func _write_raw(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.flush()


static func _cleanup_test_files(base_path: String) -> void:
	var global_base: String = ProjectSettings.globalize_path(base_path)
	for suffix in [".json", ".bak.json", ".tmp.json"]:
		var path: String = global_base + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	var directory: String = global_base.get_base_dir()
	if DirAccess.dir_exists_absolute(directory):
		DirAccess.remove_absolute(directory)
