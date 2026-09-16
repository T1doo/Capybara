extends RefCounted


static func run(tree: SceneTree, world: HomeVisualBlockout, check: Callable) -> void:
	var mill := world.get_node("PaintedWaterwheel") as PaintedWaterwheel2D
	var player := world.get_node("Player") as PlayerCharacter
	var settings := tree.root.get_node("SettingsService") as SettingsManagerService
	var previous := settings.current_settings.duplicate_profile()
	var profile := previous.duplicate_profile()
	profile.reduced_motion = false
	settings.replace_settings(profile)
	var before := mill.wheel.rotation
	for frame in range(12):
		await tree.physics_frame
	check.call(not is_equal_approx(before,mill.wheel.rotation), "flowing water turns the wheel during real frames")
	profile.reduced_motion = true
	settings.replace_settings(profile)
	before = mill.wheel.rotation
	for frame in range(12):
		await tree.physics_frame
	check.call(is_equal_approx(before,mill.wheel.rotation), "reduced-motion settings signal freezes the wheel")
	profile.reduced_motion = false
	settings.replace_settings(profile)
	mill.set_flow_enabled(false)
	before = mill.wheel.rotation
	for frame in range(12):
		await tree.physics_frame
	check.call(is_equal_approx(before,mill.wheel.rotation), "wheel stops when the visual water feed is disabled")
	mill.set_flow_enabled(true)
	for frame in range(12):
		await tree.physics_frame
	check.call(not is_equal_approx(before,mill.wheel.rotation), "restoring water feed resumes wheel motion")
	var stand := world.get_anchor_position(&"WaterwheelService")
	player.position = stand + Vector2(0,96)
	Input.action_press(&"move_up")
	for frame in range(24):
		await tree.physics_frame
	Input.action_release(&"move_up")
	check.call(player.position.distance_to(stand) < 12.0, "waterwheel service position remains reachable from the path")
	Input.action_press(&"move_up")
	for frame in range(30):
		await tree.physics_frame
	Input.action_release(&"move_up")
	var hit := player.get_last_slide_collision()
	check.call(hit != null and hit.get_collider() == mill.get_node("FrameBody"), "waterwheel frame physically blocks the player")
	profile.reduced_motion = true
	settings.replace_settings(profile)
	player.position = Vector2(768,-432)
	await tree.physics_frame
	await tree.physics_frame
	check.call(mill.z_index > player.z_index, "waterwheel sorts in front of a northern player while reduced motion is active")
	player.position = stand
	await tree.physics_frame
	await tree.physics_frame
	check.call(mill.z_index < player.z_index, "waterwheel sorts behind a player returning to the service position")
	settings.replace_settings(previous)
	player.position = Vector2.ZERO
