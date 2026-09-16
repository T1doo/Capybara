class_name PlayerCharacter
extends CharacterBody2D

signal state_changed(previous_state: int, current_state: int)
signal interaction_completed(result: InteractionResult)

const DIRECTION_8_SCRIPT: Script = preload("res://core/direction_8.gd")
const MOVEMENT_MATH_SCRIPT: Script = preload("res://core/movement_math.gd")
const PLAYER_STATE_MACHINE_SCRIPT: Script = preload("res://scenes/player/player_state_machine.gd")

@export_range(1.0, 1000.0, 1.0) var move_speed: float = 240.0

@onready var facing_marker: Polygon2D = %FacingMarker
@onready var interaction_sensor: InteractionSensor = %InteractionSensor
@onready var follow_camera: Camera2D = %Camera2D

var last_move_direction: Vector2 = Vector2.DOWN
var facing: int = Direction8.Value.DOWN
var active_task_id: StringName = &""
var state_machine: PlayerStateMachine = PLAYER_STATE_MACHINE_SCRIPT.new()


func _ready() -> void:
	state_machine.state_changed.connect(_on_state_changed)
	_update_facing_marker()
	_refresh_interaction_sensor()
	var settings_service := get_node_or_null("/root/SettingsService") as SettingsManagerService
	if settings_service != null:
		settings_service.settings_changed.connect(_on_settings_changed)
		_on_settings_changed(settings_service.current_settings)


func _physics_process(_delta: float) -> void:
	if not state_machine.can_accept_movement_input():
		velocity = Vector2.ZERO
		move_and_slide()
		_refresh_interaction_sensor()
		return

	var move_direction: Vector2 = MOVEMENT_MATH_SCRIPT.direction_from_axes(
		Input.get_axis(&"move_left", &"move_right"),
		Input.get_axis(&"move_up", &"move_down")
	)
	last_move_direction = MOVEMENT_MATH_SCRIPT.select_last_non_zero_direction(
		last_move_direction,
		move_direction
	)
	if move_direction.is_zero_approx():
		state_machine.transition_to(PlayerStateMachine.State.IDLE)
	else:
		state_machine.transition_to(PlayerStateMachine.State.MOVE)
		facing = DIRECTION_8_SCRIPT.from_vector(move_direction, facing)
	velocity = move_direction * move_speed
	move_and_slide()
	_update_facing_marker()
	_refresh_interaction_sensor()


func _unhandled_input(event: InputEvent) -> void:
	var inventory_service := get_node_or_null("/root/InventoryService") as InventoryCoordinator
	if inventory_service != null and event.is_action_pressed(&"hotbar_previous"):
		inventory_service.hotbar.select_offset(-1)
		get_viewport().set_input_as_handled()
		return
	if inventory_service != null and event.is_action_pressed(&"hotbar_next"):
		inventory_service.hotbar.select_offset(1)
		get_viewport().set_input_as_handled()
		return
	if not event.is_action_pressed(&"interact"):
		return
	if get_current_interactable() == null or not begin_interaction():
		return

	var result := try_interact_current()
	end_interaction()
	interaction_completed.emit(result)
	get_viewport().set_input_as_handled()


func get_last_move_direction() -> Vector2:
	return last_move_direction


func get_facing() -> int:
	return facing


func get_facing_id() -> StringName:
	return DIRECTION_8_SCRIPT.to_id(facing)


func get_state() -> int:
	return state_machine.current_state


func get_state_id() -> StringName:
	return state_machine.get_state_id()


func get_current_interactable() -> InteractableComponent:
	return interaction_sensor.get_current_target()


func get_current_interaction_prompt() -> StringName:
	return interaction_sensor.get_current_prompt()


func try_interact_current() -> InteractionResult:
	return interaction_sensor.interact_with_current()


func set_active_task_id(task_id: StringName) -> void:
	active_task_id = task_id
	interaction_sensor.set_active_task_id(active_task_id)


func get_active_task_id() -> StringName:
	return active_task_id


func get_equipped_tool_id() -> StringName:
	var inventory_service := get_node_or_null("/root/InventoryService") as InventoryCoordinator
	if inventory_service == null:
		return &""
	var item_id: StringName = inventory_service.hotbar.get_selected_item_id()
	var definition: ItemDefinition = inventory_service.content_registry.get_item(item_id)
	if definition == null or definition.category != ItemDefinition.Category.TOOL:
		return &""
	return item_id


func restore_runtime_state(restored_position: Vector2, restored_facing_id: StringName) -> bool:
	var restored_facing: int = DIRECTION_8_SCRIPT.from_id(restored_facing_id, -1)
	if not DIRECTION_8_SCRIPT.is_valid(restored_facing):
		return false
	global_position = restored_position
	facing = restored_facing
	last_move_direction = DIRECTION_8_SCRIPT.to_vector(facing)
	velocity = Vector2.ZERO
	state_machine.transition_to(PlayerStateMachine.State.IDLE)
	_update_facing_marker()
	_refresh_interaction_sensor()
	return true


func begin_interaction() -> bool:
	velocity = Vector2.ZERO
	return state_machine.transition_to(PlayerStateMachine.State.INTERACT)


func end_interaction() -> bool:
	if state_machine.current_state != PlayerStateMachine.State.INTERACT:
		return false
	return state_machine.transition_to(PlayerStateMachine.State.IDLE)


func set_disabled(disabled: bool) -> bool:
	if disabled:
		velocity = Vector2.ZERO
		return state_machine.transition_to(PlayerStateMachine.State.DISABLED)
	if state_machine.current_state != PlayerStateMachine.State.DISABLED:
		return false
	return state_machine.transition_to(PlayerStateMachine.State.IDLE)


func _update_facing_marker() -> void:
	var facing_vector: Vector2 = DIRECTION_8_SCRIPT.to_vector(facing)
	facing_marker.position = facing_vector * 18.0
	facing_marker.rotation = facing_vector.angle()


func _on_state_changed(previous_state: int, current_state: int) -> void:
	state_changed.emit(previous_state, current_state)


func _refresh_interaction_sensor() -> void:
	interaction_sensor.refresh_context(
		self,
		DIRECTION_8_SCRIPT.to_vector(facing),
		get_equipped_tool_id()
	)


func _on_settings_changed(settings: SettingsProfile) -> void:
	follow_camera.position_smoothing_enabled = settings.camera_smoothing and not settings.reduced_motion
