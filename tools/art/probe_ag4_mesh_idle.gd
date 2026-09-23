extends SceneTree

const WORLD: PackedScene = preload("res://scenes/visual_prototypes/home_visual_blockout.tscn")
const SOURCE_SHA: String = "e92cd4791957b4db13b65b1c8865c574a54975b907647088de26e8edd7975521"
const CANVAS: Vector2i = Vector2i(1402, 1122)
const PIVOT: Vector2 = Vector2(689, 834)
const DISPLAY_SCALE: float = 144.0 / 772.0
const COLS: int = 32
const ROWS: int = 26


func _initialize() -> void:
	call_deferred(&"_probe")


func _probe() -> void:
	if DisplayServer.get_name() == "headless":
		_fail("A real Compatibility GPU is required.")
		return
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 1:
		_fail("Expected a new output directory below build.")
		return
	var build_root: String = ProjectSettings.globalize_path("res://../build").simplify_path()
	var output: String = args[0].replace("\\", "/").simplify_path()
	if not output.begins_with(build_root + "/") or DirAccess.dir_exists_absolute(output):
		_fail("Output must be a new directory below build.")
		return
	var source: String = ProjectSettings.globalize_path("res://../art/candidates/player_ag4_v001/chr_player_ag4_down_right_v001.png")
	if FileAccess.get_sha256(source) != SOURCE_SHA:
		_fail("Source is not the exact reviewed AG4 candidate.")
		return
	var image := Image.load_from_file(source)
	if image == null or image.is_empty() or image.get_size() != CANVAS:
		_fail("Source RGBA canvas is invalid.")
		return
	if DirAccess.make_dir_recursive_absolute(output) != OK:
		_fail("Could not create output.")
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
	for node_name in ["Body", "Snout", "FacingMarker", "Shadow"]:
		(player.get_node(node_name) as CanvasItem).hide()
	_install_contact_shadow(player)
	var camera := Camera2D.new()
	camera.position = Vector2(0, -96)
	world.add_child(camera)
	var patch := Polygon2D.new()
	patch.texture = ImageTexture.create_from_image(image)
	patch.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	patch.scale = Vector2.ONE * DISPLAY_SCALE / player.scale.x
	patch.position = -PIVOT * patch.scale
	player.add_child(patch)
	var caption_layer := CanvasLayer.new()
	root.add_child(caption_layer)
	var caption := Label.new()
	caption.position = Vector2(20, 20)
	caption.add_theme_color_override("font_color", Color.WHITE)
	caption.add_theme_color_override("font_shadow_color", Color.BLACK)
	caption.add_theme_constant_override("shadow_offset_x", 2)
	caption.add_theme_constant_override("shadow_offset_y", 2)
	caption.add_theme_font_size_override("font_size", 18)
	caption_layer.add_child(caption)
	var triangles: Array[PackedInt32Array] = _make_triangles()
	var uv := _make_uv()
	patch.polygons = triangles
	patch.uv = uv
	var frames: Array[Dictionary] = []
	for pose: Dictionary in [
		{"name": "neutral", "offset": Vector2.ZERO},
		{"name": "raise_12", "offset": Vector2(0, -12)},
		{"name": "forward_12", "offset": Vector2(12, 0)},
	]:
		var start_usec: int = Time.get_ticks_usec()
		patch.polygon = _deformed_vertices(pose["offset"])
		var update_usec: int = Time.get_ticks_usec() - start_usec
		caption.text = "AG4 mesh idle / %s — UNAPPROVED TECHNICAL PROBE" % pose["name"]
		for _frame in range(3):
			await process_frame
		await RenderingServer.frame_post_draw
		var file_name: String = "%s.png" % pose["name"]
		if root.get_texture().get_image().save_png(output.path_join(file_name)) != OK:
			_fail("GPU capture failed.")
			return
		frames.append({"file": file_name, "pose": pose["name"], "offset_native_px": [pose["offset"].x, pose["offset"].y], "mesh_update_usec": update_usec})
	var manifest := FileAccess.open(output.path_join("probe.json"), FileAccess.WRITE)
	manifest.store_string(JSON.stringify({"source_sha256": SOURCE_SHA, "script_sha256": FileAccess.get_sha256(get_script().resource_path),
		"mode": "Compatibility GPU", "display_server": DisplayServer.get_name(),
		"resolution": [1280, 720], "world_scale": DISPLAY_SCALE, "pivot": [PIVOT.x, PIVOT.y],
		"mesh_cells": [COLS, ROWS], "frames": frames,
		"scope": "small idle deformation study only; not accepted animation, cutout segmentation, or game asset"}, "\t"))
	manifest.close()
	print("AG4 MESH IDLE PROBE PASSED: %d GPU views; art unapproved" % frames.size())
	quit(0)


func _make_uv() -> PackedVector2Array:
	var uv := PackedVector2Array()
	for row in range(ROWS + 1):
		for col in range(COLS + 1):
			uv.append(Vector2(float(col) * CANVAS.x / COLS, float(row) * CANVAS.y / ROWS))
	return uv


func _make_triangles() -> Array[PackedInt32Array]:
	var triangles: Array[PackedInt32Array] = []
	for row in range(ROWS):
		for col in range(COLS):
			var upper_left: int = row * (COLS + 1) + col
			var upper_right: int = upper_left + 1
			var lower_left: int = upper_left + COLS + 1
			var lower_right: int = lower_left + 1
			triangles.append(PackedInt32Array([upper_left, upper_right, lower_right]))
			triangles.append(PackedInt32Array([upper_left, lower_right, lower_left]))
	return triangles


func _deformed_vertices(offset: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for uv: Vector2 in _make_uv():
		var delta: Vector2 = (uv - Vector2(1000, 530)) / Vector2(155, 140)
		var weight: float = exp(-0.5 * delta.length_squared())
		points.append(uv + offset * weight)
	return points


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
	push_error("AG4 MESH IDLE: " + message)
	quit(1)
