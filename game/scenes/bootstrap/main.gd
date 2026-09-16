class_name GameBootstrap
extends Node2D

const HOME_ZONE_ID: StringName = &"zone_home_placeholder"
const HOME_SPAWN_ID: StringName = &"spawn_home_start"
const HOME_ZONE_SCENE: PackedScene = preload("res://scenes/world/home_zone.tscn")
const GROVE_ZONE_ID: StringName = &"zone_grove_placeholder"
const GROVE_ZONE_SCENE: PackedScene = preload("res://scenes/world/grove_zone.tscn")

@onready var world_container: Node2D = %WorldContainer
@onready var player: PlayerCharacter = %Player
@onready var storage_screen: StorageScreen = %StorageScreen

var active_chest: ChestInteractable
var _resolving_item_request: bool = false


func _ready() -> void:
	player.interaction_completed.connect(_on_player_interaction_completed)
	player.interaction_requested.connect(_on_player_interaction_requested)
	storage_screen.closed.connect(_on_storage_screen_closed)
	var scene_flow := get_node_or_null("/root/SceneFlowService") as SceneFlowCoordinator
	if scene_flow == null:
		push_error("SceneFlowService configuration failed")
		return
	if not scene_flow.configure(world_container, player):
		if scene_flow.last_error_key == &"SCENE_FLOW_ALREADY_CONFIGURED":
			queue_free()
			return
		push_error("SceneFlowService configuration failed")
		return
	_register_zone_if_needed(scene_flow, HOME_ZONE_ID, HOME_ZONE_SCENE)
	_register_zone_if_needed(scene_flow, GROVE_ZONE_ID, GROVE_ZONE_SCENE)
	if not scene_flow.transition_to(HOME_ZONE_ID, HOME_SPAWN_ID):
		push_error("Initial world zone transition failed: %s" % scene_flow.last_error_key)


func _on_player_interaction_requested(request: InteractionResult) -> void:
	if request == null or request.resolved:
		return
	request.resolved = true
	var result: InteractionResult = InteractionResult.blocked(&"INTERACTION_UNAVAILABLE")
	if not _resolving_item_request:
		_resolving_item_request = true
		result = _commit_item_request(request)
		_resolving_item_request = false
	player.interaction_completed.emit(result)


func _commit_item_request(request: InteractionResult) -> InteractionResult:
	if not request.is_requested():
		return request if not request.is_success() else InteractionResult.invalid(&"INTERACTION_UNAVAILABLE")
	if get_tree().paused or player.get_state() == PlayerStateMachine.State.DISABLED:
		return InteractionResult.blocked(&"INTERACTION_UNAVAILABLE")
	var flow := get_node("/root/SceneFlowService") as SceneFlowCoordinator
	if flow.current_zone == null:
		return InteractionResult.blocked(&"INTERACTION_UNAVAILABLE")
	# Resolve the request's stable target, never whichever object is selected now.
	var target: InteractableComponent = flow.current_zone.find_interactable(
		StringName(request.payload.get(&"interaction_id", &""))
	)
	var item_id: StringName
	var requested_quantity: int
	if target is PickupInteractable:
		var pickup := target as PickupInteractable
		if not pickup.claim_request(request):
			return InteractionResult.blocked(&"INTERACTION_UNAVAILABLE")
		item_id = pickup.item_id
		requested_quantity = pickup.quantity
	elif target is ResourceInteractable:
		var resource := target as ResourceInteractable
		if not resource.claim_request(request, player.get_equipped_tool_id()):
			return InteractionResult.blocked(&"INTERACTION_UNAVAILABLE")
		item_id = resource.resource_id
		requested_quantity = resource.yield_quantity
	else:
		return InteractionResult.blocked(&"INTERACTION_UNAVAILABLE")
	var service := get_node("/root/InventoryService") as InventoryCoordinator
	var preview: InventoryTransactionResult = service.player_inventory.add_item(item_id, requested_quantity, true)
	# Resources require the whole yield; ground pickups may transfer a partial stack.
	if preview.transferred <= 0 or (target is ResourceInteractable and preview.transferred != requested_quantity):
		return InteractionResult.blocked(&"INVENTORY_FULL")
	var transferred: int = service.player_inventory.add_item(item_id, requested_quantity).transferred
	if transferred <= 0:
		return InteractionResult.blocked(&"INVENTORY_FULL")
	if target is PickupInteractable:
		(target as PickupInteractable).commit_pickup(transferred)
	else:
		(target as ResourceInteractable).commit_harvest(transferred)
	var payload: Dictionary = request.payload.duplicate(true)
	payload[&"requested_quantity"] = requested_quantity
	payload[&"quantity"] = transferred
	if target is ResourceInteractable:
		payload[&"remaining_uses"] = (target as ResourceInteractable).remaining_uses
	return InteractionResult.succeeded(request.message_key, payload)


func _on_player_interaction_completed(result: InteractionResult) -> void:
	_request_interaction_feedback(result)
	if not result.is_success() or not result.payload.has(&"storage_id"):
		return
	var inventory_service := get_node("/root/InventoryService") as InventoryCoordinator
	var storage_id := StringName(result.payload[&"storage_id"])
	var storage: StorageInventory = inventory_service.create_storage(storage_id)
	if storage == null:
		return
	active_chest = player.get_current_interactable() as ChestInteractable
	if bool(result.payload.get(&"is_open", false)):
		storage_screen.configure(inventory_service.player_inventory, storage)
		storage_screen.open_screen()
	else:
		storage_screen.close_screen()


func _on_storage_screen_closed() -> void:
	if is_instance_valid(active_chest):
		active_chest.is_open = false
	active_chest = null


func _request_interaction_feedback(result: InteractionResult) -> void:
	if not result.is_success():
		return
	var accessibility := get_node_or_null(
		"/root/AccessibilityService"
	) as AccessibilityFeedbackService
	var input_device := get_node_or_null("/root/InputDeviceService") as InputDeviceTracker
	if accessibility == null or input_device == null:
		return
	accessibility.request_gamepad_vibration(input_device.get_gamepad_id())


func _exit_tree() -> void:
	var scene_flow := get_node_or_null("/root/SceneFlowService") as SceneFlowCoordinator
	if scene_flow != null and is_instance_valid(world_container):
		scene_flow.unconfigure(world_container)


func _register_zone_if_needed(
	scene_flow: SceneFlowCoordinator,
	zone_id: StringName,
	zone_scene: PackedScene
) -> void:
	if scene_flow.has_registered_zone(zone_id):
		return
	if not scene_flow.register_zone_scene(zone_id, zone_scene):
		push_error("World zone registration failed: %s" % zone_id)
