extends SceneTree

const WORLD: PackedScene = preload("res://scenes/visual_prototypes/home_visual_blockout.tscn")
const DISPLAY_SCALE: float = 0.5


func _initialize() -> void:
	call_deferred(&"_capture")


func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		_fail("A real Compatibility renderer is required.")
		return
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 2:
		_fail("Expected render manifest and a new build output directory.")
		return
	var build_root: String = ProjectSettings.globalize_path("res://../build").simplify_path()
	var manifest_path: String = args[0].replace("\\", "/").simplify_path()
	var output: String = args[1].replace("\\", "/").simplify_path()
	if not manifest_path.begins_with(build_root + "/") or not output.begins_with(build_root + "/"):
		_fail("Input and output must remain in build.")
		return
	if DirAccess.dir_exists_absolute(output):
		_fail("Existing capture evidence must not be overwritten.")
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not data is Dictionary or not data.get("canvas") is Array:
		_fail("Expected a render manifest with a canvas array.")
		return
	var canvas: Array = data["canvas"]
	if canvas.size() != 2 or int(canvas[0]) < 128 or int(canvas[1]) < 128:
		_fail("Expected valid source canvas dimensions.")
		return
	var display_scale: float = float(data.get("display_scale", DISPLAY_SCALE))
	if display_scale <= 0.0 or display_scale > 1.0:
		_fail("Expected a fixed display scale in (0, 1].")
		return
	if DirAccess.make_dir_recursive_absolute(output) != OK:
		_fail("Could not create capture output.")
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
	camera.zoom = Vector2.ONE
	world.add_child(camera)
	var sprite := Sprite2D.new()
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.scale = Vector2.ONE * display_scale / player.scale.x
	var pivot: Array = data["pivot"]
	sprite.position = -Vector2(pivot[0], pivot[1]) * sprite.scale
	player.add_child(sprite)
	var overlay := CanvasLayer.new()
	var caption := Label.new()
	caption.position = Vector2(20, 20)
	caption.add_theme_color_override("font_color", Color.WHITE)
	caption.add_theme_color_override("font_shadow_color", Color.BLACK)
	caption.add_theme_constant_override("shadow_offset_x", 2)
	caption.add_theme_constant_override("shadow_offset_y", 2)
	caption.add_theme_font_size_override("font_size", 18)
	root.add_child(overlay)
	overlay.add_child(caption)
	var captures: Array[Dictionary] = []
	for frame: Dictionary in data["frames"]:
		var source: String = manifest_path.get_base_dir().path_join(frame["path"]).simplify_path()
		if not source.begins_with(build_root + "/"):
			_fail("Frame escaped the generated build directory.")
			return
		var bitmap := Image.load_from_file(source)
		if bitmap == null or bitmap.is_empty():
			_fail("Frame could not be loaded.")
			return
		if bitmap.get_size() != Vector2i(int(canvas[0]), int(canvas[1])):
			_fail("Frame dimensions differ from the declared canvas.")
			return
		sprite.texture = ImageTexture.create_from_image(bitmap)
		caption.text = "%s / %s / %s — UNAPPROVED TECHNICAL COMPARISON" % [
			data["route"], frame["direction"], frame["pose"]
		]
		for _frame in range(3):
			await process_frame
		await RenderingServer.frame_post_draw
		var filename: String = "candidate_%02d.png" % captures.size()
		if root.get_texture().get_image().save_png(output.path_join(filename)) != OK:
			_fail("Capture write failed.")
			return
		captures.append({"file": filename, "source": source, "source_sha256": FileAccess.get_sha256(source),
			"direction": frame["direction"], "pose": frame["pose"]})
	var file := FileAccess.open(output.path_join("capture_manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"mode": "Compatibility GPU", "resolution": [1280, 720],
		"world_scale": display_scale, "camera_zoom": 1, "pivot": pivot,
		"player_position": [64, 0], "camera_position": [0, -96],
		"fixture_sha256": FileAccess.get_sha256(get_script().resource_path),
		"candidate_manifest_sha256": FileAccess.get_sha256(manifest_path),
		"shadow_scope": "shared approximate static contact shadow, separate from sprite; not final foot-contact animation",
		"scope": "Visual fixture; not production integration or animation acceptance", "frames": captures}, "\t"))
	file.close()
	print("CHARACTER WORLD CAPTURE PASSED: %d fixed-scale views; not production approved" % captures.size())
	quit(0)


func _install_contact_shadow(player: PlayerCharacter) -> void:
	# A shared ground cue aids static comparison; it does not prove animated foot contact.
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
	push_error("CHARACTER CAPTURE: " + message)
	quit(1)
