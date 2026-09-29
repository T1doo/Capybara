extends SceneTree

const WORLD: PackedScene = preload("res://scenes/visual_prototypes/home_visual_blockout.tscn")
const FRAME_COUNT: int = 18
const FIXTURE_FPS: int = 60
const TRAVEL_DIRECTION := Vector2(0.7071067811865476, 0.7071067811865476)

var output: String
var manifest_path: String
var source_data: Dictionary
var world: HomeVisualBlockout
var player: PlayerCharacter
var sprite: Sprite2D
var caption: Label
var driver: WalkDriver
var textures: Array[Texture2D] = []
var frames: Array[Dictionary] = []
var captures: Array[Dictionary] = []
var rows: Array[Dictionary] = []


class WalkDriver extends Node:

	signal finished
	var record: Callable
	var tick: int = 0


	func _physics_process(delta: float) -> void:
		tick += 1
		record.call(tick, delta)
		if tick == 36:
			set_physics_process(false)
			finished.emit()


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		_fail("Requires a real Compatibility GPU window.")
		return
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 2:
		_fail("Expected render manifest and new build output directory.")
		return
	var build_root: String = ProjectSettings.globalize_path("res://../build").simplify_path()
	manifest_path = args[0].replace("\\", "/").simplify_path()
	output = args[1].replace("\\", "/").simplify_path()
	if not manifest_path.begins_with(build_root + "/") or not output.begins_with(build_root + "/"):
		_fail("Only build input/output allowed.")
		return
	if DirAccess.dir_exists_absolute(output):
		_fail("Refusing to overwrite prior evidence.")
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not parsed is Dictionary:
		_fail("Invalid render manifest.")
		return
	source_data = parsed
	if _vec(source_data.get("canvas", [0, 0])) != Vector2(512, 512) or _vec(source_data.get("pivot", [0, 0])) != Vector2(256, 384):
		_fail("Unexpected fixed canvas/pivot.")
		return
	if source_data.get("display_scale") != 0.5 or source_data.get("walk", {}).get("fps") != FIXTURE_FPS:
		_fail("Expected fixed scale 0.5 and 60 fps walk.")
		return
	for frame: Dictionary in source_data.get("frames", []):
		if frame.get("walk_frame") == null:
			continue
		var source: String = manifest_path.get_base_dir().path_join(frame["path"]).simplify_path()
		if not source.begins_with(build_root + "/") or FileAccess.get_sha256(source) != frame["sha256"]:
			_fail("Frame escaped build or changed hash.")
			return
		var bitmap := Image.load_from_file(source)
		if bitmap == null or bitmap.get_size() != Vector2i(512, 512):
			_fail("Invalid rendered frame.")
			return
		if frame["direction"] != "down_right" or int(frame["walk_frame"]) != frames.size():
			_fail("Expected ordered down-right cycle.")
			return
		frames.append(frame)
		textures.append(ImageTexture.create_from_image(bitmap))
	if frames.size() != FRAME_COUNT:
		_fail("Incomplete cycle.")
		return
	if DirAccess.make_dir_recursive_absolute(output) != OK:
		_fail("Cannot create output.")
		return
	root.size = Vector2i(1280, 720)
	Engine.physics_ticks_per_second = FIXTURE_FPS
	var settings := root.get_node("SettingsService") as SettingsManagerService
	var profile := SettingsProfile.new()
	profile.reduced_motion = true
	settings.replace_settings(profile)
	settings.apply_current_settings(false)
	world = WORLD.instantiate() as HomeVisualBlockout
	world.show_grid = false
	world.show_anchor_guides = false
	root.add_child(world)
	await process_frame
	player = world.get_node("Player") as PlayerCharacter
	player.set_physics_process(false)
	player.follow_camera.enabled = false
	player.global_position = Vector2(-40, -104)
	if player.move_speed != 240.0:
		_fail("Production move speed changed; do not silently retime this probe.")
		return
	for node_name: String in ["Body", "Snout", "FacingMarker", "Shadow"]:
		(player.get_node(node_name) as CanvasItem).hide()
	_install_contact_shadow()
	var camera := Camera2D.new()
	camera.position = Vector2(0, -96)
	world.add_child(camera)
	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.scale = Vector2.ONE * 0.5 / player.scale.x
	sprite.position = -Vector2(256, 384) * sprite.scale
	sprite.texture = textures[0]
	player.add_child(sprite)
	var overlay := CanvasLayer.new()
	root.add_child(overlay)
	caption = Label.new()
	caption.position = Vector2(20, 20)
	caption.add_theme_color_override("font_color", Color.WHITE)
	caption.add_theme_color_override("font_shadow_color", Color.BLACK)
	caption.add_theme_constant_override("shadow_offset_x", 2)
	caption.add_theme_constant_override("shadow_offset_y", 2)
	overlay.add_child(caption)
	driver = WalkDriver.new()
	driver.record = record_tick
	driver.process_physics_priority = 100
	root.add_child(driver)
	driver.set_physics_process(false)
	for _frame in range(3):
		await process_frame
	Input.action_press(&"move_down")
	Input.action_press(&"move_right")
	player.set_physics_process(true)
	driver.set_physics_process(true)
	await driver.finished
	_release_input()
	player.set_physics_process(false)
	for _frame in range(3):
		await process_frame
	var maximum_slide: float = 0.0
	var maximum_move_error: float = 0.0
	for index in range(1, rows.size()):
		var previous: Dictionary = rows[index - 1]
		var current: Dictionary = rows[index]
		var movement: Vector2 = _vec(current["position"]) - _vec(previous["position"])
		maximum_move_error = maxf(maximum_move_error, (movement - TRAVEL_DIRECTION * 240.0 / FIXTURE_FPS).length())
		for foot_index in range(4):
			var before: Dictionary = previous["feet"][foot_index]
			var after: Dictionary = current["feet"][foot_index]
			if before["stance"] and after["stance"] and float(after["phase"]) > float(before["phase"]):
				maximum_slide = maxf(maximum_slide, (_vec(after["world"]) - _vec(before["world"])).length())
	var passed: bool = maximum_slide < 0.25 and maximum_move_error < 0.01 and rows.size() == 36
	var file := FileAccess.open(output.path_join("walk_probe.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed": passed, "mode": "Compatibility GPU, synthetic Input actions",
		"gpu": RenderingServer.get_video_adapter_name(), "engine": Engine.get_version_info()["string"],
		"resolution": [1280, 720], "physics_fps": FIXTURE_FPS, "move_speed": player.move_speed,
		"source_manifest_sha256": FileAccess.get_sha256(manifest_path),
		"fixture_sha256": FileAccess.get_sha256(get_script().resource_path),
		"max_stance_slide_per_tick_px": maximum_slide, "max_movement_error_per_tick_px": maximum_move_error,
		"rows": rows, "captures": captures,
		"limitations": "One direction/two cycles; projected sole markers, not image-inferred contacts; no physical controller, performance or art acceptance; no production integration"}, "\t"))
	file.close()
	if not passed:
		_fail("Actual movement/contact check failed; evidence preserved.")
		return
	print("PLAYER MESH WALK PROBE PASSED: 36 real player physics ticks, speed 240, max sole slide %f px" % maximum_slide)
	quit(0)


func record_tick(tick: int, delta: float) -> void:
	var frame_index: int = (tick - 1) % FRAME_COUNT
	sprite.texture = textures[frame_index]
	caption.text = "Route B v002 / walk %02d / tick %02d / 240 px/s — UNAPPROVED" % [frame_index, tick]
	var feet: Array[Dictionary] = []
	for foot: Dictionary in frames[frame_index]["feet"]:
		var world_point: Vector2 = sprite.to_global(_vec(foot["sole_native_px"]))
		feet.append({"id": foot["id"], "stance": foot["stance"], "phase": foot["phase"],
			"world": [world_point.x, world_point.y]})
	rows.append({"tick": tick, "delta": delta, "frame_index": frame_index,
		"position": [player.global_position.x, player.global_position.y], "feet": feet,
		"player_state": player.get_state_id(), "input_axes": [Input.get_axis(&"move_left", &"move_right"), Input.get_axis(&"move_up", &"move_down")]})
	if tick in [1, 9, 18, 27, 36]:
		call_deferred(&"_capture_later", tick)


func _capture_later(requested_tick: int) -> void:
	await RenderingServer.frame_post_draw
	var filename: String = "walk_tick_%02d.png" % requested_tick
	if root.get_texture().get_image().save_png(output.path_join(filename)) != OK:
		_fail("GPU screenshot write failed.")
		return
	captures.append({"file": filename, "requested_tick": requested_tick,
		"render_tick": driver.tick, "sha256": FileAccess.get_sha256(output.path_join(filename))})


func _vec(value: Array) -> Vector2:
	return Vector2(value[0], value[1])


func _install_contact_shadow() -> void:
	# Shared static comparison cue; not an animated sole-contact shadow.
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


func _release_input() -> void:
	Input.action_release(&"move_down")
	Input.action_release(&"move_right")


func _fail(message: String) -> void:
	_release_input()
	push_error("PLAYER MESH WALK PROBE: " + message)
	quit(1)
