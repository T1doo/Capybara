class_name PaintedFoliage2D
extends Node2D

const FOLIAGE: Texture2D = preload("res://scenes/visual_prototypes/assets/materials/tex_broadleaf_foliage_v001.png")
const SURFACE: Shader = preload("res://assets/shaders/painted_foliage.gdshader")

@export var radius := Vector2(148,116)
@export_range(0,2) var variant: int = 0

var crown: Polygon2D


func _ready() -> void:
	crown = Polygon2D.new()
	crown.polygon = build_outline()
	crown.texture = FOLIAGE
	var uv := PackedVector2Array()
	for point in crown.polygon:
		var fraction := Vector2(0.5,0.5) + point / (radius * 2.5)
		var start := Vector2(0.04,0.03) + Vector2(0.05,0.04) * float(variant)
		uv.append((start + fraction * 0.80) * FOLIAGE.get_size())
	crown.uv = uv
	var painted := ShaderMaterial.new()
	painted.shader = SURFACE
	painted.set_shader_parameter(&"crown_radius",radius)
	crown.material = painted
	add_child(crown)


func build_outline() -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(160):
		var angle := TAU * float(index) / 160.0
		var phase := float(variant) * 0.73
		var lobe := 1.0 + 0.065 * sin(angle * 7.0 + phase)
		lobe += 0.03 * sin(angle * 17.0 + phase) + 0.018 * sin(angle * 29.0)
		points.append(Vector2(cos(angle),sin(angle)) * radius * lobe)
	return points
