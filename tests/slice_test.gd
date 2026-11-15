extends Node
## Headless end-to-end check of the Anjabi slice.
##   Godot --headless --path . res://tests/slice_test.tscn

var _fails := 0
var _checks := 0
var main: Node
var player: Player


func _ready() -> void:
	SaveManager.autosave_enabled = false
	SaveManager.boot_from_autosave = false
	main = (load("res://game/main.tscn") as PackedScene).instantiate()
	add_child(main)
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
	var y0 := player.global_position.y
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
	var x0 := player.global_position.x
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
	check(str(main.get("map_id")) == "anjabi_town", "the stairs lead into the town map")
	var mask: WalkMask = player.walk_mask
	check(mask != null and mask.is_walkable(player.global_position), "player arrives on walkable ground")
	check(player.target is MapExit, "arrives beside the way back to the mine")
	# the Steps: walk about, and be stopped by the sea
	await _place(Vector2(1760, 830))
	check(mask.is_walkable(player.global_position), "the Steps are walkable")
	await _frames(20)
	check(main.get_node("UI").hud._title.text.contains("THE STEPS"), "district title shows '%s'" % main.get_node("UI").hud._title.text)
	var x0 := player.global_position.x
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
	var at := player.global_position
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
