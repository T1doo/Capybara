class_name PaintedBridge2D
extends Node2D

const SPAN: float = 512.0
const CLEAR_WIDTH: float = 192.0
const BOARD_COUNT: int = 14
const TIMBER: Texture2D = preload("res://scenes/visual_prototypes/assets/materials/tex_cottage_material_atlas_v001.png")
const WOOD_SHADER: Shader = preload("res://assets/shaders/soft_painted_wood.gdshader")

@onready var deck: Node2D = $Deck
@onready var rear_rail: Node2D = $RearRail
@onready var front_rail: Node2D = $FrontRail

var wood_material: ShaderMaterial


func _ready() -> void:
	wood_material = ShaderMaterial.new()
	wood_material.shader = WOOD_SHADER
	_build_deck()
	_build_rail(rear_rail, -96.0)
	_build_rail(front_rail, 96.0)
	_build_supports()


func _build_deck() -> void:
	var board_width := SPAN / float(BOARD_COUNT)
	for index in range(BOARD_COUNT):
		var left := -SPAN * 0.5 + float(index) * board_width
		var right := left + board_width - 1.5
		var points := PackedVector2Array([
			Vector2(left, -96.0), Vector2(right, -96.0),
			Vector2(right, 96.0), Vector2(left, 96.0),
		])
		var tint := Color.WHITE.darkened(0.035 * float(index % 3))
		_wood(deck, points, false, index, tint)
		_line(deck, PackedVector2Array([points[0], points[1]]), Color("#ebc58b"), 2.0)
		_line(deck, PackedVector2Array([points[1], points[2]]), Color("#76543a"), 1.4)
	# A front fascia makes the deck thickness visible without changing its walkable plane.
	_wood(deck, PackedVector2Array([
		Vector2(-256,96), Vector2(256,96), Vector2(246,115), Vector2(-246,115),
	]), true, 2, Color("#9b8068"))
	_line(deck, PackedVector2Array([Vector2(-256,96), Vector2(256,96)]), Color("#553c2d"), 3.0)


func _build_rail(parent: Node2D, base_y: float) -> void:
	var upper := PackedVector2Array()
	var lower := PackedVector2Array()
	for step in range(17):
		var x := -244.0 + float(step) * 30.5
		var lift := 16.0 * (1.0 - pow(x / 244.0, 2.0))
		upper.append(Vector2(x, base_y - 57.0 - lift))
		lower.append(Vector2(x, base_y - 45.0 - lift))
	for index in range(16):
		_wood(parent, PackedVector2Array([upper[index], upper[index+1], lower[index+1], lower[index]]), true, index, Color.WHITE)
	_line(parent, upper, Color("#d7ad72"), 2.0)
	_line(parent, lower, Color("#59402e"), 2.5)
	for index in range(5):
		var x := -240.0 + float(index) * 120.0
		var lift := 16.0 * (1.0 - pow(x / 244.0, 2.0))
		var top := base_y - 69.0 - lift
		_wood(parent, PackedVector2Array([
			Vector2(x-7,top), Vector2(x+7,top), Vector2(x+7,base_y+8), Vector2(x-7,base_y+8),
		]), false, index, Color.WHITE)
		_flat(parent, PackedVector2Array([
			Vector2(x-10,top), Vector2(x,top-5), Vector2(x+11,top), Vector2(x+1,top+5),
		]), Color("#deb57d"))
		_line(parent, PackedVector2Array([Vector2(x+7,top+4),Vector2(x+7,base_y+8)]),Color("#59402e"),2.0)
		var binding_y := top + 14.0
		_line(parent, PackedVector2Array([Vector2(x-8,binding_y),Vector2(x+8,binding_y+2)]),Color("#dbc795"),3.0)
		_line(parent, PackedVector2Array([Vector2(x-8,binding_y+5),Vector2(x+8,binding_y+7)]),Color("#dbc795"),3.0)


func _build_supports() -> void:
	var supports: Node2D = $Supports
	for x in [-174.0,174.0]:
		_wood(supports, PackedVector2Array([
			Vector2(x-11,88),Vector2(x+11,88),Vector2(x+8,148),Vector2(x-8,148),
		]),false,3,Color("#907258"))
		_flat(supports,PackedVector2Array([
			Vector2(x-17,139),Vector2(x+14,140),Vector2(x+26,153),Vector2(x-21,157),
		]),Color(0.12,0.22,0.19,0.27))
	_flat(supports,PackedVector2Array([
		Vector2(-258,108),Vector2(260,108),Vector2(277,129),Vector2(250,151),Vector2(-241,143),
	]),Color(0.13,0.18,0.14,0.20))


func _wood(parent: Node2D, points: PackedVector2Array, horizontal: bool, variant: int, tint: Color) -> void:
	var polygon := Polygon2D.new()
	polygon.polygon = points
	polygon.texture = TIMBER
	polygon.material = wood_material
	polygon.color = tint
	var bounds := Rect2(points[0],Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	var start := 518.0 + float(variant % 6) * 72.0
	if horizontal:
		start = 662.0
	var uv := PackedVector2Array()
	for point in points:
		var fraction := (point-bounds.position) / bounds.size.max(Vector2.ONE)
		if horizontal:
			# One grain direction across the complete rail, not a full texture per short segment.
			fraction = Vector2(fraction.y, clampf((point.x + SPAN * 0.5) / SPAN, 0.0, 1.0))
		uv.append(Vector2(start + fraction.x * 60.0, 8.0 + fraction.y * 1008.0))
	polygon.uv = uv
	parent.add_child(polygon)


func _flat(parent: Node2D, points: PackedVector2Array, color: Color) -> void:
	var polygon := Polygon2D.new()
	polygon.polygon = points
	polygon.color = color
	parent.add_child(polygon)


func _line(parent: Node2D, points: PackedVector2Array, color: Color, width: float) -> void:
	var line := Line2D.new()
	line.points = points
	line.default_color = color
	line.width = width
	line.antialiased = true
	parent.add_child(line)
