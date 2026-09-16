extends RefCounted


static func run(tree: SceneTree, blockout: HomeVisualBlockout, check: Callable) -> void:
	var cottage := blockout.get_node("CottagePrototype") as LayeredCottage2D
	var player := blockout.get_node("Player") as PlayerCharacter
	var settings := tree.root.get_node("SettingsService") as SettingsManagerService
	var original_settings := settings.current_settings.duplicate_profile()
	var reduced := original_settings.duplicate_profile()
	reduced.reduced_motion = true
	settings.replace_settings(reduced)
	var threshold := cottage.get_node("DoorThreshold") as Marker2D
	var stand := blockout.get_anchor_position(&"HouseMainDoor")
	check.call(absf(threshold.global_position.x - stand.x) < 1.0, "cottage door and approach share the same axis")
	check.call(stand.y > threshold.global_position.y + 66.0, "door approach clears the player's actual collision radius")
	check.call(cottage.z_index + cottage.roof_layer.z_index > player.z_index, "cottage roof renders above the player")
	for layer in [cottage.walls_layer, cottage.roof_layer, cottage.shadow_layer]:
		var pixels: Image = layer.texture.get_image()
		var bounds := pixels.get_used_rect()
		check.call(pixels.get_pixel(0, 0).a == 0.0 and bounds.size.x > 0, "cottage layer has transparent padding and visible content")
		check.call(bounds.position.x > 0 and bounds.end.x < pixels.get_width(), "cottage layer fits inside the shared canvas")

	player.position = Vector2(stand.x, 0.0)
	Input.action_press(&"move_up")
	for frame in range(30):
		await tree.physics_frame
	Input.action_release(&"move_up")
	check.call(player.position.distance_to(stand) < 15.0, "player can walk from the path to the door approach")
	Input.action_press(&"move_up")
	for frame in range(40):
		await tree.physics_frame
	Input.action_release(&"move_up")
	check.call(player.position.y > threshold.global_position.y + 40.0, "foundation prevents walking through the front wall")
	player.position = Vector2(-240.0, -255.0)
	Input.action_press(&"move_left")
	for frame in range(45):
		await tree.physics_frame
	Input.action_release(&"move_left")
	check.call(player.position.x > -340.0, "foundation prevents walking through the side wall")

	player.position = cottage.to_global(Vector2(0.0, -210.0))
	await tree.physics_frame
	await tree.physics_frame
	check.call(cottage.is_roof_faded(), "real player behind roof triggers occlusion")
	check.call(is_equal_approx(cottage.roof_layer.modulate.a, cottage.roof_faded_alpha), "settings signal makes reduced-motion roof fade immediate")
	check.call(cottage.walls_layer.modulate.a == 1.0, "roof fade preserves wall opacity")
	var other := CharacterBody2D.new()
	other.collision_layer = 1
	other.collision_mask = 0
	other.add_to_group(&"player")
	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 8.0
	shape_node.shape = shape
	other.add_child(shape_node)
	other.position = player.position
	blockout.add_child(other)
	await tree.physics_frame
	await tree.physics_frame
	player.remove_from_group(&"player")
	player.position = Vector2.ZERO
	await tree.physics_frame
	await tree.physics_frame
	check.call(cottage.is_roof_faded(), "second overlapping player keeps roof faded after first exits")
	other.queue_free()
	await tree.process_frame
	await tree.physics_frame
	check.call(not cottage.is_roof_faded() and cottage.roof_layer.modulate.a == 1.0, "last player freed restores roof even after first player lost its group")
	player.add_to_group(&"player")
	settings.replace_settings(original_settings)
