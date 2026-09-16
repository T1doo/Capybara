class_name InteractableComponent
extends Area2D

const RESULT_SCRIPT: Script = preload("res://systems/interaction/interaction_result.gd")

enum Priority {
	GROUND = 0,
	BUILDABLE = 100,
	PICKUP = 200,
	NPC = 300,
	TASK = 400,
}

@export var interaction_id: StringName = &""
@export var task_id: StringName = &""
@export var prompt_key: StringName = &"INTERACTION_USE"
@export var unavailable_reason_key: StringName = &"INTERACTION_UNAVAILABLE"
@export var interaction_priority: int = Priority.GROUND
@export var interaction_enabled: bool = true


func can_interact(context: InteractionContext) -> bool:
	return (
		interaction_enabled
		and not interaction_id.is_empty()
		and context != null
		and context.is_valid()
	)


func get_interaction_prompt(context: InteractionContext) -> StringName:
	if can_interact(context):
		return prompt_key
	return unavailable_reason_key


func get_interaction_position() -> Vector2:
	return global_position


func interact(context: InteractionContext) -> InteractionResult:
	if context == null or not context.is_valid():
		return RESULT_SCRIPT.invalid(&"INTERACTION_INVALID_CONTEXT")
	if interaction_id.is_empty():
		return RESULT_SCRIPT.invalid(&"INTERACTION_INVALID_ID")
	if not interaction_enabled:
		return RESULT_SCRIPT.blocked(unavailable_reason_key)
	return _perform_interaction(context)


func _perform_interaction(_context: InteractionContext) -> InteractionResult:
	return RESULT_SCRIPT.blocked(&"INTERACTION_NOT_IMPLEMENTED")
