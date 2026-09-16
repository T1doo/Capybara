class_name ChestInteractable
extends InteractableComponent

signal storage_toggle_requested(storage_id: StringName, is_open: bool)

@export var storage_id: StringName = &""

var is_open: bool = false


func get_interaction_prompt(context: InteractionContext) -> StringName:
	if not can_interact(context):
		return unavailable_reason_key
	return &"INTERACTION_CLOSE" if is_open else &"INTERACTION_OPEN"


func _perform_interaction(_context: InteractionContext) -> InteractionResult:
	if storage_id.is_empty():
		return RESULT_SCRIPT.invalid(&"INTERACTION_INVALID_STORAGE_DEFINITION")

	is_open = not is_open
	storage_toggle_requested.emit(storage_id, is_open)
	return RESULT_SCRIPT.succeeded(
		&"INTERACTION_STORAGE_OPENED" if is_open else &"INTERACTION_STORAGE_CLOSED",
		{
			&"interaction_id": interaction_id,
			&"storage_id": storage_id,
			&"is_open": is_open,
		}
	)
