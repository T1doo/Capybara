class_name NpcInteractable
extends InteractableComponent

signal conversation_requested(npc_id: StringName, conversation_id: StringName)

@export var npc_id: StringName = &""
@export var conversation_id: StringName = &""


func _perform_interaction(_context: InteractionContext) -> InteractionResult:
	if npc_id.is_empty() or conversation_id.is_empty():
		return RESULT_SCRIPT.invalid(&"INTERACTION_INVALID_NPC_DEFINITION")

	conversation_requested.emit(npc_id, conversation_id)
	return RESULT_SCRIPT.succeeded(
		&"INTERACTION_CONVERSATION_REQUESTED",
		{
			&"interaction_id": interaction_id,
			&"npc_id": npc_id,
			&"conversation_id": conversation_id,
		}
	)
