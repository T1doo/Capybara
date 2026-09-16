extends SceneTree

const SCENE: PackedScene = preload("res://scenes/visual_prototypes/home_visual_blockout.tscn")
const OUTPUT: String = "res://../build/art-pipeline/waterwheel_review"


func _initialize() -> void:
	call_deferred(&"_capture")


func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("WATERWHEEL CAPTURE: requires a renderer")
		quit(2)
		return
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT)) != OK:
		quit(3)
		return
	var settings := root.get_node("SettingsService") as SettingsManagerService
	var profile := settings.current_settings.duplicate_profile()
	profile.reduced_motion = false
	settings.replace_settings(profile)
	var world := SCENE.instantiate() as HomeVisualBlockout
	root.add_child(world)
	await process_frame
	var player := world.get_node("Player") as PlayerCharacter
	player.follow_camera.enabled = false
	player.position = world.get_anchor_position(&"WaterwheelService")
	var camera := Camera2D.new()
	camera.position = Vector2(640,-300)
	camera.zoom = Vector2(2,2)
	world.add_child(camera)
	var mill := world.get_node("PaintedWaterwheel") as PaintedWaterwheel2D
	for sample in ["flowing_a","flowing_b","reduced_motion","feed_off","north_side"]:
		if sample == "reduced_motion":
			profile.reduced_motion = true
			settings.replace_settings(profile)
		if sample == "feed_off":
			mill.set_flow_enabled(false)
		if sample == "north_side":
			player.position = Vector2(768,-432)
		for frame in range(20):
			await physics_frame
		for frame in range(3):
			await process_frame
		await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png(OUTPUT.path_join(sample + ".png")) != OK:
			quit(1)
			return
		print("WATERWHEEL CAPTURE: ",sample," angle=",mill.wheel.rotation)
	print("WATERWHEEL CAPTURE PASSED: 5 views saved")
	quit(0)
