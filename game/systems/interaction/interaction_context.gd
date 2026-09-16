class_name InteractionContext
extends RefCounted

var actor: Node2D
var actor_position: Vector2
var facing_direction: Vector2
var active_task_id: StringName
var equipped_tool_id: StringName


func _init(
	actor_node: Node2D = null,
	position: Vector2 = Vector2.ZERO,
	facing: Vector2 = Vector2.DOWN,
	task_id: StringName = &"",
	tool_id: StringName = &""
) -> void:
	actor = actor_node
	actor_position = position
	facing_direction = facing.normalized() if not facing.is_zero_approx() else Vector2.ZERO
	active_task_id = task_id
	equipped_tool_id = tool_id


func is_valid() -> bool:
	return is_instance_valid(actor) and not facing_direction.is_zero_approx()
