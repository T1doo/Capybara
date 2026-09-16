class_name MovementMath
extends RefCounted


static func direction_from_axes(horizontal: float, vertical: float) -> Vector2:
	var raw_direction := Vector2(
		clampf(horizontal, -1.0, 1.0),
		clampf(vertical, -1.0, 1.0)
	)
	return normalize_input(raw_direction)


static func normalize_input(input_vector: Vector2) -> Vector2:
	if input_vector.length_squared() > 1.0:
		return input_vector.normalized()
	return input_vector


static func select_last_non_zero_direction(
	current_direction: Vector2,
	candidate_direction: Vector2
) -> Vector2:
	if candidate_direction.is_zero_approx():
		return current_direction
	return candidate_direction.normalized()
