extends SceneTree

const WORLD_SCRIPT: Script = preload("res://../tools/art/player_motion_world.gd")
const TEXTURE_LIMIT: int = 24

var main: GameBootstrap
var manifest: Dictionary
var record: Dictionary
var base: String
var output: String
var smoke: bool = false
var static_atmospheres: bool = false
var tick: int = 0
var sprite: Sprite2D
var camera: Camera2D
var caption: Label
var atmosphere: HomeAtmosphere2D
var textures: Dictionary[int, Texture2D] = {}
var lru: Array[int] = []
var frame_map: Dictionary[int, Dictionary] = {}
var shadows: Array[Polygon2D] = []
var maximum_position_error: float = 0.0
var pickup_count: int = 0
var captured: Array[Dictionary] = []
var start_usec: int
var done: bool = false
var failed: bool = false


class Driver extends Node:
	var callback: Callable
	func _physics_process(delta: float) -> void:
		callback.call(delta)


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		_fail("Use the actual Compatibility GPU renderer.")
		return
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 3:
		_fail("Expected bank manifest, motion JSON and a new build output directory.")
		return
	var build: String = ProjectSettings.globalize_path("res://../build").simplify_path()
	for index in range(3):
		args[index] = args[index].replace("\\", "/").simplify_path()
	for path: String in args.slice(0, 3):
		if not path.replace("\\", "/").simplify_path().begins_with(build + "/"):
			_fail("All inputs/outputs must remain in build.")
			return
	base = args[0].get_base_dir()
	output = args[2]
	smoke = args.size() > 3 and args[3] == "--smoke"
	static_atmospheres = args.size() > 3 and args[3] == "--atmospheres"
	if DirAccess.dir_exists_absolute(output):
		_fail("Refusing to overwrite review evidence.")
		return
	manifest = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	record = JSON.parse_string(FileAccess.get_file_as_string(args[1]))
	if FileAccess.get_sha256(args[1]) != manifest["motion_sha256"] or (not manifest.get("complete", false) and not smoke) or manifest["timeline"].size() != 3840:
		_fail("Expected matching motion and a completed pose bank.")
		return
	for frame: Dictionary in manifest["frames"]:
		frame_map[int(frame["pose_index"])] = frame
	DirAccess.make_dir_recursive_absolute(output)
	var source_copy := FileAccess.open(output.path_join("viewer_source.gd"), FileAccess.WRITE)
	source_copy.store_string(FileAccess.get_file_as_string(get_script().resource_path))
	source_copy.close()
	root.size = Vector2i(1280, 720)
	Engine.physics_ticks_per_second = 60
	var settings := root.get_node("SettingsService") as SettingsManagerService
	var profile := SettingsProfile.new()
	profile.reduced_motion = true
	settings.replace_settings(profile)
	settings.apply_current_settings(false)
	main = WORLD_SCRIPT.create(self) as GameBootstrap
	main.player.set_physics_process(false)
	main.player.interaction_completed.connect(func(result: InteractionResult) -> void:
		if result.is_success(): pickup_count += 1
	)
	for name: String in ["Body", "Snout", "FacingMarker", "Shadow"]:
		(main.player.get_node(name) as CanvasItem).hide()
	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.scale = Vector2.ONE * float(manifest["display_scale"]) / main.player.scale.x
	sprite.position = -Vector2(manifest["pivot"][0], manifest["pivot"][1]) * sprite.scale
	main.player.add_child(sprite)
	camera = Camera2D.new()
	main.add_child(camera)
	camera.position = Vector2(0, -96)
	var layer := CanvasLayer.new()
	layer.layer = 20
	root.add_child(layer)
	caption = Label.new()
	caption.position = Vector2(20, 20)
	caption.add_theme_color_override("font_color", Color.WHITE)
	caption.add_theme_color_override("font_shadow_color", Color.BLACK)
	caption.add_theme_constant_override("shadow_offset_x", 2)
	caption.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(caption)
	var flow := root.get_node("SceneFlowService") as SceneFlowCoordinator
	atmosphere = HomeAtmosphere2D.new()
	flow.current_zone.add_child(atmosphere)
	for _index in range(4):
		var shadow := Polygon2D.new()
		var points := PackedVector2Array()
		for index in range(24):
			var angle: float = TAU * index / 24.0
			points.append(Vector2(cos(angle) * 8, sin(angle) * 3))
		shadow.polygon = points
		shadow.color = Color(0.12, 0.11, 0.07, 0.16)
		shadow.z_as_relative = false
		shadow.z_index = 49
		flow.current_zone.add_child(shadow)
		shadows.append(shadow)
	if static_atmospheres:
		main.player.restore_runtime_state(Vector2.ZERO, &"down_right")
		_show_pose(0)
		for preset: StringName in HomeAtmosphere2D.PRESETS:
			atmosphere.set_preset(preset)
			caption.text = "v004 / fixed pose / %s — TECHNICAL CANDIDATE" % preset
			for _frame in range(3): await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output.path_join(String(preset) + ".png"))
		print("MOTION STATIC ATMOSPHERES CAPTURED: 4 fixed-pose GPU views; unapproved")
		quit(0)
		return
	var before := Driver.new()
	before.callback = _before
	before.process_physics_priority = -100
	root.add_child(before)
	before.set_physics_process(false)
	var after := Driver.new()
	after.callback = _after
	after.process_physics_priority = 100
	root.add_child(after)
	after.set_physics_process(false)
	_show_pose(0)
	for _frame in range(4):
		await process_frame
	start_usec = Time.get_ticks_usec()
	main.player.set_physics_process(true)
	before.set_physics_process(true)
	after.set_physics_process(true)


func _before(_delta: float) -> void:
	if done: return
	WORLD_SCRIPT.apply_input(tick)


func _after(_delta: float) -> void:
	if done: return
	var expected: Dictionary = record["rows"][tick]
	var position: Vector2 = Vector2(expected["position"][0], expected["position"][1])
	maximum_position_error = maxf(maximum_position_error, main.player.global_position.distance_to(position))
	if maximum_position_error > 0.01 or main.player.get_facing_id() != StringName(expected["facing"]):
		_fail("Replay diverged at tick %d: actual %s expected %s" % [tick, main.player.global_position, position])
		return
	var pose_index: int = int(manifest["timeline"][tick]["pose"])
	_show_pose(0 if smoke else pose_index)
	camera.force_update_scroll()
	var mode: StringName = &"clear_morning"
	if tick >= 1920 and tick < 2400: mode = &"sunset"
	elif tick >= 2400 and tick < 2880: mode = &"rain"
	elif tick >= 2880 and tick < 3360: mode = &"night"
	if mode != atmosphere.preset: atmosphere.set_preset(mode)
	caption.text = "v004 / %.2fs / %s / 240 px/s / %s — TECHNICAL CANDIDATE" % [tick / 60.0, expected["facing"], mode]
	if int(manifest["poses"][pose_index]["dip"] * 100) > 0:
		caption.text += " / committed pickup"
	if expected["axes"] != [0.0, 0.0] and Vector2(expected["motion"][0], expected["motion"][1]).length() < .001:
		caption.text += " / blocked by wall"
	if tick in [60, 267, 420, 650, 840, 2100, 2580, 3060]:
		call_deferred(&"_capture", tick)
	tick += 1
	if tick >= (120 if smoke else 3840):
		done = true
		main.player.set_physics_process(false)
		call_deferred(&"_finish")


func _show_pose(index: int) -> void:
	if not frame_map.has(index):
		_fail("Missing rendered pose %d" % index)
		return
	if not textures.has(index):
		var path: String = base.path_join(frame_map[index]["path"]).simplify_path()
		if not path.begins_with(base + "/") or FileAccess.get_sha256(path) != frame_map[index]["sha256"]:
			_fail("Frame path/hash mismatch.")
			return
		var image := Image.load_from_file(path)
		textures[index] = ImageTexture.create_from_image(image)
	lru.erase(index)
	lru.append(index)
	while lru.size() > TEXTURE_LIMIT:
		textures.erase(lru.pop_front())
	sprite.texture = textures[index]
	for foot in range(4):
		var marker: Array = frame_map[index]["soles"][foot]
		var point: Vector2 = sprite.to_global(Vector2(marker[0], marker[1]))
		var height: float = float(manifest["poses"][index]["feet"][foot][2]) * float(manifest["height_scale"])
		shadows[foot].global_position = point + Vector2(0, height)
		shadows[foot].modulate.a = 1.0 / (1.0 + height * .15)


func _capture(requested_tick: int) -> void:
	await RenderingServer.frame_post_draw
	var filename: String = "frame_%04d.png" % requested_tick
	root.get_texture().get_image().save_png(output.path_join(filename))
	captured.append({"file": filename, "requested_tick": requested_tick, "render_tick": tick - 1})


func _finish() -> void:
	for action: StringName in [&"move_left", &"move_right", &"move_up", &"move_down"]:
		Input.action_release(action)
	for _frame in range(2): await process_frame
	if failed: return
	var circle := (main.player.get_node("CollisionShape2D") as CollisionShape2D).shape as CircleShape2D
	var passed: bool = smoke or (pickup_count == 1 and circle.radius == 22 and main.player.move_speed == 240)
	var file := FileAccess.open(output.path_join("playback.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed": passed, "smoke_only": smoke, "ticks": tick,
		"maximum_position_error_px": maximum_position_error, "committed_pickups": pickup_count,
		"radius": circle.radius, "scale": [main.player.scale.x, main.player.scale.y],
		"move_speed": main.player.move_speed, "safe_margin": main.player.safe_margin,
		"wall_seconds": (Time.get_ticks_usec() - start_usec) / 1000000.0,
		"gpu": RenderingServer.get_video_adapter_name(), "texture_cache_limit": TEXTURE_LIMIT,
		"world_script_sha256": FileAccess.get_sha256(WORLD_SCRIPT.resource_path),
		"viewer_sha256": FileAccess.get_sha256(get_script().resource_path),
		"camera_position": [0, -96], "camera_zoom": 1,
		"mode": "Compatibility GPU, fixed 60Hz movie/replay; not a performance/soak benchmark",
		"captures": captured, "scope": "candidate sample; no mother/route/Stage3 acceptance"}, "\t"))
	file.close()
	print("MOTION PLAYBACK PASSED: %d ticks, max position error %f px" % [tick, maximum_position_error])
	quit(0 if passed else 1)


func _fail(message: String) -> void:
	done = true
	failed = true
	push_error("MOTION PLAYBACK: " + message)
	quit(1)
