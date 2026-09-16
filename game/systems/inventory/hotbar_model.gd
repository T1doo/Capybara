class_name HotbarModel
extends RefCounted

signal selection_changed(previous_index: int, current_index: int)
signal assignment_changed(hotbar_index: int, inventory_slot_index: int)

const DEFAULT_SIZE: int = 8

var inventory: InventoryModel
var assignments: Array[int] = []
var selected_index: int = 0


func _init(source_inventory: InventoryModel, hotbar_size: int = DEFAULT_SIZE) -> void:
	inventory = source_inventory
	var size: int = maxi(1, hotbar_size)
	for index in range(size):
		assignments.append(index if inventory != null and index < inventory.capacity else -1)


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
