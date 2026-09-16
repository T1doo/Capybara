class_name HotbarModel
extends RefCounted

signal selection_changed(previous_index: int, current_index: int)
signal assignment_changed(hotbar_index: int, inventory_slot_index: int)

const DEFAULT_SIZE: int = 8

var inventory: InventoryModel
var assignments: Array[int] = []
var selected_index: int = 0
var _previously_occupied: Array[bool] = []


func _init(source_inventory: InventoryModel, hotbar_size: int = DEFAULT_SIZE) -> void:
	inventory = source_inventory
	var size: int = maxi(1, hotbar_size)
	for index in range(size):
		assignments.append(index if inventory != null and index < inventory.capacity else -1)
	if inventory != null:
		_remember_occupied_slots()
		inventory.slots_reordered.connect(_on_slots_reordered)
		inventory.slots_moved.connect(_on_slots_moved)
		inventory.changed.connect(_on_inventory_changed)


func select(index: int) -> bool:
	if index < 0 or index >= assignments.size():
		return false
	if selected_index == index:
		return true
	var previous_index: int = selected_index
	selected_index = index
	selection_changed.emit(previous_index, selected_index)
	return true


func select_offset(offset: int) -> int:
	if assignments.is_empty():
		return -1
	var next_index: int = posmod(selected_index + offset, assignments.size())
	select(next_index)
	return selected_index


func assign(hotbar_index: int, inventory_slot_index: int) -> bool:
	if hotbar_index < 0 or hotbar_index >= assignments.size():
		return false
	if inventory_slot_index < -1:
		return false
	if inventory_slot_index >= 0 and (
		inventory == null or inventory_slot_index >= inventory.capacity
	):
		return false
	assignments[hotbar_index] = inventory_slot_index
	assignment_changed.emit(hotbar_index, inventory_slot_index)
	return true


func get_selected_slot() -> InventorySlot:
	if inventory == null or selected_index < 0 or selected_index >= assignments.size():
		return null
	var inventory_slot_index: int = assignments[selected_index]
	if inventory_slot_index < 0 or inventory_slot_index >= inventory.slots.size():
		return null
	return inventory.slots[inventory_slot_index]


func get_selected_item_id() -> StringName:
	var selected_slot: InventorySlot = get_selected_slot()
	return selected_slot.item_id if selected_slot != null else &""


func _on_slots_reordered(previous_slots: Array[InventorySlot]) -> void:
	# Compaction merges stack identity: every old alias follows the first output
	# stack of that item. Empty positional placeholders become unassigned.
	for index in range(assignments.size()):
		var old_index: int = assignments[index]
		if old_index < 0:
			continue
		var next_index: int = -1
		if old_index < previous_slots.size() and not previous_slots[old_index].is_empty():
			for candidate in range(inventory.slots.size()):
				if inventory.slots[candidate].item_id == previous_slots[old_index].item_id:
					next_index = candidate
					break
		assignments[index] = next_index
	_remember_occupied_slots()
	assignment_changed.emit(-1, -1)


func _on_slots_moved(source: int, target: int, emptied_source: bool, swapped: bool) -> void:
	if not emptied_source and not swapped:
		return
	for index in range(assignments.size()):
		if assignments[index] == source:
			assignments[index] = target
		elif swapped and assignments[index] == target:
			assignments[index] = source
	_remember_occupied_slots()
	assignment_changed.emit(-1, -1)


func _on_inventory_changed() -> void:
	# A consumed/transferred-away stack clears its aliases, so another item
	# entering that slot cannot silently become equipped. Initial empty slot
	# placeholders keep the existing auto-assignment behavior until first filled.
	var updated: bool = false
	for index in range(assignments.size()):
		var slot_index: int = assignments[index]
		if slot_index >= 0 and _previously_occupied[slot_index] and inventory.slots[slot_index].is_empty():
			assignments[index] = -1
			updated = true
	_remember_occupied_slots()
	if updated:
		assignment_changed.emit(-1, -1)


func _remember_occupied_slots() -> void:
	_previously_occupied.clear()
	for slot in inventory.slots:
		_previously_occupied.append(not slot.is_empty())
