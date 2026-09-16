class_name InputBindingFormatter
extends RefCounted


static func format_key(key: InputEventKey) -> String:
	if key == null:
		return ""
	var parts: Array[String] = []
	if key.ctrl_pressed:
		parts.append("Ctrl")
	if key.alt_pressed:
		parts.append("Alt")
	if key.shift_pressed:
		parts.append("Shift")
	if key.meta_pressed:
		parts.append("Meta")
	var code: int = key.keycode if key.keycode != 0 else key.physical_keycode
	var key_text: String = OS.get_keycode_string(code)
	if key_text.is_empty():
		return ""
	parts.append(key_text)
	return "+".join(parts)
