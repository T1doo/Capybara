extends RefCounted

const SCENE: PackedScene = preload("res://scenes/visual_prototypes/home_visual_preview.tscn")


static func key(tree: SceneTree, code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await tree.process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await tree.process_frame


static func joy(tree: SceneTree, button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 1
	event.button_index = button
	event.pressed = true
	Input.parse_input_event(event)
	await tree.process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await tree.process_frame


static func run(tree: SceneTree, check: Callable) -> void:
	var service := tree.root.get_node("SettingsService") as SettingsManagerService
	var original := service.current_settings.duplicate_profile()
	var environment_check: Callable = service.window_environment_check
	service.window_environment_check = func() -> bool: return false
	service.replace_settings(SettingsProfile.new())
	service.apply_current_settings(false)
	var saved_settings_hash := FileAccess.get_sha256("user://settings.cfg")
	var saved_game_hash := FileAccess.get_sha256("user://saves/slot_01.json")
	var preview := SCENE.instantiate()
	tree.root.add_child(preview)
	await tree.process_frame
	var world := preview.get_node("Environment") as HomeVisualBlockout
	var player := world.get_node("Player") as PlayerCharacter
	var mill := world.get_node("PaintedWaterwheel") as PaintedWaterwheel2D
	var menu := preview.get_node("Interface/PauseMenu") as PauseMenu
	var settings := preview.get_node("Interface/SettingsScreen") as SettingsScreen
	var remap := preview.get_node("Interface/InputRemapScreen") as InputRemapScreen
	check.call(not world.show_grid and not world.show_anchor_guides, "preview hides technical grid and anchor guides")
	check.call(not menu.allow_game_saves and not menu.save_button.visible and not menu.load_button.visible,
		"preview hides save and load without changing production defaults")
	check.call(not settings.persist_settings, "preview settings are session-only")
	menu._save_game()
	menu._load_game()
	check.call(menu.save_status_label.text.is_empty(), "disabled preview save handlers safely ignore calls")
	await key(tree, KEY_ESCAPE)
	check.call(tree.paused and menu.visible and menu.continue_button.has_focus(), "real Escape routes to preview pause and Continue focus")
	var position_before := player.position
	var angle_before := mill.wheel.rotation
	Input.action_press(&"move_right")
	for frame in range(8):
		await tree.physics_frame
	Input.action_release(&"move_right")
	check.call(player.position == position_before and mill.wheel.rotation == angle_before,
		"preview pause freezes both player and wheel across physics frames")
	await key(tree, KEY_DOWN)
	check.call(menu.settings_button.has_focus(), "keyboard Down focuses preview Settings")
	await key(tree, KEY_ENTER)
	check.call(tree.paused and settings.visible and not menu.visible, "keyboard Enter opens preview settings while paused")
	settings.controls_button.grab_focus()
	await joy(tree, JOY_BUTTON_A)
	check.call(remap.visible and not settings.visible, "controller accept opens input remapping")
	await key(tree, KEY_ESCAPE)
	check.call(settings.visible and not remap.visible and tree.paused, "Escape returns from remapping without resuming")
	settings.reduced_motion_check.button_pressed = true
	settings.apply_button.grab_focus()
	await joy(tree, JOY_BUTTON_A)
	check.call(service.current_settings.reduced_motion, "controller accept applies reduced motion through real Settings UI")
	check.call(settings.status_label.text == settings.tr(&"UI_SETTINGS_SESSION_APPLIED"), "session-only settings report truthful feedback")
	await key(tree, KEY_ESCAPE)
	check.call(tree.paused and menu.visible and menu.settings_button.has_focus(), "Escape returns settings to pause with focus")
	await joy(tree, JOY_BUTTON_DPAD_DOWN)
	check.call(menu.exit_button.has_focus(), "controller navigation skips hidden save and load buttons")
	await joy(tree, JOY_BUTTON_START)
	check.call(not tree.paused and not menu.visible, "controller Start resumes preview")
	angle_before = mill.wheel.rotation
	Input.action_press(&"move_right")
	for frame in range(8):
		await tree.physics_frame
	Input.action_release(&"move_right")
	check.call(player.position.x > position_before.x and mill.wheel.rotation == angle_before,
		"resumed preview moves player while reduced-motion wheel stays frozen")
	await joy(tree, JOY_BUTTON_START)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = menu.continue_button.get_global_rect().get_center()
	click.global_position = click.position
	click.pressed = true
	tree.root.push_input(click, true)
	await tree.process_frame
	click = click.duplicate()
	click.pressed = false
	tree.root.push_input(click, true)
	await tree.process_frame
	check.call(not tree.paused and not menu.visible, "mouse click on Continue resumes the preview")
	var english := service.current_settings.duplicate_profile()
	english.locale = &"en"
	service.replace_settings(english)
	service.apply_current_settings(false)
	settings.open_screen()
	check.call(settings.display_option.get_item_text(0) == "Windowed",
		"reopening settings refreshes option labels after an external locale change")
	settings.hide()
	check.call(FileAccess.get_sha256("user://settings.cfg") == saved_settings_hash,
		"preview settings application does not alter the persistent settings file")
	check.call(FileAccess.get_sha256("user://saves/slot_01.json") == saved_game_hash,
		"disabled preview saving does not alter the real game slot")
	tree.paused = false
	preview.queue_free()
	await tree.process_frame
	service.window_environment_check = environment_check
	service.replace_settings(original)
	service.apply_current_settings(false)
