class_name PaintedDock2D
extends Node2D

const DECK_RECT := Rect2(-192.0, -96.0, 384.0, 192.0)
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
	_build_rail(rear_rail, Vector2(-192,-96), Vector2(-32,-96), 3)
	_build_rail(rear_rail, Vector2(160,-96), Vector2(192,-96), 2)
	_build_rail(front_rail, Vector2(-192,96), Vector2(192,96), 4)
	_build_rail(front_rail, Vector2(-192,-96), Vector2(-192,96), 3)
	_build_rail(front_rail, Vector2(192,-96), Vector2(192,96), 3)
	_build_supports()


func get_deck_polygon() -> PackedVector2Array:
	return PackedVector2Array([
		DECK_RECT.position, Vector2(DECK_RECT.end.x, DECK_RECT.position.y),
		DECK_RECT.end, Vector2(DECK_RECT.position.x, DECK_RECT.end.y),
	])


func _build_deck() -> void:
	for index in range(8):
		var left := -192.0 + float(index) * 48.0
		var points := PackedVector2Array([
			Vector2(left,-96), Vector2(left+46.5,-96),
			Vector2(left+46.5,96), Vector2(left,96),
		])
		_wood(deck, points, index, false, Color.WHITE.darkened(0.035 * float(index % 3)))
		_line(deck, PackedVector2Array([points[0], points[1]]), Color("#ebc58b"), 2.0)
		_line(deck, PackedVector2Array([points[1], points[2]]), Color("#70523b"), 1.5)
		for y in [-79.0,79.0]:
			_disc(deck, Vector2(left+8,y), 1.9, Color("#584535"))
			_disc(deck, Vector2(left+38,y), 1.9, Color("#584535"))
	_wood(deck, PackedVector2Array([
		Vector2(-192,96),Vector2(192,96),Vector2(192,115),Vector2(-192,115),
	]), 2, true, Color("#967c63"))
	# The shore entrance stays open; the short apron covers the join to the path.
	_wood(deck, PackedVector2Array([
		Vector2(-32,-107),Vector2(160,-107),Vector2(160,-96),Vector2(-32,-96),
	]), 1, true, Color("#c7b092"))
	_line(deck, PackedVector2Array([Vector2(-192,96),Vector2(192,96)]), Color("#574230"), 3.0)


func _build_rail(parent: Node2D, start: Vector2, end: Vector2, count: int) -> void:
	for segment in range(count - 1):
		var a := start.lerp(end, float(segment) / float(count - 1))
		var b := start.lerp(end, float(segment + 1) / float(count - 1))
		var rope := PackedVector2Array()
		for step in range(13):
			var fraction := float(step) / 12.0
			var point := a.lerp(b, fraction) + Vector2(0,-43)
			point.y += 10.0 * sin(fraction * PI)
			rope.append(point)
		_line(parent, rope, Color("#6d5940"), 5.0)
		_line(parent, rope, Color("#d9c49a"), 3.0)
	for index in range(count):
		var base := start.lerp(end, float(index) / float(count - 1))
		_wood(parent, PackedVector2Array([
			base+Vector2(-8,-56),base+Vector2(8,-56),base+Vector2(8,8),base+Vector2(-8,8),
		]), index, false, Color("#c9b499"))
		_disc(parent, base+Vector2(0,-56), 10.0, Color("#ddbd88"), 0.45)
		_line(parent, PackedVector2Array([base+Vector2(7,-51),base+Vector2(7,7)]), Color("#644c35"), 2.0)
		for wrap in range(3):
			var y := -43.0 + float(wrap) * 4.0
			_line(parent, PackedVector2Array([base+Vector2(-9,y),base+Vector2(9,y+2)]), Color("#d9c49a"), 2.6)


func _build_supports() -> void:
	var supports: Node2D = $Supports
	for x in [-160.0,160.0]:
		_wood(supports, PackedVector2Array([
			Vector2(x-11,90),Vector2(x+11,90),Vector2(x+9,144),Vector2(x-9,144),
		]), 3, false, Color("#8c7964"))
		_disc(supports,Vector2(x+9,143),30.0,Color(0.14,0.21,0.17,0.24),0.28)
	var shadow := Polygon2D.new()
	shadow.polygon = PackedVector2Array([
		Vector2(-197,102),Vector2(195,102),Vector2(219,125),Vector2(190,150),Vector2(-182,132),
	])
	shadow.color = Color(0.12,0.20,0.17,0.22)
	supports.add_child(shadow)


func _wood(parent: Node2D, points: PackedVector2Array, variant: int, horizontal: bool, tint: Color) -> void:
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
		var fraction := (point - bounds.position) / bounds.size.max(Vector2.ONE)
		if horizontal:
			fraction = Vector2(fraction.y, fraction.x)
		uv.append(Vector2(520.0 + float(variant % 6) * 72.0 + fraction.x * 60.0,
			80.0 + fraction.y * 850.0))
	polygon.uv = uv
	parent.add_child(polygon)


func _line(parent: Node2D, points: PackedVector2Array, color: Color, width: float) -> void:
	var line := Line2D.new()
	line.points = points
	line.default_color = color
	line.width = width
	line.antialiased = true
	parent.add_child(line)


func _disc(parent: Node2D, center: Vector2, radius: float, color: Color, squash: float = 1.0) -> void:
	var polygon := Polygon2D.new()
	var points := PackedVector2Array()
	for step in range(20):
		var angle := TAU * float(step) / 20.0
		points.append(center + Vector2(cos(angle),sin(angle) * squash) * radius)
	polygon.polygon = points
	polygon.color = color
	parent.add_child(polygon)
