class_name LayeredCottage2D
extends Area2D

@export_range(0.1, 1.0, 0.01) var roof_faded_alpha: float = 0.28
@export_range(0.0, 1.0, 0.01) var fade_seconds: float = 0.2

@onready var roof_layer: Sprite2D = %RoofLayer
@onready var walls_layer: Sprite2D = %WallsLayer
@onready var shadow_layer: Sprite2D = %ShadowLayer

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


func get_display_content_width() -> float:
	var bounds := walls_layer.texture.get_image().get_used_rect()
	bounds = bounds.merge(roof_layer.texture.get_image().get_used_rect())
	return float(bounds.size.x) * absf(global_scale.x)


func is_roof_faded() -> bool:
	return not _overlapping_players.is_empty()


func set_roof_faded(faded: bool, immediate: bool = false) -> void:
	var target_alpha := roof_faded_alpha if faded else 1.0
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	if immediate or _reduced_motion or is_zero_approx(fade_seconds):
		roof_layer.modulate.a = target_alpha
		return
	_active_tween = create_tween()
	_active_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_active_tween.tween_property(roof_layer, ^"modulate:a", target_alpha, fade_seconds)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	var body_id := body.get_instance_id()
	if _overlapping_players.has(body_id):
		return
	_overlapping_players[body_id] = true
	var cleanup := _forget_player.bind(body_id)
	if not body.tree_exiting.is_connected(cleanup):
		body.tree_exiting.connect(cleanup, CONNECT_ONE_SHOT)
	set_roof_faded(true)


func _on_body_exited(body: Node2D) -> void:
	_forget_player(body.get_instance_id())


func _forget_player(body_id: int) -> void:
	if not _overlapping_players.has(body_id):
		return
	_overlapping_players.erase(body_id)
	set_roof_faded(is_roof_faded())


func _on_settings_changed(settings: SettingsProfile) -> void:
	_reduced_motion = settings.reduced_motion
	set_roof_faded(is_roof_faded(), _reduced_motion)
