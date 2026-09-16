extends SceneTree

const SCENE: PackedScene = preload("res://scenes/visual_prototypes/home_visual_blockout.tscn")
const OUTPUT: String = "res://../build/art-pipeline/dock_review"


func _initialize() -> void:
	call_deferred(&"_capture")


func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("DOCK CAPTURE: requires a renderer")
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
	camera.position = Vector2(704,302)
	camera.zoom = Vector2(1.9,1.9)
	world.add_child(camera)
	var views: Dictionary[String, Vector2] = {
		"shore_entrance":Vector2(768,216),
		"deck_center":Vector2(704,350),
		"river_side":Vector2(590,352),
		"front_rail":Vector2(704,380),
		"east_rail":Vector2(828,352),
	}
	for sample in views:
		player.position = views[sample]
		for frame in range(8):
			await physics_frame
		for frame in range(3):
			await process_frame
		await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png(OUTPUT.path_join(sample + ".png")) != OK:
			quit(1)
			return
		print("DOCK CAPTURE: ", sample)
	print("DOCK CAPTURE PASSED: 5 views saved")
	quit(0)
