extends RefCounted


static func run(tree: SceneTree, world: HomeVisualBlockout, check: Callable) -> void:
	var player := world.get_node("Player") as PlayerCharacter
	var bridge := world.get_node("PaintedBridge") as PaintedBridge2D
	player.position = Vector2(64,0)
	Input.action_press(&"move_right")
	for frame in range(165):
		await tree.physics_frame
	Input.action_release(&"move_right")
	check.call(player.position.x > 680.0, "painted bridge carries the player fully onto the east bank")
	Input.action_press(&"move_left")
	for frame in range(165):
		await tree.physics_frame
	Input.action_release(&"move_left")
	check.call(player.position.x < 100.0, "painted bridge carries the player back onto the west bank")
	for direction in [-1.0,1.0]:
		player.position = Vector2(160,0)
		var action := &"move_up" if direction < 0.0 else &"move_down"
		Input.action_press(action)
		for frame in range(35):
			await tree.physics_frame
		Input.action_release(action)
		check.call(absf(player.position.y) < 35.0, "painted bridge railing blocks lateral departure")
		var hit := player.get_last_slide_collision()
		check.call(hit != null and hit.get_collider() == bridge.get_node("RailCollision"), "bridge rail has real collision independently of river corners")
	check.call(bridge.front_rail.z_index > player.z_index and bridge.rear_rail.z_index < player.z_index, "front and rear railing straddle player rendering order")
	player.position = Vector2.ZERO
