class_name InventoryModel
extends RefCounted

signal changed
signal slots_reordered(previous_slots: Array[InventorySlot])
signal slots_moved(source_index: int, target_index: int, emptied_source: bool, swapped: bool)

const DEFAULT_CAPACITY: int = 24

var capacity: int
var slots: Array[InventorySlot] = []
var registry: ContentRegistryService


func _init(content_registry: ContentRegistryService, slot_capacity: int = DEFAULT_CAPACITY) -> void:
	registry = content_registry
	capacity = maxi(1, slot_capacity)
	for _index in range(capacity):
		slots.append(InventorySlot.new())


func add_item(
	item_id: StringName,
	quantity: int,
	simulate: bool = false
) -> InventoryTransactionResult:
	var validation_result := _validate_transaction(item_id, quantity)
	if validation_result != null:
		return validation_result
	var working_slots: Array[InventorySlot] = _copy_slots()
	var definition: ItemDefinition = registry.get_item(item_id)
	var remaining: int = quantity
	for slot in working_slots:
		if slot.item_id == item_id and slot.quantity < definition.max_stack:
			var added: int = mini(remaining, definition.max_stack - slot.quantity)
			slot.quantity += added
			remaining -= added
			if remaining == 0:
				break
	for slot in working_slots:
		if remaining == 0:
			break
		if slot.is_empty():
			var added: int = mini(remaining, definition.max_stack)
			slot.item_id = item_id
			slot.quantity = added
			remaining -= added
	var transferred: int = quantity - remaining
	if transferred > 0 and not simulate:
		_commit_slots(working_slots)
	return _make_transfer_result(quantity, transferred, &"INVENTORY_FULL")


func remove_item(
	item_id: StringName,
	quantity: int,
	simulate: bool = false
) -> InventoryTransactionResult:
	var validation_result := _validate_transaction(item_id, quantity)
	if validation_result != null:
		return validation_result
	var working_slots: Array[InventorySlot] = _copy_slots()
	var remaining: int = quantity
	for slot in working_slots:
		if slot.item_id != item_id:
			continue
		var removed: int = mini(remaining, slot.quantity)
		slot.quantity -= removed
		remaining -= removed
		if slot.quantity == 0:
			slot.clear()
		if remaining == 0:
			break
	var transferred: int = quantity - remaining
	if transferred > 0 and not simulate:
		_commit_slots(working_slots)
	return _make_transfer_result(quantity, transferred, &"INVENTORY_NOT_ENOUGH_ITEMS")


func remove_item_exact(
	item_id: StringName,
	quantity: int,
	simulate: bool = false
) -> InventoryTransactionResult:
	var validation_result := _validate_transaction(item_id, quantity)
	if validation_result != null:
		return validation_result
	if count_item(item_id) < quantity:
		return InventoryTransactionResult.create(
			InventoryTransactionResult.Status.REJECTED,
			quantity,
			0,
			&"INVENTORY_NOT_ENOUGH_ITEMS"
		)
	return remove_item(item_id, quantity, simulate)


func split_stack(source_index: int, quantity: int, target_index: int = -1) -> bool:
	if not _is_valid_slot_index(source_index) or quantity <= 0:
		return false
	var source: InventorySlot = slots[source_index]
	if source.is_empty() or quantity >= source.quantity:
		return false
	if target_index < 0:
		target_index = _find_empty_slot(source_index)
	if not _is_valid_slot_index(target_index) or not slots[target_index].is_empty():
		return false
	slots[target_index].item_id = source.item_id
	slots[target_index].quantity = quantity
	source.quantity -= quantity
	changed.emit()
	return true


func move_or_merge(source_index: int, target_index: int, quantity: int = -1) -> bool:
	if (
		not _is_valid_slot_index(source_index)
		or not _is_valid_slot_index(target_index)
		or source_index == target_index
	):
		return false
	var source: InventorySlot = slots[source_index]
	var target: InventorySlot = slots[target_index]
	if source.is_empty():
		return false
	var move_quantity: int = source.quantity if quantity < 0 else mini(quantity, source.quantity)
	if move_quantity <= 0:
		return false
	var swapped: bool = not target.is_empty() and target.item_id != source.item_id
	if target.is_empty():
		target.item_id = source.item_id
		target.quantity = move_quantity
		source.quantity -= move_quantity
		if source.quantity == 0:
			source.clear()
	elif target.item_id == source.item_id:
		var definition: ItemDefinition = registry.get_item(source.item_id)
		var merged: int = mini(move_quantity, definition.max_stack - target.quantity)
		if merged <= 0:
			return false
		target.quantity += merged
		source.quantity -= merged
		if source.quantity == 0:
			source.clear()
	elif move_quantity == source.quantity:
		var target_copy: InventorySlot = target.copy()
		target.item_id = source.item_id
		target.quantity = source.quantity
		source.item_id = target_copy.item_id
		source.quantity = target_copy.quantity
	else:
		return false
	slots_moved.emit(source_index, target_index, source.is_empty(), swapped)
	changed.emit()
	return true


func discard_from_slot(slot_index: int, quantity: int) -> InventoryTransactionResult:
	if not _is_valid_slot_index(slot_index) or quantity <= 0 or slots[slot_index].is_empty():
		return InventoryTransactionResult.create(
			InventoryTransactionResult.Status.INVALID,
			quantity,
			0,
			&"INVENTORY_INVALID_DISCARD"
		)
	var slot: InventorySlot = slots[slot_index]
	var definition: ItemDefinition = registry.get_item(slot.item_id)
	if definition.category == ItemDefinition.Category.QUEST or definition.has_tag(&"quest_item"):
		return InventoryTransactionResult.create(
			InventoryTransactionResult.Status.REJECTED,
			quantity,
			0,
			&"INVENTORY_QUEST_ITEM_LOCKED"
		)
	var discarded: int = mini(quantity, slot.quantity)
	slot.quantity -= discarded
	if slot.quantity == 0:
		slot.clear()
	changed.emit()
	return _make_transfer_result(quantity, discarded, &"INVENTORY_NOT_ENOUGH_ITEMS")


func take_from_slot(
	slot_index: int,
	quantity: int,
	simulate: bool = false
) -> InventoryTransactionResult:
	if not _is_valid_slot_index(slot_index) or quantity <= 0 or slots[slot_index].is_empty():
		return InventoryTransactionResult.create(
			InventoryTransactionResult.Status.INVALID,
			quantity,
			0,
			&"INVENTORY_INVALID_SLOT_TRANSFER"
		)
	var available: int = slots[slot_index].quantity
	var transferred: int = mini(quantity, available)
	if not simulate:
		slots[slot_index].quantity -= transferred
		if slots[slot_index].quantity == 0:
			slots[slot_index].clear()
		changed.emit()
	return _make_transfer_result(quantity, transferred, &"INVENTORY_NOT_ENOUGH_ITEMS")


func sort_and_compact() -> void:
	var totals: Dictionary[StringName, int] = {}
	for slot in slots:
		if not slot.is_empty():
			totals[slot.item_id] = totals.get(slot.item_id, 0) + slot.quantity
	var item_ids: Array[StringName] = []
	for item_id in totals:
		item_ids.append(item_id)
	item_ids.sort_custom(func(first: StringName, second: StringName) -> bool:
		var first_definition: ItemDefinition = registry.get_item(first)
		var second_definition: ItemDefinition = registry.get_item(second)
		if first_definition.category != second_definition.category:
			return first_definition.category < second_definition.category
		return String(first) < String(second)
	)
	var sorted_slots: Array[InventorySlot] = []
	for item_id in item_ids:
		var definition: ItemDefinition = registry.get_item(item_id)
		var remaining: int = totals[item_id]
		while remaining > 0:
			var stack_quantity: int = mini(remaining, definition.max_stack)
			sorted_slots.append(InventorySlot.new(item_id, stack_quantity))
			remaining -= stack_quantity
	while sorted_slots.size() < capacity:
		sorted_slots.append(InventorySlot.new())
	var previous_slots: Array[InventorySlot] = slots
	slots = sorted_slots
	slots_reordered.emit(previous_slots)
	changed.emit()


func count_item(item_id: StringName) -> int:
	var total: int = 0
	for slot in slots:
		if slot.item_id == item_id:
			total += slot.quantity
	return total


func get_occupied_slot_count() -> int:
	var occupied: int = 0
	for slot in slots:
		if not slot.is_empty():
			occupied += 1
	return occupied


func validate_invariants() -> bool:
	if slots.size() != capacity or registry == null:
		return false
	for slot in slots:
		if slot == null:
			return false
		if slot.is_empty():
			continue
		if slot.item_id.is_empty() or slot.quantity <= 0 or not registry.has_item(slot.item_id):
			return false
		if slot.quantity > registry.get_item(slot.item_id).max_stack:
			return false
	return true


func create_snapshot() -> Array[InventorySlot]:
	return _copy_slots()


func restore_snapshot(snapshot: Array[InventorySlot], emit_change: bool = true) -> bool:
	if snapshot.size() != capacity:
		return false
	var restored_slots: Array[InventorySlot] = []
	for slot in snapshot:
		if slot == null:
			return false
		restored_slots.append(slot.copy())
	var previous_slots: Array[InventorySlot] = slots
	slots = restored_slots
	if not validate_invariants():
		slots = previous_slots
		return false
	if emit_change:
		changed.emit()
	return true


func notify_changed() -> void:
	changed.emit()


func _validate_transaction(
	item_id: StringName,
	quantity: int
) -> InventoryTransactionResult:
	if quantity <= 0:
		return InventoryTransactionResult.create(
			InventoryTransactionResult.Status.INVALID,
			quantity,
			0,
			&"INVENTORY_INVALID_QUANTITY"
		)
	if registry == null or not registry.has_item(item_id):
		return InventoryTransactionResult.create(
			InventoryTransactionResult.Status.INVALID,
			quantity,
			0,
			&"INVENTORY_UNKNOWN_ITEM"
		)
	return null


func _make_transfer_result(
	requested: int,
	transferred: int,
	partial_reason: StringName
) -> InventoryTransactionResult:
	var status := InventoryTransactionResult.Status.REJECTED
	var reason: StringName = partial_reason
	if transferred == requested:
		status = InventoryTransactionResult.Status.SUCCESS
		reason = &""
	elif transferred > 0:
		status = InventoryTransactionResult.Status.PARTIAL
	return InventoryTransactionResult.create(status, requested, transferred, reason)


func _copy_slots() -> Array[InventorySlot]:
	var copied_slots: Array[InventorySlot] = []
	for slot in slots:
		copied_slots.append(slot.copy())
	return copied_slots


func _commit_slots(new_slots: Array[InventorySlot]) -> void:
	slots = new_slots
	changed.emit()


func _find_empty_slot(excluded_index: int = -1) -> int:
	for index in range(slots.size()):
		if index != excluded_index and slots[index].is_empty():
			return index
	return -1


func _is_valid_slot_index(index: int) -> bool:
	return index >= 0 and index < slots.size()
