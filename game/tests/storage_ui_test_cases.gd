class_name StorageUiTestCases
extends RefCounted


static func run(
	tree: SceneTree,
	main_scene: GameBootstrap,
	assert_true: Callable,
	assert_int_equal: Callable
) -> void:
	var inventory_service := tree.root.get_node("InventoryService") as InventoryCoordinator
	var storage := inventory_service.create_storage(&"storage_ui_test", 32)
	inventory_service.player_inventory.add_item(&"item_branch", 3)
	storage.add_item(&"item_reed_fiber", 2)
	var screen := main_scene.get_node("Interface/StorageScreen") as StorageScreen
	screen.configure(inventory_service.player_inventory, storage)
	screen.open_screen()
	assert_true.call(tree.paused and screen.visible, "storage screen opens as a paused modal")
	assert_int_equal.call(screen.player_buttons.size(), 24, "storage UI builds player slots")
	assert_int_equal.call(screen.storage_buttons.size(), 32, "storage UI builds container slots")
	assert_true.call(screen.player_buttons[0].has_focus(), "storage UI focuses the first player slot")
	var player_branch_slot: int = _find_item_slot(
		inventory_service.player_inventory,
		&"item_branch"
	)
	assert_true.call(player_branch_slot >= 0, "storage fixture locates its player item slot")
	assert_true.call(
		not screen.player_buttons[player_branch_slot].pressed.get_connections().is_empty(),
		"player storage slot has a transfer callback"
	)
	var observed_state: Dictionary = {"consistent": true, "notifications": 0}
	var observe_final_state := func() -> void:
		observed_state["notifications"] += 1
		observed_state["consistent"] = (
			observed_state["consistent"]
			and inventory_service.player_inventory.count_item(&"item_branch") == 0
			and storage.count_item(&"item_branch") == 3
		)
	inventory_service.player_inventory.changed.connect(observe_final_state)
	storage.changed.connect(observe_final_state)
	var to_storage: InventoryTransactionResult = screen._transfer_to_storage(player_branch_slot)
	assert_true.call(
		to_storage.made_progress(),
		"player-to-storage UI handler reports a completed transfer: %s" % to_storage.reason_key
	)
	assert_int_equal.call(
		inventory_service.player_inventory.count_item(&"item_branch"),
		0,
		"selecting a player slot transfers its stack to storage"
	)
	assert_int_equal.call(
		storage.count_item(&"item_branch"),
		3,
		"storage receives the transferred stack"
	)
	assert_true.call(
		observed_state["consistent"] and observed_state["notifications"] == 2,
		"transfer listeners only observe the final two-inventory state"
	)
	inventory_service.player_inventory.changed.disconnect(observe_final_state)
	storage.changed.disconnect(observe_final_state)
	var branch_slot: int = _find_item_slot(storage, &"item_branch")
	assert_true.call(
		not screen.storage_buttons[branch_slot].pressed.get_connections().is_empty(),
		"container slot has a transfer callback"
	)
	var to_player: InventoryTransactionResult = screen._transfer_to_player(branch_slot)
	assert_true.call(
		to_player.made_progress(),
		"storage-to-player UI handler reports a completed transfer: %s" % to_player.reason_key
	)
	assert_int_equal.call(
		inventory_service.player_inventory.count_item(&"item_branch"),
		3,
		"selecting a storage slot transfers its stack to the player"
	)
	assert_int_equal.call(storage.count_item(&"item_branch"), 0, "storage transfer removes its source")
	screen.close_button.pressed.emit()
	assert_true.call(not tree.paused and not screen.visible, "storage Back resumes the world")
	inventory_service.player_inventory.remove_item(&"item_branch", 3)
	storage.remove_item(&"item_reed_fiber", 2)
	inventory_service.storages.erase(&"storage_ui_test")

	var open_result := InteractionResult.succeeded(&"INTERACTION_STORAGE_OPENED", {
		&"storage_id": &"storage_context_test",
		&"is_open": true,
	})
	main_scene._on_player_interaction_completed(open_result)
	assert_true.call(
		screen.visible and tree.paused,
		"typed storage interaction payload opens the storage UI"
	)
	screen.close_button.pressed.emit()
	inventory_service.storages.erase(&"storage_context_test")


static func _find_item_slot(model: InventoryModel, item_id: StringName) -> int:
	for index in range(model.slots.size()):
		if model.slots[index].item_id == item_id:
			return index
	return -1
