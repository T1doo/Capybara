class_name BedInteractable
extends InteractableComponent

signal rest_requested(rest_event_id: StringName)

@export var rest_event_id: StringName = &""


func _perform_interaction(_context: InteractionContext) -> InteractionResult:
	if rest_event_id.is_empty():
		return RESULT_SCRIPT.invalid(&"INTERACTION_INVALID_BED_DEFINITION")
	rest_requested.emit(rest_event_id)
	return RESULT_SCRIPT.succeeded(
		&"INTERACTION_REST_REQUESTED",
		{
			&"interaction_id": interaction_id,
			&"rest_event_id": rest_event_id,
		}
	)
