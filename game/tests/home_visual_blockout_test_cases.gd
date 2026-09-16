extends RefCounted

const BLOCKOUT_SCENE: PackedScene = preload(
	"res://scenes/visual_prototypes/home_visual_blockout.tscn"
)


static func run(
	tree: SceneTree,
	assert_true: Callable,
	assert_int_equal: Callable,
	assert_vector_approx: Callable
) -> void:
	var blockout := BLOCKOUT_SCENE.instantiate() as HomeVisualBlockout
	tree.root.add_child(blockout)
	await tree.process_frame
	await tree.physics_frame

	assert_true.call(is_equal_approx(blockout.GRID_SIZE, 64.0), "home blockout uses the 64px logic grid")
	assert_true.call(
		is_equal_approx(blockout.PLAYER_REFERENCE_HEIGHT, 144.0),
		"home blockout records the 144px player reference"
	)
	assert_true.call(blockout.style_profile != null, "home blockout loads an environment style profile")
	assert_true.call(
		blockout.style_profile.validate().is_empty(),
		"home environment style profile passes its invariants"
	)
	assert_true.call(
		is_equal_approx(blockout.style_profile.camera_pitch_degrees, 35.0),
		"home style fixes the 35 degree camera pitch"
	)
	assert_true.call(
		blockout.style_profile.light_direction.x < 0.0
		and blockout.style_profile.light_direction.y < 0.0,
		"home style fixes upper-left lighting"
	)
	assert_true.call(
		blockout.style_profile.contact_shadow_offset.x > 0.0
		and blockout.style_profile.contact_shadow_offset.y > 0.0,
		"home style fixes lower-right contact shadows"
	)
	assert_true.call(
		blockout.style_profile.shore_highlight_width < blockout.style_profile.shore_band_width,
		"home style keeps the shoreline highlight inside its shallow band"
	)
	assert_int_equal.call(blockout.get_anchor_count(), 9, "home blockout exposes nine stable anchors")
	for anchor_name in [
		&"Spawn",
		&"HouseMainDoor",
		&"GardenEntrance",
		&"BridgeWest",
		&"BridgeEast",
		&"WaterwheelService",
		&"DockStand",
		&"PrimaryPathRest",
		&"CameraBoundaryReference",
	]:
		var anchor_position := blockout.get_anchor_position(anchor_name)
		assert_true.call(anchor_position.is_finite(), "home anchor %s exists" % anchor_name)
		assert_true.call(
			is_equal_approx(fmod(absf(anchor_position.x), 64.0), 0.0)
			and is_equal_approx(fmod(absf(anchor_position.y), 64.0), 0.0),
			"home anchor %s is aligned to the 64px grid" % anchor_name
		)

	assert_true.call(blockout.is_water_blocked_at(Vector2(384.0, -256.0)), "upper river is blocked")
	assert_true.call(blockout.is_water_blocked_at(Vector2(384.0, 256.0)), "lower river is blocked")
	assert_true.call(not blockout.is_water_blocked_at(Vector2.ZERO), "spawn starts on dry land")
	assert_true.call(not blockout.is_water_blocked_at(Vector2(384.0, 0.0)), "bridge corridor remains walkable")
	assert_true.call(
		not blockout.is_water_blocked_at(blockout.get_anchor_position(&"HouseMainDoor")),
		"house door stand stays on land"
	)
	assert_true.call(
		not blockout.is_water_blocked_at(blockout.get_anchor_position(&"WaterwheelService")),
		"waterwheel service stand stays on land"
	)
	assert_true.call(
		not blockout.is_water_blocked_at(blockout.get_anchor_position(&"DockStand")),
		"dock interaction stand stays on land"
	)

	var upper_collision := blockout.get_node("WaterCollision/UpperWaterCollision") as CollisionPolygon2D
	var lower_collision := blockout.get_node("WaterCollision/LowerWaterCollision") as CollisionPolygon2D
	assert_true.call(
		upper_collision.polygon == blockout.upper_water,
		"upper visual topology is the actual collision polygon"
	)
	assert_true.call(
		Geometry2D.is_point_in_polygon(Vector2(480,352), lower_collision.polygon)
		and not Geometry2D.is_point_in_polygon(Vector2(560,352), lower_collision.polygon),
		"lower water collision preserves river while excluding the raised dock"
	)
	var upper_surface := blockout.get_node("UpperWaterSurface") as Polygon2D
	var lower_surface := blockout.get_node("LowerWaterSurface") as Polygon2D
	var water_material := upper_surface.material as ShaderMaterial
	assert_true.call(
		water_material == lower_surface.material,
		"both river segments share one scene-local water material"
	)
	assert_true.call(
		water_material.shader.resource_path == "res://assets/shaders/storybook_water.gdshader",
		"home blockout uses the storybook water shader"
	)
	blockout.set_water_accessibility(true, false)
	assert_true.call(
		is_zero_approx(float(water_material.get_shader_parameter(&"motion_strength"))),
		"reduced motion freezes storybook water animation"
	)
	blockout.set_water_accessibility(false, true)
	assert_true.call(
		is_equal_approx(float(water_material.get_shader_parameter(&"motion_strength")), 1.0),
		"normal motion restores storybook water animation"
	)
	assert_true.call(
		is_equal_approx(float(water_material.get_shader_parameter(&"contrast_strength")), 1.0),
		"high contrast strengthens storybook water separation"
	)
	var ground_surface := blockout.get_node("GroundSurface") as Polygon2D
	var ground_material := ground_surface.material as ShaderMaterial
	assert_true.call(
		ground_material.shader.resource_path == "res://assets/shaders/storybook_ground.gdshader",
		"home blockout uses the world-space storybook ground shader"
	)
	assert_true.call(
		ground_material.get_shader_parameter(&"base_color") == blockout.style_profile.ground_base,
		"ground shader consumes the locked style base color"
	)
	var canopy := blockout.get_node("PathCanopy") as CanopyOccluder2D
	assert_true.call(canopy.collision_mask == 1, "path canopy detects the player collision layer")
	canopy.set_occluded(true, true)
	assert_true.call(
		is_equal_approx(canopy.modulate.a, blockout.style_profile.canopy_faded_alpha),
		"path canopy fades to the locked style alpha"
	)
	canopy.set_occluded(false, true)
	assert_true.call(is_equal_approx(canopy.modulate.a, 1.0), "path canopy restores full opacity")
	var motes := blockout.get_node("AmbientMotes") as AmbientMotes2D
	var first_mote := motes.get_mote_position(0, 0.0)
	assert_true.call(first_mote.is_finite(), "ambient motes expose a deterministic first position")
	assert_true.call(
		first_mote == motes.get_mote_position(0, 0.0),
		"ambient mote sampling is deterministic"
	)
	motes.set_reduced_motion(true)
	var frozen_time := motes.get_elapsed()
	motes._process(1.0)
	assert_true.call(is_equal_approx(motes.get_elapsed(), frozen_time), "reduced motion freezes ambient motes")
	motes.set_reduced_motion(false)
	motes._process(1.0)
	assert_true.call(motes.get_elapsed() > frozen_time, "normal motion resumes ambient motes")
	var cottage := blockout.get_node("CottagePrototype") as LayeredCottage2D
	assert_true.call(
		cottage.get_display_content_width() >= 420.0
		and cottage.get_display_content_width() <= 520.0,
		"layered cottage stays within the game-width target"
	)
	assert_true.call(
		cottage.walls_layer.texture.resource_path.ends_with("bld_home_cottage_walls_v001.svg"),
		"cottage walls use the independent transparent layer"
	)
	assert_true.call(
		cottage.roof_layer.texture.resource_path.ends_with("bld_home_cottage_roof_v001.svg"),
		"cottage roof uses the independent transparent layer"
	)
	assert_true.call(
		cottage.shadow_layer.texture.resource_path.ends_with("bld_home_cottage_shadow_v001.svg"),
		"cottage shadow uses the independent transparent layer"
	)
	cottage.set_roof_faded(true, true)
	assert_true.call(
		is_equal_approx(cottage.roof_layer.modulate.a, cottage.roof_faded_alpha),
		"cottage roof can fade independently"
	)
	cottage.set_roof_faded(false, true)
	assert_true.call(is_equal_approx(cottage.roof_layer.modulate.a, 1.0), "cottage roof restores independently")

	var player := blockout.get_node("Player") as PlayerCharacter
	assert_vector_approx.call(player.position, Vector2.ZERO, "blockout player starts at the stable spawn")
	assert_true.call(
		absf(player.scale.y * 46.0 - blockout.PLAYER_REFERENCE_HEIGHT) <= 8.0,
		"blockout player silhouette stays within eight pixels of the 144px reference"
	)
	player.position = canopy.position
	await tree.physics_frame
	await tree.physics_frame
	assert_true.call(canopy.is_occluded(), "path canopy detects a real player overlap")
	player.position = Vector2.ZERO
	await tree.physics_frame
	await tree.physics_frame
	assert_true.call(not canopy.is_occluded(), "path canopy restores after the real player exits")

	player.position = Vector2(0.0, -256.0)
	Input.action_press(&"move_right", 1.0)
	for _frame_index in range(70):
		await tree.physics_frame
	Input.action_release(&"move_right")
	assert_true.call(player.position.x < 180.0, "player cannot walk into ordinary river water")

	player.position = Vector2.ZERO
	player.velocity = Vector2.ZERO
	Input.action_press(&"move_right", 1.0)
	for _frame_index in range(145):
		await tree.physics_frame
	Input.action_release(&"move_right")
	assert_true.call(player.position.x > 480.0, "player can cross the river through the bridge corridor")
	await preload("res://tests/cottage_test_cases.gd").run(tree, blockout, assert_true)
	await preload("res://tests/bridge_test_cases.gd").run(tree, blockout, assert_true)
	await preload("res://tests/waterwheel_test_cases.gd").run(tree, blockout, assert_true)
	await preload("res://tests/dock_test_cases.gd").run(tree, blockout, assert_true)
	await preload("res://tests/foliage_test_cases.gd").run(tree, blockout, assert_true)

	blockout.queue_free()
	await tree.process_frame
	await preload("res://tests/home_visual_preview_test_cases.gd").run(tree, assert_true)
