extends RefCounted


static func run(tree: SceneTree, world: HomeVisualBlockout, check: Callable) -> void:
	var canopy := world.get_node("PathCanopy") as CanopyOccluder2D
	var foliage := canopy.get_node("Foliage") as PaintedFoliage2D
	var player := world.get_node("Player") as PlayerCharacter
	var trunk := world.get_node("PathTreeTrunk") as StaticBody2D
	check.call(not canopy.draw_placeholder and foliage.crown.texture == PaintedFoliage2D.FOLIAGE,
		"path tree replaces placeholder circles with the approved painted foliage material")
	check.call(Geometry2D.triangulate_polygon(foliage.crown.polygon).size() > 0,
		"organic canopy contour triangulates without self-crossing failure")
	var valid_uv: bool = true
	for uv in foliage.crown.uv:
		valid_uv = valid_uv and uv.x >= 0 and uv.y >= 0 and uv.x < 1254 and uv.y < 1254
	check.call(valid_uv, "canopy sampling stays inside the source without texture repeat")
	var alternate := world.get_node("NorthWestTree/Crown/Foliage") as PaintedFoliage2D
	check.call(alternate.variant == 1 and alternate.crown.polygon != foliage.crown.polygon,
		"decorative trees select a deterministic silhouette and UV variant before building")
	var service := tree.root.get_node("SettingsService") as SettingsManagerService
	var original := service.current_settings.duplicate_profile()
	var reduced := original.duplicate_profile()
	reduced.reduced_motion = true
	service.replace_settings(reduced)
	player.position = canopy.position
	for frame in range(3):
		await tree.physics_frame
	check.call(canopy.is_occluded() and is_equal_approx(canopy.modulate.a,0.34),
		"real player fades painted canopy immediately under reduced motion")
	check.call(trunk.z_index > player.z_index, "tree trunk sorts in front of a northern player")
	player.position = Vector2(-256,250)
	for frame in range(3):
		await tree.physics_frame
	check.call(not canopy.is_occluded() and is_equal_approx(canopy.modulate.a,1.0),
		"painted canopy restores opacity after the player leaves")
	check.call(trunk.z_index < player.z_index, "tree trunk sorts behind a southern player")
	Input.action_press(&"move_up")
	for frame in range(30):
		await tree.physics_frame
	Input.action_release(&"move_up")
	var hit := player.get_last_slide_collision()
	check.call(player.position.y >= 204.0 and hit != null and hit.get_collider() == trunk,
		"tree trunk has an actual blocking footprint")
	player.position = Vector2.ZERO
	var probe := CharacterBody2D.new()
	probe.add_to_group(&"player")
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	probe.add_child(shape)
	probe.position = canopy.position
	world.add_child(probe)
	for frame in range(3):
		await tree.physics_frame
	check.call(canopy.is_occluded(), "secondary real body enters the canopy tracking set")
	probe.remove_from_group(&"player")
	probe.queue_free()
	for frame in range(3):
		await tree.physics_frame
	check.call(not canopy.is_occluded() and is_equal_approx(canopy.modulate.a,1.0),
		"removing a player after its group changes cannot leave the canopy permanently faded")
	service.replace_settings(original)
