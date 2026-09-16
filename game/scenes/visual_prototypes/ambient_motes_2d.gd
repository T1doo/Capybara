class_name AmbientMotes2D
extends Node2D

const MOTE_COUNT: int = 12

@export var field_rect := Rect2(-896.0, -544.0, 1792.0, 1088.0)
@export var mote_color := Color(0.94, 0.84, 0.48, 0.48)
@export_range(0.0, 64.0, 0.5) var drift_speed: float = 10.0

var _motion_enabled: bool = true
var _elapsed: float = 0.0


func _ready() -> void:
	var settings_service := get_node_or_null("/root/SettingsService") as SettingsManagerService
	if settings_service != null:
		settings_service.settings_changed.connect(_on_settings_changed)
		_on_settings_changed(settings_service.current_settings)
	queue_redraw()


func _process(delta: float) -> void:
	if _motion_enabled:
		_elapsed += delta
		queue_redraw()


func set_reduced_motion(reduced_motion: bool) -> void:
	_motion_enabled = not reduced_motion


func is_motion_enabled() -> bool:
	return _motion_enabled


func get_elapsed() -> float:
	return _elapsed


func get_mote_position(index: int, sample_time: float = -1.0) -> Vector2:
	if index < 0 or index >= MOTE_COUNT:
		return Vector2.INF
	var time := _elapsed if sample_time < 0.0 else sample_time
	var base_x := fmod(83.0 + float(index * 137), field_rect.size.x)
	var base_y := fmod(47.0 + float(index * 223), field_rect.size.y)
	var phase := float(index) * 1.618
	var drift := Vector2(
		sin(time * 0.47 + phase) * 24.0,
		-fmod(time * drift_speed + float(index * 31), field_rect.size.y)
	)
	var local_position := Vector2(base_x, base_y) + drift
	local_position.x = fposmod(local_position.x, field_rect.size.x)
	local_position.y = fposmod(local_position.y, field_rect.size.y)
	return field_rect.position + local_position


func _draw() -> void:
	for mote_index in range(MOTE_COUNT):
		var position := get_mote_position(mote_index)
		var radius := 2.0 + float(mote_index % 3)
		draw_circle(position, radius, mote_color)
		draw_circle(position + Vector2(-1.0, -1.0), radius * 0.42, Color(1.0, 0.95, 0.72, 0.5))


func _on_settings_changed(settings: SettingsProfile) -> void:
	set_reduced_motion(settings.reduced_motion)
