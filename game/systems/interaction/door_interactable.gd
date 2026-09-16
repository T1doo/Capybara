class_name DoorInteractable
extends InteractableComponent

signal transition_requested(destination_zone_id: StringName, destination_spawn_id: StringName)

@export var destination_zone_id: StringName = &""
@export var destination_spawn_id: StringName = &""
@export var is_locked: bool = false


func get_interaction_prompt(context: InteractionContext) -> StringName:
	if not super.can_interact(context):
		return unavailable_reason_key
	return &"INTERACTION_DOOR_LOCKED" if is_locked else &"INTERACTION_ENTER"


func _perform_interaction(_context: InteractionContext) -> InteractionResult:
	if destination_zone_id.is_empty() or destination_spawn_id.is_empty():
		return RESULT_SCRIPT.invalid(&"INTERACTION_INVALID_DOOR_DEFINITION")
	if is_locked:
		return RESULT_SCRIPT.blocked(&"INTERACTION_DOOR_LOCKED")

	transition_requested.emit(destination_zone_id, destination_spawn_id)
	return RESULT_SCRIPT.succeeded(
		&"INTERACTION_TRANSITION_REQUESTED",
		{
			&"interaction_id": interaction_id,
			&"destination_zone_id": destination_zone_id,
			&"destination_spawn_id": destination_spawn_id,
		}
	)
