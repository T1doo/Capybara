extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://scenes/bootstrap/main.tscn")
const MOVE_ACTIONS: Array[StringName] = [
	&"move_right",
	&"move_down",
	&"move_left",
	&"move_up",
]
const DEFAULT_DURATION_SECONDS: int = 1200
const HEARTBEAT_INTERVAL_SECONDS: int = 60

var failure_messages: Array[String] = []
var transition_count: int = 0
var input_interaction_count: int = 0
var target_selection_count: int = 0
var state_check_count: int = 0
var home_pickup: PickupInteractable
var home_resource: ResourceInteractable
var home_chest: ChestInteractable
var expected_resource_uses: int = 0


func _init() -> void:
	call_deferred(&"_run_soak")


func _run_soak() -> void:
	var duration_seconds: int = _read_duration_seconds()
	var main_scene := MAIN_SCENE.instantiate()
	root.add_child(main_scene)
	await process_frame
	var player := main_scene.get_node("Player") as PlayerCharacter
	var world_container := main_scene.get_node("WorldContainer") as Node2D
	var pause_menu := main_scene.get_node("Interface/PauseMenu") as Control
	var scene_flow := root.get_node("SceneFlowService") as SceneFlowCoordinator
	player.interaction_completed.connect(_on_player_interaction_completed)
	_initialize_state_probe(player, scene_flow)
	var started_ms: int = Time.get_ticks_msec()
	var next_heartbeat_seconds: int = HEARTBEAT_INTERVAL_SECONDS
	var cycle_count: int = 0

	while _elapsed_seconds(started_ms) < duration_seconds and failure_messages.is_empty():
		var move_action: StringName = MOVE_ACTIONS[cycle_count % MOVE_ACTIONS.size()]
		await _exercise_movement(move_action)
		_validate_runtime(main_scene, player, world_container, scene_flow)
		if cycle_count % 4 == 0:
			await _exercise_transition(player, scene_flow, pause_menu, cycle_count)
		if cycle_count % 8 == 0:
			await _exercise_pause(player, pause_menu, move_action)
		if cycle_count % 16 == 2:
			await _exercise_target_selection(player, scene_flow, cycle_count)
		cycle_count += 1

		var elapsed_seconds: int = _elapsed_seconds(started_ms)
		if elapsed_seconds >= next_heartbeat_seconds:
			print(
				(
					"STAGE 1 SOAK HEARTBEAT: elapsed=%ds cycles=%d transitions=%d "
					+ "inputs=%d selections=%d state_checks=%d zone=%s"
				)
				% [
					elapsed_seconds,
					cycle_count,
					transition_count,
					input_interaction_count,
					target_selection_count,
					state_check_count,
					scene_flow.get_current_zone_id(),
				]
			)
			next_heartbeat_seconds += HEARTBEAT_INTERVAL_SECONDS

	_release_movement_actions()
	if paused:
		paused = false
	if transition_count == 0 or input_interaction_count == 0 or target_selection_count == 0:
		_fail("soak coverage counters must all be non-zero")
	main_scene.queue_free()
	await process_frame
	if not failure_messages.is_empty():
		push_error("STAGE 1 SOAK FAILED: %s" % " | ".join(failure_messages))
		quit(1)
		return

	var actual_seconds: int = _elapsed_seconds(started_ms)
	print(
		(
			"CAPYBARA STAGE 1 SOAK PASSED: duration=%ds cycles=%d transitions=%d "
			+ "inputs=%d selections=%d state_checks=%d"
		)
		% [
			actual_seconds,
			cycle_count,
			transition_count,
			input_interaction_count,
			target_selection_count,
			state_check_count,
		]
	)
	quit(0)


func _exercise_movement(action: StringName) -> void:
	_release_movement_actions()
	Input.action_press(action, 1.0)
	for _frame_index in range(6):
		await physics_frame
	Input.action_release(action)
	await physics_frame


func _exercise_transition(
	player: PlayerCharacter,
	scene_flow: SceneFlowCoordinator,
	pause_menu: Control,
	cycle_count: int
) -> void:
	var previous_zone_id: StringName = scene_flow.get_current_zone_id()
	var previous_direction: Vector2 = player.get_last_move_direction()
	var previous_facing: int = player.get_facing()
	var doors: Array[DoorInteractable] = scene_flow.current_zone.find_transition_doors()
	if doors.size() != 1:
		_fail("expected exactly one transition door in %s" % previous_zone_id)
		return
	var expected_door: DoorInteractable = doors[0]
	player.global_position = expected_door.global_position
	for _frame_index in range(3):
		await physics_frame
	if player.get_current_interactable() != expected_door:
		_fail("real sensor did not select expected door in %s" % previous_zone_id)
		return
	var interaction_count_before: int = input_interaction_count
	var press_event: InputEvent = _make_interaction_event(transition_count, true)
	var pause_race: bool = cycle_count % 64 == 0 or cycle_count % 64 == 36
	player._unhandled_input(press_event)
	if not scene_flow.has_pending_transition():
		_fail("real player input did not queue a transition in %s" % previous_zone_id)
		return
	if pause_race:
		var pause_event: InputEvent = _make_pause_event(transition_count)
		pause_menu.call(&"_input", pause_event)
		for _frame_index in range(3):
			await process_frame
		if scene_flow.get_current_zone_id() != previous_zone_id:
			_fail("queued transition executed during pause")
		pause_menu.call(&"_input", pause_event)
		await process_frame
	else:
		await process_frame
	transition_count += 1
	if input_interaction_count != interaction_count_before + 1:
		_fail("player interaction_completed count did not advance exactly once")
	if scene_flow.get_current_zone_id() == previous_zone_id:
		_fail("transition did not leave %s" % previous_zone_id)
	if not player.get_last_move_direction().is_equal_approx(previous_direction):
		_fail("transition lost the player's last movement direction")
	if player.get_facing() != previous_facing:
		_fail("transition lost the player's facing state")


func _exercise_target_selection(
	player: PlayerCharacter,
	scene_flow: SceneFlowCoordinator,
	cycle_count: int
) -> void:
	var task_target := _make_probe_interactable(
		&"soak_task_target",
		&"task_soak_priority",
		InteractableComponent.Priority.GROUND,
		player.position
	)
	var high_priority_target := _make_probe_interactable(
		&"soak_npc_target",
		&"",
		InteractableComponent.Priority.NPC,
		player.position
	)
	if cycle_count % 32 == 2:
		scene_flow.current_zone.add_child(task_target)
		scene_flow.current_zone.add_child(high_priority_target)
	else:
		scene_flow.current_zone.add_child(high_priority_target)
		scene_flow.current_zone.add_child(task_target)
	for _frame_index in range(3):
		await physics_frame
	player.set_active_task_id(&"task_soak_priority")
	await physics_frame
	if player.get_current_interactable() != task_target:
		_fail("real overlapping candidates did not select the active task")
	player.set_active_task_id(&"")
	await physics_frame
	if player.get_current_interactable() != high_priority_target:
		_fail("real overlapping candidates did not restore type priority")
	target_selection_count += 1
	task_target.queue_free()
	high_priority_target.queue_free()
	await process_frame
	player.get_current_interactable()


func _exercise_pause(
	player: PlayerCharacter,
	pause_menu: Control,
	move_action: StringName
) -> void:
	var pause_event := InputEventKey.new()
	pause_event.keycode = KEY_ESCAPE
	pause_event.pressed = true
	pause_menu.call(&"_input", pause_event)
	if not paused:
		_fail("Escape did not pause the game")
		return
	var paused_position: Vector2 = player.position
	Input.action_press(move_action, 1.0)
	for _frame_index in range(10):
		await process_frame
	Input.action_release(move_action)
	if not player.position.is_equal_approx(paused_position):
		_fail("movement penetrated the pause state")
	pause_menu.call(&"_input", pause_event)
	if paused:
		_fail("Escape did not resume the game")


func _validate_runtime(
	main_scene: Node,
	player: PlayerCharacter,
	world_container: Node2D,
	scene_flow: SceneFlowCoordinator
) -> void:
	if get_nodes_in_group(&"player").size() != 1:
		_fail("player instance count is not one")
	if world_container.get_child_count() != 1:
		_fail("active zone count is not one")
	if not is_instance_valid(scene_flow.current_zone):
		_fail("current zone is invalid")
	if player.get_parent() != main_scene:
		_fail("persistent player left the bootstrap scene")
	var target: InteractableComponent = player.get_current_interactable()
	if target != null and not scene_flow.current_zone.is_ancestor_of(target):
		_fail("interaction target belongs to an inactive zone")
	if target != null:
		player.interaction_sensor.refresh_context(player, player.last_move_direction)
		if player.get_current_interactable() != target:
			_fail("unchanged interaction candidates selected a different target")
	if not is_instance_valid(home_pickup) or home_pickup.interaction_enabled:
		_fail("home pickup runtime state was lost")
	if not is_instance_valid(home_resource) or home_resource.remaining_uses != expected_resource_uses:
		_fail("home resource runtime state was lost")
	if not is_instance_valid(home_chest) or not home_chest.is_open:
		_fail("home chest runtime state was lost")
	state_check_count += 1


func _initialize_state_probe(
	player: PlayerCharacter,
	scene_flow: SceneFlowCoordinator
) -> void:
	home_pickup = scene_flow.current_zone.get_node("PickupPlaceholder") as PickupInteractable
	home_resource = scene_flow.current_zone.get_node("ResourcePlaceholder") as ResourceInteractable
	home_chest = scene_flow.current_zone.get_node("ChestPlaceholder") as ChestInteractable
	var context := InteractionContext.new(player, player.position, Vector2.RIGHT)
	if not home_pickup.interact(context).is_requested():
		_fail("failed to initialize pickup state probe")
	if not home_resource.interact(context).is_requested():
		_fail("failed to initialize resource state probe")
	if not home_chest.interact(context).is_success():
		_fail("failed to initialize chest state probe")
	expected_resource_uses = home_resource.remaining_uses


func _make_probe_interactable(
	stable_id: StringName,
	task_id: StringName,
	priority: int,
	position: Vector2
) -> InteractableComponent:
	var probe := InteractableComponent.new()
	probe.interaction_id = stable_id
	probe.task_id = task_id
	probe.interaction_priority = priority
	probe.position = position
	probe.collision_layer = 4
	probe.collision_mask = 0
	probe.monitoring = false
	var collision_shape := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 16.0
	collision_shape.shape = shape
	probe.add_child(collision_shape)
	return probe


func _make_interaction_event(sequence: int, pressed: bool) -> InputEvent:
	if sequence % 2 == 0:
		var key_event := InputEventKey.new()
		key_event.keycode = KEY_E
		key_event.physical_keycode = KEY_E
		key_event.pressed = pressed
		return key_event
	var button_event := InputEventJoypadButton.new()
	button_event.button_index = JOY_BUTTON_A
	button_event.pressed = pressed
	return button_event


func _make_pause_event(sequence: int) -> InputEvent:
	if sequence % 2 == 0:
		var key_event := InputEventKey.new()
		key_event.keycode = KEY_ESCAPE
		key_event.physical_keycode = KEY_ESCAPE
		key_event.pressed = true
		return key_event
	var button_event := InputEventJoypadButton.new()
	button_event.button_index = JOY_BUTTON_START
	button_event.pressed = true
	return button_event


func _on_player_interaction_completed(result: InteractionResult) -> void:
	if result.is_success():
		input_interaction_count += 1


func _read_duration_seconds() -> int:
	var raw_duration: String = OS.get_environment("CAPYBARA_STAGE_1_SOAK_SECONDS")
	if raw_duration.is_valid_int() and raw_duration.to_int() > 0:
		return raw_duration.to_int()
	return DEFAULT_DURATION_SECONDS


func _elapsed_seconds(started_ms: int) -> int:
	return (Time.get_ticks_msec() - started_ms) / 1000


func _release_movement_actions() -> void:
	for action in MOVE_ACTIONS:
		Input.action_release(action)


func _fail(message: String) -> void:
	if not failure_messages.has(message):
		failure_messages.append(message)
