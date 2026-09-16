extends StaticBody2D

@export var sort_actor: Node2D


func _physics_process(_delta: float) -> void:
	if is_instance_valid(sort_actor):
		z_index = 55 if sort_actor.global_position.y < global_position.y else 20


func _draw() -> void:
	draw_set_transform(Vector2(12,16),0.0,Vector2(1,0.28))
	draw_circle(Vector2.ZERO,42.0,Color(0.15,0.12,0.09,0.24))
	draw_set_transform(Vector2.ZERO)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-20,1),Vector2(-11,-56),Vector2(-17,-109),Vector2(8,-117),
		Vector2(14,-64),Vector2(23,2),Vector2(5,-3),
	]),Color("#76543a"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-14,-4),Vector2(-8,-58),Vector2(-13,-108),Vector2(-3,-111),
		Vector2(4,-52),Vector2(7,-4),
	]),Color("#b19364"))
	draw_polyline(PackedVector2Array([
		Vector2(-2,-49),Vector2(-35,-88),Vector2(-44,-121),
	]),Color("#836442"),10.0,true)
	draw_polyline(PackedVector2Array([
		Vector2(7,-65),Vector2(38,-93),Vector2(42,-124),
	]),Color("#76543a"),9.0,true)
	draw_polyline(PackedVector2Array([
		Vector2(9,-104),Vector2(7,-63),Vector2(14,-14),
	]),Color("#574634"),2.5,true)
