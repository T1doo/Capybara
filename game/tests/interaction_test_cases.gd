class_name InteractionTestCases
extends RefCounted

const INTERACTABLE_COMPONENT_SCRIPT: Script = preload("res://systems/interaction/interactable_component.gd")
const INTERACTION_CONTEXT_SCRIPT: Script = preload("res://systems/interaction/interaction_context.gd")
const INTERACTION_SENSOR_SCRIPT: Script = preload("res://systems/interaction/interaction_sensor.gd")
const INTERACTION_SELECTOR_SCRIPT: Script = preload("res://systems/interaction/interaction_selector.gd")


static func run(
	assert_true: Callable,
	assert_int_equal: Callable,
	assert_float_approx: Callable
) -> void:
	_test_typed_protocol(assert_true, assert_int_equal, assert_float_approx)
	_test_deterministic_selection(assert_true)
	_test_sensor_lifecycle(assert_true, assert_int_equal)


static func _test_typed_protocol(
	assert_true: Callable,
	assert_int_equal: Callable,
	assert_float_approx: Callable
) -> void:
	var actor := Node2D.new()
	var context: InteractionContext = INTERACTION_CONTEXT_SCRIPT.new(
		actor,
		Vector2(32.0, 48.0),
		Vector2(1.0, 1.0),
		&"task_restore_pump"
	)
	assert_true.call(context.is_valid(), "interaction context accepts a valid actor and facing")
	assert_float_approx.call(
		context.facing_direction.length(),
		1.0,
		"interaction facing is normalized"
	)

	var interactable := _make_interactable(&"test_interactable", Vector2.ZERO)
	interactable.prompt_key = &"INTERACTION_TEST"
	assert_true.call(interactable.can_interact(context), "interactable accepts a valid typed context")
	assert_true.call(
		interactable.get_interaction_prompt(context) == &"INTERACTION_TEST",
		"interactable returns a stable prompt key"
	)
	var base_result: InteractionResult = interactable.interact(context)
	assert_int_equal.call(
		base_result.status,
		InteractionResult.Status.BLOCKED,
		"base interactable does not pretend an interaction succeeded"
	)
	assert_true.call(
		base_result.reason_key == &"INTERACTION_NOT_IMPLEMENTED",
		"base interactable returns a localized not-implemented reason"
	)

	interactable.interaction_enabled = false
	assert_int_equal.call(
		interactable.interact(context).status,
		InteractionResult.Status.BLOCKED,
		"disabled interactable returns Blocked"
	)
	assert_int_equal.call(
		interactable.interact(INTERACTION_CONTEXT_SCRIPT.new(null, Vector2.ZERO, Vector2.ZERO)).status,
		InteractionResult.Status.INVALID,
		"invalid interaction context returns Invalid"
	)
	interactable.free()
	actor.free()


static func _test_deterministic_selection(assert_true: Callable) -> void:
	var actor := Node2D.new()
	var context: InteractionContext = INTERACTION_CONTEXT_SCRIPT.new(
		actor,
		Vector2.ZERO,
		Vector2.RIGHT,
		&"task_priority"
	)
	var task_target := _make_interactable(&"task_target", Vector2(-12.0, 0.0))
	task_target.task_id = &"task_priority"
	task_target.interaction_priority = InteractableComponent.Priority.GROUND
	var npc_target := _make_interactable(&"npc_target", Vector2(8.0, 0.0))
	npc_target.interaction_priority = InteractableComponent.Priority.NPC
	var disabled_target := _make_interactable(&"disabled_target", Vector2(1.0, 0.0))
	disabled_target.interaction_priority = InteractableComponent.Priority.TASK
	disabled_target.interaction_enabled = false
	var candidates: Array[InteractableComponent] = [npc_target, disabled_target, task_target]
	assert_true.call(
		INTERACTION_SELECTOR_SCRIPT.select_best(context, candidates) == task_target,
		"active task match outranks type priority and facing"
	)

	context.active_task_id = &""
	assert_true.call(
		INTERACTION_SELECTOR_SCRIPT.select_best(context, candidates) == npc_target,
		"type priority wins when no task target matches"
	)

	npc_target.interaction_priority = InteractableComponent.Priority.PICKUP
	task_target.interaction_priority = InteractableComponent.Priority.PICKUP
	assert_true.call(
		INTERACTION_SELECTOR_SCRIPT.select_best(context, candidates) == npc_target,
		"facing score breaks equal-priority ties"
	)

	var near_target := _make_interactable(&"near_target", Vector2(4.0, 0.0))
	near_target.interaction_priority = InteractableComponent.Priority.PICKUP
	var far_target := _make_interactable(&"far_target", Vector2(14.0, 0.0))
	far_target.interaction_priority = InteractableComponent.Priority.PICKUP
	var distance_candidates: Array[InteractableComponent] = [far_target, near_target]
	assert_true.call(
		INTERACTION_SELECTOR_SCRIPT.select_best(context, distance_candidates) == near_target,
		"distance breaks equal-priority equal-facing ties"
	)

	var alpha_target := _make_interactable(&"alpha", Vector2(6.0, 0.0))
	var zulu_target := _make_interactable(&"zulu", Vector2(6.0, 0.0))
	var stable_id_candidates: Array[InteractableComponent] = [zulu_target, alpha_target]
	assert_true.call(
		INTERACTION_SELECTOR_SCRIPT.select_best(context, stable_id_candidates) == alpha_target,
		"stable ID makes exact ties deterministic"
	)
	var empty_candidates: Array[InteractableComponent] = []
	assert_true.call(
		INTERACTION_SELECTOR_SCRIPT.select_best(context, empty_candidates) == null,
		"selector returns null when no candidate is valid"
	)

	for candidate in [
		task_target,
		npc_target,
		disabled_target,
		near_target,
		far_target,
		alpha_target,
		zulu_target,
	]:
		candidate.free()
	actor.free()


static func _test_sensor_lifecycle(
	assert_true: Callable,
	assert_int_equal: Callable
) -> void:
	var actor := Node2D.new()
	var sensor: InteractionSensor = INTERACTION_SENSOR_SCRIPT.new()
	actor.add_child(sensor)
	sensor.refresh_context(actor, Vector2.RIGHT)
	var far_target := _make_interactable(&"far_sensor_target", Vector2(20.0, 0.0))
	var near_target := _make_interactable(&"near_sensor_target", Vector2(5.0, 0.0))
	sensor.register_candidate(far_target)
	sensor.register_candidate(near_target)
	assert_true.call(
		sensor.current_target == near_target,
		"sensor selects the best registered candidate"
	)
	assert_true.call(
		sensor.get_current_prompt() == &"INTERACTION_USE",
		"sensor exposes the current stable prompt key"
	)

	near_target.interaction_enabled = false
	sensor.refresh_context(actor, Vector2.RIGHT)
	assert_true.call(
		sensor.current_target == far_target,
		"sensor reselects when the current candidate becomes disabled"
	)
	sensor.unregister_candidate(far_target)
	assert_true.call(sensor.current_target == null, "sensor clears target after the last valid exit")
	assert_int_equal.call(
		sensor.interact_with_current().status,
		InteractionResult.Status.INVALID,
		"sensor returns Invalid when interaction has no target"
	)
	var task_target := _make_interactable(&"sensor_task_target", Vector2(-8.0, 0.0))
	task_target.task_id = &"task_sensor_priority"
	task_target.interaction_priority = InteractableComponent.Priority.GROUND
	var high_priority_target := _make_interactable(&"sensor_npc_target", Vector2(8.0, 0.0))
	high_priority_target.interaction_priority = InteractableComponent.Priority.NPC
	sensor.register_candidate(high_priority_target)
	sensor.register_candidate(task_target)
	sensor.set_active_task_id(&"task_sensor_priority")
	assert_true.call(sensor.get_current_target() == task_target, "sensor applies active task priority")
	sensor.refresh_context(actor, Vector2.RIGHT)
	assert_true.call(sensor.get_current_target() == task_target, "context refresh preserves active task")
	sensor.set_active_task_id(&"")
	assert_true.call(
		sensor.get_current_target() == high_priority_target,
		"clearing active task restores type priority"
	)
	high_priority_target.free()
	assert_true.call(
		sensor.get_current_target() == task_target,
		"sensor prunes a freed current target before public access"
	)

	near_target.free()
	far_target.free()
	task_target.free()
	actor.free()


static func _make_interactable(
	stable_id: StringName,
	position: Vector2
) -> InteractableComponent:
	var interactable: InteractableComponent = INTERACTABLE_COMPONENT_SCRIPT.new()
	interactable.interaction_id = stable_id
	interactable.position = position
	return interactable
