class_name InventoryDataCodec
extends RefCounted

const SCHEMA_VERSION: int = 1


static func encode_inventory(inventory: InventoryModel) -> Dictionary:
	var slot_data: Array[Dictionary] = []
	for slot in inventory.slots:
		if slot.is_empty():
			slot_data.append({})
		else:
			slot_data.append({
				"item_id": String(slot.item_id),
				"quantity": slot.quantity,
			})
	return {
		"schema_version": SCHEMA_VERSION,
		"capacity": inventory.capacity,
		"slots": slot_data,
	}


static func decode_inventory(inventory: InventoryModel, data: Variant) -> InventoryDataResult:
	if not data is Dictionary:
		return InventoryDataResult.failed(&"INVENTORY_DATA_NOT_DICTIONARY")
	var dictionary := data as Dictionary
	if dictionary.get("schema_version", 0) != SCHEMA_VERSION:
		return InventoryDataResult.failed(&"INVENTORY_DATA_UNSUPPORTED_SCHEMA")
	var saved_capacity: Variant = dictionary.get("capacity")
	var slot_data: Variant = dictionary.get("slots")
	if not saved_capacity is int or saved_capacity < 1 or saved_capacity > inventory.capacity:
		return InventoryDataResult.failed(&"INVENTORY_DATA_INVALID_CAPACITY")
	if not slot_data is Array or slot_data.size() != saved_capacity:
		return InventoryDataResult.failed(&"INVENTORY_DATA_INVALID_SLOTS")
	var decoded_slots: Array[InventorySlot] = []
	for entry in slot_data:
		var decoded_slot_result: Array = _decode_slot(inventory.registry, entry)
		if not decoded_slot_result[0]:
			return InventoryDataResult.failed(decoded_slot_result[1])
		decoded_slots.append(decoded_slot_result[2])
	while decoded_slots.size() < inventory.capacity:
		decoded_slots.append(InventorySlot.new())
	if not inventory.restore_snapshot(decoded_slots):
		return InventoryDataResult.failed(&"INVENTORY_DATA_RESTORE_FAILED")
	return InventoryDataResult.succeeded()


static func encode_hotbar(hotbar: HotbarModel) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"assignments": hotbar.assignments.duplicate(),
		"selected_index": hotbar.selected_index,
	}


static func decode_hotbar(hotbar: HotbarModel, data: Variant) -> InventoryDataResult:
	if not data is Dictionary:
		return InventoryDataResult.failed(&"HOTBAR_DATA_NOT_DICTIONARY")
	var dictionary := data as Dictionary
	if dictionary.get("schema_version", 0) != SCHEMA_VERSION:
		return InventoryDataResult.failed(&"HOTBAR_DATA_UNSUPPORTED_SCHEMA")
	var assignments_data: Variant = dictionary.get("assignments")
	var selected_data: Variant = dictionary.get("selected_index")
	if not assignments_data is Array or assignments_data.size() != hotbar.assignments.size():
		return InventoryDataResult.failed(&"HOTBAR_DATA_INVALID_ASSIGNMENTS")
	if not selected_data is int or selected_data < 0 or selected_data >= hotbar.assignments.size():
		return InventoryDataResult.failed(&"HOTBAR_DATA_INVALID_SELECTION")
	var decoded_assignments: Array[int] = []
	for assignment in assignments_data:
		if not assignment is int or assignment < -1:
			return InventoryDataResult.failed(&"HOTBAR_DATA_INVALID_ASSIGNMENT")
		if assignment >= 0 and (
			hotbar.inventory == null or assignment >= hotbar.inventory.capacity
		):
			return InventoryDataResult.failed(&"HOTBAR_DATA_INVALID_ASSIGNMENT")
		decoded_assignments.append(assignment)
	hotbar.assignments = decoded_assignments
	hotbar.selected_index = selected_data
	hotbar.assignment_changed.emit(-1, -1)
	hotbar.selection_changed.emit(selected_data, selected_data)
	return InventoryDataResult.succeeded()


static func encode_storage(storage: StorageInventory) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"storage_id": String(storage.storage_id),
		"inventory": encode_inventory(storage),
	}


static func decode_storage(storage: StorageInventory, data: Variant) -> InventoryDataResult:
	if not data is Dictionary:
		return InventoryDataResult.failed(&"STORAGE_DATA_NOT_DICTIONARY")
	var dictionary := data as Dictionary
	if dictionary.get("schema_version", 0) != SCHEMA_VERSION:
		return InventoryDataResult.failed(&"STORAGE_DATA_UNSUPPORTED_SCHEMA")
	if StringName(dictionary.get("storage_id", "")) != storage.storage_id:
		return InventoryDataResult.failed(&"STORAGE_DATA_ID_MISMATCH")
	return decode_inventory(storage, dictionary.get("inventory"))


static func _decode_slot(
	registry: ContentRegistryService,
	entry: Variant
) -> Array:
	if not entry is Dictionary:
		return [false, &"INVENTORY_DATA_INVALID_SLOT", null]
	var slot_dictionary := entry as Dictionary
	if slot_dictionary.is_empty():
		return [true, &"", InventorySlot.new()]
	var item_id_value: Variant = slot_dictionary.get("item_id")
	var quantity_value: Variant = slot_dictionary.get("quantity")
	if not item_id_value is String and not item_id_value is StringName:
		return [false, &"INVENTORY_DATA_INVALID_ITEM_ID", null]
	var item_id := StringName(item_id_value)
	if item_id.is_empty() or registry == null or not registry.has_item(item_id):
		return [false, &"INVENTORY_DATA_UNKNOWN_ITEM", null]
	if not quantity_value is int or quantity_value <= 0:
		return [false, &"INVENTORY_DATA_INVALID_QUANTITY", null]
	if quantity_value > registry.get_item(item_id).max_stack:
		return [false, &"INVENTORY_DATA_STACK_OVERFLOW", null]
	return [true, &"", InventorySlot.new(item_id, quantity_value)]
