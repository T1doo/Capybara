class_name SettingsScreen
extends Control

signal closed

const DEFAULT_SETTINGS_PATH: String = "user://settings.cfg"

@export var persist_settings: bool = true

@onready var language_option: OptionButton = %LanguageOption
@onready var display_option: OptionButton = %DisplayOption
@onready var resolution_option: OptionButton = %ResolutionOption
@onready var ui_scale_option: OptionButton = %UiScaleOption
@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sound_slider: HSlider = %SoundSlider
@onready var camera_smoothing_check: CheckButton = %CameraSmoothingCheck
@onready var reduced_motion_check: CheckButton = %ReducedMotionCheck
@onready var vibration_check: CheckButton = %VibrationCheck
@onready var high_contrast_check: CheckButton = %HighContrastCheck
@onready var status_label: Label = %StatusLabel
@onready var apply_button: Button = %ApplyButton
@onready var controls_button: Button = %ControlsButton
@onready var back_button: Button = %BackButton
@onready var input_remap_screen := get_node("../InputRemapScreen") as InputRemapScreen

var settings_service: SettingsManagerService
var draft_profile: SettingsProfile
var responsive_scroll: ResponsiveModalLayout
var settings_path: String = DEFAULT_SETTINGS_PATH


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	responsive_scroll = ResponsiveModalLayout.new()
	responsive_scroll.install(
		self,
		get_node("CenterContainer") as CenterContainer,
		get_node("CenterContainer/Panel") as Control
	)
	settings_service = get_node_or_null("/root/SettingsService") as SettingsManagerService
	_build_options()
	apply_button.pressed.connect(_apply_settings)
	controls_button.pressed.connect(_open_input_remap)
	back_button.pressed.connect(close_screen)
	input_remap_screen.closed.connect(_on_input_remap_closed)
	hide()


func open_screen() -> void:
	if settings_service == null:
		return
	draft_profile = settings_service.current_settings.duplicate_profile()
	_refresh_localized_options()
	_populate_controls(draft_profile)
	status_label.text = ""
	show()
	language_option.grab_focus()


func close_screen() -> void:
	hide()
	closed.emit()


func _build_options() -> void:
	language_option.clear()
	_add_option(language_option, &"UI_LANGUAGE_ZH_CN", &"zh_CN")
	_add_option(language_option, &"UI_LANGUAGE_EN", &"en")
	display_option.clear()
	_add_option(display_option, &"UI_DISPLAY_WINDOWED", SettingsProfile.DISPLAY_WINDOWED)
	_add_option(display_option, &"UI_DISPLAY_FULLSCREEN", SettingsProfile.DISPLAY_FULLSCREEN)
	resolution_option.clear()
	for resolution in SettingsProfile.SUPPORTED_RESOLUTIONS:
		resolution_option.add_item("%d × %d" % [resolution.x, resolution.y])
		resolution_option.set_item_metadata(resolution_option.item_count - 1, resolution)
	ui_scale_option.clear()
	for scale in SettingsProfile.SUPPORTED_UI_SCALES:
		ui_scale_option.add_item("%d%%" % roundi(scale * 100.0))
		ui_scale_option.set_item_metadata(ui_scale_option.item_count - 1, scale)


func _add_option(option: OptionButton, text_key: StringName, metadata: Variant) -> void:
	option.add_item(tr(text_key))
	option.set_item_metadata(option.item_count - 1, metadata)


func _populate_controls(profile: SettingsProfile) -> void:
	_select_metadata(language_option, profile.locale)
	_select_metadata(display_option, profile.display_mode)
	_select_metadata(resolution_option, profile.resolution)
	_select_metadata(ui_scale_option, profile.ui_scale)
	master_slider.value = profile.master_volume * 100.0
	music_slider.value = profile.music_volume * 100.0
	sound_slider.value = profile.sound_volume * 100.0
	camera_smoothing_check.button_pressed = profile.camera_smoothing
	reduced_motion_check.button_pressed = profile.reduced_motion
	vibration_check.button_pressed = profile.gamepad_vibration
	high_contrast_check.button_pressed = profile.high_contrast_interactions


func _select_metadata(option: OptionButton, target: Variant) -> void:
	for index in range(option.item_count):
		var metadata: Variant = option.get_item_metadata(index)
		if metadata == target or (
			metadata is float
			and target is float
			and is_equal_approx(metadata, target)
		):
			option.select(index)
			return


func _apply_settings() -> void:
	var candidate: SettingsProfile = draft_profile
	candidate.locale = language_option.get_selected_metadata()
	candidate.display_mode = display_option.get_selected_metadata()
	candidate.resolution = resolution_option.get_selected_metadata()
	candidate.ui_scale = ui_scale_option.get_selected_metadata()
	candidate.master_volume = master_slider.value / 100.0
	candidate.music_volume = music_slider.value / 100.0
	candidate.sound_volume = sound_slider.value / 100.0
	candidate.camera_smoothing = camera_smoothing_check.button_pressed
	candidate.reduced_motion = reduced_motion_check.button_pressed
	candidate.gamepad_vibration = vibration_check.button_pressed
	candidate.high_contrast_interactions = high_contrast_check.button_pressed
	var replace_result: SettingsOperationResult = settings_service.replace_settings(candidate)
	if not replace_result.success:
		status_label.text = tr(&"UI_SETTINGS_SAVE_FAILED")
		return
	var apply_error: StringName = settings_service.apply_current_settings()
	var saved: bool = true
	if persist_settings:
		saved = settings_service.save_settings(settings_path).success
	if not apply_error.is_empty() or not saved:
		status_label.text = tr(&"UI_SETTINGS_SAVE_FAILED")
		return
	_refresh_localized_options()
	status_label.text = tr(&"UI_SETTINGS_SAVED" if persist_settings else &"UI_SETTINGS_SESSION_APPLIED")
	draft_profile = settings_service.current_settings.duplicate_profile()


func _open_input_remap() -> void:
	hide()
	input_remap_screen.open_screen(draft_profile)


func _on_input_remap_closed() -> void:
	show()
	controls_button.grab_focus()


func _refresh_localized_options() -> void:
	language_option.set_item_text(0, tr(&"UI_LANGUAGE_ZH_CN"))
	language_option.set_item_text(1, tr(&"UI_LANGUAGE_EN"))
	display_option.set_item_text(0, tr(&"UI_DISPLAY_WINDOWED"))
	display_option.set_item_text(1, tr(&"UI_DISPLAY_FULLSCREEN"))
