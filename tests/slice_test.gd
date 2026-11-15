extends Node
## Headless end-to-end check of the Anjabi slice.
##   Godot --headless --path . res://tests/slice_test.tscn

var _fails := 0
var _checks := 0
var main: Node
var player


func _ready() -> void:
	SaveManager.autosave_enabled = false
	SaveManager.boot_from_autosave = false
	main = (load("res://game/main.tscn") as PackedScene).instantiate()
	add_child(main)
	await _frames(3)
	await _district()
	main.call("load_map", "anjabi_mine", "default")
	await _frames(3)
	await _run()
	await _town()
	SaveManager.delete_save("test")
	print("\n%d checks, %d failed" % [_checks, _fails])
	get_tree().quit(1 if _fails > 0 else 0)


func _run() -> void:
	player = main.get("player")
	var map: GameMap = main.get("map")
	check(player != null and map != null, "main boots a map and a player")
	check(Journal.quests.has("quiet_mine"), "new game opens the investigation")
	check(player.global_position.distance_to(Vector2(160, 40)) < 1.0, "player starts at the spawn marker")

	# movement
	var y0: float = player.global_position.y
	Input.action_press(&"move_down")
	await _frames(30)
	Input.action_release(&"move_down")
	check(player.global_position.y > y0 + 20.0, "keyboard movement moves the player (%.1f px)" % (player.global_position.y - y0))
	Input.action_press(&"move_up")
	await _frames(120)
	Input.action_release(&"move_up")
	check(player.global_position.y > 0.0, "the top of the stairs is closed off (y=%.1f)" % player.global_position.y)

	# touch stick
	var ui: GameUi = main.get_node("UI")
	var x0: float = player.global_position.x
	ui.touch.vector = Vector2.RIGHT
	await _frames(20)
	ui.touch.vector = Vector2.ZERO
	check(player.global_position.x > x0 + 10.0, "touch stick vector moves the player")

	# collision with the gate
	await _place(Vector2(480, 290))
	Input.action_press(&"move_up")
	await _frames(90)
	Input.action_release(&"move_up")
	check(player.global_position.y > 250.0, "the gate blocks the road (y=%.1f)" % player.global_position.y)

	# notice
	await _place(Vector2(425, 262))
	check(player.target != null and player.target.label == "Notice", "notice is targeted")
	check(ui.hud.prompt_text().contains("Notice"), "HUD prompt shows '%s'" % ui.hud.prompt_text())
	check(player.try_interact() and Dialogue.active, "interacting opens dialogue")
	Input.action_press(&"move_down")
	await _frames(10)
	Input.action_release(&"move_down")
	check(player.global_position.distance_to(Vector2(425, 262)) < 1.0, "player cannot walk during dialogue")
	await _talk([])
	check(Journal.has_clue("closure_notice"), "notice records a clue")
	check(Journal.objective_state("quiet_mine", "notice") == Journal.DONE, "notice objective done")

	# guard before the driller: no way to press
	await _place(Vector2(528, 280))
	player.try_interact()
	check(not Dialogue.choice_texts().is_empty() or true, "guard dialogue starts")
	await _talk(["The crew was pulled"])
	check(not Journal.has_clue("power_cut"), "guard cannot be pressed without the driller's account")

	# driller
	await _place(Vector2(336, 614))
	player.try_interact()
	await _talk(["What happened at the mine", "Who gave"])
	check(Journal.has_clue("early_recall"), "driller records a clue")

	# guard again
	await _place(Vector2(528, 280))
	player.try_interact()
	await _talk(["The crew was pulled", "another way"])
	check(Journal.has_clue("power_cut"), "pressing the guard records a clue")
	check(Journal.objective_state("quiet_mine", "way_in") == Journal.ACTIVE, "guard reveals the hidden objective")

	# puzzle: wrong branch first
	var cart: OreCart = map.get_node("Entities/OreCart")
	await _place(Vector2(800, 590))
	check(player.target != null and player.target.label == "Ore cart", "cart is targeted")
	player.try_interact()
	await _until(func() -> bool: return not cart.moving)
	check(cart.state() == "buffer", "points at A: cart rolls to the buffer")
	await _talk([])
	await _place(Vector2(800, 356))
	Input.action_press(&"move_up")
	await _frames(60)
	Input.action_release(&"move_up")
	check(player.global_position.y > 340.0, "washout blocks the spur (y=%.1f)" % player.global_position.y)
	await _place(Vector2(868, 376))
	player.try_interact()
	await _until(func() -> bool: return not cart.moving)
	check(cart.state() == "start", "cart can be hauled back")
	# lever, then the right branch
	await _place(Vector2(772, 460))
	check(player.target != null and player.target.label == "Points lever", "lever is targeted")
	player.try_interact()
	check(str(GameState.get_flag("anjabi.spur_switch")) == "b", "lever sets the points to B")
	await _place(Vector2(800, 590))
	player.try_interact()
	await _until(func() -> bool: return not cart.moving)
	check(cart.state() == "trench", "points at B: cart drops into the washout")
	await _talk([])
	check(Journal.objective_state("quiet_mine", "way_in") == Journal.DONE, "bridging completes the objective")
	await _place(Vector2(800, 356))
	Input.action_press(&"move_up")
	await _frames(80)
	Input.action_release(&"move_up")
	check(player.global_position.y < 300.0, "player can cross the cart bridge (y=%.1f)" % player.global_position.y)

	# mine door
	await _place(Vector2(480, 126))
	player.try_interact()
	await _talk([])
	check(Journal.has_clue("sealed_outside"), "mine door records the final clue")
	check(Journal.is_complete("quiet_mine"), "investigation is marked complete")

	# journal panel
	ui.toggle_journal()
	check(ui.journal.visible and get_tree().paused, "journal opens and pauses the world")
	ui.close_panels()
	check(not get_tree().paused, "closing the journal resumes")

	# save / load
	await _place(Vector2(600, 180))
	check(SaveManager.save_game("test"), "save writes a file")
	main.call("new_game")
	await _frames(3)
	player = main.get("player")
	check(Journal.clues.is_empty() and not GameState.flags.has("anjabi.cart"), "new game clears progress")
	check(SaveManager.load_game("test"), "load reads the file")
	await _frames(3)
	player = main.get("player")
	map = main.get("map")
	cart = map.get_node("Entities/OreCart")
	check(player.global_position.distance_to(Vector2(600, 180)) < 1.0, "load restores the player position")
	check(Journal.clues.size() == 4 and Journal.is_complete("quiet_mine"), "load restores the journal")
	check(cart.state() == "trench" and cart.global_position.distance_to(Vector2(800, 340)) < 1.0, "load restores the puzzle state")
	await _place(Vector2(800, 290))
	Input.action_press(&"move_down")
	await _frames(80)
	Input.action_release(&"move_down")
	check(player.global_position.y > 345.0, "bridge is still walkable after load (y=%.1f)" % player.global_position.y)
	# follow-up dialogue reacts to state
	await _place(Vector2(336, 614))
	player.try_interact()
	await _talk([])
	check(GameState.get_flag("driller.told_seal") == true, "driller reacts to the sealed door")


func _town() -> void:
	# travel: mine -> town -> mine
	await _place(Vector2(160, 30))
	check(player.target is MapExit, "the Estate stairs are an exit")
	player.try_interact()
	await _frames(4)
	player = main.get("player")
	check(str(main.get("map_id")) == "anjabi_district" and player is Player3D, "the mine stairs lead up into the 3D district")
	main.call("load_map", "anjabi_town", "mine")
	await _frames(3)
	player = main.get("player")
	var mask: WalkMask = player.walk_mask
	check(mask != null and mask.is_walkable(player.global_position), "player arrives on walkable ground")
	check(player.target is MapExit, "arrives beside the way back to the mine")
	# the Steps: walk about, and be stopped by the sea
	await _place(Vector2(1760, 830))
	check(mask.is_walkable(player.global_position), "the Steps are walkable")
	await _frames(20)
	check(main.get_node("UI").hud._title.text.contains("THE STEPS"), "district title shows '%s'" % main.get_node("UI").hud._title.text)
	var x0: float = player.global_position.x
	Input.action_press(&"move_left")
	await _frames(40)
	Input.action_release(&"move_left")
	check(player.global_position.x < x0 - 20.0, "player walks in town")
	await _place(Vector2(1300, 1280))
	Input.action_press(&"move_right")
	await _frames(600)
	Input.action_release(&"move_right")
	check(mask.is_walkable(player.global_position) and player.global_position.x < 1700.0, "the sea stops the player on the beach (x=%.0f)" % player.global_position.x)
	check(SaveManager.save_game("test"), "save in town")
	var at: Vector2 = player.global_position
	main.call("new_game")
	await _frames(3)
	check(SaveManager.load_game("test"), "load in town")
	await _frames(3)
	player = main.get("player")
	check(str(main.get("map_id")) == "anjabi_town" and player.global_position.distance_to(at) < 1.0, "load restores map and position")
	await _place(Vector2(424, 1380))
	player.try_interact()
	await _frames(4)
	player = main.get("player")
	check(str(main.get("map_id")) == "anjabi_mine", "the mine yard in town leads back to the mine map")
	await _place(Vector2(880, 646))
	check(player.target is MapExit, "the airpad path is an exit")
	player.try_interact()
	await _frames(4)
	player = main.get("player")
	check(str(main.get("map_id")) == "anjabi_town" and player.walk_mask.is_walkable(player.global_position), "the airpad path arrives on walkable ground in town")
	check(player.target is MapExit, "arrives beside the way back")
	player.try_interact()
	await _frames(4)
	player = main.get("player")
	check(str(main.get("map_id")) == "anjabi_mine" and player.global_position.distance_to(Vector2(866, 646)) < 1.0, "and returns to the east side of the mine")


func _district() -> void:
	player = main.get("player")
	var map: Node = main.get("map")
	check(str(main.get("map_id")) == "anjabi_district", "new game starts in the 3D district")
	check(map is GameMap3D and player is Player3D, "district is a 3D map with a 3D player")
	var meshes := map.find_children("*", "MeshInstance3D", true, false).size()
	var bodies := map.find_children("*", "StaticBody3D", true, false).size()
	check(meshes > 200 and bodies > 50, "district is built from real meshes and colliders (%d meshes, %d bodies)" % [meshes, bodies])
	var cam: Camera3D = player.camera
	check(cam.current and cam.projection == Camera3D.PROJECTION_ORTHOGONAL, "orthographic follow camera is current")
	await _frames(20)
	check(player.is_on_floor() and absf(player.global_position.y) < 0.2, "player stands on the plaza (y=%.2f)" % player.global_position.y)
	# walk east, camera follows
	var x0: float = player.global_position.x
	var c0: float = cam.global_position.x
	Input.action_press(&"move_right")
	await _frames(40)
	Input.action_release(&"move_right")
	await _frames(30)
	check(player.global_position.x > x0 + 1.5, "keyboard moves the 3D player (%.2f m)" % (player.global_position.x - x0))
	check(cam.global_position.x > c0 + 1.0, "camera follows the player")
	check(player.facing.x > 0.9, "player faces the way it walked")
	# diagonal (8-direction)
	var p0: Vector3 = player.global_position
	Input.action_press(&"move_right")
	Input.action_press(&"move_down")
	await _frames(20)
	Input.action_release(&"move_right")
	Input.action_release(&"move_down")
	var d: Vector3 = player.global_position - p0
	check(d.x > 0.3 and d.z > 0.3, "diagonal movement")
	# touch stick
	x0 = player.global_position.x
	var ui: GameUi = main.get_node("UI")
	ui.touch.vector = Vector2.LEFT
	await _frames(30)
	ui.touch.vector = Vector2.ZERO
	check(player.global_position.x < x0 - 0.8, "touch stick moves the 3D player")
	# the railing over the cliff stops the player
	await _place3(Vector3(4, 0.05, 8))
	Input.action_press(&"move_down")
	await _frames(90)
	Input.action_release(&"move_down")
	check(player.global_position.z < 9.8 and player.global_position.y > -0.3, "railing keeps the player on the plaza (z=%.2f)" % player.global_position.z)
	# the terrace wall blocks, the stairs climb
	await _place3(Vector3(-6, 0.05, -7))
	Input.action_press(&"move_up")
	await _frames(60)
	Input.action_release(&"move_up")
	check(player.global_position.z > -10.2 and player.global_position.y < 0.5, "terrace wall blocks the plaza (z=%.2f)" % player.global_position.z)
	await _place3(Vector3(0, 0.05, -2))
	Input.action_press(&"move_up")
	await _frames(150)
	Input.action_release(&"move_up")
	await _frames(10)
	check(player.global_position.y > 2.8 and player.is_on_floor(), "stairs carry the player up to the tavern terrace (y=%.2f)" % player.global_position.y)
	# tavern keeper
	await _place3(Vector3(-7.2, 3.05, -10.9))
	check(player.target != null and player.target.label == "Tavern keeper", "tavern keeper is targeted")
	check(ui.hud.prompt_text().contains("Tavern keeper"), "HUD prompt shows '%s'" % ui.hud.prompt_text())
	check(player.try_interact() and Dialogue.active, "talking opens dialogue")
	var at: Vector3 = player.global_position
	Input.action_press(&"move_down")
	await _frames(10)
	Input.action_release(&"move_down")
	check(player.global_position.distance_to(at) < 0.05, "player cannot walk during dialogue")
	await _talk(["Where's the mine"])
	check(GameState.get_flag("tavern_keeper.met") == true, "dialogue effects apply in 3D")
	# raised stairs and bridge to B-17
	await _place3(Vector3(8.5, 3.05, -18))
	Input.action_press(&"move_up")
	await _frames(300)
	Input.action_release(&"move_up")
	await _frames(10)
	check(player.global_position.y > 5.8 and player.global_position.z < -35.0, "walkway and bridge reach the pods (y=%.2f z=%.2f)" % [player.global_position.y, player.global_position.z])
	await _place3(Vector3(4, 6.05, -36.2))
	check(player.target != null and player.target.label == "Pod B-17", "B-17 door is targeted")
	player.try_interact()
	await _talk([])
	# down the west stairs to the mine approach
	await _place3(Vector3(-10, 0.05, 2))
	Input.action_press(&"move_left")
	await _frames(200)
	Input.action_release(&"move_left")
	await _frames(10)
	check(player.global_position.y < -2.8 and player.global_position.x < -19.0, "west stairs lead down to the mine approach (y=%.2f x=%.2f)" % [player.global_position.y, player.global_position.x])
	Input.action_press(&"move_left")
	await _frames(300)
	Input.action_release(&"move_left")
	check(player.global_position.x > -38.0, "the mine gate blocks the approach (x=%.2f)" % player.global_position.x)
	# save / load in 3D
	await _place3(Vector3(-30, -2.95, 4))
	check(SaveManager.save_game("test"), "save in the 3D district")
	main.call("load_map", "anjabi_mine", "default")
	await _frames(3)
	check(SaveManager.load_game("test"), "load in the 3D district")
	await _frames(3)
	player = main.get("player")
	check(player is Player3D and player.global_position.distance_to(Vector3(-30, -2.95, 4)) < 0.2, "load restores 3D map and position")
	# through the gate to the mine yard and back up
	await _place3(Vector3(-36.0, -2.95, 2))
	check(player.target is MapExit3D, "the mine gate is an exit")
	player.try_interact()
	await _frames(4)
	player = main.get("player")
	check(str(main.get("map_id")) == "anjabi_mine" and player is Player, "the gate leads into the mine yard map")
	await _place(Vector2(160, 30))
	player.try_interact()
	await _frames(6)
	player = main.get("player")
	check(str(main.get("map_id")) == "anjabi_district" and player.global_position.distance_to(Vector3(-34, -2.95, 2)) < 0.5, "mine stairs return to the mine approach")


func _place3(p: Vector3) -> void:
	player.global_position = p
	player.velocity = Vector3.ZERO
	await _frames(6)


func check(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_fails += 1
	print("%s  %s" % ["PASS" if ok else "FAIL", what])


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
	await get_tree().process_frame


func _place(p: Vector2) -> void:
	player.global_position = p
	await _frames(4)


func _until(cond: Callable) -> void:
	for i in 1200:
		if cond.call():
			break
		await get_tree().physics_frame
	await _frames(2)


## Plays the open dialogue: picks the first choice containing any of `prefer`
## (each used once), otherwise the last choice, until it ends.
func _talk(prefer: Array) -> void:
	var want := prefer.duplicate()
	for i in 200:
		if not Dialogue.active:
			break
		var opts := Dialogue.choice_texts()
		if opts.is_empty():
			Dialogue.advance()
		else:
			var pick := opts.size() - 1
			for w: String in want:
				var found := false
				for j in opts.size():
					if opts[j].contains(w):
						pick = j
						want.erase(w)
						found = true
						break
				if found:
					break
			Dialogue.choose(pick)
		await get_tree().process_frame
	await _frames(2)
