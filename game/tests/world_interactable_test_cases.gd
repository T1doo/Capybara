class_name WorldInteractableTestCases
extends RefCounted

const BED_SCRIPT: Script = preload("res://systems/interaction/bed_interactable.gd")
const CHEST_SCRIPT: Script = preload("res://systems/interaction/chest_interactable.gd")
const CONTEXT_SCRIPT: Script = preload("res://systems/interaction/interaction_context.gd")
const DOOR_SCRIPT: Script = preload("res://systems/interaction/door_interactable.gd")
const NPC_SCRIPT: Script = preload("res://systems/interaction/npc_interactable.gd")
const PICKUP_SCRIPT: Script = preload("res://systems/interaction/pickup_interactable.gd")
const RESOURCE_SCRIPT: Script = preload("res://systems/interaction/resource_interactable.gd")


static func run(assert_true: Callable, assert_int_equal: Callable) -> void:
	var actor := Node2D.new()
	var context: InteractionContext = CONTEXT_SCRIPT.new(
		actor,
		Vector2.ZERO,
		Vector2.RIGHT
	)
	_test_pickup(context, assert_true, assert_int_equal)
	_test_resource(context, assert_true, assert_int_equal)
	_test_bed(context, assert_true, assert_int_equal)
	_test_chest(context, assert_true, assert_int_equal)
	_test_door(context, assert_true, assert_int_equal)
	_test_npc(context, assert_true, assert_int_equal)
	actor.free()


static func _test_pickup(
	context: InteractionContext,
	assert_true: Callable,
	assert_int_equal: Callable
) -> void:
	var pickup: PickupInteractable = PICKUP_SCRIPT.new()
	pickup.interaction_id = &"pickup_test"
	pickup.item_id = &"item_branch"
	pickup.quantity = 2
	var result := pickup.interact(context)
	assert_int_equal.call(result.status, InteractionResult.Status.SUCCESS, "pickup succeeds")
	assert_true.call(
		result.payload[&"item_id"] == &"item_branch" and result.payload[&"quantity"] == 2,
		"pickup returns a typed item payload"
	)
	assert_true.call(pickup.interaction_enabled, "pickup waits for inventory commit after request")
	pickup.commit_pickup(2)
	assert_true.call(not pickup.interaction_enabled, "pickup disables after committed transfer")
	assert_int_equal.call(
		pickup.interact(context).status,
		InteractionResult.Status.BLOCKED,
		"used pickup returns Blocked"
	)
	pickup.free()


static func _test_resource(
	context: InteractionContext,
	assert_true: Callable,
	assert_int_equal: Callable
) -> void:
	var resource: ResourceInteractable = RESOURCE_SCRIPT.new()
	resource.interaction_id = &"resource_test"
	resource.resource_id = &"item_branch"
	resource.required_tool_id = &"item_reed_spade"
	resource.remaining_uses = 2
	assert_int_equal.call(
		resource.interact(context).status,
		InteractionResult.Status.BLOCKED,
		"resource rejects an incorrect equipped tool"
	)
	context.equipped_tool_id = &"item_reed_spade"
	var first_result: InteractionResult = resource.interact(context)
	assert_int_equal.call(
		first_result.status,
		InteractionResult.Status.SUCCESS,
		"resource succeeds while uses remain"
	)
	assert_true.call(
		first_result.payload[&"tool_id"] == &"item_reed_spade",
		"resource result records the equipped contextual tool"
	)
	assert_true.call(resource.remaining_uses == 2, "resource waits for inventory commit")
	resource.commit_harvest(1)
	assert_true.call(resource.remaining_uses == 1, "resource decrements after committed yield")
	resource.interact(context)
	resource.commit_harvest(1)
	assert_true.call(
		resource.remaining_uses == 0 and not resource.interaction_enabled,
		"resource disables at depletion"
	)
	assert_int_equal.call(
		resource.interact(context).status,
		InteractionResult.Status.BLOCKED,
		"depleted resource returns Blocked"
	)
	context.equipped_tool_id = &""
	resource.free()


static func _test_bed(
	context: InteractionContext,
	assert_true: Callable,
	assert_int_equal: Callable
) -> void:
	var bed: BedInteractable = BED_SCRIPT.new()
	bed.interaction_id = &"bed_test"
	bed.rest_event_id = &"rest_home"
	var result := bed.interact(context)
	assert_int_equal.call(result.status, InteractionResult.Status.SUCCESS, "bed request succeeds")
	assert_true.call(
		result.payload[&"rest_event_id"] == &"rest_home",
		"bed returns a typed rest request without advancing time"
	)
	bed.free()


static func _test_chest(
	context: InteractionContext,
	assert_true: Callable,
	assert_int_equal: Callable
) -> void:
	var chest: ChestInteractable = CHEST_SCRIPT.new()
	chest.interaction_id = &"chest_test"
	chest.storage_id = &"storage_test"
	assert_true.call(chest.get_interaction_prompt(context) == &"INTERACTION_OPEN", "closed chest prompt is Open")
	var open_result := chest.interact(context)
	assert_int_equal.call(open_result.status, InteractionResult.Status.SUCCESS, "chest opens")
	assert_true.call(chest.is_open, "chest stores minimal open state")
	assert_true.call(chest.get_interaction_prompt(context) == &"INTERACTION_CLOSE", "open chest prompt is Close")
	chest.interact(context)
	assert_true.call(not chest.is_open, "second chest interaction closes it")
	chest.free()


static func _test_door(
	context: InteractionContext,
	assert_true: Callable,
	assert_int_equal: Callable
) -> void:
	var door: DoorInteractable = DOOR_SCRIPT.new()
	door.interaction_id = &"door_test"
	door.destination_zone_id = &"zone_test"
	door.destination_spawn_id = &"spawn_test"
	door.is_locked = true
	assert_true.call(door.get_interaction_prompt(context) == &"INTERACTION_DOOR_LOCKED", "locked door prompt is stable")
	assert_int_equal.call(
		door.interact(context).status,
		InteractionResult.Status.BLOCKED,
		"locked door returns Blocked"
	)
	door.is_locked = false
	var result := door.interact(context)
	assert_int_equal.call(result.status, InteractionResult.Status.SUCCESS, "unlocked door requests transition")
	assert_true.call(
		result.payload[&"destination_zone_id"] == &"zone_test"
		and result.payload[&"destination_spawn_id"] == &"spawn_test",
		"door returns typed zone and spawn IDs without changing scenes"
	)
	door.destination_spawn_id = &""
	assert_int_equal.call(
		door.interact(context).status,
		InteractionResult.Status.INVALID,
		"door with an empty spawn ID is invalid"
	)
	door.free()


static func _test_npc(
	context: InteractionContext,
	assert_true: Callable,
	assert_int_equal: Callable
) -> void:
	var npc: NpcInteractable = NPC_SCRIPT.new()
	npc.interaction_id = &"npc_interaction_test"
	npc.npc_id = &"npc_otter_builder"
	npc.conversation_id = &"conversation_intro"
	var result := npc.interact(context)
	assert_int_equal.call(
		result.status,
		InteractionResult.Status.SUCCESS,
		"NPC interaction requests a conversation"
	)
	assert_true.call(
		result.payload[&"npc_id"] == &"npc_otter_builder"
		and result.payload[&"conversation_id"] == &"conversation_intro",
		"NPC returns stable typed IDs without starting dialogue logic"
	)
	npc.free()
