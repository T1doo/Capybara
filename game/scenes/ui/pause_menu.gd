class_name PauseMenu
extends Control

const DEFAULT_SAVE_BASE_PATH: String = "user://saves/slot_01"

@export var allow_game_saves: bool = true

@onready var continue_button: Button = %ContinueButton
@onready var settings_button: Button = %SettingsButton
@onready var save_button: Button = %SaveButton
@onready var load_button: Button = %LoadButton
@onready var exit_button: Button = %ExitButton
@onready var save_status_label: Label = %SaveStatusLabel
@onready var settings_screen := get_node("../SettingsScreen") as SettingsScreen
@onready var input_remap_screen := get_node("../InputRemapScreen") as InputRemapScreen

var save_base_path: String = DEFAULT_SAVE_BASE_PATH
var responsive_scroll: ResponsiveModalLayout


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	responsive_scroll = ResponsiveModalLayout.new()
	responsive_scroll.install(
		self,
		get_node("CenterContainer") as CenterContainer,
		get_node("CenterContainer/PanelContainer") as Control
	)
	continue_button.pressed.connect(_resume_game)
	settings_button.pressed.connect(_open_settings)
	save_button.pressed.connect(_save_game)
	load_button.pressed.connect(_load_game)
	settings_screen.closed.connect(_on_settings_closed)
	exit_button.pressed.connect(_exit_game)

	save_button.visible = allow_game_saves
	load_button.visible = allow_game_saves
	save_status_label.visible = allow_game_saves
	hide()


func _input(event: InputEvent) -> void:
	var pause_requested := event.is_action_pressed(&"pause_game")
	if event is InputEventKey:
		var key_event := event as InputEventKey
		pause_requested = pause_requested or (
			key_event.pressed
			and not key_event.echo
			and (
				key_event.keycode == KEY_ESCAPE
				or key_event.physical_keycode == KEY_ESCAPE
			)
		)
	elif event is InputEventJoypadButton:
		var button_event := event as InputEventJoypadButton
		pause_requested = pause_requested or (
			button_event.pressed
			and button_event.button_index == JOY_BUTTON_START
		)

	if not pause_requested:
		return
	var storage_screen := get_node_or_null("../StorageScreen") as StorageScreen
	if storage_screen != null and storage_screen.visible:
		storage_screen.close_screen()
		get_viewport().set_input_as_handled()
		return
	if input_remap_screen.visible:
		input_remap_screen.close_screen()
		get_viewport().set_input_as_handled()
		return
	if settings_screen.visible:
		settings_screen.close_screen()
		get_viewport().set_input_as_handled()
		return
	var inventory_screen := get_node_or_null("../InventoryScreen") as InventoryScreen
	if inventory_screen != null and inventory_screen.visible:
		inventory_screen.close_inventory()
		get_viewport().set_input_as_handled()
		return

	if get_tree().paused:
		_resume_game()
	else:
		_pause_game()
	get_viewport().set_input_as_handled()


func _pause_game() -> void:
	show()
	get_tree().paused = true
	continue_button.grab_focus()


func _resume_game() -> void:
	get_tree().paused = false
	hide()


func _open_settings() -> void:
	hide()
	settings_screen.open_screen()


func _on_settings_closed() -> void:
	show()
	settings_button.grab_focus()


func _exit_game() -> void:
	get_tree().quit()


func _save_game() -> void:
	if not allow_game_saves:
		return
	var save_manager := get_node("/root/SaveManager") as SaveManagerService
	var inventory_service := get_node("/root/InventoryService") as InventoryCoordinator
	var scene_flow := get_node("/root/SceneFlowService") as SceneFlowCoordinator
	var player := get_node("../../Player") as PlayerCharacter
	var snapshot: SaveOperationResult = save_manager.create_runtime_snapshot(
		inventory_service,
		player,
		scene_flow
	)
	if not snapshot.success:
		save_status_label.text = tr(&"UI_SAVE_FAILED")
		return
	var result: SaveOperationResult = save_manager.save_game(save_base_path, snapshot.data)
	save_status_label.text = tr(
		&"UI_SAVE_SUCCESS" if result.success else &"UI_SAVE_FAILED"
	)


func _load_game() -> void:
	if not allow_game_saves:
		return
	var save_manager := get_node("/root/SaveManager") as SaveManagerService
	var inventory_service := get_node("/root/InventoryService") as InventoryCoordinator
	var scene_flow := get_node("/root/SceneFlowService") as SceneFlowCoordinator
	var player := get_node("../../Player") as PlayerCharacter
	var result: SaveOperationResult = save_manager.load_and_apply(
		save_base_path,
		inventory_service,
		player,
		scene_flow
	)
	if not result.success:
		save_status_label.text = tr(&"UI_LOAD_FAILED")
	elif result.recovered_from_backup:
		save_status_label.text = tr(&"UI_LOAD_RECOVERED_BACKUP")
	else:
		save_status_label.text = tr(&"UI_LOAD_SUCCESS")
	load_button.grab_focus()
