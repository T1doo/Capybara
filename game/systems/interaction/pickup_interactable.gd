class_name PickupInteractable
extends InteractableComponent

signal pickup_requested(item_id: StringName, quantity: int)

@export var item_id: StringName = &""
@export_range(1, 999, 1) var quantity: int = 1:
	set(value):
		quantity = value
		_refresh_presentation()
@export var visual: CanvasItem
var _pending_request: InteractionResult


func _ready() -> void:
	_refresh_presentation()


func _refresh_presentation() -> void:
	if is_instance_valid(visual):
		visual.visible = quantity > 0


func _perform_interaction(_context: InteractionContext) -> InteractionResult:
	if item_id.is_empty() or quantity <= 0:
		return RESULT_SCRIPT.invalid(&"INTERACTION_INVALID_PICKUP_DEFINITION")

	var request: InteractionResult = RESULT_SCRIPT.requested(
		&"INTERACTION_PICKUP_SUCCESS",
		{
			&"interaction_id": interaction_id,
			&"item_id": item_id,
			&"quantity": quantity,
			&"source_instance_id": get_instance_id(),
		}
	)
	_pending_request = request
	pickup_requested.emit(item_id, quantity)
	return request


func claim_request(request: InteractionResult) -> bool:
	if request != _pending_request:
		return false
	_pending_request = null
	return (
		interaction_enabled and quantity > 0
		and request.payload.get(&"item_id") == item_id
		and request.payload.get(&"quantity") == quantity
		and request.payload.get(&"source_instance_id") == get_instance_id()
	)


func invalidate_pending_request() -> void:
	if _pending_request != null:
		_pending_request.cancel()
	_pending_request = null


func commit_pickup(transferred: int) -> void:
	if transferred <= 0 or transferred > quantity:
		return
	quantity = maxi(0, quantity - transferred)
	if quantity == 0:
		interaction_enabled = false
