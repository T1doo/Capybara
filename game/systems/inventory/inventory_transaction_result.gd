class_name InventoryTransactionResult
extends RefCounted

enum Status {
	SUCCESS,
	PARTIAL,
	REJECTED,
	INVALID,
}

var status: Status = Status.INVALID
var requested: int = 0
var transferred: int = 0
var remainder: int = 0
var reason_key: StringName = &""


func is_success() -> bool:
	return status == Status.SUCCESS


func made_progress() -> bool:
	return transferred > 0


static func create(
	result_status: Status,
	requested_quantity: int,
	transferred_quantity: int,
	reason: StringName = &""
) -> InventoryTransactionResult:
	var result := InventoryTransactionResult.new()
	result.status = result_status
	result.requested = requested_quantity
	result.transferred = transferred_quantity
	result.remainder = maxi(0, requested_quantity - transferred_quantity)
	result.reason_key = reason
	return result
