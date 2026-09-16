class_name InteractionResult
extends RefCounted

enum Status {
	SUCCESS,
	BLOCKED,
	INVALID,
	REQUESTED,
}

var status: int = Status.INVALID
var message_key: StringName = &""
var reason_key: StringName = &""
var payload: Dictionary = {}
var resolved: bool = false


func is_success() -> bool:
	return status == Status.SUCCESS


func is_requested() -> bool:
	return status == Status.REQUESTED


func cancel() -> void:
	resolved = true


static func requested(message: StringName, request_payload: Dictionary) -> InteractionResult:
	return _create(Status.REQUESTED, message, &"", request_payload)


static func succeeded(
	success_message_key: StringName = &"",
	result_payload: Dictionary = {}
) -> InteractionResult:
	return _create(Status.SUCCESS, success_message_key, &"", result_payload)


static func blocked(block_reason_key: StringName) -> InteractionResult:
	return _create(Status.BLOCKED, &"", block_reason_key)


static func invalid(invalid_reason_key: StringName) -> InteractionResult:
	return _create(Status.INVALID, &"", invalid_reason_key)


static func _create(
	result_status: int,
	result_message_key: StringName,
	result_reason_key: StringName,
	result_payload: Dictionary = {}
) -> InteractionResult:
	var result := InteractionResult.new()
	result.status = result_status
	result.message_key = result_message_key
	result.reason_key = result_reason_key
	result.payload = result_payload.duplicate(true)
	return result
