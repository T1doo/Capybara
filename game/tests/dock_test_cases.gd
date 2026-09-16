extends RefCounted


static func run(tree: SceneTree, world: HomeVisualBlockout, check: Callable) -> void:
	var dock := world.get_node("PaintedDock") as PaintedDock2D
	var player := world.get_node("Player") as PlayerCharacter
	check.call(dock.get_deck_polygon().size() == 4 and dock.DECK_RECT.size == Vector2(384,192),
		"dock exposes its exact raised deck footprint")
	check.call(not world.is_water_blocked_at(Vector2(560,352))
		and world.is_water_blocked_at(Vector2(480,352))
		and world.is_water_blocked_at(Vector2(560,224))
		and world.is_water_blocked_at(Vector2(560,480)),
		"dock notch removes only the covered river collision")
	var collision_matches: bool = true
	var footprint := Rect2(Vector2(512,256),Vector2(384,192))
	for x in range(225,705,17):
		for y in range(100,590,23):
			var point := Vector2(x,y)
			var expected := Geometry2D.is_point_in_polygon(point,world.lower_water) and not footprint.has_point(point)
			if world.is_water_blocked_at(point) != expected:
				collision_matches = false
	check.call(collision_matches, "river collision sampling differs from original only inside the exact dock footprint")
	player.position = world.get_anchor_position(&"DockStand")
	player.velocity = Vector2.ZERO
	await _move(tree, &"move_down", 40)
	check.call(player.position.y > 315.0 and absf(player.position.x - 768.0) < 4.0,
		"player enters dock from the stable road-side stand through its open entrance")
	await _move(tree, &"move_left", 50)
	check.call(player.position.x < 615.0 and Geometry2D.is_point_in_polygon(player.position,world.lower_water)
		and not world.is_water_blocked_at(player.position),
		"player can stand on raised deck over the original river surface")
	check.call(player.position.x >= 577.0, "west dock edge prevents falling into the river")
	player.position = Vector2(704,352)
	await _move(tree, &"move_down", 24)
	var hit := player.get_last_slide_collision()
	check.call(player.position.y < 384.0 and hit != null and hit.get_collider() == dock.get_node("RailCollision"),
		"front dock rail has real collision independent of the river")
	player.position = Vector2(704,352)
	await _move(tree, &"move_right", 50)
	hit = player.get_last_slide_collision()
	check.call(player.position.x < 832.0 and hit != null and hit.get_collider() == dock.get_node("RailCollision"),
		"east dock rail blocks the real player before the world boundary")
	player.position = Vector2(660,352)
	await _move(tree, &"move_up", 30)
	hit = player.get_last_slide_collision()
	check.call(player.position.y > 320.0 and hit != null and hit.get_collider() == dock.get_node("RailCollision"),
		"north non-entrance rail blocks the real player independently of the river corner")
	player.position = Vector2(768,352)
	await _move(tree, &"move_up", 50)
	check.call(player.position.y < 200.0, "player can leave the dock through the same shore entrance")
	check.call(dock.front_rail.z_index > player.z_index and dock.rear_rail.z_index < player.z_index,
		"dock front and rear ropes straddle player rendering order")
	player.position = Vector2.ZERO
	player.velocity = Vector2.ZERO


static func _move(tree: SceneTree, action: StringName, frames: int) -> void:
	Input.action_press(action)
	for frame in range(frames):
		await tree.physics_frame
	Input.action_release(action)
