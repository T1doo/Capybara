class_name CanopyOccluder2D
extends Area2D

@export var full_alpha: float = 1.0
@export var faded_alpha: float = 0.34
@export var fade_seconds: float = 0.18
@export var canopy_dark: Color = Color("#3f6549")
@export var canopy_mid: Color = Color("#567b52")
@export var canopy_light: Color = Color("#78975d")
@export var draw_placeholder: bool = true

var _overlapping_players: Dictionary[int, bool] = {}
var _active_tween: Tween
var _reduced_motion: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	var settings_service := get_node_or_null("/root/SettingsService") as SettingsManagerService
	if settings_service != null:
		settings_service.settings_changed.connect(_on_settings_changed)
		_on_settings_changed(settings_service.current_settings)
	queue_redraw()


func is_occluded() -> bool:
	return not _overlapping_players.is_empty()


func set_occluded(occluded: bool, immediate: bool = false) -> void:
	var target_alpha := faded_alpha if occluded else full_alpha
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	if immediate or _reduced_motion or is_zero_approx(fade_seconds):
		modulate.a = target_alpha
		return
	_active_tween = create_tween()
	_active_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_active_tween.tween_property(self, ^"modulate:a", target_alpha, fade_seconds)


func _draw() -> void:
	if not draw_placeholder:
		return
	draw_circle(Vector2.ZERO, 116.0, canopy_dark)
	draw_circle(Vector2(-64.0, 10.0), 82.0, canopy_mid)
	draw_circle(Vector2(58.0, -18.0), 88.0, canopy_mid)
	draw_circle(Vector2(-18.0, -62.0), 76.0, canopy_light)
	draw_circle(Vector2(76.0, 40.0), 58.0, Color(canopy_light, 0.92))


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	_overlapping_players[body.get_instance_id()] = true
	var on_exit := _on_player_removed.bind(body.get_instance_id())
	if not body.tree_exiting.is_connected(on_exit):
		body.tree_exiting.connect(on_exit, CONNECT_ONE_SHOT)
	set_occluded(true)


func _on_body_exited(body: Node2D) -> void:
	_overlapping_players.erase(body.get_instance_id())
	set_occluded(is_occluded())


func _on_player_removed(instance_id: int) -> void:
	_overlapping_players.erase(instance_id)
	set_occluded(is_occluded())


func _on_settings_changed(settings: SettingsProfile) -> void:
	_reduced_motion = settings.reduced_motion
	set_occluded(is_occluded(), _reduced_motion)
