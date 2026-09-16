extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://scenes/bootstrap/main.tscn")


func _init() -> void:
	call_deferred(&"_show_storage")


func _show_storage() -> void:
	var main_scene := MAIN_SCENE.instantiate() as GameBootstrap
	root.add_child(main_scene)
	await process_frame
	var inventory_service := root.get_node("InventoryService") as InventoryCoordinator
	inventory_service.player_inventory.add_item(&"item_branch", 7)
	var storage := inventory_service.create_storage(&"storage_visual_fixture", 32)
	storage.add_item(&"item_reed_fiber", 5)
	var screen := main_scene.get_node("Interface/StorageScreen") as StorageScreen
	screen.configure(inventory_service.player_inventory, storage)
	screen.open_screen()
