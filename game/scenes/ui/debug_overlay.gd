class_name DebugOverlay
extends Label

@export var player_path: NodePath
@export var world_container_path: NodePath

var player: PlayerCharacter
var world_container: Node2D
var scene_flow: SceneFlowCoordinator
var input_device_service: InputDeviceTracker


func _ready() -> void:
	player = get_node_or_null(player_path) as PlayerCharacter
	if player == null:
		player = get_tree().get_first_node_in_group(&"player") as PlayerCharacter
	world_container = get_node_or_null(world_container_path) as Node2D
	scene_flow = get_node_or_null("/root/SceneFlowService") as SceneFlowCoordinator
	input_device_service = get_node_or_null("/root/InputDeviceService") as InputDeviceTracker
	refresh_now()


func _process(_delta: float) -> void:
	if visible:
		refresh_now()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"toggle_debug_overlay"):
		return
	visible = not visible
	get_viewport().set_input_as_handled()


func refresh_now() -> void:
	var target_id: StringName = &""
	var current_target: InteractableComponent = null
	if player != null:
		current_target = player.get_current_interactable()
	if current_target != null:
		target_id = current_target.interaction_id
	var device_id: StringName = &""
	if input_device_service != null:
		device_id = input_device_service.get_device_id()
	var zone_id: StringName = &""
	if scene_flow != null:
		zone_id = scene_flow.get_current_zone_id()
	var active_zone_count: int = world_container.get_child_count() if world_container != null else 0
	var player_count: int = get_tree().get_nodes_in_group(&"player").size()

	text = "\n".join(
		[
			tr(&"DEBUG_OVERLAY_TITLE"),
			_format_line(&"DEBUG_ZONE", zone_id),
			_format_line(&"DEBUG_STATE", player.get_state_id() if player != null else &""),
			_format_line(&"DEBUG_FACING", player.get_facing_id() if player != null else &""),
			_format_line(&"DEBUG_TARGET", target_id),
			_format_line(&"DEBUG_DEVICE", device_id),
			"%s: %d" % [tr(&"DEBUG_PLAYER_COUNT"), player_count],
			"%s: %d" % [tr(&"DEBUG_ACTIVE_ZONE_COUNT"), active_zone_count],
		]
	)


func _format_line(label_key: StringName, value: StringName) -> String:
	var display_value: String = str(value) if not value.is_empty() else tr(&"DEBUG_NONE")
	return "%s: %s" % [tr(label_key), display_value]
