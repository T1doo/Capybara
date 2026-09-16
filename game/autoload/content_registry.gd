class_name ContentRegistryService
extends Node

signal registry_reloaded(item_count: int)

const BUILTIN_ITEM_DEFINITIONS: Array[ItemDefinition] = [
	preload("res://data/definitions/items/item_branch.tres"),
	preload("res://data/definitions/items/item_reed_fiber.tres"),
	preload("res://data/definitions/items/item_reed_spade.tres"),
]

var _item_definitions: Dictionary[StringName, ItemDefinition] = {}
var is_locked: bool = false
var last_error_key: StringName = &""
var last_error_subject_id: StringName = &""


func _ready() -> void:
	if not load_item_definitions(BUILTIN_ITEM_DEFINITIONS):
		push_error(
			"ContentRegistry startup validation failed: %s (%s)"
			% [last_error_key, last_error_subject_id]
		)
		return
	is_locked = true


func load_item_definitions(definitions: Array[ItemDefinition]) -> bool:
	if is_locked:
		return _fail(&"CONTENT_REGISTRY_LOCKED")
	var candidate_registry: Dictionary[StringName, ItemDefinition] = {}
	for definition in definitions:
		if definition == null:
			return _fail(&"CONTENT_NULL_ITEM_DEFINITION")
		var validation_errors: PackedStringArray = definition.validate()
		if not validation_errors.is_empty():
			return _fail(StringName(validation_errors[0]), definition.id)
		if candidate_registry.has(definition.id):
			return _fail(&"CONTENT_DUPLICATE_ITEM_ID", definition.id)
		candidate_registry[definition.id] = definition.duplicate(true) as ItemDefinition

	_item_definitions = candidate_registry
	last_error_key = &""
	last_error_subject_id = &""
	registry_reloaded.emit(_item_definitions.size())
	return true


func has_item(item_id: StringName) -> bool:
	return _item_definitions.has(item_id)


func get_item(item_id: StringName) -> ItemDefinition:
	var definition := _item_definitions.get(item_id) as ItemDefinition
	return definition.duplicate(true) as ItemDefinition if definition != null else null


func get_item_ids() -> Array[StringName]:
	var item_ids: Array[StringName] = []
	for item_id in _item_definitions:
		item_ids.append(item_id)
	item_ids.sort_custom(func(first: StringName, second: StringName) -> bool:
		return String(first) < String(second)
	)
	return item_ids


func get_item_count() -> int:
	return _item_definitions.size()


func _fail(error_key: StringName, subject_id: StringName = &"") -> bool:
	last_error_key = error_key
	last_error_subject_id = subject_id
	return false
