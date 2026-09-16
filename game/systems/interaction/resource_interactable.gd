class_name ResourceInteractable
extends InteractableComponent

signal harvest_requested(resource_id: StringName, quantity: int)

@export var resource_id: StringName = &""
@export var required_tool_id: StringName = &""
@export_range(1, 999, 1) var yield_quantity: int = 1
@export_range(1, 99, 1) var remaining_uses: int = 3
var _pending_request: InteractionResult


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
	var request: InteractionResult = RESULT_SCRIPT.requested(
		&"INTERACTION_GATHER_SUCCESS",
		{
			&"interaction_id": interaction_id,
			&"resource_id": resource_id,
			&"quantity": yield_quantity,
			&"remaining_uses": remaining_uses,
			&"tool_id": context.equipped_tool_id,
			&"source_instance_id": get_instance_id(),
		}
	)
	_pending_request = request
	harvest_requested.emit(resource_id, yield_quantity)
	return request


func claim_request(request: InteractionResult, equipped_tool: StringName) -> bool:
	if request != _pending_request:
		return false
	_pending_request = null
	return (
		interaction_enabled and remaining_uses > 0
		and (required_tool_id.is_empty() or equipped_tool == required_tool_id)
		and request.payload.get(&"resource_id") == resource_id
		and request.payload.get(&"quantity") == yield_quantity
		and request.payload.get(&"remaining_uses") == remaining_uses
		and request.payload.get(&"source_instance_id") == get_instance_id()
	)


func invalidate_pending_request() -> void:
	if _pending_request != null:
		_pending_request.cancel()
	_pending_request = null


func commit_harvest(transferred: int) -> void:
	if transferred != yield_quantity or remaining_uses <= 0:
		return
	remaining_uses -= 1
	if remaining_uses == 0:
		interaction_enabled = false
