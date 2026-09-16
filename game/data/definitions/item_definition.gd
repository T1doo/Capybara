class_name ItemDefinition
extends Resource

enum Category {
	MATERIAL,
	FOOD,
	SEED,
	TOOL,
	QUEST,
	FURNITURE,
	OTHER,
}

@export var id: StringName = &""
@export var name_key: StringName = &""
@export var description_key: StringName = &""
@export var icon: Texture2D
@export var category: Category = Category.OTHER
@export_range(1, 999, 1) var max_stack: int = 1
@export_range(0, 999999, 1) var sell_price: int = 0
@export var tags: Array[StringName] = []
@export var world_scene: PackedScene


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if id.is_empty() or not String(id).is_valid_identifier():
		errors.append("CONTENT_INVALID_ITEM_ID")
	if name_key.is_empty():
		errors.append("CONTENT_MISSING_ITEM_NAME_KEY")
	if description_key.is_empty():
		errors.append("CONTENT_MISSING_ITEM_DESCRIPTION_KEY")
	if category < Category.MATERIAL or category > Category.OTHER:
		errors.append("CONTENT_INVALID_ITEM_CATEGORY")
	if max_stack < 1:
		errors.append("CONTENT_INVALID_MAX_STACK")
	if category == Category.TOOL and max_stack != 1:
		errors.append("CONTENT_TOOL_MUST_NOT_STACK")
	if sell_price < 0:
		errors.append("CONTENT_INVALID_SELL_PRICE")
	var seen_tags: Dictionary[StringName, bool] = {}
	for tag in tags:
		if tag.is_empty() or not String(tag).is_valid_identifier():
			errors.append("CONTENT_INVALID_ITEM_TAG")
		elif seen_tags.has(tag):
			errors.append("CONTENT_DUPLICATE_ITEM_TAG")
		else:
			seen_tags[tag] = true
	return errors


func has_tag(tag: StringName) -> bool:
	return tag in tags
