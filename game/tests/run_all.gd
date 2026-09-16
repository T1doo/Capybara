extends SceneTree

const PLAYER_LOGIC_TEST_CASES: Script = preload("res://tests/player_logic_test_cases.gd")

const DEBUG_OVERLAY_TEST_CASES: Script = preload("res://tests/debug_overlay_test_cases.gd")
const DISPLAY_MATRIX_TEST_CASES: Script = preload("res://tests/display_matrix_test_cases.gd")
const CONTENT_REGISTRY_TEST_CASES: Script = preload("res://tests/content_registry_test_cases.gd")
const INTERACTION_TEST_CASES: Script = preload("res://tests/interaction_test_cases.gd")
const INTERACTION_COMMIT_TEST_CASES: Script = preload("res://tests/interaction_commit_test_cases.gd")
const INPUT_DEVICE_TEST_CASES: Script = preload("res://tests/input_device_test_cases.gd")
const HOME_VISUAL_BLOCKOUT_TEST_CASES: Script = preload("res://tests/home_visual_blockout_test_cases.gd")
const INVENTORY_TEST_CASES: Script = preload("res://tests/inventory_test_cases.gd")
const HOTBAR_REMAP_TEST_CASES: Script = preload("res://tests/hotbar_remap_test_cases.gd")
const INVENTORY_UI_TEST_CASES: Script = preload("res://tests/inventory_ui_test_cases.gd")
const INVENTORY_SERIALIZATION_TEST_CASES: Script = preload(
	"res://tests/inventory_serialization_test_cases.gd"
)
const MAIN_SCENE: PackedScene = preload("res://scenes/bootstrap/main.tscn")
const REAL_SCENE_FLOW_TEST_CASES: Script = preload("res://tests/real_scene_flow_test_cases.gd")
const SAVE_MANAGER_TEST_CASES: Script = preload("res://tests/save_manager_test_cases.gd")
const SAVE_UI_TEST_CASES: Script = preload("res://tests/save_ui_test_cases.gd")
const SETTINGS_TEST_CASES: Script = preload("res://tests/settings_test_cases.gd")
const STORAGE_UI_TEST_CASES: Script = preload("res://tests/storage_ui_test_cases.gd")
const RUNTIME_SAVE_TEST_CASES: Script = preload("res://tests/runtime_save_test_cases.gd")
const SCENE_FLOW_TEST_CASES: Script = preload("res://tests/scene_flow_test_cases.gd")
const WORLD_INTERACTABLE_TEST_CASES: Script = preload("res://tests/world_interactable_test_cases.gd")

var test_count: int = 0
var failure_count: int = 0


func _init() -> void:
	call_deferred(&"_run_tests")


func _run_tests() -> void:
	var settings_service := root.get_node("SettingsService") as SettingsManagerService
	settings_service.replace_settings(SettingsProfile.new())
	settings_service.apply_current_settings(false)
	PLAYER_LOGIC_TEST_CASES.run(_assert_true, _assert_int_equal, _assert_float_approx, _assert_vector_approx)
	CONTENT_REGISTRY_TEST_CASES.run(_assert_true, _assert_int_equal)
	INVENTORY_TEST_CASES.run(_assert_true, _assert_int_equal)
	HOTBAR_REMAP_TEST_CASES.run(root.get_node("ContentRegistry"), _assert_true)
	INVENTORY_SERIALIZATION_TEST_CASES.run(_assert_true, _assert_int_equal)
	SAVE_MANAGER_TEST_CASES.run(_assert_true, _assert_int_equal)
	SETTINGS_TEST_CASES.run(_assert_true, _assert_int_equal)
	INTERACTION_TEST_CASES.run(_assert_true, _assert_int_equal, _assert_float_approx)
	INPUT_DEVICE_TEST_CASES.run(_assert_true, _assert_int_equal)
	WORLD_INTERACTABLE_TEST_CASES.run(_assert_true, _assert_int_equal)
	SCENE_FLOW_TEST_CASES.run(root, _assert_true, _assert_int_equal)
	await _test_phase_zero_scene()
	await HOME_VISUAL_BLOCKOUT_TEST_CASES.run(self, _assert_true, _assert_int_equal, _assert_vector_approx)

	if failure_count == 0:
		print("CAPYBARA TESTS PASSED: %d/%d" % [test_count, test_count])
		quit(0)
		return

	push_error("CAPYBARA TESTS FAILED: %d/%d failed" % [failure_count, test_count])
	quit(1)


func _test_phase_zero_scene() -> void:
	var main_scene := MAIN_SCENE.instantiate() as GameBootstrap
	root.add_child(main_scene)
	await process_frame

	var player := main_scene.get_node("Player") as CharacterBody2D
	HOTBAR_REMAP_TEST_CASES.run_runtime(self, main_scene, _assert_true)
	INTERACTION_COMMIT_TEST_CASES.run(self, main_scene, _assert_true)
	INVENTORY_UI_TEST_CASES.run(self, main_scene, _assert_true, _assert_int_equal)
	await SETTINGS_TEST_CASES.run_runtime(
		self,
		main_scene,
		_assert_true,
		_assert_float_approx
	)
	STORAGE_UI_TEST_CASES.run(self, main_scene, _assert_true, _assert_int_equal)
	await DISPLAY_MATRIX_TEST_CASES.run(self, main_scene, _assert_true)
	RUNTIME_SAVE_TEST_CASES.run(
		self,
		main_scene,
		_assert_true,
		_assert_int_equal,
		_assert_vector_approx
	)
	SAVE_UI_TEST_CASES.run(self, main_scene, _assert_true, _assert_int_equal, _assert_vector_approx)
	var joy_axis_event := InputEventJoypadMotion.new()
	joy_axis_event.axis = JOY_AXIS_LEFT_Y
	joy_axis_event.axis_value = 1.0
	_assert_true(
		InputMap.action_has_event(&"move_down", joy_axis_event),
		"left stick down is registered"
	)
	var dpad_event := InputEventJoypadButton.new()
	dpad_event.button_index = JOY_BUTTON_DPAD_DOWN
	_assert_true(
		InputMap.action_has_event(&"move_down", dpad_event),
		"D-pad down is registered"
	)
	var interact_key_event := InputEventKey.new()
	interact_key_event.keycode = KEY_E
	_assert_true(
		InputMap.action_has_event(&"interact", interact_key_event),
		"E interaction key is registered"
	)
	var interact_button_event := InputEventJoypadButton.new()
	interact_button_event.button_index = JOY_BUTTON_A
	_assert_true(
		InputMap.action_has_event(&"interact", interact_button_event),
		"controller south interaction button is registered"
	)
	var debug_key_event := InputEventKey.new()
	debug_key_event.keycode = KEY_F3
	_assert_true(
		InputMap.action_has_event(&"toggle_debug_overlay", debug_key_event),
		"F3 debug overlay key is registered"
	)
	var hotbar_previous_button := InputEventJoypadButton.new()
	hotbar_previous_button.button_index = JOY_BUTTON_LEFT_SHOULDER
	_assert_true(
		InputMap.action_has_event(&"hotbar_previous", hotbar_previous_button),
		"left shoulder hotbar selection is registered"
	)
	var hotbar_next_key := InputEventKey.new()
	hotbar_next_key.keycode = KEY_R
	_assert_true(
		InputMap.action_has_event(&"hotbar_next", hotbar_next_key),
		"R hotbar selection is registered"
	)
	await REAL_SCENE_FLOW_TEST_CASES.run(
		self,
		main_scene,
		player,
		_assert_true,
		_assert_int_equal,
		_assert_vector_approx
	)
	DEBUG_OVERLAY_TEST_CASES.run(main_scene, debug_key_event, _assert_true)

	var starting_position := player.position
	Input.action_press(&"move_right", 1.0)
	for _frame_index in range(10):
		await physics_frame
	Input.action_release(&"move_right")
	_assert_true(player.position.x > starting_position.x, "player moves right in the real scene")
	_assert_int_equal(
		player.call(&"get_state"),
		PlayerStateMachine.State.MOVE,
		"real player enters Move while movement input is held"
	)
	_assert_int_equal(
		player.call(&"get_facing"),
		Direction8.Value.RIGHT,
		"real player stores an eight-direction facing"
	)
	var last_direction: Vector2 = player.call(&"get_last_move_direction")
	_assert_vector_approx(last_direction, Vector2.RIGHT, "real player saves the last direction")
	await physics_frame
	_assert_int_equal(
		player.call(&"get_state"),
		PlayerStateMachine.State.IDLE,
		"real player returns to Idle after movement input is released"
	)

	var interaction_start_position := player.position
	_assert_true(player.call(&"begin_interaction"), "player can begin an interaction from Idle")
	Input.action_press(&"move_right", 1.0)
	for _frame_index in range(5):
		await physics_frame
	Input.action_release(&"move_right")
	_assert_vector_approx(
		player.position,
		interaction_start_position,
		"Interact state blocks movement"
	)
	_assert_true(player.call(&"end_interaction"), "player can end an active interaction")
	_assert_true(player.call(&"set_disabled", true), "player can enter Disabled")
	_assert_true(not player.call(&"begin_interaction"), "Disabled player cannot begin interaction")
	_assert_true(player.call(&"set_disabled", false), "player can leave Disabled for Idle")

	player.position = Vector2(900.0, 0.0)
	player.velocity = Vector2.ZERO
	Input.action_press(&"move_right", 1.0)
	for _frame_index in range(30):
		await physics_frame
	Input.action_release(&"move_right")
	_assert_true(player.position.x <= 907.0, "player stops at the right world boundary")

	var pause_menu := main_scene.get_node("Interface/PauseMenu") as PauseMenu
	var escape_event := InputEventKey.new()
	escape_event.keycode = KEY_ESCAPE
	escape_event.pressed = true
	pause_menu.call(&"_input", escape_event)
	_assert_true(paused and pause_menu.visible, "Escape opens and pauses the real scene")
	_assert_true(pause_menu.continue_button.has_focus(), "pause menu focuses Continue by default")
	pause_menu.call(&"_input", escape_event)
	_assert_true(not paused and not pause_menu.visible, "Escape resumes the real scene")
	var start_button_event := InputEventJoypadButton.new()
	start_button_event.button_index = JOY_BUTTON_START
	start_button_event.pressed = true
	pause_menu.call(&"_input", start_button_event)
	_assert_true(paused and pause_menu.visible, "controller Start pauses the real scene")
	pause_menu.call(&"_input", start_button_event)
	_assert_true(not paused and not pause_menu.visible, "controller Start resumes the real scene")

	main_scene.queue_free()
	await process_frame


func _assert_vector_approx(actual: Vector2, expected: Vector2, test_name: String) -> void:
	test_count += 1
	if actual.is_equal_approx(expected):
		print("PASS: %s" % test_name)
		return
	_record_failure(test_name, str(expected), str(actual))


func _assert_float_approx(actual: float, expected: float, test_name: String) -> void:
	test_count += 1
	if is_equal_approx(actual, expected):
		print("PASS: %s" % test_name)
		return
	_record_failure(test_name, str(expected), str(actual))


func _assert_true(condition: bool, test_name: String) -> void:
	test_count += 1
	if condition:
		print("PASS: %s" % test_name)
		return
	_record_failure(test_name, "true", "false")


func _assert_int_equal(actual: int, expected: int, test_name: String) -> void:
	test_count += 1
	if actual == expected:
		print("PASS: %s" % test_name)
		return
	_record_failure(test_name, str(expected), str(actual))


func _record_failure(test_name: String, expected: String, actual: String) -> void:
	failure_count += 1
	push_error("FAIL: %s | expected=%s actual=%s" % [test_name, expected, actual])
