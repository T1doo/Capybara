class_name StorageInventory
extends InventoryModel

const DEFAULT_STORAGE_CAPACITY: int = 32

var storage_id: StringName


func _init(
	content_registry: ContentRegistryService,
	stable_storage_id: StringName,
	slot_capacity: int = DEFAULT_STORAGE_CAPACITY
) -> void:
	storage_id = stable_storage_id
	super(content_registry, slot_capacity)


func has_valid_id() -> bool:
	return not storage_id.is_empty() and String(storage_id).is_valid_identifier()
