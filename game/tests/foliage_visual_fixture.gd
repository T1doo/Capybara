extends SceneTree

const SCENE: PackedScene = preload("res://scenes/visual_prototypes/home_visual_blockout.tscn")
const OUTPUT: String = "res://../build/art-pipeline/foliage_review"


func _initialize() -> void:
	call_deferred(&"_capture")


func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("FOLIAGE CAPTURE: requires a renderer")
		quit(2)
		return
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT)) != OK:
		quit(3)
		return
	var world := SCENE.instantiate() as HomeVisualBlockout
	world.show_grid = false
	world.show_anchor_guides = false
	root.add_child(world)
	await process_frame
	var player := world.get_node("Player") as PlayerCharacter
	player.follow_camera.enabled = false
	var camera := Camera2D.new()
	camera.position = Vector2(-256,20)
	camera.zoom = Vector2(1.65,1.65)
	world.add_child(camera)
	var service := root.get_node("SettingsService") as SettingsManagerService
	var profile := service.current_settings.duplicate_profile()
	profile.reduced_motion = true
	service.replace_settings(profile)
	for sample in ["opaque","occluded","restored"]:
		player.position = Vector2(-256,0) if sample == "occluded" else Vector2(0,0)
		for frame in range(6):
			await physics_frame
		for frame in range(3):
			await process_frame
		await RenderingServer.frame_post_draw
		if not _save(root.get_texture().get_image(),sample):
			return
	var viewport := SubViewport.new()
	viewport.size = Vector2i(512,512)
	viewport.world_2d = World2D.new()
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var crown := PaintedFoliage2D.new()
	crown.position = Vector2(256,256)
	viewport.add_child(crown)
	for alpha in [1.0,0.34]:
		crown.modulate.a = alpha
		for frame in range(4):
			await process_frame
		await RenderingServer.frame_post_draw
		var rendered := viewport.get_texture().get_image()
		if absf(rendered.get_pixel(256,256).a-alpha) > 0.02 or rendered.get_pixel(8,8).a > 0.01:
			push_error("FOLIAGE CAPTURE: actual shader alpha does not preserve fade or transparent padding")
			quit(1)
			return
		if not _save(rendered,"alpha_" + str(alpha)):
			return
	print("FOLIAGE CAPTURE PASSED: 3 world views and 2 alpha renders; actual center alpha 1.0/0.34, corner 0")
	quit(0)


func _save(rendered: Image, sample: String) -> bool:
	if rendered.save_png(OUTPUT.path_join(sample + ".png")) != OK:
		quit(1)
		return false
	return true
