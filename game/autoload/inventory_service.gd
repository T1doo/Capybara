class_name InventoryCoordinator
extends Node

signal models_replaced

var content_registry: ContentRegistryService
var player_inventory: InventoryModel
var hotbar: HotbarModel
var storages: Dictionary[StringName, StorageInventory] = {}


func _ready() -> void:
	content_registry = get_node_or_null("/root/ContentRegistry") as ContentRegistryService
	if content_registry == null:
		push_error("InventoryService requires ContentRegistry")
		return
	player_inventory = InventoryModel.new(content_registry)
	hotbar = HotbarModel.new(player_inventory)


func create_storage(storage_id: StringName, capacity: int = 32) -> StorageInventory:
	if storage_id.is_empty() or storages.has(storage_id):
		return storages.get(storage_id) as StorageInventory
	var storage := StorageInventory.new(content_registry, storage_id, capacity)
	if not storage.has_valid_id():
		return null
	storages[storage_id] = storage
	return storage


func preflight_save_sections(
	inventories_data: Variant,
	hotbar_data: Variant,
	storages_data: Variant
) -> InventoryDataResult:
	# Use the same decoder and current capacity without replacing live models or
	# notifying UI consumers. The detached coordinator owns only staged models.
	var staging := InventoryCoordinator.new()
	staging.content_registry = content_registry
	staging.player_inventory = player_inventory
	var result: InventoryDataResult = staging.apply_save_sections(
		inventories_data, hotbar_data, storages_data
	)
	staging.free()
	return result


func apply_save_sections(
	inventories_data: Variant,
	hotbar_data: Variant,
	storages_data: Variant
) -> InventoryDataResult:
	if not inventories_data is Dictionary or not storages_data is Dictionary:
		return InventoryDataResult.failed(&"SAVE_RUNTIME_INVALID_INVENTORY_SECTIONS")
	var inventories := inventories_data as Dictionary
	var player_data: Variant = inventories.get("player")
	if not player_data is Dictionary:
		return InventoryDataResult.failed(&"SAVE_RUNTIME_MISSING_PLAYER_INVENTORY")
	var new_inventory := InventoryModel.new(content_registry, player_inventory.capacity)
	var inventory_result: InventoryDataResult = InventoryDataCodec.decode_inventory(
		new_inventory,
		player_data
	)
	if not inventory_result.success:
		return inventory_result
	if not hotbar_data is Dictionary:
		return InventoryDataResult.failed(&"SAVE_RUNTIME_INVALID_HOTBAR")
	var assignment_data: Variant = (hotbar_data as Dictionary).get("assignments")
	if not assignment_data is Array or assignment_data.is_empty():
		return InventoryDataResult.failed(&"SAVE_RUNTIME_INVALID_HOTBAR")
	var new_hotbar := HotbarModel.new(new_inventory, assignment_data.size())
	var hotbar_result: InventoryDataResult = InventoryDataCodec.decode_hotbar(
		new_hotbar,
		hotbar_data
	)
	if not hotbar_result.success:
		return hotbar_result
	var new_storages: Dictionary[StringName, StorageInventory] = {}
	for storage_id in storages_data:
		var storage_data: Variant = storages_data[storage_id]
		if not storage_data is Dictionary:
			return InventoryDataResult.failed(&"SAVE_RUNTIME_INVALID_STORAGE")
		var storage_inventory_data: Variant = (storage_data as Dictionary).get("inventory")
		if not storage_inventory_data is Dictionary:
			return InventoryDataResult.failed(&"SAVE_RUNTIME_INVALID_STORAGE")
		var saved_capacity: Variant = (storage_inventory_data as Dictionary).get("capacity")
		if not saved_capacity is int:
			return InventoryDataResult.failed(&"SAVE_RUNTIME_INVALID_STORAGE")
		var new_storage := StorageInventory.new(
			content_registry,
			StringName(storage_id),
			saved_capacity
		)
		var storage_result: InventoryDataResult = InventoryDataCodec.decode_storage(
			new_storage,
			storage_data
		)
		if not storage_result.success:
			return storage_result
		new_storages[StringName(storage_id)] = new_storage

	player_inventory = new_inventory
	hotbar = new_hotbar
	storages = new_storages
	models_replaced.emit()
	return InventoryDataResult.succeeded()
