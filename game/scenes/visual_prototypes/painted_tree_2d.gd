extends Node2D

@export_range(0,2) var variant: int = 0
@export var sort_actor: Node2D


func _enter_tree() -> void:
	($Crown/Foliage as PaintedFoliage2D).variant = variant


func _ready() -> void:
	$Trunk.sort_actor = sort_actor
