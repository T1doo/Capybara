extends SceneTree

const WORLD: PackedScene = preload("res://scenes/visual_prototypes/home_visual_blockout.tscn")
const ATMOSPHERE: Script = preload("res://scenes/visual_prototypes/home_atmosphere_2d.gd")
const AG4_SHA: String = "e92cd4791957b4db13b65b1c8865c574a54975b907647088de26e8edd7975521"
const DISPLAY_SCALE: float = 144.0 / 772.0
const PIVOT: Vector2 = Vector2(689, 834)


func _initialize() -> void:
	call_deferred(&"_capture")


func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		_fail("A real Compatibility renderer is required.")
		return
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 1:
		_fail("Expected a new output directory below build.")
		return
	var build_root: String = ProjectSettings.globalize_path("res://../build").simplify_path()
	var output: String = args[0].replace("\\", "/").simplify_path()
	if not output.begins_with(build_root + "/") or DirAccess.dir_exists_absolute(output):
		_fail("Output must be a new directory under build.")
		return
	var source: String = ProjectSettings.globalize_path("res://../art/candidates/player_ag4_v001/chr_player_ag4_down_right_v001.png")
	if FileAccess.get_sha256(source) != AG4_SHA:
		_fail("The AG4 source is not the exact reviewed image.")
		return
	var source_image := Image.load_from_file(source)
	if source_image == null or source_image.get_size() != Vector2i(1402, 1122):
		_fail("AG4 canvas is invalid.")
		return
	if DirAccess.make_dir_recursive_absolute(output) != OK:
		_fail("Could not create output directory.")
		return
	root.size = Vector2i(1280, 720)
	var settings := root.get_node("SettingsService") as SettingsManagerService
	var profile := SettingsProfile.new()
	profile.reduced_motion = true
	settings.replace_settings(profile)
	settings.apply_current_settings(false)
	var world := WORLD.instantiate() as HomeVisualBlockout
	world.show_grid = false
	world.show_anchor_guides = false
	root.add_child(world)
	await process_frame
	var player := world.get_node("Player") as PlayerCharacter
	player.follow_camera.enabled = false
	player.global_position = Vector2(64, 0)
	for name in ["Body", "Snout", "FacingMarker", "Shadow"]:
		(player.get_node(name) as CanvasItem).hide()
	_install_contact_shadow(player)
	var camera := Camera2D.new()
	camera.position = Vector2(0, -96)
	world.add_child(camera)
	var sprite := Sprite2D.new()
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.texture = ImageTexture.create_from_image(source_image)
	sprite.scale = Vector2.ONE * DISPLAY_SCALE / player.scale.x
	sprite.position = -PIVOT * sprite.scale
	player.add_child(sprite)
	var atmosphere := ATMOSPHERE.new() as HomeAtmosphere2D
	world.add_child(atmosphere)
	var overlay := CanvasLayer.new()
	var caption := Label.new()
	caption.position = Vector2(20, 20)
	caption.add_theme_color_override(&"font_color", Color.WHITE)
	caption.add_theme_color_override(&"font_shadow_color", Color.BLACK)
	caption.add_theme_constant_override(&"shadow_offset_x", 2)
	caption.add_theme_constant_override(&"shadow_offset_y", 2)
	caption.add_theme_font_size_override(&"font_size", 18)
	root.add_child(overlay)
	overlay.add_child(caption)
	var frames: Array[Dictionary] = []
	for preset: StringName in HomeAtmosphere2D.PRESETS:
		if not atmosphere.set_preset(preset):
			_fail("Could not apply preset.")
			return
		caption.text = "HOME / %s — UNAPPROVED ATMOSPHERE PROBE" % preset
		for _frame in range(4):
			await process_frame
		await RenderingServer.frame_post_draw
		var file_name: String = "%s.png" % preset
		var path: String = output.path_join(file_name)
		if root.get_texture().get_image().save_png(path) != OK:
			_fail("Could not save GPU frame.")
			return
		frames.append({"preset": preset, "file": file_name, "sha256": FileAccess.get_sha256(path)})
	var manifest := FileAccess.open(output.path_join("capture_manifest.json"), FileAccess.WRITE)
	manifest.store_string(JSON.stringify({"mode": "Compatibility GPU", "resolution": [1280, 720],
		"camera_position": [0, -96], "player_position": [64, 0], "world_scale": DISPLAY_SCALE,
		"ag4_sha256": AG4_SHA, "atmosphere_script_sha256": FileAccess.get_sha256(ATMOSPHERE.resource_path),
		"capture_script_sha256": FileAccess.get_sha256(get_script().resource_path),
		"reduced_motion": true, "same_world_instance": true, "frames": frames,
		"scope": "Four static visual probes; not approved weather, day-night, art quality, or player integration"}, "\t"))
	manifest.close()
	print("HOME ATMOSPHERE CAPTURE PASSED: %d same-scene GPU views; art unapproved" % frames.size())
	quit(0)


func _install_contact_shadow(player: PlayerCharacter) -> void:
	for layer in range(3):
		var shadow := Polygon2D.new()
		var points := PackedVector2Array()
		var radius: Vector2 = Vector2(80 - layer * 15, 28 - layer * 5) / player.scale.x
		for index in range(40):
			var angle: float = TAU * index / 40.0
			points.append(Vector2(cos(angle), sin(angle)) * radius)
		shadow.polygon = points
		shadow.position = Vector2(5, 6) / player.scale.x
		shadow.color = Color(0.13, 0.17, 0.12, 0.035 + layer * 0.025)
		shadow.antialiased = true
		shadow.z_index = -1
		player.add_child(shadow)


func _fail(message: String) -> void:
	push_error("HOME ATMOSPHERE CAPTURE: " + message)
	quit(1)
