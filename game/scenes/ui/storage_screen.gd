class_name StorageScreen
extends Control

signal closed

const PLAYER_COLUMNS: int = 6
const STORAGE_COLUMNS: int = 6

@onready var player_grid: GridContainer = %PlayerGrid
@onready var storage_grid: GridContainer = %StorageGrid
@onready var close_button: Button = %CloseButton

var player_inventory: InventoryModel
var storage: StorageInventory
var storage_id: StringName = &""
var player_buttons: Array[Button] = []
var storage_buttons: Array[Button] = []
var was_tree_paused: bool = false
var responsive_scroll: ResponsiveModalLayout


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	responsive_scroll = ResponsiveModalLayout.new()
	responsive_scroll.install(
		self,
		get_node("Center") as CenterContainer,
		get_node("Center/Panel") as Control
	)
	close_button.pressed.connect(close_screen)
	var inventory_service := get_node_or_null("/root/InventoryService") as InventoryCoordinator
	if inventory_service != null:
		inventory_service.models_replaced.connect(
			_on_inventory_models_replaced.bind(inventory_service)
		)
	hide()


func configure(player_model: InventoryModel, storage_model: StorageInventory) -> void:
	_disconnect_models()
	player_inventory = player_model
	storage = storage_model
	storage_id = storage.storage_id if storage != null else &""
	player_inventory.changed.connect(_refresh)
	storage.changed.connect(_refresh)
	_rebuild_buttons()
	_refresh()


func open_screen() -> void:
	was_tree_paused = get_tree().paused
	_refresh()
	show()
	get_tree().paused = true
	if not player_buttons.is_empty():
		player_buttons[0].grab_focus()


func close_screen() -> void:
	hide()
	get_tree().paused = was_tree_paused
	closed.emit()


func _input(event: InputEvent) -> void:
	if visible and _is_close_event(event):
		close_screen()
		get_viewport().set_input_as_handled()


func _rebuild_buttons() -> void:
	for child in player_grid.get_children():
		child.free()
	for child in storage_grid.get_children():
		child.free()
	player_buttons.clear()
	storage_buttons.clear()
	player_grid.columns = PLAYER_COLUMNS
	storage_grid.columns = STORAGE_COLUMNS
	for index in range(player_inventory.capacity):
		var button := _create_slot_button()
		button.pressed.connect(_transfer_to_storage.bind(index))
		player_grid.add_child(button)
		player_buttons.append(button)
	for index in range(storage.capacity):
		var button := _create_slot_button()
		button.pressed.connect(_transfer_to_player.bind(index))
		storage_grid.add_child(button)
		storage_buttons.append(button)


func _create_slot_button() -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(74.0, 50.0)
	button.focus_mode = Control.FOCUS_ALL
	return button


func _refresh() -> void:
	if player_inventory == null or storage == null:
		return
	for index in range(player_buttons.size()):
		player_buttons[index].text = _format_slot(player_inventory, index)
	for index in range(storage_buttons.size()):
		storage_buttons[index].text = _format_slot(storage, index)


func _format_slot(model: InventoryModel, index: int) -> String:
	var slot: InventorySlot = model.slots[index]
	if slot.is_empty():
		return tr(&"UI_INVENTORY_EMPTY_SLOT")
	var definition: ItemDefinition = model.registry.get_item(slot.item_id)
	if definition == null:
		return tr(&"UI_INVENTORY_UNKNOWN_ITEM")
	return "%s ×%d" % [tr(definition.name_key), slot.quantity]


func _transfer_to_storage(index: int) -> InventoryTransactionResult:
	return InventoryTransferService.transfer_slot(player_inventory, storage, index)


func _transfer_to_player(index: int) -> InventoryTransactionResult:
	return InventoryTransferService.transfer_slot(storage, player_inventory, index)


func _disconnect_models() -> void:
	if player_inventory != null and player_inventory.changed.is_connected(_refresh):
		player_inventory.changed.disconnect(_refresh)
	if storage != null and storage.changed.is_connected(_refresh):
		storage.changed.disconnect(_refresh)


func _on_inventory_models_replaced(inventory_service: InventoryCoordinator) -> void:
	var replacement := inventory_service.storages.get(storage_id) as StorageInventory
	if replacement == null:
		_disconnect_models()
		player_inventory = null
		storage = null
		if visible:
			close_screen()
		return
	configure(inventory_service.player_inventory, replacement)


func _is_close_event(event: InputEvent) -> bool:
	return event.is_action_pressed(&"pause_game") or event.is_action_pressed(&"toggle_inventory")
