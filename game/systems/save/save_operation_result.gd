class_name SaveOperationResult
extends RefCounted

var success: bool = false
var reason_key: StringName = &""
var data: Dictionary = {}
var recovered_from_backup: bool = false
var source_path: String = ""


static func succeeded(
	result_data: Dictionary = {},
	source: String = "",
	recovered: bool = false
) -> SaveOperationResult:
	var result := SaveOperationResult.new()
	result.success = true
	result.data = result_data
	result.source_path = source
	result.recovered_from_backup = recovered
	return result


static func failed(reason: StringName) -> SaveOperationResult:
	var result := SaveOperationResult.new()
	result.reason_key = reason
	return result
