extends SceneTree

const CASES: Script = preload("res://tests/home_visual_preview_test_cases.gd")
const OUTPUT: String = "res://../build/art-pipeline/preview_ui_review"

var failures: int = 0


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	await CASES.run(self, _check)
	if failures > 0 or DisplayServer.get_name() == "headless":
		quit(1 if failures > 0 else 0)
		return
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT)) != OK:
		quit(2)
		return
	var service := root.get_node("SettingsService") as SettingsManagerService
	var profile := SettingsProfile.new()
	profile.locale = &"zh_CN"
	service.replace_settings(profile)
	service.apply_current_settings(false)
	var preview := CASES.SCENE.instantiate()
	root.add_child(preview)
	await process_frame
	await _capture("walking_zh")
	await CASES.key(self, KEY_ESCAPE)
	await _capture("pause_zh")
	await CASES.key(self, KEY_DOWN)
	await CASES.key(self, KEY_ENTER)
	await _capture("settings_zh")
	var settings := preview.get_node("Interface/SettingsScreen") as SettingsScreen
	settings.reduced_motion_check.button_pressed = true
	settings.apply_button.grab_focus()
	await CASES.key(self, KEY_ENTER)
	await _capture("settings_applied_zh")
	profile = service.current_settings.duplicate_profile()
	profile.locale = &"en"
	profile.resolution = Vector2i(1280,800)
	profile.ui_scale = 1.5
	service.replace_settings(profile)
	service.apply_current_settings()
	settings.open_screen()
	for frame in range(4):
		await process_frame
	settings.back_button.grab_focus()
	await _capture("settings_en_800_150")
	paused = false
	print("PREVIEW UI CAPTURE: 5 screenshots, failures=", failures)
	quit(1 if failures else 0)


func _capture(sample: String) -> void:
	for frame in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(OUTPUT.path_join(sample + ".png")) == OK,
		"captured " + sample)


func _check(passed: bool, description: String) -> void:
	if passed:
		print("PASS: ", description)
	else:
		failures += 1
		push_error("FAIL: " + description)
