class_name PickupInteractable
extends InteractableComponent

signal pickup_requested(item_id: StringName, quantity: int)

@export var item_id: StringName = &""
@export_range(1, 999, 1) var quantity: int = 1


func _perform_interaction(_context: InteractionContext) -> InteractionResult:
	if item_id.is_empty() or quantity <= 0:
		return RESULT_SCRIPT.invalid(&"INTERACTION_INVALID_PICKUP_DEFINITION")

	pickup_requested.emit(item_id, quantity)
	return RESULT_SCRIPT.succeeded(
		&"INTERACTION_PICKUP_SUCCESS",
		{
			&"interaction_id": interaction_id,
			&"item_id": item_id,
			&"quantity": quantity,
		}
	)


func commit_pickup(transferred: int) -> void:
	quantity = maxi(0, quantity - transferred)
	if quantity == 0:
		interaction_enabled = false
