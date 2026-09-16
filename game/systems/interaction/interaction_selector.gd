class_name InteractionSelector
extends RefCounted


static func select_best(
	context: InteractionContext,
	candidates: Array[InteractableComponent]
) -> InteractableComponent:
	var sorted_candidates := sort_candidates(context, candidates)
	if sorted_candidates.is_empty():
		return null
	return sorted_candidates[0]


static func sort_candidates(
	context: InteractionContext,
	candidates: Array[InteractableComponent]
) -> Array[InteractableComponent]:
	var valid_candidates: Array[InteractableComponent] = []
	for candidate in candidates:
		if is_instance_valid(candidate) and candidate.can_interact(context):
			valid_candidates.append(candidate)

	valid_candidates.sort_custom(func(first: InteractableComponent, second: InteractableComponent) -> bool:
		return _comes_before(context, first, second)
	)
	return valid_candidates


static func _comes_before(
	context: InteractionContext,
	first: InteractableComponent,
	second: InteractableComponent
) -> bool:
	var first_task_match := _matches_active_task(context, first)
	var second_task_match := _matches_active_task(context, second)
	if first_task_match != second_task_match:
		return first_task_match

	if first.interaction_priority != second.interaction_priority:
		return first.interaction_priority > second.interaction_priority

	var first_facing_score := _facing_score(context, first)
	var second_facing_score := _facing_score(context, second)
	if not is_equal_approx(first_facing_score, second_facing_score):
		return first_facing_score > second_facing_score

	var first_distance := context.actor_position.distance_squared_to(
		first.get_interaction_position()
	)
	var second_distance := context.actor_position.distance_squared_to(
		second.get_interaction_position()
	)
	if not is_equal_approx(first_distance, second_distance):
		return first_distance < second_distance

	return String(first.interaction_id) < String(second.interaction_id)


static func _matches_active_task(
	context: InteractionContext,
	interactable: InteractableComponent
) -> bool:
	return (
		not context.active_task_id.is_empty()
		and interactable.task_id == context.active_task_id
	)


static func _facing_score(
	context: InteractionContext,
	interactable: InteractableComponent
) -> float:
	var offset := interactable.get_interaction_position() - context.actor_position
	if offset.is_zero_approx():
		return 1.0
	return context.facing_direction.dot(offset.normalized())
