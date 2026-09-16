class_name InventorySerializationTestCases
extends RefCounted

const REGISTRY_SCRIPT: Script = preload("res://autoload/content_registry.gd")


static func run(assert_true: Callable, assert_int_equal: Callable) -> void:
	var registry := _make_registry()
	_test_inventory_round_trip(registry, assert_true, assert_int_equal)
	_test_corrupt_inventory_is_atomic(registry, assert_true, assert_int_equal)
	_test_hotbar_and_storage_round_trip(registry, assert_true, assert_int_equal)
	registry.free()


static func _test_inventory_round_trip(
	registry: ContentRegistryService,
	assert_true: Callable,
	assert_int_equal: Callable
) -> void:
	var source := InventoryModel.new(registry, 6)
	source.add_item(&"item_codec_branch", 7)
	source.add_item(&"item_codec_fiber", 3)
	source.move_or_merge(1, 4)
	var encoded: Dictionary = InventoryDataCodec.encode_inventory(source)
	encoded["future_field"] = "ignored"
	var restored := InventoryModel.new(registry, 8)
	var result: InventoryDataResult = InventoryDataCodec.decode_inventory(restored, encoded)
	assert_true.call(result.success, "inventory data round trip succeeds")
	assert_int_equal.call(restored.capacity, 8, "larger current capacity is preserved")
	assert_int_equal.call(restored.count_item(&"item_codec_branch"), 7, "branch total survives round trip")
	assert_int_equal.call(restored.count_item(&"item_codec_fiber"), 3, "fiber total survives round trip")
	assert_true.call(restored.slots[4].item_id == &"item_codec_branch", "slot position survives round trip")
	assert_true.call(restored.validate_invariants(), "restored inventory satisfies invariants")


static func _test_corrupt_inventory_is_atomic(
	registry: ContentRegistryService,
	assert_true: Callable,
	assert_int_equal: Callable
) -> void:
	var inventory := InventoryModel.new(registry, 4)
	inventory.add_item(&"item_codec_branch", 4)
	var original_total: int = inventory.count_item(&"item_codec_branch")
	var corrupt_data: Dictionary = {
		"schema_version": 1,
		"capacity": 1,
		"slots": [{"item_id": "item_missing", "quantity": 1}],
	}
	var unknown_result: InventoryDataResult = InventoryDataCodec.decode_inventory(
		inventory,
		corrupt_data
	)
	assert_true.call(not unknown_result.success, "unknown saved item is rejected")
	assert_true.call(
		unknown_result.reason_key == &"INVENTORY_DATA_UNKNOWN_ITEM",
		"unknown saved item returns a stable reason"
	)
	assert_int_equal.call(inventory.count_item(&"item_codec_branch"), original_total, "failed decode preserves inventory")
	corrupt_data["slots"] = [{"item_id": "item_codec_branch", "quantity": 6}]
	var overflow_result: InventoryDataResult = InventoryDataCodec.decode_inventory(
		inventory,
		corrupt_data
	)
	assert_true.call(not overflow_result.success, "saved stack overflow is rejected")
	assert_int_equal.call(inventory.count_item(&"item_codec_branch"), original_total, "overflow decode is atomic")


static func _test_hotbar_and_storage_round_trip(
	registry: ContentRegistryService,
	assert_true: Callable,
	assert_int_equal: Callable
) -> void:
	var inventory := InventoryModel.new(registry, 8)
	var hotbar := HotbarModel.new(inventory, 4)
	hotbar.assign(0, 3)
	hotbar.select(2)
	var hotbar_data: Dictionary = InventoryDataCodec.encode_hotbar(hotbar)
	var restored_hotbar := HotbarModel.new(inventory, 4)
	assert_true.call(
		InventoryDataCodec.decode_hotbar(restored_hotbar, hotbar_data).success,
		"hotbar data round trip succeeds"
	)
	assert_int_equal.call(restored_hotbar.assignments[0], 3, "hotbar assignment survives round trip")
	assert_int_equal.call(restored_hotbar.selected_index, 2, "hotbar selection survives round trip")
	var invalid_hotbar: Dictionary = hotbar_data.duplicate(true)
	invalid_hotbar["assignments"] = [99, 1, 2, 3]
	assert_true.call(
		not InventoryDataCodec.decode_hotbar(restored_hotbar, invalid_hotbar).success,
		"invalid hotbar assignment is rejected"
	)
	assert_int_equal.call(restored_hotbar.assignments[0], 3, "failed hotbar decode preserves assignments")

	var storage := StorageInventory.new(registry, &"storage_codec", 4)
	storage.add_item(&"item_codec_fiber", 2)
	var storage_data: Dictionary = InventoryDataCodec.encode_storage(storage)
	var restored_storage := StorageInventory.new(registry, &"storage_codec", 4)
	assert_true.call(
		InventoryDataCodec.decode_storage(restored_storage, storage_data).success,
		"storage data round trip succeeds"
	)
	assert_int_equal.call(restored_storage.count_item(&"item_codec_fiber"), 2, "storage item survives round trip")
	var wrong_storage := StorageInventory.new(registry, &"storage_other", 4)
	assert_true.call(
		not InventoryDataCodec.decode_storage(wrong_storage, storage_data).success,
		"storage ID mismatch is rejected"
	)


static func _make_registry() -> ContentRegistryService:
	var registry: ContentRegistryService = REGISTRY_SCRIPT.new()
	var branch := _make_item(&"item_codec_branch", 5)
	var fiber := _make_item(&"item_codec_fiber", 10)
	var definitions: Array[ItemDefinition] = [branch, fiber]
	registry.load_item_definitions(definitions)
	return registry


static func _make_item(item_id: StringName, max_stack: int) -> ItemDefinition:
	var definition := ItemDefinition.new()
	definition.id = item_id
	definition.name_key = &"ITEM_CODEC_NAME"
	definition.description_key = &"ITEM_CODEC_DESCRIPTION"
	definition.category = ItemDefinition.Category.MATERIAL
	definition.max_stack = max_stack
	return definition
