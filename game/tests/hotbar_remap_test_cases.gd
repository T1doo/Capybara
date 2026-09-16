class_name HotbarRemapTestCases
extends RefCounted


static func run(registry: ContentRegistryService, check: Callable) -> void:
	var inventory := InventoryModel.new(registry, 12)
	inventory.add_item(&"item_branch", 8)
	inventory.add_item(&"item_reed_spade", 1)
	inventory.move_or_merge(1, 5)
	var hotbar := HotbarModel.new(inventory)
	hotbar.assign(0, 5)
	hotbar.assign(3, 5)
	hotbar.assign(4, 0)
	hotbar.assign(7, -1)
	inventory.sort_and_compact()
	check.call(hotbar.get_selected_item_id() == &"item_reed_spade", "sort preserves selected tool")
	check.call(_item(hotbar, 3) == &"item_reed_spade", "sort preserves unselected duplicate binding")
	check.call(_item(hotbar, 4) == &"item_branch", "sort preserves other assigned item")
	check.call(hotbar.assignments[7] == -1, "sort preserves explicitly unassigned slot")
	var tool_index: int = hotbar.assignments[0]
	var branch_index: int = hotbar.assignments[4]
	inventory.move_or_merge(tool_index, branch_index)
	check.call(hotbar.get_selected_item_id() == &"item_reed_spade", "swap follows tool")
	check.call(_item(hotbar, 4) == &"item_branch", "swap follows displaced item")
	check.call(_item(hotbar, 3) == &"item_reed_spade", "swap updates all aliases")
	branch_index = hotbar.assignments[4]
	inventory.split_stack(branch_index, 3, 9)
	check.call(hotbar.assignments[4] == branch_index, "split keeps source binding")
	hotbar.assign(5, 9)
	inventory.move_or_merge(9, branch_index, 1)
	check.call(hotbar.assignments[5] == 9, "partial merge keeps source remainder binding")
	inventory.move_or_merge(9, branch_index)
	check.call(hotbar.assignments[5] == branch_index, "complete merge follows destination")
	inventory.split_stack(branch_index, 2, 9)
	hotbar.assign(5, 9)
	inventory.sort_and_compact()
	check.call(hotbar.assignments[4] == hotbar.assignments[5], "compaction aliases same merged stack")
	var storage := StorageInventory.new(registry, &"hotbar_regression_chest", 4)
	branch_index = hotbar.assignments[4]
	InventoryTransferService.transfer_slot(inventory, storage, branch_index, 2, false)
	check.call(_item(hotbar, 4) == &"item_branch", "partial storage transfer keeps binding")
	InventoryTransferService.transfer_slot(inventory, storage, hotbar.assignments[0], -1, false)
	check.call(hotbar.get_selected_item_id().is_empty(), "whole tool transfer clears equipment")
	check.call(hotbar.assignments[0] == -1 and hotbar.assignments[3] == -1, "whole transfer clears all aliases")
	InventoryTransferService.transfer_slot(storage, inventory, 1, -1, false)
	check.call(hotbar.get_selected_item_id().is_empty(), "returning tool requires explicit reassignment")
	inventory.remove_item(&"item_branch", inventory.count_item(&"item_branch"))
	check.call(hotbar.assignments[4] == -1 and hotbar.assignments[5] == -1, "depletion clears all stack aliases")
	inventory.add_item(&"item_reed_fiber", 1)
	check.call(_item(hotbar, 4).is_empty(), "later slot reuse never silently changes assigned item")
	hotbar.assign(2, 11)
	inventory.sort_and_compact()
	check.call(hotbar.assignments[2] == -1, "sort clears empty positional placeholder")
	_test_serialization(registry, check)
	_test_edge_cases(registry, check)


static func _test_edge_cases(registry: ContentRegistryService, check: Callable) -> void:
	var inventory := InventoryModel.new(registry, 4)
	var hotbar := HotbarModel.new(inventory, 4)
	inventory.add_item(&"item_branch", 3)
	check.call(hotbar.get_selected_item_id() == &"item_branch", "initial empty placeholder adopts first occupant")
	var before: Array[int] = hotbar.assignments.duplicate()
	inventory.remove_item(&"item_branch", 3, true)
	check.call(hotbar.assignments == before, "simulation preserves bindings")
	check.call(not inventory.move_or_merge(0, 99) and hotbar.assignments == before, "rejected move preserves bindings")
	var storage := StorageInventory.new(registry, &"full_hotbar_chest", 1)
	storage.add_item(&"item_reed_spade", 1)
	InventoryTransferService.transfer_slot(inventory, storage, 0, 3, false)
	check.call(hotbar.assignments == before, "rejected chest transfer preserves bindings")
	inventory.discard_from_slot(0, 3)
	check.call(hotbar.assignments[0] == -1, "discarded last stack clears binding")
	inventory.add_item(&"item_reed_spade", 2)
	hotbar.assign(0, 0)
	hotbar.assign(1, 1)
	inventory.sort_and_compact()
	check.call(hotbar.assignments[0] == hotbar.assignments[1], "same-item tool aliases resolve to first output stack")
	inventory.take_from_slot(hotbar.assignments[0], 1)
	check.call(hotbar.assignments[0] == -1 and hotbar.assignments[1] == -1, "depleting bound stack clears despite another identical stack")
	check.call(inventory.count_item(&"item_reed_spade") == 1, "alias clearing does not consume other identical item")


static func _test_serialization(registry: ContentRegistryService, check: Callable) -> void:
	var inventory := InventoryModel.new(registry, 12)
	inventory.add_item(&"item_reed_spade", 1)
	inventory.move_or_merge(0, 5)
	var hotbar := HotbarModel.new(inventory)
	# Existing schema remains index-based; decoding old assignments needs no migration.
	var legacy: Dictionary = {"schema_version": 1, "assignments": [5, -1, 5, 11, -1, -1, -1, -1], "selected_index": 2}
	check.call(InventoryDataCodec.decode_hotbar(hotbar, legacy).success, "legacy schema 1 decodes")
	inventory.sort_and_compact()
	check.call(hotbar.get_selected_item_id() == &"item_reed_spade", "loaded legacy binding follows sort")
	var restored := InventoryModel.new(registry, 12)
	check.call(InventoryDataCodec.decode_inventory(restored, InventoryDataCodec.encode_inventory(inventory)).success, "inventory roundtrip")
	var restored_hotbar := HotbarModel.new(restored)
	check.call(InventoryDataCodec.decode_hotbar(restored_hotbar, InventoryDataCodec.encode_hotbar(hotbar)).success, "remapped hotbar roundtrip")
	check.call(restored_hotbar.get_selected_item_id() == &"item_reed_spade" and restored_hotbar.selected_index == 2, "roundtrip preserves tool and selected position")
	restored.move_or_merge(restored_hotbar.assignments[2], 9)
	check.call(restored_hotbar.assignments[0] == 9 and restored_hotbar.assignments[2] == 9, "restored aliases follow full move")


static func run_runtime(tree: SceneTree, main: Node, check: Callable) -> void:
	var coordinator := tree.root.get_node("InventoryService") as InventoryCoordinator
	var inventory: InventoryModel = coordinator.player_inventory
	var hotbar: HotbarModel = coordinator.hotbar
	var old_inventory: Dictionary = InventoryDataCodec.encode_inventory(inventory)
	var old_hotbar: Dictionary = InventoryDataCodec.encode_hotbar(hotbar)
	var screen := main.get_node("Interface/InventoryScreen") as InventoryScreen
	var player := main.get_node("Player") as PlayerCharacter
	inventory.add_item(&"item_reed_spade", 1)
	var tool_index: int = -1
	for index in range(inventory.slots.size()):
		if inventory.slots[index].item_id == &"item_reed_spade":
			tool_index = index
			break
	inventory.move_or_merge(tool_index, 20)
	hotbar.assign(6, 20)
	hotbar.select(6)
	screen.configure(inventory, hotbar)
	var tool_label: String = screen.get_hotbar_button(6).text
	screen._sort_inventory()
	check.call(player.get_equipped_tool_id() == &"item_reed_spade", "production UI sort preserves player equipped tool")
	check.call(screen.get_hotbar_button(6).text == tool_label, "production UI label preserves selected tool")
	check.call(hotbar.assignments[6] != 20, "production UI sort remaps actual inventory index")
	InventoryDataCodec.decode_inventory(inventory, old_inventory)
	InventoryDataCodec.decode_hotbar(hotbar, old_hotbar)


static func _item(hotbar: HotbarModel, index: int) -> StringName:
	var slot_index: int = hotbar.assignments[index]
	return hotbar.inventory.slots[slot_index].item_id if slot_index >= 0 else &""
