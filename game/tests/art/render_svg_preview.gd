extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	if arguments.size() != 2:
		push_error("SVG PREVIEW: expected input SVG and output PNG paths")
		quit(2)
		return
	var input_path: String = arguments[0]
	var output_path: String = arguments[1]
	if not FileAccess.file_exists(input_path):
		push_error("SVG PREVIEW: input does not exist")
		quit(3)
		return
	var svg_text: String = FileAccess.get_file_as_string(input_path)
	if svg_text.is_empty():
		push_error("SVG PREVIEW: input is empty or unreadable")
		quit(4)
		return
	var image := Image.new()
	var load_error: Error = image.load_svg_from_string(svg_text, 1.0)
	if load_error != OK:
		push_error("SVG PREVIEW: load failed with %s" % error_string(load_error))
		quit(5)
		return
	var save_error: Error = image.save_png(output_path)
	if save_error != OK:
		push_error("SVG PREVIEW: save failed with %s" % error_string(save_error))
		quit(6)
		return
	print("SVG PREVIEW PASSED: %dx%d" % [image.get_width(), image.get_height()])
	quit(0)
