class_name InventoryUiTestCases
extends RefCounted


static func run(
	tree: SceneTree,
	main_scene: Node,
	assert_true: Callable,
	assert_int_equal: Callable
) -> void:
	var content_registry := tree.root.get_node("ContentRegistry") as ContentRegistryService
	var inventory := InventoryModel.new(content_registry, 24)
	inventory.add_item(&"item_branch", 3)
	inventory.add_item(&"item_reed_fiber", 2)
	var hotbar := HotbarModel.new(inventory, 8)
	var screen := main_scene.get_node("Interface/InventoryScreen") as InventoryScreen
	screen.configure(inventory, hotbar)
	assert_int_equal.call(screen.slot_buttons.size(), 24, "inventory UI builds 24 slot buttons")
	assert_int_equal.call(screen.hotbar_buttons.size(), 8, "inventory UI builds eight hotbar buttons")
	assert_true.call(not screen.visible, "inventory UI starts hidden")

	var tab_event := InputEventKey.new()
	tab_event.keycode = KEY_TAB
	tab_event.pressed = true
	assert_true.call(
		InputMap.action_has_event(&"toggle_inventory", tab_event),
		"Tab inventory action is registered"
	)
	screen._unhandled_input(tab_event)
	assert_true.call(tree.paused and screen.visible, "Tab opens inventory and pauses the world")
	assert_true.call(screen.get_slot_button(0).has_focus(), "inventory focuses the first slot")
	assert_true.call(
		screen.get_slot_button(0).text.contains("3"),
		"inventory slot displays its quantity"
	)
	assert_true.call(
		screen.get_hotbar_button(0).text.contains("3"),
		"hotbar reflects the assigned inventory slot"
	)
	screen.get_slot_button(0).pressed.emit()
	assert_true.call(screen.selected_slot_index == 0, "slot activation selects an inventory slot")
	screen.split_button.pressed.emit()
	assert_true.call(
		inventory.get_occupied_slot_count() == 3,
		"inventory UI splits the selected stack into an empty slot"
	)
	screen.hotbar.select(2)
	screen.assign_button.pressed.emit()
	assert_true.call(hotbar.assignments[2] == 0, "inventory UI assigns a slot to selected hotbar")
	var branch_before_discard: int = inventory.count_item(&"item_branch")
	screen.discard_button.pressed.emit()
	assert_true.call(
		inventory.count_item(&"item_branch") == branch_before_discard,
		"first discard activation only requests confirmation"
	)
	screen.discard_button.pressed.emit()
	assert_true.call(
		inventory.count_item(&"item_branch") == branch_before_discard - 1,
		"second discard activation removes one item"
	)
	screen.sort_button.pressed.emit()
	assert_true.call(inventory.validate_invariants(), "inventory UI sort preserves invariants")
	var quest_registry := ContentRegistryService.new()
	var quest_definition := ItemDefinition.new()
	quest_definition.id = &"item_ui_quest"
	quest_definition.name_key = &"ITEM_UI_QUEST_NAME"
	quest_definition.description_key = &"ITEM_UI_QUEST_DESCRIPTION"
	quest_definition.category = ItemDefinition.Category.QUEST
	quest_definition.max_stack = 1
	quest_definition.tags = [&"quest"]
	quest_registry.load_item_definitions([quest_definition])
	var quest_inventory := InventoryModel.new(quest_registry, 24)
	quest_inventory.add_item(&"item_ui_quest", 1)
	var quest_hotbar := HotbarModel.new(quest_inventory, 8)
	screen.configure(quest_inventory, quest_hotbar)
	screen._select_slot(0)
	screen.discard_button.pressed.emit()
	screen.discard_button.pressed.emit()
	assert_true.call(
		quest_inventory.count_item(&"item_ui_quest") == 1,
		"inventory UI cannot discard a quest item"
	)
	assert_true.call(
		screen.status_label.text == screen.tr(&"UI_INVENTORY_DISCARD_LOCKED"),
		"inventory UI shows localized quest discard rejection"
	)
	screen.configure(inventory, hotbar)
	quest_registry.free()

	var back_event := InputEventJoypadButton.new()
	back_event.button_index = JOY_BUTTON_BACK
	back_event.pressed = true
	assert_true.call(
		InputMap.action_has_event(&"toggle_inventory", back_event),
		"controller Back inventory action is registered"
	)
	screen._unhandled_input(back_event)
	assert_true.call(not tree.paused and not screen.visible, "controller Back closes inventory")
	screen._unhandled_input(tab_event)
	var escape_event := InputEventKey.new()
	escape_event.keycode = KEY_ESCAPE
	escape_event.pressed = true
	var pause_menu := main_scene.get_node("Interface/PauseMenu") as PauseMenu
	pause_menu._input(escape_event)
	assert_true.call(not tree.paused and not screen.visible, "Escape closes inventory before pause menu")
	assert_true.call(not pause_menu.visible, "Escape does not open pause menu over inventory")
	assert_true.call(
		screen.responsive_scroll.panel.custom_minimum_size.y <= 720.0,
		"inventory panel fits the current 720p viewport height"
	)
