class_name HomeAtmosphere2D
extends Node2D

## Four deterministic visual probes for one real home scene; not a weather clock.
const PRESETS: Array[StringName] = [&"clear_morning", &"sunset", &"rain", &"night"]
const RAIN_SEED: int = 20260923

var preset: StringName = &"clear_morning"
var tone_overlay: ColorRect
var night_glows: Array[Sprite2D] = []


func _ready() -> void:
	z_as_relative = false
	z_index = 100
	tone_overlay = ColorRect.new()
	tone_overlay.position = Vector2(-960, -600)
	tone_overlay.size = Vector2(1920, 1200)
	tone_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tone_overlay.z_index = -1
	var multiply := CanvasItemMaterial.new()
	multiply.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
	tone_overlay.material = multiply
	add_child(tone_overlay)
	var glow_texture: ImageTexture = _make_glow_texture()
	_make_window_glow(glow_texture, Vector2(-601, -376))
	_make_window_glow(glow_texture, Vector2(-421, -318))
	_apply_preset()


func set_preset(next_preset: StringName) -> bool:
	if not PRESETS.has(next_preset):
		push_error("Unknown home atmosphere preset: %s" % next_preset)
		return false
	preset = next_preset
	if is_inside_tree():
		_apply_preset()
	return true


func _apply_preset() -> void:
	match preset:
		&"clear_morning":
			tone_overlay.color = Color.WHITE
		&"sunset":
			tone_overlay.color = Color(1.0, 0.79, 0.66)
		&"rain":
			tone_overlay.color = Color(0.72, 0.81, 0.86)
		&"night":
			tone_overlay.color = Color(0.43, 0.49, 0.66)
	for glow in night_glows:
		glow.visible = preset == &"night"
	queue_redraw()


func _make_glow_texture() -> ImageTexture:
	var image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	for y in range(128):
		for x in range(128):
			var radius: float = Vector2(x - 63.5, y - 63.5).length() / 63.5
			var falloff: float = pow(maxf(0.0, 1.0 - radius), 2.2)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, falloff))
	return ImageTexture.create_from_image(image)


func _make_window_glow(texture: Texture2D, at: Vector2) -> void:
	var glow := Sprite2D.new()
	glow.texture = texture
	glow.position = at
	glow.scale = Vector2.ONE * 1.7
	glow.modulate = Color(1.0, 0.62, 0.27, 0.85)
	glow.z_index = 1
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = additive
	add_child(glow)
	night_glows.append(glow)


func _draw() -> void:
	if preset != &"rain":
		return
	var random := RandomNumberGenerator.new()
	random.seed = RAIN_SEED
	for _index in range(190):
		var start := Vector2(random.randf_range(-960.0, 960.0), random.randf_range(-600.0, 600.0))
		var length: float = random.randf_range(19.0, 36.0)
		draw_line(start, start + Vector2(length * 0.24, length), Color(0.89, 0.95, 1.0, 0.21), 1.5, true)
