extends SceneTree

const WORLD_SCRIPT: Script = preload("res://../tools/art/player_motion_world.gd")
const VISUAL_SCRIPT = preload("res://../tools/art/player_hybrid_visual.gd")
const TOTAL_TICKS: int = 3840

var main: GameBootstrap
var visual: VISUAL_SCRIPT
var camera: Camera2D
var atmosphere: HomeAtmosphere2D
var caption: Label
var output: String
var manifest_path: String
var tick: int = 0
var smoke: bool = false
var interactive: bool = false
var done: bool = false
var start_usec: int
var previous_position: Vector2
var rows: Array[Dictionary] = []
var captures: Array[Dictionary] = []
var headings_seen: Dictionary[int, bool] = {}
var facing_seen: Dictionary[StringName, bool] = {}
var blocked_ticks: int = 0
var maximum_marker_error: float = 0.0
var initial_branch_count: int = 0


class Driver extends Node:
	var callback: Callable
	func _physics_process(delta: float) -> void:
		callback.call(delta)


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		_fail("Actual Compatibility GPU required.")
		return
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 2:
		_fail("Expected hybrid manifest, new build output, optional --smoke or --interactive.")
		return
	var build: String = ProjectSettings.globalize_path("res://../build").simplify_path()
	manifest_path = args[0].replace("\\", "/").simplify_path()
	output = args[1].replace("\\", "/").simplify_path()
	if not manifest_path.begins_with(build + "/") or not output.begins_with(build + "/") or DirAccess.dir_exists_absolute(output):
		_fail("Use existing input and NEW output strictly below build.")
		return
	smoke = args.size() > 2 and args[2] == "--smoke"
	interactive = args.size() > 2 and args[2] == "--interactive"
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280, 720)
	Engine.physics_ticks_per_second = 60
	var settings := root.get_node("SettingsService") as SettingsManagerService
	var profile := SettingsProfile.new()
	profile.reduced_motion = true
	settings.replace_settings(profile)
	settings.apply_current_settings(false)
	main = WORLD_SCRIPT.create(self) as GameBootstrap
	initial_branch_count = (root.get_node("InventoryService") as InventoryCoordinator).player_inventory.count_item(&"item_branch")
	main.player.set_physics_process(false)
	for name: String in ["Body", "Snout", "FacingMarker", "Shadow"]:
		(main.player.get_node(name) as CanvasItem).hide()
	visual = VISUAL_SCRIPT.new()
	main.player.add_child(visual)
	if visual.configure(main.player, manifest_path) != OK:
		_fail("Invalid plate manifest/hash/pixel data.")
		return
	for source: String in [get_script().resource_path, visual.get_script().resource_path, visual.gait.get_script().resource_path]:
		var copy := FileAccess.open(output.path_join(source.get_file()), FileAccess.WRITE)
		copy.store_buffer(FileAccess.get_file_as_bytes(source))
	visual.set_physics_process(false)
	visual._physics_process(1.0 / 60.0)
	camera = Camera2D.new()
	main.add_child(camera)
	camera.position = Vector2(0, -96)
	var layer := CanvasLayer.new()
	layer.layer = 20
	root.add_child(layer)
	caption = Label.new()
	caption.position = Vector2(20, 20)
	caption.add_theme_color_override("font_shadow_color", Color.BLACK)
	caption.add_theme_constant_override("shadow_offset_x", 2)
	caption.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(caption)
	var flow := root.get_node("SceneFlowService") as SceneFlowCoordinator
	atmosphere = HomeAtmosphere2D.new()
	flow.current_zone.add_child(atmosphere)
	var before := Driver.new()
	before.process_physics_priority = -100
	before.callback = _before
	root.add_child(before)
	before.set_physics_process(false)
	var after := Driver.new()
	after.process_physics_priority = 200
	after.callback = _after
	root.add_child(after)
	after.set_physics_process(false)
	for _frame in range(4): await process_frame
	previous_position = main.player.global_position
	start_usec = Time.get_ticks_usec()
	main.player.set_physics_process(true)
	visual.set_physics_process(true)
	before.set_physics_process(true)
	after.set_physics_process(true)


func _before(_delta: float) -> void:
	if done or interactive: return
	if tick < 330:
		WORLD_SCRIPT.apply_input(tick)
		return
	var axes: Vector2 = _axes(tick)
	for entry: Array in [[&"move_left", axes.x < 0], [&"move_right", axes.x > 0], [&"move_up", axes.y < 0], [&"move_down", axes.y > 0]]:
		if entry[1]: Input.action_press(entry[0])
		else: Input.action_release(entry[0])


func _axes(at: int) -> Vector2:
	if at == 330 or (at >= 414 and at < 431) or (at >= 442 and at < 450): return Vector2(-1, -1)
	if (at >= 431 and at < 442) or (at >= 450 and at < 464): return Vector2(1, 1)
	if at >= 464 and at < 486: return Vector2.RIGHT
	if at < 486: return Vector2.ZERO
	var phase: int = (at - 486) % 914
	if phase < 120: return Vector2.RIGHT
	if phase < 484:
		var section: int = (phase - 120) / 91
		var offset: int = (phase - 120) % 91
		if offset == 0 or offset >= 61:
			return [Vector2.LEFT, Vector2.UP, Vector2.RIGHT, Vector2.DOWN][section]
		return Vector2.ZERO
	if phase < 504: return Vector2.ZERO
	if phase < 844:
		var section: int = (phase - 504) / 85
		var offset: int = (phase - 504) % 85
		if offset == 0 or offset >= 61:
			return [Vector2(-1, 1), Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1)][section]
	return Vector2.ZERO


func _after(delta: float) -> void:
	if done: return
	var position: Vector2 = main.player.global_position
	var motion: Vector2 = position - previous_position
	previous_position = position
	var axes: Vector2 = WORLD_SCRIPT.axes_at(tick) if tick < 330 else _axes(tick)
	if not interactive and not axes.is_zero_approx() and motion.length() < 0.001: blocked_ticks += 1
	headings_seen[visual.body_heading] = true
	facing_seen[main.player.get_facing_id()] = true
	if interactive: camera.global_position = position + Vector2(0, -96)
	caption.text = "v005 LIVE displacement / %s / heading %02d / %s — UNAPPROVED" % [main.player.get_facing_id(), visual.body_heading, "free input" if interactive else "%.2fs" % (tick / 60.0)]
	if not interactive:
		var soles: Array[Vector2] = visual.sample_drawn_soles()
		var feet: Array[Dictionary] = []
		for index in range(4):
			var foot: Dictionary = visual.state["feet"][index]
			var target: Vector2 = foot["sole"]
			if not soles[index].is_finite():
				_fail("Authored sole lies outside rendered mesh UV triangles.")
				return
			maximum_marker_error = maxf(maximum_marker_error, soles[index].distance_to(target))
			feet.append({"stance": foot["stance"], "episode": foot["episode"], "lift": foot["lift"],
				"drawn_sole": [soles[index].x, soles[index].y], "requested_sole": [target.x, target.y]})
		rows.append({"tick": tick, "delta": delta, "position": [position.x, position.y],
			"motion": [motion.x, motion.y], "axes": [axes.x, axes.y], "facing": main.player.get_facing_id(),
			"heading": visual.body_heading, "yaw": visual.state["yaw"], "settled": visual.state["settled"], "feet": feet})
		if tick in [60, 150, 267, 365, 410, 440, 530, 680, 770, 860, 950, 1060, 1145, 1230, 1315, 2100, 2600, 3100, 3800]:
			call_deferred(&"_capture", tick)
		var mode: StringName = &"clear_morning"
		if tick >= 1920 and tick < 2400: mode = &"sunset"
		elif tick >= 2400 and tick < 2880: mode = &"rain"
		elif tick >= 2880 and tick < 3360: mode = &"night"
		if atmosphere.preset != mode: atmosphere.set_preset(mode)
	tick += 1
	if not interactive and tick >= (1400 if smoke else TOTAL_TICKS):
		done = true
		main.player.set_physics_process(false)
		visual.set_physics_process(false)
		call_deferred(&"_finish")


func _capture(requested: int) -> void:
	await RenderingServer.frame_post_draw
	var filename: String = "frame_%04d.png" % requested
	root.get_texture().get_image().save_png(output.path_join(filename))
	captures.append({"file": filename, "requested_tick": requested, "render_tick": tick - 1})


func _finish() -> void:
	for action: StringName in [&"move_left", &"move_right", &"move_up", &"move_down"]: Input.action_release(action)
	for _frame in range(2): await process_frame
	var circle := (main.player.get_node("CollisionShape2D") as CollisionShape2D).shape as CircleShape2D
	var inventory_delta: int = (root.get_node("InventoryService") as InventoryCoordinator).player_inventory.count_item(&"item_branch") - initial_branch_count
	var flow := root.get_node("SceneFlowService") as SceneFlowCoordinator
	var pickup := flow.current_zone.find_interactable(&"pickup_motion_study_branch") as PickupInteractable
	var pickup_visual_consumed: bool = pickup.quantity == 0 and is_instance_valid(pickup.visual) and not pickup.visual.visible
	var passed: bool = visual.pickup_count == 1 and facing_seen.size() == 8 and blocked_ticks > 30 and maximum_marker_error < 0.02
	passed = passed and main.player.move_speed == 240 and circle.radius == 22
	passed = passed and inventory_delta == 1 and pickup_visual_consumed
	var file := FileAccess.open(output.path_join("live_motion.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed": passed, "ticks": tick, "nominal_seconds": tick / 60.0,
		"smoke_only": smoke, "world_seconds": (Time.get_ticks_usec() - start_usec) / 1000000.0,
		"blocked_ticks": blocked_ticks, "facings": facing_seen.keys(), "headings": headings_seen.keys(),
		"maximum_drawn_marker_error_px": maximum_marker_error, "maximum_ankle_reach_px": visual.gait.maximum_reach_px,
		"texture_bytes": visual.texture_bytes, "textures": visual.images.size(), "pickup_count": visual.pickup_count,
		"unsupported_pickups": visual.unsupported_pickup_count, "gait_resets": visual.gait.reset_count,
		"inventory_delta": inventory_delta, "pickup_visual_consumed": pickup_visual_consumed,
		"pickup_script_sha256": FileAccess.get_sha256(pickup.get_script().resource_path),
		"speed": main.player.move_speed, "radius": circle.radius, "scale": [main.player.scale.x, main.player.scale.y],
		"safe_margin": main.player.safe_margin, "world_sha256": FileAccess.get_sha256(WORLD_SCRIPT.resource_path),
		"player_sha256": FileAccess.get_sha256(main.player.get_script().resource_path),
		"gpu": RenderingServer.get_video_adapter_name(), "manifest_sha256": FileAccess.get_sha256(manifest_path),
		"gait_sha256": FileAccess.get_sha256(visual.gait.get_script().resource_path),
		"visual_sha256": FileAccess.get_sha256(visual.get_script().resource_path),
		"driver_sha256": FileAccess.get_sha256(get_script().resource_path), "captures": captures, "rows": rows,
		"scope": "live candidate driven by actual Player; authored UV sole markers, not image-inferred contact; no visual approval"}))
	file.close()
	print("HYBRID LIVE SAMPLE: %s; %d ticks / %d facings / %d blocked" % [passed, tick, facing_seen.size(), blocked_ticks])
	quit(0 if passed else 1)


func _fail(message: String) -> void:
	done = true
	push_error("HYBRID CANDIDATE: " + message)
	quit(1)
