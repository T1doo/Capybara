class_name WorldStateCodec
extends RefCounted

const TYPE_PICKUP := "pickup"
const TYPE_RESOURCE := "resource"


static func normalize_and_validate(data: Variant) -> StringName:
	if not data is Dictionary:
		return &"SAVE_INVALID_WORLD_STATE"
	for zone_id in data:
		if not zone_id is String or String(zone_id).is_empty():
			return &"SAVE_INVALID_WORLD_STATE_ZONE"
		var interactions: Variant = data[zone_id]
		if not interactions is Dictionary:
			return &"SAVE_INVALID_WORLD_STATE_ZONE"
		for interaction_id in interactions:
			if not interaction_id is String or String(interaction_id).is_empty():
				return &"SAVE_INVALID_WORLD_STATE_INTERACTION"
			var state: Variant = interactions[interaction_id]
			if not state is Dictionary:
				return &"SAVE_INVALID_WORLD_STATE_INTERACTION"
			var error: StringName = _normalize_state(state as Dictionary)
			if not error.is_empty():
				return error
	return &""


static func _normalize_state(state: Dictionary) -> StringName:
	if not state.get("type") is String:
		return &"SAVE_INVALID_WORLD_STATE_INTERACTION"
	var value_field: String = ""
	match String(state["type"]):
		TYPE_PICKUP:
			value_field = "quantity"
		TYPE_RESOURCE:
			value_field = "remaining_uses"
		_:
			return &"SAVE_INVALID_WORLD_STATE_TYPE"
	var result: Array = _coerce_integer(state.get(value_field))
	if not result[0] or result[1] < 0 or result[1] > 999:
		return &"SAVE_INVALID_WORLD_STATE_VALUE"
	state[value_field] = result[1]
	return &""


static func _coerce_integer(value: Variant) -> Array:
	if value is int:
		return [true, value]
	if value is float and is_finite(value) and is_equal_approx(value, roundf(value)):
		return [true, int(value)]
	return [false, 0]
