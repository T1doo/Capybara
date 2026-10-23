extends SceneTree

const WORLD_SCRIPT: Script = preload("res://../tools/art/player_motion_world.gd")
const TOTAL_TICKS: int = 3840

var main: GameBootstrap
var rows: Array[Dictionary] = []
var events: Array[Dictionary] = []
var output: String
var tick: int = 0
var previous: Vector2
var blocked_ticks: int = 0
var start_usec: int


class Driver extends Node:
	var callback: Callable
	func _physics_process(delta: float) -> void:
		callback.call(delta)


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 1:
		_fail("Expected a new build output directory.")
		return
	var build: String = ProjectSettings.globalize_path("res://../build").simplify_path()
	output = args[0].replace("\\", "/").simplify_path()
	if not output.begins_with(build + "/") or DirAccess.dir_exists_absolute(output):
		_fail("Output must be new and strictly in build.")
		return
	DirAccess.make_dir_recursive_absolute(output)
	Engine.physics_ticks_per_second = 60
	main = WORLD_SCRIPT.create(self) as GameBootstrap
	main.player.set_physics_process(false)
	main.player.interaction_completed.connect(_interaction)
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
	for _frame in range(4):
		await process_frame
	previous = main.player.global_position
	start_usec = Time.get_ticks_usec()
	main.player.set_physics_process(true)
	before.set_physics_process(true)
	after.set_physics_process(true)


func _before(_delta: float) -> void:
	WORLD_SCRIPT.apply_input(tick)


func _after(delta: float) -> void:
	var actor: PlayerCharacter = main.player
	var actual: Vector2 = actor.global_position - previous
	var axes: Vector2 = WORLD_SCRIPT.axes_at(tick)
	if axes.length() > 0 and actual.length() < 0.001:
		blocked_ticks += 1
	rows.append({"tick": tick, "delta": delta, "position": [actor.global_position.x, actor.global_position.y],
		"motion": [actual.x, actual.y], "axes": [axes.x, axes.y], "facing": actor.get_facing_id(),
		"state": actor.get_state_id(), "collisions": actor.get_slide_collision_count()})
	previous = actor.global_position
	tick += 1
	if tick >= TOTAL_TICKS:
		for action: StringName in [&"move_left", &"move_right", &"move_up", &"move_down"]:
			Input.action_release(action)
		actor.set_physics_process(false)
		var passed: bool = events.size() == 1 and blocked_ticks > 30 and get_nodes_in_group(&"player").size() == 1
		var result: Dictionary = {"passed": passed, "engine": Engine.get_version_info()["string"],
			"executed_at_utc": Time.get_datetime_string_from_system(true),
			"mode": "fixed-60Hz actual Player/Input/WorldZone/Bootstrap recording, not wall-clock soak",
			"duration_game_seconds": TOTAL_TICKS / 60.0, "wall_seconds": (Time.get_ticks_usec() - start_usec) / 1000000.0,
			"speed": actor.move_speed, "preview_scale": [actor.scale.x, actor.scale.y], "collider_radius": 22,
			"blocked_ticks": blocked_ticks, "events": events, "rows": rows,
			"world_script_sha256": FileAccess.get_sha256(WORLD_SCRIPT.resource_path),
			"recorder_sha256": FileAccess.get_sha256(get_script().resource_path)}
		var file := FileAccess.open(output.path_join("motion.json"), FileAccess.WRITE)
		file.store_string(JSON.stringify(result))
		file.close()
		if not passed:
			_fail("Recording did not cover committed pickup, collision and single Player.")
			return
		print("MOTION RECORD PASSED: 64 game seconds; %d blocked ticks, 1 committed pickup" % blocked_ticks)
		quit(0)


func _interaction(result: InteractionResult) -> void:
	if result.is_success() and result.payload.get(&"item_id") == &"item_branch":
		events.append({"tick": tick, "kind": "committed_pickup", "quantity": result.payload.get(&"quantity")})


func _fail(message: String) -> void:
	push_error("MOTION RECORD: " + message)
	quit(1)
