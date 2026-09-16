class_name PlayerStateMachine
extends RefCounted

signal state_changed(previous_state: int, current_state: int)

enum State {
	IDLE,
	MOVE,
	INTERACT,
	DISABLED,
}

const STATE_IDS: Array[StringName] = [
	&"idle",
	&"move",
	&"interact",
	&"disabled",
]

var current_state: int = State.IDLE


func transition_to(next_state: int) -> bool:
	if not is_valid_state(next_state):
		return false
	if next_state == current_state:
		return false
	if not _is_transition_allowed(current_state, next_state):
		return false

	var previous_state := current_state
	current_state = next_state
	state_changed.emit(previous_state, current_state)
	return true


func can_accept_movement_input() -> bool:
	return current_state == State.IDLE or current_state == State.MOVE


func get_state_id() -> StringName:
	return STATE_IDS[current_state]


static func is_valid_state(state: int) -> bool:
	return state >= State.IDLE and state <= State.DISABLED


static func _is_transition_allowed(from_state: int, to_state: int) -> bool:
	match from_state:
		State.IDLE:
			return to_state in [State.MOVE, State.INTERACT, State.DISABLED]
		State.MOVE:
			return to_state in [State.IDLE, State.INTERACT, State.DISABLED]
		State.INTERACT:
			return to_state in [State.IDLE, State.DISABLED]
		State.DISABLED:
			return to_state == State.IDLE
	return false
