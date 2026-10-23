extends SceneTree

const GAIT = preload("res://../tools/art/player_hybrid_gait.gd")
const MATRIX: Transform2D = Transform2D(Vector2(80, -30), Vector2(40, 60), Vector2.ZERO)
var failures: Array[String] = []
var cases: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 1:
		push_error("Expected new build JSON report path.")
		quit(1)
		return
	var path: String = args[0].replace("\\", "/").simplify_path()
	var build: String = ProjectSettings.globalize_path("res://../build").simplify_path()
	if not path.begins_with(build + "/") or FileAccess.file_exists(path):
		push_error("Use a new report strictly below build.")
		quit(1)
		return
	for mode: String in ["blocked", "straight", "reverse", "turn_in_place", "eight_directions"]:
		_motion_case(mode, 1.0 / 60.0)
	_motion_case("eight_directions", 1.0 / 30.0)
	_motion_case("eight_directions", 1.0 / 120.0)
	_teleport_case()
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed": failures.is_empty(), "cases": cases, "failures": failures,
		"scope": "online gait state invariants, not art/renderer acceptance",
		"source_sha256": FileAccess.get_sha256((GAIT as Script).resource_path)}, "\t"))
	file.close()
	print("HYBRID GAIT: %d cases / %d failures" % [cases.size(), failures.size()])
	for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)


func _motion_case(mode: String, delta: float) -> void:
	var gait: GAIT = GAIT.new()
	var position := Vector2.ZERO
	var facing := Vector2(1, 1)
	gait.configure(MATRIX, 60, position, facing)
	var prior: Array = []
	var comparisons: int = 0
	var slide: float = 0.0
	var state: Dictionary
	for step in range(roundi(6.0 / delta)):
		var t: float = step * delta
		var velocity := Vector2.ZERO
		if mode == "straight": velocity = facing.normalized() * 240
		elif mode == "reverse":
			facing = Vector2(1, 1) if fmod(t, 0.73) < 0.31 else Vector2(-1, -1)
			velocity = facing.normalized() * 240
		elif mode == "turn_in_place": facing = Vector2(-1, -1)
		elif mode == "eight_directions":
			facing = Vector2.RIGHT.rotated((floori(t / 0.37) % 8) * PI / 4)
			velocity = facing * (240.0 if fmod(t, 1.13) < 0.81 else 0.0)
		position += velocity * delta
		state = gait.advance(position, facing, delta)
		var feet: Array = state["feet"]
		_expect(feet.size() == 4, mode + ": four anatomical feet")
		for index in range(4):
			var foot: Dictionary = feet[index]
			_expect(Vector2(foot["sole"]).is_finite(), mode + ": finite contact")
			_expect(float(foot["lift"]) >= 0 and float(foot["lift"]) <= 7.00001, mode + ": bounded lift")
			if not prior.is_empty() and foot["stance"] and prior[index]["stance"] and foot["episode"] == prior[index]["episode"]:
				slide = maxf(slide, Vector2(foot["sole"]).distance_to(prior[index]["sole"]))
				comparisons += 1
		prior = feet
	for _step in range(ceili(2.0 / delta)): state = gait.advance(position, facing, delta)
	_expect(state["settled"], mode + ": settles after stop")
	var stopped: Array = state["feet"].duplicate(true)
	for _step in range(ceili(1.0 / delta)):
		state = gait.advance(position, facing, delta)
		for index in range(4):
			_expect(state["feet"][index]["stance"] and state["feet"][index]["episode"] == stopped[index]["episode"], mode + ": no idle marching")
	_expect(slide < 0.00001 and comparisons > 10, mode + ": actual stance anchors remain fixed")
	_expect(gait.maximum_reach_px < 100, mode + ": no runaway foot target")
	cases.append({"mode": mode, "physics_hz": 1.0 / delta, "stance_comparisons": comparisons,
		"max_stance_slide_px": slide, "max_reach_px": gait.maximum_reach_px, "settled": state["settled"]})


func _teleport_case() -> void:
	var gait: GAIT = GAIT.new()
	gait.configure(MATRIX, 60, Vector2.ZERO, Vector2.RIGHT)
	for step in range(20): gait.advance(Vector2(step * 4, 0), Vector2.RIGHT, 1.0 / 60)
	var position := Vector2(1000, -700)
	var state: Dictionary = gait.advance(position, Vector2.UP, 1.0 / 60)
	_expect(gait.reset_count == 2 and not state["moving"], "teleport: gait resets instead of dragging feet")
	for foot: Dictionary in state["feet"]:
		_expect(Vector2(foot["sole"]).distance_to(position) < 150, "teleport: foot local to new actor")
	cases.append({"mode": "teleport", "gait_resets": gait.reset_count})


func _expect(condition: bool, message: String) -> void:
	if not condition and message not in failures: failures.append(message)
