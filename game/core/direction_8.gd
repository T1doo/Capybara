class_name Direction8
extends RefCounted

enum Value {
	DOWN,
	DOWN_RIGHT,
	RIGHT,
	UP_RIGHT,
	UP,
	UP_LEFT,
	LEFT,
	DOWN_LEFT,
}

const DIRECTION_VECTORS: Array[Vector2] = [
	Vector2.DOWN,
	Vector2(0.7071067811865476, 0.7071067811865476),
	Vector2.RIGHT,
	Vector2(0.7071067811865476, -0.7071067811865476),
	Vector2.UP,
	Vector2(-0.7071067811865476, -0.7071067811865476),
	Vector2.LEFT,
	Vector2(-0.7071067811865476, 0.7071067811865476),
]
const DIRECTION_IDS: Array[StringName] = [
	&"down",
	&"down_right",
	&"right",
	&"up_right",
	&"up",
	&"up_left",
	&"left",
	&"down_left",
]


static func from_vector(direction: Vector2, fallback: int = Value.DOWN) -> int:
	if direction.is_zero_approx():
		return fallback if is_valid(fallback) else Value.DOWN

	var normalized_direction := direction.normalized()
	var best_direction: int = Value.DOWN
	var best_dot := -2.0
	for index in range(DIRECTION_VECTORS.size()):
		var direction_dot := normalized_direction.dot(DIRECTION_VECTORS[index])
		if direction_dot > best_dot:
			best_dot = direction_dot
			best_direction = index
	return best_direction


static func to_vector(direction: int) -> Vector2:
	if not is_valid(direction):
		return Vector2.DOWN
	return DIRECTION_VECTORS[direction]


static func to_id(direction: int) -> StringName:
	if not is_valid(direction):
		return &"down"
	return DIRECTION_IDS[direction]


static func from_id(direction_id: StringName, fallback: int = Value.DOWN) -> int:
	var index: int = DIRECTION_IDS.find(direction_id)
	if index >= 0:
		return index
	return fallback if is_valid(fallback) else Value.DOWN


static func is_valid(direction: int) -> bool:
	return direction >= Value.DOWN and direction <= Value.DOWN_LEFT
