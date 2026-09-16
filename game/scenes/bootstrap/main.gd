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


func _ready() -> void:
	player.interaction_completed.connect(_on_player_interaction_completed)
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


func _on_player_interaction_completed(result: InteractionResult) -> void:
	_request_interaction_feedback(result)
	if result.is_success() and result.payload.has(&"item_id"):
		var inventory_service := get_node("/root/InventoryService") as InventoryCoordinator
		var add_result: InventoryTransactionResult = inventory_service.player_inventory.add_item(
			StringName(result.payload[&"item_id"]),
			int(result.payload.get(&"quantity", 1))
		)
		var pickup := player.get_current_interactable() as PickupInteractable
		if pickup == null and result.payload.has(&"interaction_id"):
			var scene_flow := get_node("/root/SceneFlowService") as SceneFlowCoordinator
			pickup = scene_flow.current_zone.find_interactable(
				StringName(result.payload[&"interaction_id"])
			) as PickupInteractable
		if pickup != null:
			pickup.commit_pickup(add_result.transferred)
	if result.is_success() and result.payload.has(&"resource_id"):
		var inventory_service := get_node("/root/InventoryService") as InventoryCoordinator
		var resource_id := StringName(result.payload[&"resource_id"])
		var requested_quantity: int = int(result.payload.get(&"quantity", 1))
		var harvest_preview: InventoryTransactionResult = (
			inventory_service.player_inventory.add_item(resource_id, requested_quantity, true)
		)
		var transferred: int = 0
		if harvest_preview.transferred == requested_quantity:
			transferred = inventory_service.player_inventory.add_item(
				resource_id, requested_quantity
			).transferred
		var resource: ResourceInteractable = player.get_current_interactable() as ResourceInteractable
		if resource == null and result.payload.has(&"interaction_id"):
			var scene_flow := get_node("/root/SceneFlowService") as SceneFlowCoordinator
			resource = scene_flow.current_zone.find_interactable(
				StringName(result.payload[&"interaction_id"])
			) as ResourceInteractable
		if resource != null:
			resource.commit_harvest(transferred)
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
