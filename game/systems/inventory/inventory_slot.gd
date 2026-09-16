class_name InventorySlot
extends RefCounted

var item_id: StringName = &""
var quantity: int = 0


func _init(initial_item_id: StringName = &"", initial_quantity: int = 0) -> void:
	item_id = initial_item_id
	quantity = initial_quantity
	if quantity <= 0:
		clear()


func is_empty() -> bool:
	return item_id.is_empty() and quantity == 0


func clear() -> void:
	item_id = &""
	quantity = 0


func copy() -> InventorySlot:
	return InventorySlot.new(item_id, quantity)
