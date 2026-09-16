extends SceneTree

const CASES: Script = preload("res://tests/hotbar_remap_test_cases.gd")
var failures: int = 0
var checks: int = 0


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	CASES.run(root.get_node("ContentRegistry"), _check)
	var main: Node = load("res://scenes/bootstrap/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	CASES.run_runtime(self, main, _check)
	print("HOTBAR REGRESSION: %d/%d failed" % [failures, checks])
	quit(0 if failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("FAIL: " + label)
