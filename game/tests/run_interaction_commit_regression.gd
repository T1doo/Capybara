extends SceneTree

const CASES: Script = preload("res://tests/interaction_commit_test_cases.gd")
var failures: int = 0
var checks: int = 0


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	preload("res://tests/world_interactable_test_cases.gd").run(_check, _check_int)
	var main := load("res://scenes/bootstrap/main.tscn").instantiate() as GameBootstrap
	root.add_child(main)
	await process_frame
	CASES.run(self, main, _check)
	print("INTERACTION COMMIT REGRESSION: %d/%d failed" % [failures, checks])
	quit(0 if failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("FAIL: " + label)


func _check_int(actual: int, expected: int, label: String) -> void:
	_check(actual == expected, label)
