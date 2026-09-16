class_name PlayerLogicTestCases
extends RefCounted

const DIRECTION_8_SCRIPT: Script = preload("res://core/direction_8.gd")
const MOVEMENT_MATH_SCRIPT: Script = preload("res://core/movement_math.gd")
const PLAYER_STATE_MACHINE_SCRIPT: Script = preload("res://scenes/player/player_state_machine.gd")


static func run(
	_assert_true: Callable, _assert_int_equal: Callable,
	_assert_float_approx: Callable, _assert_vector_approx: Callable
) -> void:
	# cardinal_axis_conversion
	_assert_vector_approx.call(
		MOVEMENT_MATH_SCRIPT.direction_from_axes(-1.0, 0.0),
		Vector2.LEFT,
		"horizontal input converts to left"
	)

	# axis_values_are_clamped
	_assert_vector_approx.call(
		MOVEMENT_MATH_SCRIPT.direction_from_axes(2.0, 0.0),
		Vector2.RIGHT,
		"axis values are clamped"
	)

	# diagonal_input_is_normalized
	var direction: Vector2 = MOVEMENT_MATH_SCRIPT.direction_from_axes(1.0, 1.0)
	_assert_float_approx.call(direction.length(), 1.0, "diagonal speed is normalized")

	# subunit_input_is_preserved
	var analog_input := Vector2(0.25, 0.5)
	_assert_vector_approx.call(
		MOVEMENT_MATH_SCRIPT.normalize_input(analog_input),
		analog_input,
		"subunit analog input keeps its magnitude"
	)

	# zero_input_is_preserved
	_assert_vector_approx.call(
		MOVEMENT_MATH_SCRIPT.normalize_input(Vector2.ZERO),
		Vector2.ZERO,
		"zero input remains zero"
	)

	# zero_input_keeps_last_direction
	_assert_vector_approx.call(
		MOVEMENT_MATH_SCRIPT.select_last_non_zero_direction(Vector2.UP, Vector2.ZERO),
		Vector2.UP,
		"zero input keeps the last direction"
	)

	# non_zero_input_updates_last_direction
	_assert_vector_approx.call(
		MOVEMENT_MATH_SCRIPT.select_last_non_zero_direction(Vector2.UP, Vector2(1.0, 1.0)),
		Vector2(1.0, 1.0).normalized(),
		"non-zero input updates and normalizes the last direction"
	)

	# eight_direction_mapping
	var cases: Array[Array] = [
		[Vector2.DOWN, Direction8.Value.DOWN],
		[Vector2(1.0, 1.0), Direction8.Value.DOWN_RIGHT],
		[Vector2.RIGHT, Direction8.Value.RIGHT],
		[Vector2(1.0, -1.0), Direction8.Value.UP_RIGHT],
		[Vector2.UP, Direction8.Value.UP],
		[Vector2(-1.0, -1.0), Direction8.Value.UP_LEFT],
		[Vector2.LEFT, Direction8.Value.LEFT],
		[Vector2(-1.0, 1.0), Direction8.Value.DOWN_LEFT],
	]
	for test_case in cases:
		_assert_int_equal.call(
			DIRECTION_8_SCRIPT.from_vector(test_case[0]),
			test_case[1],
			"direction maps to %s" % DIRECTION_8_SCRIPT.to_id(test_case[1])
		)

	# zero_direction_uses_fallback
	_assert_int_equal.call(
		DIRECTION_8_SCRIPT.from_vector(Vector2.ZERO, Direction8.Value.UP_LEFT),
		Direction8.Value.UP_LEFT,
		"zero direction preserves the facing fallback"
	)

	# player_state_machine_transitions
	var machine: PlayerStateMachine = PLAYER_STATE_MACHINE_SCRIPT.new()
	_assert_int_equal.call(machine.current_state, PlayerStateMachine.State.IDLE, "state starts Idle")
	_assert_true.call(machine.transition_to(PlayerStateMachine.State.MOVE), "Idle transitions to Move")
	_assert_true.call(machine.transition_to(PlayerStateMachine.State.INTERACT), "Move transitions to Interact")
	_assert_true.call(
		not machine.transition_to(PlayerStateMachine.State.MOVE),
		"Interact rejects a direct transition to Move"
	)
	_assert_true.call(machine.transition_to(PlayerStateMachine.State.IDLE), "Interact transitions to Idle")
	_assert_true.call(machine.transition_to(PlayerStateMachine.State.DISABLED), "Idle transitions to Disabled")
	_assert_true.call(
		not machine.transition_to(PlayerStateMachine.State.MOVE),
		"Disabled rejects a direct transition to Move"
	)
	_assert_true.call(machine.transition_to(PlayerStateMachine.State.IDLE), "Disabled transitions to Idle")
