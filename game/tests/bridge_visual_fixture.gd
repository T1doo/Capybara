extends SceneTree

const SCENE: PackedScene = preload("res://scenes/visual_prototypes/home_visual_blockout.tscn")
const OUTPUT: String = "res://../build/art-pipeline/bridge_review"


func _initialize() -> void:
	call_deferred(&"_capture")


func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("BRIDGE CAPTURE: requires a renderer")
		quit(2)
		return
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT)) != OK:
		quit(3)
		return
	var world := SCENE.instantiate() as HomeVisualBlockout
	root.add_child(world)
	await process_frame
	var player := world.get_node("Player") as PlayerCharacter
	player.follow_camera.enabled = false
	var camera := Camera2D.new()
	camera.position = Vector2(384,0)
	camera.zoom = Vector2(1.3,1.3)
	world.add_child(camera)
	var samples := {
		"center": Vector2(384,0), "front": Vector2(384,24), "rear": Vector2(384,-24),
		"west_end": Vector2(88,0), "east_end": Vector2(680,0),
	}
	for name in samples:
		player.position = samples[name]
		for frame in range(8):
			await physics_frame
		for frame in range(3):
			await process_frame
		await RenderingServer.frame_post_draw
		var result := root.get_texture().get_image().save_png(OUTPUT.path_join(name + ".png"))
		if result != OK:
			push_error("BRIDGE CAPTURE: failed " + name)
			quit(1)
			return
	print("BRIDGE CAPTURE PASSED: 5 views saved")
	quit(0)
