class_name InventoryTransferService
extends RefCounted


static func transfer_slot(
	source: InventoryModel,
	destination: InventoryModel,
	source_slot_index: int,
	quantity: int = -1,
	allow_partial: bool = true
) -> InventoryTransactionResult:
	if source == null or destination == null or source == destination:
		return _invalid(&"INVENTORY_INVALID_TRANSFER_TARGET")
	if source_slot_index < 0 or source_slot_index >= source.slots.size():
		return _invalid(&"INVENTORY_INVALID_SLOT_TRANSFER")
	var source_slot: InventorySlot = source.slots[source_slot_index]
	if source_slot.is_empty():
		return _invalid(&"INVENTORY_INVALID_SLOT_TRANSFER")
	var requested: int = source_slot.quantity if quantity < 0 else quantity
	if requested <= 0:
		return _invalid(&"INVENTORY_INVALID_QUANTITY")
	var available: int = mini(requested, source_slot.quantity)
	var transfer_item_id: StringName = source_slot.item_id
	if not allow_partial and available < requested:
		return InventoryTransactionResult.create(
			InventoryTransactionResult.Status.REJECTED,
			requested,
			0,
			&"INVENTORY_NOT_ENOUGH_ITEMS"
		)
	var destination_plan: InventoryTransactionResult = destination.add_item(
		source_slot.item_id,
		available,
		true
	)
	var transferable: int = mini(available, destination_plan.transferred)
	if not allow_partial and transferable < requested:
		return InventoryTransactionResult.create(
			InventoryTransactionResult.Status.REJECTED,
			requested,
			0,
			&"INVENTORY_DESTINATION_FULL"
		)
	if transferable <= 0:
		return InventoryTransactionResult.create(
			InventoryTransactionResult.Status.REJECTED,
			requested,
			0,
			&"INVENTORY_DESTINATION_FULL"
		)

	var source_snapshot: Array[InventorySlot] = source.create_snapshot()
	var destination_snapshot: Array[InventorySlot] = destination.create_snapshot()
	var source_work := InventoryModel.new(source.registry, source.capacity)
	var destination_work := InventoryModel.new(destination.registry, destination.capacity)
	if (
		not source_work.restore_snapshot(source_snapshot, false)
		or not destination_work.restore_snapshot(destination_snapshot, false)
	):
		return _rolled_back(requested)
	var source_result: InventoryTransactionResult = source_work.take_from_slot(
		source_slot_index,
		transferable
	)
	var destination_result: InventoryTransactionResult = destination_work.add_item(
		transfer_item_id,
		transferable
	)
	if (
		source_result.transferred != transferable
		or destination_result.transferred != transferable
		or not source_work.validate_invariants()
		or not destination_work.validate_invariants()
	):
		return _rolled_back(requested)
	if not source.restore_snapshot(source_work.create_snapshot(), false):
		return _rolled_back(requested)
	if not destination.restore_snapshot(destination_work.create_snapshot(), false):
		source.restore_snapshot(source_snapshot, false)
		return _rolled_back(requested)
	source.notify_changed()
	destination.notify_changed()
	var status := (
		InventoryTransactionResult.Status.SUCCESS
		if transferable == requested
		else InventoryTransactionResult.Status.PARTIAL
	)
	return InventoryTransactionResult.create(status, requested, transferable)


static func _invalid(reason_key: StringName) -> InventoryTransactionResult:
	return InventoryTransactionResult.create(
		InventoryTransactionResult.Status.INVALID,
		0,
		0,
		reason_key
	)


static func _rolled_back(requested: int) -> InventoryTransactionResult:
	return InventoryTransactionResult.create(
		InventoryTransactionResult.Status.REJECTED,
		requested,
		0,
		&"INVENTORY_TRANSFER_ROLLED_BACK"
	)
