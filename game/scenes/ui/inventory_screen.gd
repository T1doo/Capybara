class_name InventoryScreen
extends Control

const INVENTORY_COLUMNS: int = 6

@onready var capacity_label: Label = %CapacityLabel
@onready var slot_grid: GridContainer = %SlotGrid
@onready var hotbar_row: HBoxContainer = %HotbarRow
@onready var split_button: Button = %SplitButton
@onready var assign_button: Button = %AssignButton
@onready var discard_button: Button = %DiscardButton
@onready var sort_button: Button = %SortButton
@onready var status_label: Label = %StatusLabel

var inventory: InventoryModel
var hotbar: HotbarModel
var slot_buttons: Array[Button] = []
var hotbar_buttons: Array[Button] = []
var was_tree_paused_before_open: bool = false
var selected_slot_index: int = 0
var discard_confirmation_slot: int = -1
var responsive_scroll: ResponsiveModalLayout


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	responsive_scroll = ResponsiveModalLayout.new()
	responsive_scroll.install(
		self,
		get_node("CenterContainer") as CenterContainer,
		get_node("CenterContainer/PanelContainer") as Control
	)
	var inventory_service := get_node_or_null("/root/InventoryService") as InventoryCoordinator
	if inventory_service != null:
		inventory_service.models_replaced.connect(_on_inventory_models_replaced.bind(inventory_service))
		configure(inventory_service.player_inventory, inventory_service.hotbar)
	split_button.pressed.connect(_split_selected_stack)
	assign_button.pressed.connect(_assign_selected_to_hotbar)
	discard_button.pressed.connect(_discard_selected_item)
	sort_button.pressed.connect(_sort_inventory)
	hide()


func configure(inventory_model: InventoryModel, hotbar_model: HotbarModel) -> void:
	_disconnect_models()
	inventory = inventory_model
	hotbar = hotbar_model
	if inventory != null:
		inventory.changed.connect(_refresh)
	if hotbar != null:
		hotbar.selection_changed.connect(_on_hotbar_selection_changed)
		hotbar.assignment_changed.connect(_on_hotbar_assignment_changed)
	_rebuild_controls()
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if _handle_inventory_toggle(event):
		get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if _handle_inventory_toggle(event):
		get_viewport().set_input_as_handled()
		return
	if visible and _is_pause_requested(event):
		close_inventory()
		get_viewport().set_input_as_handled()


func open_inventory() -> void:
	_refresh()
	was_tree_paused_before_open = get_tree().paused
	show()
	get_tree().paused = true
	discard_confirmation_slot = -1
	status_label.text = ""
	if not slot_buttons.is_empty():
		slot_buttons[0].grab_focus()


func close_inventory() -> void:
	hide()
	get_tree().paused = was_tree_paused_before_open


func get_slot_button(index: int) -> Button:
	return slot_buttons[index] if index >= 0 and index < slot_buttons.size() else null


func get_hotbar_button(index: int) -> Button:
	return hotbar_buttons[index] if index >= 0 and index < hotbar_buttons.size() else null


func _rebuild_controls() -> void:
	for child in slot_grid.get_children():
		child.free()
	for child in hotbar_row.get_children():
		child.free()
	slot_buttons.clear()
	hotbar_buttons.clear()
	if inventory == null:
		return
	slot_grid.columns = INVENTORY_COLUMNS
	for slot_index in range(inventory.capacity):
		var slot_button := Button.new()
		slot_button.custom_minimum_size = Vector2(96.0, 64.0)
		slot_button.focus_mode = Control.FOCUS_ALL
		slot_button.tooltip_text = tr(&"UI_INVENTORY_SLOT_TOOLTIP") % (slot_index + 1)
		slot_button.pressed.connect(_select_slot.bind(slot_index))
		slot_grid.add_child(slot_button)
		slot_buttons.append(slot_button)
	if hotbar == null:
		return
	for hotbar_index in range(hotbar.assignments.size()):
		var hotbar_button := Button.new()
		hotbar_button.custom_minimum_size = Vector2(68.0, 54.0)
		hotbar_button.focus_mode = Control.FOCUS_ALL
		hotbar_button.pressed.connect(_on_hotbar_pressed.bind(hotbar_index))
		hotbar_row.add_child(hotbar_button)
		hotbar_buttons.append(hotbar_button)


func _refresh() -> void:
	if inventory == null:
		return
	capacity_label.text = tr(&"UI_INVENTORY_CAPACITY") % [
		inventory.get_occupied_slot_count(),
		inventory.capacity,
	]
	for index in range(mini(slot_buttons.size(), inventory.slots.size())):
		slot_buttons[index].text = _format_slot(inventory.slots[index])
	_refresh_hotbar()


func _refresh_hotbar() -> void:
	if hotbar == null or inventory == null:
		return
	for index in range(hotbar_buttons.size()):
		var inventory_slot_index: int = hotbar.assignments[index]
		var slot: InventorySlot = null
		if inventory_slot_index >= 0 and inventory_slot_index < inventory.slots.size():
			slot = inventory.slots[inventory_slot_index]
		var prefix: String = "▶ " if index == hotbar.selected_index else ""
		hotbar_buttons[index].text = "%s%d\n%s" % [prefix, index + 1, _format_slot(slot)]


func _format_slot(slot: InventorySlot) -> String:
	if slot == null or slot.is_empty():
		return tr(&"UI_INVENTORY_EMPTY_SLOT")
	var definition: ItemDefinition = inventory.registry.get_item(slot.item_id)
	if definition == null:
		return tr(&"UI_INVENTORY_UNKNOWN_ITEM")
	return "%s ×%d" % [tr(definition.name_key), slot.quantity]


func _disconnect_models() -> void:
	if inventory != null and inventory.changed.is_connected(_refresh):
		inventory.changed.disconnect(_refresh)
	if hotbar != null:
		if hotbar.selection_changed.is_connected(_on_hotbar_selection_changed):
			hotbar.selection_changed.disconnect(_on_hotbar_selection_changed)
		if hotbar.assignment_changed.is_connected(_on_hotbar_assignment_changed):
			hotbar.assignment_changed.disconnect(_on_hotbar_assignment_changed)


func _is_pause_requested(event: InputEvent) -> bool:
	if event.is_action_pressed(&"pause_game"):
		return true
	if event is InputEventKey:
		var key_event := event as InputEventKey
		return (
			key_event.pressed
			and not key_event.echo
			and (
				key_event.keycode == KEY_ESCAPE
				or key_event.physical_keycode == KEY_ESCAPE
			)
		)
	if event is InputEventJoypadButton:
		var button_event := event as InputEventJoypadButton
		return button_event.pressed and button_event.button_index == JOY_BUTTON_START
	return false


func _handle_inventory_toggle(event: InputEvent) -> bool:
	if not event.is_action_pressed(&"toggle_inventory"):
		return false
	if visible:
		close_inventory()
	elif not get_tree().paused:
		open_inventory()
	else:
		return false
	return true


func _on_hotbar_pressed(index: int) -> void:
	if hotbar != null:
		hotbar.select(index)


func _select_slot(index: int) -> void:
	selected_slot_index = index
	discard_confirmation_slot = -1
	status_label.text = tr(&"UI_INVENTORY_SELECTED_SLOT") % (index + 1)


func _split_selected_stack() -> void:
	if not _has_selected_item():
		_show_operation_result(false)
		return
	var slot: InventorySlot = inventory.slots[selected_slot_index]
	if slot.quantity < 2:
		_show_operation_result(false)
		return
	var success: bool = inventory.split_stack(selected_slot_index, floori(slot.quantity / 2.0))
	_show_operation_result(success)


func _assign_selected_to_hotbar() -> void:
	if not _has_selected_item() or hotbar == null:
		_show_operation_result(false)
		return
	_show_operation_result(hotbar.assign(hotbar.selected_index, selected_slot_index))


func _discard_selected_item() -> void:
	if not _has_selected_item():
		_show_operation_result(false)
		return
	if discard_confirmation_slot != selected_slot_index:
		discard_confirmation_slot = selected_slot_index
		status_label.text = tr(&"UI_INVENTORY_CONFIRM_DISCARD")
		return
	var result: InventoryTransactionResult = inventory.discard_from_slot(
		selected_slot_index,
		1
	)
	discard_confirmation_slot = -1
	if result.reason_key == &"INVENTORY_QUEST_ITEM_LOCKED":
		status_label.text = tr(&"UI_INVENTORY_DISCARD_LOCKED")
	else:
		_show_operation_result(result.made_progress())


func _sort_inventory() -> void:
	if inventory == null:
		_show_operation_result(false)
		return
	inventory.sort_and_compact()
	selected_slot_index = 0
	discard_confirmation_slot = -1
	status_label.text = tr(&"UI_INVENTORY_SORTED")


func _has_selected_item() -> bool:
	return (
		inventory != null
		and selected_slot_index >= 0
		and selected_slot_index < inventory.slots.size()
		and not inventory.slots[selected_slot_index].is_empty()
	)


func _show_operation_result(success: bool) -> void:
	status_label.text = tr(
		&"UI_INVENTORY_OPERATION_SUCCESS" if success else &"UI_INVENTORY_OPERATION_FAILED"
	)


func _on_hotbar_selection_changed(_previous_index: int, _current_index: int) -> void:
	_refresh_hotbar()


func _on_hotbar_assignment_changed(_hotbar_index: int, _inventory_slot_index: int) -> void:
	_refresh_hotbar()


func _on_inventory_models_replaced(inventory_service: InventoryCoordinator) -> void:
	configure(inventory_service.player_inventory, inventory_service.hotbar)
