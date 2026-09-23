class_name PaintedWaterwheel2D
extends Node2D

const TIMBER: Texture2D = preload("res://scenes/visual_prototypes/assets/materials/tex_cottage_material_atlas_v001.png")
const WOOD_SHADER: Shader = preload("res://assets/shaders/soft_painted_wood.gdshader")
const TURN_SPEED: float = -0.38

@export var sort_actor: Node2D

@onready var wheel: Node2D = $WheelProjection/RotatingWheel
@onready var frame: Node2D = $Frame
var flow_enabled: bool = true
var reduced_motion: bool = false
var _flow_phase: float = 0.0
var wood_material: ShaderMaterial


func _ready() -> void:
	wood_material = ShaderMaterial.new()
	wood_material.shader = WOOD_SHADER
	_build_frame()
	_build_wheel()
	var settings := get_node_or_null("/root/SettingsService") as SettingsManagerService
	if settings != null:
		settings.settings_changed.connect(_on_settings_changed)
		_on_settings_changed(settings.current_settings)
	queue_redraw()


func _process(delta: float) -> void:
	wheel.rotation = fposmod(wheel.rotation + TURN_SPEED * delta, TAU)
	_flow_phase = fposmod(_flow_phase + delta * 30.0, 40.0)
	queue_redraw()


func _physics_process(_delta: float) -> void:
	# Sorting must keep updating even when reduced motion or disabled feed stops animation.
	if is_instance_valid(sort_actor):
		z_index = 55 if sort_actor.global_position.y < global_position.y else 8
	else:
		z_index = 8


func set_flow_enabled(enabled: bool) -> void:
	flow_enabled = enabled
	set_process(flow_enabled and not reduced_motion)
	queue_redraw()


func _on_settings_changed(settings: SettingsProfile) -> void:
	reduced_motion = settings.reduced_motion
	set_process(flow_enabled and not reduced_motion)


func _build_frame() -> void:
	# Axle bearings and the A-frame stay fixed while the wheel turns in its projected plane.
	for side in [-1.0, 1.0]:
		var foot := Vector2(side * 63.0, 72.0)
		var bearing := Vector2(side * 14.0, -10.0)
		_timber(frame, PackedVector2Array([
			foot+Vector2(-8,0),foot+Vector2(9,0),bearing+Vector2(8,0),bearing-Vector2(8,0),
		]), Color("#bda78d"))
		_solid(frame, PackedVector2Array([
			foot+Vector2(-20,0),foot+Vector2(18,0),foot+Vector2(24,13),foot+Vector2(-25,16),
		]),Color("#a0a18b"))
	_timber(frame, PackedVector2Array([Vector2(-76,54),Vector2(76,54),Vector2(76,68),Vector2(-76,68)]),Color("#bba087"))
	# Elevated intake flume ends over the upper-left paddles; discharge runs back to the river.
	_timber(frame, PackedVector2Array([Vector2(-191,-115),Vector2(-39,-95),Vector2(-39,-82),Vector2(-191,-100)]),Color.WHITE)
	_timber(frame, PackedVector2Array([Vector2(-196,-99),Vector2(-47,-78),Vector2(-47,-67),Vector2(-196,-85)]),Color.WHITE)
	_timber(frame, PackedVector2Array([Vector2(-177,-95),Vector2(-163,-93),Vector2(-159,2),Vector2(-173,2)]),Color("#ad957d"))
	_timber(frame, PackedVector2Array([Vector2(-115,-86),Vector2(-102,-84),Vector2(-99,12),Vector2(-112,12)]),Color("#ad957d"))
	_timber(frame, PackedVector2Array([Vector2(-103,100),Vector2(4,80),Vector2(4,89),Vector2(-103,111)]),Color("#8e7b68"))
	_timber($Bearing, PackedVector2Array([Vector2(-23,-8),Vector2(25,-8),Vector2(25,8),Vector2(-23,8)]),Color("#b59b73"))
	_solid($Bearing, _circle(Vector2.ZERO,13.0,24),Color("#4b5a53"))
	_solid($Bearing, _circle(Vector2(-3,-3),5.0,16),Color("#c7b88e"))


func _build_wheel() -> void:
	for index in range(16):
		var angle := TAU * float(index) / 16.0
		var next_angle := TAU * float(index+1) / 16.0
		var inner := 65.0
		var outer := 78.0
		_timber(wheel, PackedVector2Array([
			Vector2.from_angle(angle)*inner,Vector2.from_angle(next_angle)*inner,
			Vector2.from_angle(next_angle)*outer,Vector2.from_angle(angle)*outer,
		]),Color("#ccb28e"))
		var blade := PackedVector2Array()
		for point in [Vector2(75,-10),Vector2(94,-10),Vector2(94,8),Vector2(75,8)]:
			blade.append(point.rotated(angle))
		_timber(wheel,blade,Color.WHITE.darkened(float(index%3)*0.07))
	for index in range(8):
		var angle := TAU * float(index) / 8.0
		var points := PackedVector2Array()
		for point in [Vector2(5,-6),Vector2(70,-6),Vector2(70,6),Vector2(5,6)]:
			points.append(point.rotated(angle))
		_timber(wheel,points,Color("#e6d3b3"))
	_solid(wheel,_circle(Vector2.ZERO,20.0,24),Color("#806044"))


func _draw() -> void:
	draw_colored_polygon(_ellipse(Vector2(10,86),Vector2(184,52)),Color(0.13,0.19,0.15,0.25))
	if not flow_enabled:
		return
	draw_colored_polygon(PackedVector2Array([
		Vector2(-190,-109),Vector2(-42,-90),Vector2(-48,-77),Vector2(-193,-95),
	]),Color("#83bcb0"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-47,-85),Vector2(-35,-82),Vector2(-40,-40),Vector2(-55,-42),
	]),Color(0.65,0.87,0.79,0.8))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-1,75),Vector2(13,88),Vector2(-95,114),Vector2(-113,103),
	]),Color("#77b9ae"))
	for index in range(3):
		var y := -80.0 + fposmod(_flow_phase + index * 13.0, 38.0)
		draw_line(Vector2(-46,y),Vector2(-48,y+7.0),Color(0.91,0.98,0.88,0.8),2.0,true)
	for index in range(4):
		var offset := fposmod(_flow_phase + index * 10.0, 40.0)
		draw_arc(Vector2(-97,108),offset+5.0,0.0,PI,12,Color(0.83,0.94,0.82,0.35*(1.0-offset/40.0)),1.5,true)


func _timber(parent: Node2D, points: PackedVector2Array, tint: Color) -> void:
	var polygon := Polygon2D.new()
	polygon.polygon = points
	polygon.texture = TIMBER
	polygon.material = wood_material
	polygon.color = tint
	var bounds := Rect2(points[0],Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	var uv := PackedVector2Array()
	for point in points:
		var fraction := (point-bounds.position) / bounds.size.max(Vector2.ONE)
		if bounds.size.x > bounds.size.y:
			fraction = Vector2(fraction.y,fraction.x)
		uv.append(Vector2(664+fraction.x*60,30+fraction.y*700))
	polygon.uv = uv
	parent.add_child(polygon)


func _solid(parent: Node2D, points: PackedVector2Array, tint: Color) -> void:
	var polygon := Polygon2D.new()
	polygon.polygon = points
	polygon.color = tint
	parent.add_child(polygon)


func _circle(center: Vector2, radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(segments):
		points.append(center + Vector2.from_angle(TAU * float(index) / float(segments)) * radius)
	return points


func _ellipse(center: Vector2, size: Vector2) -> PackedVector2Array:
	var points := _circle(Vector2.ZERO,1.0,32)
	for index in range(points.size()):
		points[index] = center + points[index] * size * 0.5
	return points
