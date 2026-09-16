class_name ContentRegistryTestCases
extends RefCounted

const BRANCH_DEFINITION: ItemDefinition = preload(
	"res://data/definitions/items/item_branch.tres"
)
const REED_FIBER_DEFINITION: ItemDefinition = preload(
	"res://data/definitions/items/item_reed_fiber.tres"
)
const REED_SPADE_DEFINITION: ItemDefinition = preload(
	"res://data/definitions/items/item_reed_spade.tres"
)
const REGISTRY_SCRIPT: Script = preload("res://autoload/content_registry.gd")


static func run(assert_true: Callable, assert_int_equal: Callable) -> void:
	_test_item_definition_validation(assert_true)
	_test_transactional_registry(assert_true, assert_int_equal)


static func _test_item_definition_validation(assert_true: Callable) -> void:
	assert_true.call(BRANCH_DEFINITION.validate().is_empty(), "built-in branch definition is valid")
	assert_true.call(
		REED_FIBER_DEFINITION.validate().is_empty(),
		"built-in reed fiber definition is valid"
	)
	assert_true.call(
		REED_SPADE_DEFINITION.validate().is_empty()
		and REED_SPADE_DEFINITION.category == ItemDefinition.Category.TOOL,
		"built-in reed spade is a valid non-stacking tool"
	)
	var invalid_definition := _make_item(&"Invalid Item", 0, 1)
	invalid_definition.name_key = &""
	invalid_definition.description_key = &""
	invalid_definition.tags = [&"material", &"material", &""]
	var errors: PackedStringArray = invalid_definition.validate()
	assert_true.call(errors.has("CONTENT_INVALID_ITEM_ID"), "invalid item ID is rejected")
	assert_true.call(errors.has("CONTENT_MISSING_ITEM_NAME_KEY"), "missing name key is rejected")
	assert_true.call(
		errors.has("CONTENT_MISSING_ITEM_DESCRIPTION_KEY"),
		"missing description key is rejected"
	)
	assert_true.call(errors.has("CONTENT_INVALID_MAX_STACK"), "zero max stack is rejected")
	assert_true.call(errors.has("CONTENT_DUPLICATE_ITEM_TAG"), "duplicate tag is rejected")
	assert_true.call(errors.has("CONTENT_INVALID_ITEM_TAG"), "empty tag is rejected")
	var tool_definition := _make_item(&"item_test_tool", 2, -1)
	tool_definition.category = ItemDefinition.Category.TOOL
	var tool_errors: PackedStringArray = tool_definition.validate()
	assert_true.call(tool_errors.has("CONTENT_TOOL_MUST_NOT_STACK"), "stacked tool is rejected")
	assert_true.call(tool_errors.has("CONTENT_INVALID_SELL_PRICE"), "negative price is rejected")


static func _test_transactional_registry(
	assert_true: Callable,
	assert_int_equal: Callable
) -> void:
	var registry: ContentRegistryService = REGISTRY_SCRIPT.new()
	var valid_definitions: Array[ItemDefinition] = [
		REED_FIBER_DEFINITION,
		BRANCH_DEFINITION,
	]
	assert_true.call(registry.load_item_definitions(valid_definitions), "valid item registry loads")
	assert_int_equal.call(registry.get_item_count(), 2, "registry exposes its item count")
	assert_true.call(registry.has_item(&"item_branch"), "registry finds a stable item ID")
	assert_true.call(
		registry.get_item(&"item_branch").id == BRANCH_DEFINITION.id,
		"registry returns the registered definition data"
	)
	var sorted_item_ids: Array[StringName] = registry.get_item_ids()
	assert_true.call(
		sorted_item_ids.size() == 2
		and sorted_item_ids[0] == &"item_branch"
		and sorted_item_ids[1] == &"item_reed_fiber",
		"registry returns stable sorted IDs"
	)
	assert_true.call(registry.get_item(&"item_missing") == null, "missing item lookup returns null")

	var duplicate_branch := _make_item(&"item_branch", 99, 0)
	var duplicate_definitions: Array[ItemDefinition] = [BRANCH_DEFINITION, duplicate_branch]
	assert_true.call(
		not registry.load_item_definitions(duplicate_definitions),
		"duplicate item ID rejects registry reload"
	)
	assert_true.call(
		registry.last_error_key == &"CONTENT_DUPLICATE_ITEM_ID",
		"duplicate item returns a stable error key"
	)
	assert_int_equal.call(registry.get_item_count(), 2, "failed reload preserves previous registry")
	assert_true.call(
		registry.get_item(&"item_branch").max_stack == BRANCH_DEFINITION.max_stack,
		"failed reload preserves previous item definition data"
	)
	var external_copy: ItemDefinition = registry.get_item(&"item_branch")
	external_copy.max_stack = 1
	assert_true.call(
		registry.get_item(&"item_branch").max_stack == BRANCH_DEFINITION.max_stack,
		"registry callers cannot mutate registered definitions"
	)
	var null_definitions: Array[ItemDefinition] = [null]
	assert_true.call(
		not registry.load_item_definitions(null_definitions),
		"null item definition rejects registry reload"
	)
	assert_true.call(
		registry.last_error_key == &"CONTENT_NULL_ITEM_DEFINITION",
		"null definition returns a stable error key"
	)
	registry.free()


static func _make_item(item_id: StringName, stack_size: int, price: int) -> ItemDefinition:
	var definition := ItemDefinition.new()
	definition.id = item_id
	definition.name_key = &"ITEM_TEST_NAME"
	definition.description_key = &"ITEM_TEST_DESCRIPTION"
	definition.category = ItemDefinition.Category.MATERIAL
	definition.max_stack = stack_size
	definition.sell_price = price
	return definition
