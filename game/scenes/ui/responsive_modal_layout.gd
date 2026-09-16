class_name ResponsiveModalLayout
extends ScrollContainer

var content_center: CenterContainer
var panel: Control


func install(screen: Control, previous_center: CenterContainer, modal_panel: Control) -> void:
	name = "ResponsiveScroll"
	process_mode = Node.PROCESS_MODE_ALWAYS
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	follow_focus = true
	previous_center.remove_child(modal_panel)
	previous_center.hide()
	screen.add_child(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_center = CenterContainer.new()
	content_center.name = "ContentCenter"
	content_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(content_center)
	panel = modal_panel
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	content_center.add_child(panel)
	resized.connect(_sync_content_size)
	panel.minimum_size_changed.connect(_sync_content_size)
	call_deferred(&"_sync_content_size")


func _sync_content_size() -> void:
	if content_center == null or panel == null:
		return
	var panel_minimum: Vector2 = panel.get_combined_minimum_size()
	content_center.custom_minimum_size = Vector2(
		maxf(size.x, panel_minimum.x),
		maxf(size.y, panel_minimum.y)
	)
