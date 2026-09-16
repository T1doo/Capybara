class_name InputRemapScreen
extends Control

signal closed

@onready var rows: VBoxContainer = %BindingRows
@onready var reset_button: Button = %ResetButton
@onready var back_button: Button = %BackButton

var profile: SettingsProfile
var keyboard_buttons: Dictionary[StringName, Button] = {}
var gamepad_buttons: Dictionary[StringName, Button] = {}
var pending_action: StringName = &""
var pending_keyboard: bool = true
var responsive_scroll: ResponsiveModalLayout


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	responsive_scroll = ResponsiveModalLayout.new()
	responsive_scroll.install(
		self,
		get_node("CenterContainer") as CenterContainer,
		get_node("CenterContainer/Panel") as Control
	)
	_build_rows()
	reset_button.pressed.connect(_reset_defaults)
	back_button.pressed.connect(close_screen)
	hide()


func open_screen(draft_profile: SettingsProfile) -> void:
	profile = draft_profile
	pending_action = &""
	_refresh_buttons()
	show()
	keyboard_buttons[SettingsProfile.REMAPPABLE_ACTIONS[0]].grab_focus()


func close_screen() -> void:
	pending_action = &""
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if pending_action.is_empty():
		return
	var accepted: bool = (
		pending_keyboard and event is InputEventKey and event.pressed and not event.echo
	) or (
		not pending_keyboard
		and (
			(event is InputEventJoypadButton and event.pressed)
			or (event is InputEventJoypadMotion and absf(event.axis_value) >= 0.5)
		)
	)
	if not accepted:
		return
	_apply_captured_event(event)
	get_viewport().set_input_as_handled()


func begin_capture(action: StringName, keyboard: bool) -> void:
	pending_action = action
	pending_keyboard = keyboard
	var target_button: Button = keyboard_buttons[action] if keyboard else gamepad_buttons[action]
	target_button.text = tr(&"UI_REMAP_WAITING")


func _apply_captured_event(event: InputEvent) -> void:
	var events: Array = _events_for_action(pending_action)
	var replacement: Array = []
	for existing_event in events:
		var is_keyboard: bool = existing_event is InputEventKey
		if is_keyboard != pending_keyboard:
			replacement.append(existing_event)
	var captured_event: InputEvent = event.duplicate()
	if captured_event is InputEventJoypadMotion:
		(captured_event as InputEventJoypadMotion).axis_value = signf(
			(captured_event as InputEventJoypadMotion).axis_value
		)
	if captured_event is InputEventJoypadButton or captured_event is InputEventJoypadMotion:
		captured_event.device = -1
	replacement.append(captured_event)
	profile.set_input_binding(pending_action, replacement)
	pending_action = &""
	_refresh_buttons()


func _build_rows() -> void:
	for action in SettingsProfile.REMAPPABLE_ACTIONS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var label := Label.new()
		label.custom_minimum_size = Vector2(190.0, 40.0)
		label.text = String(_action_text_key(action))
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(label)
		var keyboard_button := Button.new()
		keyboard_button.custom_minimum_size = Vector2(200.0, 40.0)
		keyboard_button.pressed.connect(begin_capture.bind(action, true))
		row.add_child(keyboard_button)
		keyboard_buttons[action] = keyboard_button
		var gamepad_button := Button.new()
		gamepad_button.custom_minimum_size = Vector2(200.0, 40.0)
		gamepad_button.pressed.connect(begin_capture.bind(action, false))
		row.add_child(gamepad_button)
		gamepad_buttons[action] = gamepad_button
		rows.add_child(row)


func _refresh_buttons() -> void:
	if profile == null:
		return
	for action in SettingsProfile.REMAPPABLE_ACTIONS:
		var events: Array = _events_for_action(action)
		keyboard_buttons[action].text = _first_event_text(events, true)
		gamepad_buttons[action].text = _first_event_text(events, false)


func _events_for_action(action: StringName) -> Array:
	if profile.input_bindings.has(action):
		return profile.input_bindings[action]
	return InputSetup.get_default_events(action)


func _first_event_text(events: Array, keyboard: bool) -> String:
	for event in events:
		if keyboard and event is InputEventKey:
			var key := event as InputEventKey
			return InputBindingFormatter.format_key(key)
		if not keyboard and event is InputEventJoypadButton:
			return tr(&"UI_REMAP_GAMEPAD_BUTTON") % (
				(event as InputEventJoypadButton).button_index + 1
			)
		if not keyboard and event is InputEventJoypadMotion:
			var motion := event as InputEventJoypadMotion
			var direction: String = "+" if motion.axis_value > 0.0 else "−"
			return tr(&"UI_REMAP_GAMEPAD_AXIS") % [motion.axis, direction]
	return tr(&"UI_REMAP_UNBOUND")


func _reset_defaults() -> void:
	profile.input_bindings.clear()
	pending_action = &""
	_refresh_buttons()


func _action_text_key(action: StringName) -> StringName:
	return StringName("UI_ACTION_%s" % String(action).to_upper())
