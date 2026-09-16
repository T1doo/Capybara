extends SceneTree


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 2:
		quit(2)
		return
	var mode: String = args[0]
	var base_path: String = args[1]
	if mode == "cleanup":
		for suffix in [".json", ".bak.json", ".tmp.json"]:
			var path: String = ProjectSettings.globalize_path(base_path + suffix)
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(base_path).get_base_dir())
		quit(0)
		return
	var main: Node = load("res://scenes/bootstrap/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var inventory := root.get_node("InventoryService") as InventoryCoordinator
	var player := main.get_node("Player") as PlayerCharacter
	var flow := root.get_node("SceneFlowService") as SceneFlowCoordinator
	var manager := root.get_node("SaveManager") as SaveManagerService
	var screen := main.get_node("Interface/InventoryScreen") as InventoryScreen
	var valid: bool = true
	if mode == "write":
		inventory.player_inventory.add_item(&"item_reed_spade", 1)
		for index in range(inventory.player_inventory.slots.size()):
			if inventory.player_inventory.slots[index].item_id == &"item_reed_spade":
				inventory.player_inventory.move_or_merge(index, 20)
				break
		inventory.hotbar.assign(6, 20)
		inventory.hotbar.assign(7, 20)
		inventory.hotbar.select(6)
		screen._sort_inventory()
		var snapshot: SaveOperationResult = manager.create_runtime_snapshot(inventory, player, flow)
		valid = snapshot.success and manager.save_game(base_path, snapshot.data).success
	elif mode == "read":
		valid = manager.load_and_apply(base_path, inventory, player, flow).success
	else:
		valid = false
	valid = valid and inventory.hotbar.selected_index == 6
	valid = valid and inventory.hotbar.assignments[6] == inventory.hotbar.assignments[7]
	valid = valid and inventory.hotbar.assignments[6] != 20
	valid = valid and player.get_equipped_tool_id() == &"item_reed_spade"
	valid = valid and screen.get_hotbar_button(6).text.contains(TranslationServer.translate(&"ITEM_REED_SPADE_NAME"))
	print("HOTBAR PROCESS %s: %s" % [mode, "PASS" if valid else "FAIL"])
	quit(0 if valid else 1)
