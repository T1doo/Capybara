class_name HomeVisualBlockout
extends Node2D

const GRID_SIZE: float = 64.0
const PLAYER_REFERENCE_HEIGHT: float = 144.0
const WORLD_BOUNDS := Rect2(-960.0, -600.0, 1920.0, 1200.0)
var upper_water := PackedVector2Array([
	Vector2(256.0, -600.0),
	Vector2(704.0, -600.0),
	Vector2(576.0, -96.0),
	Vector2(192.0, -96.0),
])
var lower_water := PackedVector2Array([
	Vector2(192.0, 96.0),
	Vector2(576.0, 96.0),
	Vector2(704.0, 600.0),
	Vector2(224.0, 600.0),
])
var water_under_bridge := PackedVector2Array([
	Vector2(192.0, -96.0),
	Vector2(576.0, -96.0),
	Vector2(576.0, 96.0),
	Vector2(192.0, 96.0),
])

@export var show_grid: bool = true
@export var show_anchor_guides: bool = true
@export var style_profile: EnvironmentStyleProfile

@onready var upper_water_collision: CollisionPolygon2D = %UpperWaterCollision
@onready var lower_water_collision: CollisionPolygon2D = %LowerWaterCollision
@onready var upper_water_surface: Polygon2D = %UpperWaterSurface
@onready var lower_water_surface: Polygon2D = %LowerWaterSurface
@onready var ground_surface: Polygon2D = %GroundSurface
@onready var anchors: Node2D = %Anchors


func _ready() -> void:
	if style_profile == null or not style_profile.validate().is_empty():
		push_error("HOME BLOCKOUT: missing or invalid environment style profile")
		return
	upper_water_collision.polygon = upper_water
	lower_water_collision.polygon = lower_water
	_configure_dock_water_collision()
	upper_water_surface.polygon = _scale_polygon_toward_center(upper_water, 0.96)
	lower_water_surface.polygon = _scale_polygon_toward_center(lower_water, 0.96)
	var ground_material := ground_surface.material as ShaderMaterial
	ground_material.set_shader_parameter(&"base_color", style_profile.ground_base)
	ground_material.set_shader_parameter(&"light_wash", style_profile.ground_light)
	ground_material.set_shader_parameter(&"deep_wash", style_profile.ground_deep)
	var settings_service := get_node_or_null("/root/SettingsService") as SettingsManagerService
	if settings_service != null:
		settings_service.settings_changed.connect(_on_settings_changed)
		_on_settings_changed(settings_service.current_settings)
	queue_redraw()


func is_water_blocked_at(world_position: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(world_position, upper_water) or Geometry2D.is_point_in_polygon(
		world_position, lower_water_collision.polygon
	)


func _configure_dock_water_collision() -> void:
	var dock := get_node("PaintedDock") as PaintedDock2D
	var footprint := PackedVector2Array()
	for point in dock.get_deck_polygon():
		footprint.append(dock.transform * point)
	# Keep visual water under the raised platform; remove only its occupied collision area.
	var clipped := Geometry2D.clip_polygons(lower_water, footprint)
	if clipped.size() != 1:
		push_error("HOME BLOCKOUT: dock must cut one shore-connected notch in the river")
		return
	lower_water_collision.polygon = clipped[0]


func get_anchor_position(anchor_name: StringName) -> Vector2:
	var marker := anchors.get_node_or_null(NodePath(String(anchor_name))) as Marker2D
	if marker == null:
		return Vector2.INF
	return marker.position


func get_anchor_count() -> int:
	return anchors.get_child_count()


func set_water_accessibility(reduced_motion: bool, high_contrast: bool) -> void:
	var water_material := upper_water_surface.material as ShaderMaterial
	water_material.set_shader_parameter(&"motion_strength", 0.0 if reduced_motion else 1.0)
	water_material.set_shader_parameter(&"contrast_strength", 1.0 if high_contrast else 0.0)


func _on_settings_changed(settings: SettingsProfile) -> void:
	set_water_accessibility(settings.reduced_motion, settings.high_contrast_interactions)


func _draw() -> void:
	_draw_grid()
	_draw_water()
	_draw_paths()
	_draw_garden()
	_draw_vegetation()
	_draw_anchor_guides()


func _draw_grid() -> void:
	if not show_grid:
		return
	var grid_color := Color(0.15, 0.2, 0.14, 0.12)
	var grid_step := int(GRID_SIZE)
	var first_grid_x := ceili(WORLD_BOUNDS.position.x / GRID_SIZE) * grid_step
	var first_grid_y := ceili(WORLD_BOUNDS.position.y / GRID_SIZE) * grid_step
	for x in range(first_grid_x, int(WORLD_BOUNDS.end.x) + 1, grid_step):
		draw_line(Vector2(x, WORLD_BOUNDS.position.y), Vector2(x, WORLD_BOUNDS.end.y), grid_color)
	for y in range(first_grid_y, int(WORLD_BOUNDS.end.y) + 1, grid_step):
		draw_line(Vector2(WORLD_BOUNDS.position.x, y), Vector2(WORLD_BOUNDS.end.x, y), grid_color)


func _draw_water() -> void:
	var deep_edge := style_profile.shore_edge
	var water := style_profile.water_base
	var shallows := style_profile.shallow_glint
	for polygon in [upper_water, lower_water, water_under_bridge]:
		var closed_polygon := PackedVector2Array(Array(polygon) + [polygon[0]])
		draw_polyline(closed_polygon, deep_edge, style_profile.shore_band_width, true)
		draw_colored_polygon(polygon, deep_edge)
		var inset := _scale_polygon_toward_center(polygon, 0.96)
		draw_colored_polygon(inset, water)
		draw_polyline(
			closed_polygon,
			style_profile.shore_highlight,
			style_profile.shore_highlight_width,
			true
		)
	for ripple in [
		[Vector2(360.0, -420.0), Vector2(520.0, -420.0)],
		[Vector2(288.0, -220.0), Vector2(460.0, -220.0)],
		[Vector2(292.0, 230.0), Vector2(470.0, 230.0)],
		[Vector2(360.0, 430.0), Vector2(550.0, 430.0)],
	]:
		draw_line(ripple[0], ripple[1], shallows, 7.0, true)


func _draw_paths() -> void:
	var path_outline := style_profile.path_edge
	var path_fill := style_profile.path_fill
	var main_path := PackedVector2Array([
		Vector2(-576.0, -128.0),
		Vector2(-480.0, -96.0),
		Vector2(-192.0, 0.0),
		Vector2(144.0, 0.0),
	])
	draw_polyline(main_path, path_outline, 98.0, true)
	draw_polyline(main_path, path_fill, 82.0, true)
	var garden_path := PackedVector2Array([
		Vector2(-416.0, -32.0),
		Vector2(-512.0, 192.0),
	])
	draw_polyline(garden_path, path_outline, 76.0, true)
	draw_polyline(garden_path, path_fill, 62.0, true)
	var right_path := PackedVector2Array([
		Vector2(608.0, 0.0),
		Vector2(736.0, -192.0),
		Vector2(704.0, -320.0),
	])
	draw_polyline(right_path, path_outline, 76.0, true)
	draw_polyline(right_path, path_fill, 62.0, true)
	var dock_path := PackedVector2Array([
		Vector2(608.0, 0.0),
		Vector2(768.0, 192.0),
		Vector2(736.0, 320.0),
	])
	draw_polyline(dock_path, path_outline, 76.0, true)
	draw_polyline(dock_path, path_fill, 62.0, true)


func _draw_garden() -> void:
	draw_rect(Rect2(-768.0, 128.0, 384.0, 320.0), Color("#806548"))
	draw_rect(Rect2(-768.0, 128.0, 384.0, 320.0), Color("#5f523e"), false, 8.0)
	for row_index in range(3):
		var row_y := 168.0 + row_index * 88.0
		draw_rect(Rect2(-728.0, row_y, 304.0, 56.0), Color("#584333"))
		for crop_index in range(5):
			var crop_position := Vector2(-696.0 + crop_index * 64.0, row_y + 28.0)
			draw_circle(crop_position, 15.0, Color("#73964e"))
			draw_circle(crop_position + Vector2(8.0, -5.0), 10.0, Color("#9fb862"))
	# The opening makes the intended interaction entry legible.
	draw_rect(Rect2(-600.0, 432.0, 96.0, 20.0), Color("#c9ad77"))


func _draw_vegetation() -> void:
	for reed_position in [
		Vector2(216.0, -256.0),
		Vector2(592.0, -160.0),
		Vector2(220.0, 224.0),
		Vector2(592.0, 352.0),
	]:
		for offset in [-20.0, 0.0, 20.0]:
			draw_line(reed_position + Vector2(offset, 30.0), reed_position + Vector2(offset, -28.0), Color("#496f48"), 5.0)
			draw_circle(reed_position + Vector2(offset, -32.0), 6.0, Color("#8d6b43"))


func _draw_anchor_guides() -> void:
	if not show_anchor_guides:
		return
	for child in anchors.get_children():
		if child is Marker2D:
			var marker := child as Marker2D
			draw_circle(marker.position, 14.0, Color(0.94, 0.82, 0.35, 0.72))
			draw_circle(marker.position, 22.0, Color(0.29, 0.23, 0.16, 0.76), false, 3.0)


func _scale_polygon_toward_center(polygon: PackedVector2Array, factor: float) -> PackedVector2Array:
	var center := Vector2.ZERO
	for point in polygon:
		center += point
	center /= float(polygon.size())
	var scaled := PackedVector2Array()
	for point in polygon:
		scaled.append(center + (point - center) * factor)
	return scaled


func _make_ellipse_polygon(center: Vector2, size: Vector2, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for segment_index in range(segments):
		var angle := TAU * float(segment_index) / float(segments)
		points.append(center + Vector2(cos(angle) * size.x * 0.5, sin(angle) * size.y * 0.5))
	return points
