class_name ResourceInteractable
extends InteractableComponent

signal harvest_requested(resource_id: StringName, quantity: int)

@export var resource_id: StringName = &""
@export var required_tool_id: StringName = &""
@export_range(1, 999, 1) var yield_quantity: int = 1
@export_range(1, 99, 1) var remaining_uses: int = 3


func can_interact(context: InteractionContext) -> bool:
	return (
		super.can_interact(context)
		and not resource_id.is_empty()
		and yield_quantity > 0
		and remaining_uses > 0
	)


func _perform_interaction(context: InteractionContext) -> InteractionResult:
	if resource_id.is_empty() or yield_quantity <= 0:
		return RESULT_SCRIPT.invalid(&"INTERACTION_INVALID_RESOURCE_DEFINITION")
	if remaining_uses <= 0:
		interaction_enabled = false
		return RESULT_SCRIPT.blocked(&"INTERACTION_RESOURCE_DEPLETED")
	if not required_tool_id.is_empty() and context.equipped_tool_id != required_tool_id:
		return RESULT_SCRIPT.blocked(&"INTERACTION_REQUIRES_TOOL")
	harvest_requested.emit(resource_id, yield_quantity)
	return RESULT_SCRIPT.succeeded(
		&"INTERACTION_GATHER_SUCCESS",
		{
			&"interaction_id": interaction_id,
			&"resource_id": resource_id,
			&"quantity": yield_quantity,
			&"remaining_uses": remaining_uses,
			&"tool_id": context.equipped_tool_id,
		}
	)


func commit_harvest(transferred: int) -> void:
	if transferred <= 0 or remaining_uses <= 0:
		return
	remaining_uses -= 1
	if remaining_uses == 0:
		interaction_enabled = false
