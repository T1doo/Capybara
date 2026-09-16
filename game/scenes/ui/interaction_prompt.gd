class_name InteractionPrompt
extends Label

@export var player_path: NodePath

const DEFAULT_FONT_COLOR := Color(0.92, 0.96, 0.93, 1.0)
const DEFAULT_OUTLINE_COLOR := Color(0.03, 0.05, 0.04, 1.0)
const HIGH_CONTRAST_FONT_COLOR := Color(1.0, 0.92, 0.2, 1.0)
const HIGH_CONTRAST_OUTLINE_COLOR := Color(0.0, 0.0, 0.0, 1.0)
const HIGH_CONTRAST_TARGET_MODULATE := Color(1.0, 1.0, 0.25, 1.0)

var player: PlayerCharacter
var input_device_service: InputDeviceTracker
var high_contrast_enabled: bool = false
var highlighted_target: InteractableComponent
var highlighted_target_original_modulate: Color = Color.WHITE


func _ready() -> void:
	player = get_node_or_null(player_path) as PlayerCharacter
	if player == null:
		player = get_tree().get_first_node_in_group(&"player") as PlayerCharacter
	if player == null:
		hide()
		set_process(false)
		return
	player.interaction_sensor.current_target_changed.connect(_on_current_target_changed)

	input_device_service = get_node_or_null("/root/InputDeviceService") as InputDeviceTracker
	if input_device_service != null:
		input_device_service.device_changed.connect(_on_device_changed)
	var settings_service := get_node_or_null("/root/SettingsService") as SettingsManagerService
	if settings_service != null:
		settings_service.settings_changed.connect(_on_settings_changed)
		_on_settings_changed(settings_service.current_settings)
	_refresh_prompt()


func _process(_delta: float) -> void:
	_refresh_prompt()


func _refresh_prompt() -> void:
	if player == null:
		hide()
		return
	var interaction_key := player.get_current_interaction_prompt()
	if interaction_key.is_empty():
		hide()
		return

	var input_text: String = tr(&"INPUT_PROMPT_INTERACT_KEYBOARD")
	if input_device_service != null:
		input_text = input_device_service.get_action_prompt_text(&"interact")
	text = "%s  [%s]" % [tr(interaction_key), input_text]
	show()


func _on_device_changed(_previous_device: int, _current_device: int) -> void:
	_refresh_prompt()


func _on_settings_changed(settings: SettingsProfile) -> void:
	var high_contrast: bool = settings.high_contrast_interactions
	high_contrast_enabled = high_contrast
	add_theme_color_override(
		&"font_color",
		HIGH_CONTRAST_FONT_COLOR if high_contrast else DEFAULT_FONT_COLOR
	)
	add_theme_color_override(
		&"font_outline_color",
		HIGH_CONTRAST_OUTLINE_COLOR if high_contrast else DEFAULT_OUTLINE_COLOR
	)
	add_theme_constant_override(&"outline_size", 10 if high_contrast else 5)
	_refresh_target_highlight(player.get_current_interactable() if player != null else null)
	_refresh_prompt()


func _on_current_target_changed(
	_previous_target: InteractableComponent,
	current_target: InteractableComponent
) -> void:
	_refresh_target_highlight(current_target)


func _refresh_target_highlight(current_target: InteractableComponent) -> void:
	if is_instance_valid(highlighted_target):
		highlighted_target.modulate = highlighted_target_original_modulate
	highlighted_target = null
	if not high_contrast_enabled or not is_instance_valid(current_target):
		return
	highlighted_target = current_target
	highlighted_target_original_modulate = current_target.modulate
	highlighted_target.modulate = HIGH_CONTRAST_TARGET_MODULATE
