extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://scenes/bootstrap/main.tscn")


func _init() -> void:
	call_deferred(&"_show_inventory")


func _show_inventory() -> void:
	var main_scene := MAIN_SCENE.instantiate() as GameBootstrap
	root.add_child(main_scene)
	await process_frame
	var inventory_service := root.get_node("InventoryService") as InventoryCoordinator
	inventory_service.player_inventory.add_item(&"item_branch", 7)
	inventory_service.player_inventory.add_item(&"item_reed_fiber", 4)
	inventory_service.player_inventory.add_item(&"item_reed_spade", 1)
	var screen := main_scene.get_node("Interface/InventoryScreen") as InventoryScreen
	screen.open_inventory()
