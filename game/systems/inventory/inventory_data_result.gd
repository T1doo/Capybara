class_name InventoryDataResult
extends RefCounted

var success: bool = false
var reason_key: StringName = &""


static func succeeded() -> InventoryDataResult:
	var result := InventoryDataResult.new()
	result.success = true
	return result


static func failed(reason: StringName) -> InventoryDataResult:
	var result := InventoryDataResult.new()
	result.reason_key = reason
	return result
