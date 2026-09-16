class_name DisplayMatrixTestCases
extends RefCounted


static func run(tree: SceneTree, main_scene: GameBootstrap, assert_true: Callable) -> void:
	var original_size: Vector2i = tree.root.size
	var original_scale: float = tree.root.content_scale_factor
	var entries: Array[Dictionary] = _build_entries(main_scene)
	for resolution in SettingsProfile.SUPPORTED_RESOLUTIONS:
		for ui_scale in SettingsProfile.SUPPORTED_UI_SCALES:
			tree.root.content_scale_factor = ui_scale
			tree.root.size = resolution
			await tree.process_frame
			await tree.process_frame
			for entry in entries:
				var screen := entry["screen"] as Control
				var scroll := entry["scroll"] as ResponsiveModalLayout
				var first_control := entry["first"] as Control
				var last_control := entry["last"] as Control
				screen.show()
				scroll._sync_content_size()
				assert_true.call(
					_is_bounded(scroll, screen),
					"%s stays bounded at %dx%d / %d%%" % [
						entry["name"], resolution.x, resolution.y, roundi(ui_scale * 100.0)
					]
				)
				scroll.scroll_horizontal = 0
				scroll.scroll_vertical = 0
				first_control.grab_focus()
				await tree.process_frame
				last_control.grab_focus()
				await tree.process_frame
				assert_true.call(
					scroll.follow_focus and _control_is_visible(scroll, last_control),
					"%s follows focus at %dx%d / %d%%" % [
						entry["name"], resolution.x, resolution.y, roundi(ui_scale * 100.0)
					]
				)
				screen.hide()
				assert_true.call(
					scroll.content_center.size.x >= scroll.panel.get_combined_minimum_size().x
					and scroll.content_center.size.y >= scroll.panel.get_combined_minimum_size().y,
					"%s keeps all content scroll-reachable at %dx%d / %d%%" % [
						entry["name"], resolution.x, resolution.y, roundi(ui_scale * 100.0)
					]
				)
	tree.root.content_scale_factor = original_scale
	tree.root.size = original_size
	await tree.process_frame


static func _build_entries(main_scene: GameBootstrap) -> Array[Dictionary]:
	var pause := main_scene.get_node("Interface/PauseMenu") as PauseMenu
	var settings := main_scene.get_node("Interface/SettingsScreen") as SettingsScreen
	var remap := main_scene.get_node("Interface/InputRemapScreen") as InputRemapScreen
	var inventory := main_scene.get_node("Interface/InventoryScreen") as InventoryScreen
	var storage := main_scene.get_node("Interface/StorageScreen") as StorageScreen
	return [
		{"name": "pause", "screen": pause, "scroll": pause.responsive_scroll,
			"first": pause.continue_button, "last": pause.exit_button},
		{"name": "settings", "screen": settings, "scroll": settings.responsive_scroll,
			"first": settings.language_option, "last": settings.back_button},
		{"name": "input remap", "screen": remap, "scroll": remap.responsive_scroll,
			"first": remap.keyboard_buttons[&"move_left"],
			"last": remap.gamepad_buttons[&"hotbar_next"]},
		{"name": "inventory", "screen": inventory, "scroll": inventory.responsive_scroll,
			"first": inventory.slot_buttons[0], "last": inventory.hotbar_buttons[-1]},
		{"name": "storage", "screen": storage, "scroll": storage.responsive_scroll,
			"first": storage.player_buttons[0], "last": storage.storage_buttons[-1]},
	]


static func _is_bounded(scroll: ResponsiveModalLayout, screen: Control) -> bool:
	return (
		scroll.position.x >= -0.5
		and scroll.position.y >= -0.5
		and scroll.position.x + scroll.size.x <= screen.size.x + 0.5
		and scroll.position.y + scroll.size.y <= screen.size.y + 0.5
	)


static func _control_is_visible(scroll: ResponsiveModalLayout, control: Control) -> bool:
	var visible_rect: Rect2 = scroll.get_global_rect().grow(1.0)
	var control_rect: Rect2 = control.get_global_rect()
	return visible_rect.has_point(control_rect.get_center())
