extends SceneTree

const SCENE: PackedScene = preload("res://scenes/visual_prototypes/home_visual_blockout.tscn")
const OUTPUT: String = "res://../build/art-pipeline/cottage_review"
var failures: int = 0


func _initialize() -> void:
	call_deferred(&"_capture")


func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("COTTAGE CAPTURE: requires the Compatibility renderer")
		quit(2)
		return
	var directory_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	if directory_error != OK:
		quit(3)
		return
	var settings := root.get_node("SettingsService") as SettingsManagerService
	var profile := settings.current_settings.duplicate_profile()
	profile.reduced_motion = true
	settings.replace_settings(profile)
	var world := SCENE.instantiate() as HomeVisualBlockout
	root.add_child(world)
	await process_frame
	var player := world.get_node("Player") as PlayerCharacter
	player.follow_camera.enabled = false
	var camera := Camera2D.new()
	camera.position = Vector2(-510.0, -325.0)
	world.add_child(camera)
	var cottage := world.get_node("CottagePrototype") as LayeredCottage2D
	player.position = cottage.to_global(Vector2(0.0, -210.0))
	for frame in range(8):
		await physics_frame
	for frame in range(3):
		await process_frame
	await RenderingServer.frame_post_draw
	_save(root.get_texture().get_image(), "roof_faded.png")
	print("COTTAGE CAPTURE: faded alpha=", cottage.roof_layer.modulate.a, " overlaps=", cottage.get_overlapping_bodies().size(), " position=", player.global_position)
	if not cottage.is_roof_faded() or cottage.roof_layer.modulate.a >= 0.99:
		failures += 1
		push_error("COTTAGE CAPTURE: actual overlap did not reveal player")
	# Diagnostic control at the same player/camera position: opaque roof must hide the player.
	cottage.set_roof_faded(false, true)
	for frame in range(3):
		await process_frame
	await RenderingServer.frame_post_draw
	_save(root.get_texture().get_image(), "roof_opaque.png")
	player.position = world.get_anchor_position(&"HouseMainDoor")
	await physics_frame
	await physics_frame
	for frame in range(3):
		await process_frame
	await RenderingServer.frame_post_draw
	_save(root.get_texture().get_image(), "door_approach.png")
	# Same-camera control for judging surface painting, without changing geometry or Alpha.
	for layer in [cottage.walls_layer, cottage.roof_layer]:
		(layer.material as ShaderMaterial).set_shader_parameter(&"paint_strength", 0.0)
	for frame in range(3):
		await process_frame
	await RenderingServer.frame_post_draw
	_save(root.get_texture().get_image(), "unpainted_control.png")
	for layer in [cottage.walls_layer, cottage.roof_layer]:
		(layer.material as ShaderMaterial).set_shader_parameter(&"paint_strength", 1.0)
	var canvas := SubViewport.new()
	canvas.size = Vector2i(1024, 1024)
	canvas.transparent_bg = true
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(canvas)
	var alpha_reference := Image.create(1024, 1024, false, Image.FORMAT_RGBA8)
	alpha_reference.fill(Color.TRANSPARENT)
	for layer in [cottage.shadow_layer, cottage.walls_layer, cottage.roof_layer]:
		var pixels: Image = layer.texture.get_image()
		pixels.convert(Image.FORMAT_RGBA8)
		_save(pixels, String(layer.name).to_snake_case() + ".png")
		alpha_reference.blend_rect(pixels, Rect2i(0, 0, 1024, 1024), Vector2i.ZERO)
		var sprite := Sprite2D.new()
		sprite.texture = layer.texture
		sprite.material = layer.material
		sprite.position = Vector2(512.0, 512.0)
		canvas.add_child(sprite)
	for frame in range(3):
		await process_frame
	await RenderingServer.frame_post_draw
	var assembled: Image = canvas.get_texture().get_image()
	var alpha_mismatches: int = 0
	for y in range(0, 1024, 4):
		for x in range(0, 1024, 4):
			if absf(assembled.get_pixel(x, y).a - alpha_reference.get_pixel(x, y).a) > 0.01:
				alpha_mismatches += 1
	if alpha_mismatches > 0:
		failures += 1
		push_error("COTTAGE CAPTURE: painting changed source Alpha at %d samples" % alpha_mismatches)
	print("COTTAGE CAPTURE: Alpha samples=65536 mismatches=", alpha_mismatches)
	_save(assembled, "assembled.png")
	var sheet := Image.create(1024, 1024, false, Image.FORMAT_RGBA8)
	var backgrounds: Array[Color] = [Color.WHITE, Color.BLACK, Color("#78906d"), Color("#5ea7a0")]
	for index in range(backgrounds.size()):
		var panel := Image.create(1024, 1024, false, Image.FORMAT_RGBA8)
		panel.fill(backgrounds[index])
		panel.blend_rect(assembled, Rect2i(0, 0, 1024, 1024), Vector2i.ZERO)
		panel.resize(512, 512, Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(panel, Rect2i(0, 0, 512, 512), Vector2i(index % 2, index / 2) * 512)
	_save(sheet, "four_backgrounds.png")
	print("COTTAGE CAPTURE: failures=%d output=%s" % [failures, OUTPUT])
	quit(0 if failures == 0 else 1)


func _save(pixels: Image, filename: String) -> void:
	var result := pixels.save_png(OUTPUT.path_join(filename))
	if result != OK:
		failures += 1
		push_error("COTTAGE CAPTURE: %s failed: %s" % [filename, error_string(result)])
