class_name InteractionSensor
extends Area2D

signal current_target_changed(
	previous_target: InteractableComponent,
	current_target: InteractableComponent
)

const CONTEXT_SCRIPT: Script = preload("res://systems/interaction/interaction_context.gd")
const RESULT_SCRIPT: Script = preload("res://systems/interaction/interaction_result.gd")
const SELECTOR_SCRIPT: Script = preload("res://systems/interaction/interaction_selector.gd")

var candidates: Array[InteractableComponent] = []
var current_target: InteractableComponent
var context_actor: Node2D
var facing_direction: Vector2 = Vector2.DOWN
var active_task_id: StringName = &""
var equipped_tool_id: StringName = &""


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	context_actor = get_parent() as Node2D
	_refresh_selection()


func refresh_context(
	actor: Node2D,
	facing: Vector2,
	tool_id: StringName = &""
) -> void:
	context_actor = actor
	facing_direction = facing.normalized() if not facing.is_zero_approx() else Vector2.ZERO
	equipped_tool_id = tool_id
	_refresh_selection()


func set_active_task_id(task_id: StringName) -> void:
	active_task_id = task_id
	_refresh_selection()


func register_candidate(candidate: InteractableComponent) -> void:
	if not is_instance_valid(candidate) or candidate in candidates:
		return
	candidates.append(candidate)
	var exit_callable := Callable(self, &"_on_candidate_tree_exiting").bind(candidate)
	if candidate.is_inside_tree() and not candidate.tree_exiting.is_connected(exit_callable):
		candidate.tree_exiting.connect(exit_callable, CONNECT_ONE_SHOT)
	_refresh_selection()


func unregister_candidate(candidate: InteractableComponent) -> void:
	candidates.erase(candidate)
	_refresh_selection()


func get_current_target() -> InteractableComponent:
	_refresh_selection()
	return current_target if is_instance_valid(current_target) else null


func get_current_prompt() -> StringName:
	_refresh_selection()
	var context := _create_context()
	if not is_instance_valid(current_target) or context == null:
		return &""
	return current_target.get_interaction_prompt(context)


func interact_with_current() -> InteractionResult:
	_refresh_selection()
	var context := _create_context()
	if not is_instance_valid(current_target):
		return RESULT_SCRIPT.invalid(&"INTERACTION_NO_TARGET")
	if context == null:
		return RESULT_SCRIPT.invalid(&"INTERACTION_INVALID_CONTEXT")
	return current_target.interact(context)


func _refresh_selection() -> void:
	_prune_invalid_candidates()
	var context := _create_context()
	var next_target: InteractableComponent = null
	if context != null:
		next_target = SELECTOR_SCRIPT.select_best(context, candidates)
	_set_current_target(next_target)


func _create_context() -> InteractionContext:
	if not is_instance_valid(context_actor) or facing_direction.is_zero_approx():
		return null
	return CONTEXT_SCRIPT.new(
		context_actor,
		context_actor.global_position,
		facing_direction,
		active_task_id,
		equipped_tool_id
	)


func _prune_invalid_candidates() -> void:
	for index in range(candidates.size() - 1, -1, -1):
		if not is_instance_valid(candidates[index]):
			candidates.remove_at(index)


func _set_current_target(next_target: InteractableComponent) -> void:
	if not is_instance_valid(next_target):
		next_target = null
	if next_target == current_target:
		return
	var previous_target: InteractableComponent = (
		current_target if is_instance_valid(current_target) else null
	)
	current_target = next_target
	current_target_changed.emit(previous_target, current_target)


func _on_area_entered(area: Area2D) -> void:
	if area is InteractableComponent:
		register_candidate(area as InteractableComponent)


func _on_area_exited(area: Area2D) -> void:
	if area is InteractableComponent:
		unregister_candidate(area as InteractableComponent)


func _on_candidate_tree_exiting(candidate: InteractableComponent) -> void:
	unregister_candidate(candidate)
