class_name InventoryTestCases
extends RefCounted

const REGISTRY_SCRIPT: Script = preload("res://autoload/content_registry.gd")


static func run(assert_true: Callable, assert_int_equal: Callable) -> void:
	var registry := _make_registry()
	_test_add_remove_and_simulation(registry, assert_true, assert_int_equal)
	_test_slot_operations(registry, assert_true, assert_int_equal)
	_test_quest_discard_rule(registry, assert_true, assert_int_equal)
	_test_hotbar_and_storage(registry, assert_true, assert_int_equal)
	_test_deterministic_random_transactions(registry, assert_true, assert_int_equal)
	registry.free()


static func _test_add_remove_and_simulation(
	registry: ContentRegistryService,
	assert_true: Callable,
	assert_int_equal: Callable
) -> void:
	var inventory := InventoryModel.new(registry, 2)
	var partial_add: InventoryTransactionResult = inventory.add_item(&"item_test_material", 12)
	assert_int_equal.call(partial_add.status, InventoryTransactionResult.Status.PARTIAL, "full inventory returns Partial")
	assert_int_equal.call(partial_add.transferred, 10, "partial add transfers available capacity")
	assert_int_equal.call(partial_add.remainder, 2, "partial add reports its remainder")
	assert_int_equal.call(inventory.count_item(&"item_test_material"), 10, "stacked total is correct")
	assert_true.call(inventory.validate_invariants(), "inventory invariants hold after partial add")

	var simulated_remove: InventoryTransactionResult = inventory.remove_item(
		&"item_test_material",
		7,
		true
	)
	assert_true.call(simulated_remove.is_success(), "simulated remove reports success")
	assert_int_equal.call(inventory.count_item(&"item_test_material"), 10, "simulation does not mutate inventory")
	var exact_failure := inventory.remove_item_exact(&"item_test_material", 11)
	assert_int_equal.call(exact_failure.transferred, 0, "failed exact remove transfers nothing")
	assert_int_equal.call(inventory.count_item(&"item_test_material"), 10, "failed exact remove is atomic")
	assert_true.call(
		inventory.remove_item_exact(&"item_test_material", 7).is_success(),
		"exact remove succeeds when enough items exist"
	)
	assert_int_equal.call(inventory.count_item(&"item_test_material"), 3, "exact remove updates total")
	assert_true.call(inventory.validate_invariants(), "inventory invariants hold after remove")


static func _test_slot_operations(
	registry: ContentRegistryService,
	assert_true: Callable,
	assert_int_equal: Callable
) -> void:
	var inventory := InventoryModel.new(registry, 5)
	inventory.add_item(&"item_test_food", 8)
	assert_true.call(inventory.split_stack(0, 3, 2), "stack splits into an empty target")
	assert_int_equal.call(inventory.slots[0].quantity, 5, "split preserves source remainder")
	assert_int_equal.call(inventory.slots[2].quantity, 3, "split writes requested target quantity")
	assert_true.call(inventory.move_or_merge(2, 0), "matching stacks merge")
	assert_int_equal.call(inventory.slots[0].quantity, 8, "merged quantity is correct")
	assert_true.call(inventory.slots[2].is_empty(), "merged source becomes empty")
	inventory.add_item(&"item_test_material", 5)
	assert_true.call(inventory.move_or_merge(0, 1), "different full stacks swap")
	assert_true.call(inventory.slots[0].item_id == &"item_test_material", "swap updates source")
	assert_true.call(inventory.slots[1].item_id == &"item_test_food", "swap updates target")
	inventory.sort_and_compact()
	assert_true.call(inventory.slots[0].item_id == &"item_test_material", "sort uses category then stable ID")
	assert_true.call(inventory.validate_invariants(), "inventory invariants hold after sort")


static func _test_quest_discard_rule(
	registry: ContentRegistryService,
	assert_true: Callable,
	assert_int_equal: Callable
) -> void:
	var inventory := InventoryModel.new(registry, 4)
	inventory.add_item(&"item_test_quest", 1)
	var result: InventoryTransactionResult = inventory.discard_from_slot(0, 1)
	assert_int_equal.call(result.status, InventoryTransactionResult.Status.REJECTED, "quest item discard is rejected")
	assert_int_equal.call(inventory.count_item(&"item_test_quest"), 1, "quest item remains after rejected discard")
	assert_true.call(inventory.validate_invariants(), "quest discard rejection preserves invariants")


static func _test_deterministic_random_transactions(
	registry: ContentRegistryService,
	assert_true: Callable,
	assert_int_equal: Callable
) -> void:
	var inventory := InventoryModel.new(registry, 24)
	var expected_totals: Dictionary[StringName, int] = {
		&"item_test_material": 0,
		&"item_test_food": 0,
	}
	var random := RandomNumberGenerator.new()
	random.seed = 0xCA9B4A
	var item_ids: Array[StringName] = [&"item_test_material", &"item_test_food"]
	var all_invariants_valid: bool = true
	var all_totals_accounted: bool = true
	for _operation_index in range(200):
		var item_id: StringName = item_ids[random.randi_range(0, item_ids.size() - 1)]
		var quantity: int = random.randi_range(1, 12)
		if random.randi_range(0, 1) == 0:
			var add_result: InventoryTransactionResult = inventory.add_item(item_id, quantity)
			expected_totals[item_id] += add_result.transferred
		else:
			var remove_result: InventoryTransactionResult = inventory.remove_item(item_id, quantity)
			expected_totals[item_id] -= remove_result.transferred
		all_invariants_valid = all_invariants_valid and inventory.validate_invariants()
		all_totals_accounted = (
			all_totals_accounted
			and inventory.count_item(item_id) == expected_totals[item_id]
		)
	assert_true.call(all_invariants_valid, "200 random transactions preserve every invariant")
	assert_true.call(all_totals_accounted, "200 random transactions preserve accounted totals")
	for item_id in item_ids:
		assert_int_equal.call(
			inventory.count_item(item_id),
			expected_totals[item_id],
			"final randomized total matches accounting"
		)


static func _test_hotbar_and_storage(
	registry: ContentRegistryService,
	assert_true: Callable,
	assert_int_equal: Callable
) -> void:
	var inventory := InventoryModel.new(registry, 24)
	inventory.add_item(&"item_test_material", 5)
	inventory.add_item(&"item_test_food", 4)
	var hotbar := HotbarModel.new(inventory, 8)
	assert_int_equal.call(hotbar.assignments.size(), 8, "hotbar exposes eight assignments")
	assert_true.call(hotbar.get_selected_item_id() == &"item_test_material", "hotbar reads inventory slot data")
	assert_int_equal.call(hotbar.select_offset(-1), 7, "hotbar selection wraps backward")
	assert_int_equal.call(hotbar.select_offset(1), 0, "hotbar selection wraps forward")
	assert_true.call(hotbar.assign(2, 1), "hotbar accepts a valid slot assignment")
	assert_true.call(not hotbar.assign(2, 99), "hotbar rejects an invalid slot assignment")
	hotbar.select(2)
	assert_true.call(hotbar.get_selected_item_id() == &"item_test_food", "hotbar assignment follows inventory slot")

	var storage := StorageInventory.new(registry, &"storage_test_chest", 2)
	assert_true.call(storage.has_valid_id(), "storage uses a valid stable ID")
	var transfer: InventoryTransactionResult = InventoryTransferService.transfer_slot(
		inventory,
		storage,
		0,
		3,
		false
	)
	assert_true.call(transfer.is_success(), "inventory transfers an exact stack quantity to storage")
	assert_int_equal.call(inventory.count_item(&"item_test_material"), 2, "source total decreases after transfer")
	assert_int_equal.call(storage.count_item(&"item_test_material"), 3, "storage total increases after transfer")
	storage.add_item(&"item_test_material", 7)
	var source_before: int = inventory.count_item(&"item_test_food")
	var destination_before: int = storage.count_item(&"item_test_food")
	var rejected_transfer: InventoryTransactionResult = InventoryTransferService.transfer_slot(
		inventory,
		storage,
		1,
		4,
		false
	)
	assert_int_equal.call(
		rejected_transfer.status,
		InventoryTransactionResult.Status.REJECTED,
		"full storage rejects a required-complete transfer"
	)
	assert_int_equal.call(inventory.count_item(&"item_test_food"), source_before, "rejected transfer preserves source")
	assert_int_equal.call(storage.count_item(&"item_test_food"), destination_before, "rejected transfer preserves destination")
	assert_true.call(inventory.validate_invariants(), "source invariants hold after transfers")
	assert_true.call(storage.validate_invariants(), "storage invariants hold after transfers")


static func _make_registry() -> ContentRegistryService:
	var registry: ContentRegistryService = REGISTRY_SCRIPT.new()
	var material := _make_item(&"item_test_material", ItemDefinition.Category.MATERIAL, 5)
	var food := _make_item(&"item_test_food", ItemDefinition.Category.FOOD, 10)
	var quest := _make_item(&"item_test_quest", ItemDefinition.Category.QUEST, 1)
	quest.tags = [&"quest_item"]
	var definitions: Array[ItemDefinition] = [material, food, quest]
	registry.load_item_definitions(definitions)
	return registry


static func _make_item(
	item_id: StringName,
	category: ItemDefinition.Category,
	max_stack: int
) -> ItemDefinition:
	var definition := ItemDefinition.new()
	definition.id = item_id
	definition.name_key = &"ITEM_TEST_NAME"
	definition.description_key = &"ITEM_TEST_DESCRIPTION"
	definition.category = category
	definition.max_stack = max_stack
	return definition
