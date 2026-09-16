class_name DebugOverlayTestCases
extends RefCounted


static func run(
	main_scene: Node,
	debug_key_event: InputEventKey,
	assert_true: Callable
) -> void:
	var debug_overlay := main_scene.get_node("Interface/DebugOverlay") as DebugOverlay
	debug_overlay.refresh_now()
	assert_true.call(debug_overlay.visible, "debug overlay starts visible in the prototype")
	assert_true.call(
		debug_overlay.text.contains("zone_home_placeholder"),
		"debug overlay reports the current zone"
	)
	assert_true.call(debug_overlay.text.contains("1"), "debug overlay reports runtime counts")
	debug_key_event.pressed = true
	debug_overlay._unhandled_input(debug_key_event)
	assert_true.call(not debug_overlay.visible, "F3 hides the debug overlay")
	debug_overlay._unhandled_input(debug_key_event)
	assert_true.call(debug_overlay.visible, "F3 restores the debug overlay")
