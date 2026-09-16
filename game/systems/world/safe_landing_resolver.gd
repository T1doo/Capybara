class_name SafeLandingResolver
extends RefCounted

const STEP: float = 64.0
const DIRECTIONS: Array[Vector2] = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]


static func resolve(
	zone: Node2D, body: CharacterBody2D, requested: Vector2,
	spawn_position: Vector2, bounds: Rect2
) -> Dictionary:
	if body == null:
		return {"success": false}
	var shape_node := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null or shape_node.shape == null:
		return {"success": false}
	var context: Dictionary = {
		"zone": zone, "shape": shape_node.shape, "offset": shape_node.transform,
		"basis": body.global_transform, "bounds": bounds,
		"obstacles": _obstacles(zone, body.collision_mask),
	}
	if not _safe(spawn_position, context):
		return {"success": false}
	if _safe(requested, context) and _clear_path(spawn_position, requested, context):
		return {"success": true, "position": requested}
	# Bounded graph search proves connection to the named spawn, including paths around walls.
	var reachable: Array[Vector2] = [spawn_position]
	var visited: Dictionary = {Vector2i.ZERO: true}
	var cells: Array[Vector2i] = [Vector2i.ZERO]
	var index: int = 0
	while index < cells.size() and cells.size() < 2048:
		var cell: Vector2i = cells[index]
		index += 1
		for direction in DIRECTIONS:
			var next_cell: Vector2i = cell + Vector2i(direction)
			if visited.has(next_cell):
				continue
			visited[next_cell] = true
			var point: Vector2 = spawn_position + Vector2(next_cell) * STEP
			if _safe(point, context) and _clear_path(spawn_position + Vector2(cell) * STEP, point, context):
				cells.append(next_cell)
				reachable.append(point)
	var candidates: Array[Vector2] = [requested]
	for radius in [32.0, 64.0, 96.0, 128.0]:
		for direction in DIRECTIONS:
			candidates.append(requested + direction * radius)
	for candidate in candidates:
		if not _safe(candidate, context):
			continue
		for point in reachable:
			if candidate.distance_squared_to(point) <= STEP * STEP * 2.0 and _clear_path(point, candidate, context):
				return {"success": true, "position": candidate}
	return {"success": true, "position": spawn_position}


static func is_safe(zone: Node2D, body: CharacterBody2D, point: Vector2, bounds: Rect2) -> bool:
	var shape_node := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		return false
	return _safe(point, {
		"zone": zone, "shape": shape_node.shape, "offset": shape_node.transform,
		"basis": body.global_transform, "bounds": bounds,
		"obstacles": _obstacles(zone, body.collision_mask),
	})


static func _safe(point: Vector2, context: Dictionary) -> bool:
	if not point.is_finite():
		return false
	var zone := context["zone"] as Node2D
	var bounds: Rect2 = context["bounds"]
	if not bounds.has_point(zone.to_local(point)):
		return false
	return _clear_path(point, point, context)


static func _clear_path(start: Vector2, finish: Vector2, context: Dictionary) -> bool:
	var transform: Transform2D = context["basis"]
	transform.origin = start
	transform = transform * (context["offset"] as Transform2D)
	var shape := context["shape"] as Shape2D
	for obstacle: Dictionary in context["obstacles"]:
		if shape.collide_with_motion(transform, finish - start, obstacle["shape"], obstacle["transform"], Vector2.ZERO):
			return false
	return true


static func _obstacles(zone: Node2D, mask: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var pending: Array[Node] = [zone]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		for child in node.get_children():
			pending.append(child)
		var body := node.get_parent() as PhysicsBody2D
		if body == null or (body.collision_layer & mask) == 0:
			continue
		if node is CollisionShape2D:
			var collision := node as CollisionShape2D
			if not collision.disabled and collision.shape != null:
				result.append({"shape": collision.shape, "transform": collision.global_transform})
		elif node is CollisionPolygon2D:
			var polygon := node as CollisionPolygon2D
			if polygon.disabled or polygon.polygon.size() < 3:
				continue
			for part: PackedVector2Array in Geometry2D.decompose_polygon_in_convex(polygon.polygon):
				var shape := ConvexPolygonShape2D.new()
				shape.points = part
				result.append({"shape": shape, "transform": polygon.global_transform})
	return result
