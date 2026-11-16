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
	await _world()
	await _proto2d()
	SaveManager.delete_save("test")
	print("\n%d checks, %d failed" % [_checks, _fails])
	get_tree().quit(1 if _fails > 0 else 0)


func _run() -> void:
	player = main.get("player")
	var map = main.get("map")
	check(player != null and map is GameMap3D and player is Player3D, "the mine yard is a 3D map with a 3D player")
	check(Journal.quests.has("quiet_mine"), "new game opens the investigation")
	check(player.global_position.distance_to(Vector3(8, 6.05, 1.2)) < 0.3, "player starts at the top of the Estate stairs")

	# movement, and the real 6 m stair down to the yard
	var z0: float = player.global_position.z
	Input.action_press(&"move_down")
	await _frames(30)
	Input.action_release(&"move_down")
	check(player.global_position.z > z0 + 1.0, "keyboard movement moves the player (%.2f m)" % (player.global_position.z - z0))
	Input.action_press(&"move_up")
	await _frames(120)
	Input.action_release(&"move_up")
	check(player.global_position.z > 0.0 and player.global_position.y > 5.8, "the top of the stairs is closed off (z=%.2f)" % player.global_position.z)
	Input.action_press(&"move_down")
	await _frames(240)
	Input.action_release(&"move_down")
	await _frames(10)
	check(player.global_position.y < 0.2 and player.global_position.z > 12.6 and player.is_on_floor(), "the stairs lead down into the yard (y=%.2f z=%.2f)" % [player.global_position.y, player.global_position.z])

	# touch stick
	var ui: GameUi = main.get_node("UI")
	var x0: float = player.global_position.x
	ui.touch.vector = Vector2.RIGHT
	await _frames(20)
	ui.touch.vector = Vector2.ZERO
	check(player.global_position.x > x0 + 0.5, "touch stick vector moves the player")

	# collision with the gate
	await _place3(Vector3(24, 0.05, 14.5))
	Input.action_press(&"move_up")
	await _frames(90)
	Input.action_release(&"move_up")
	check(player.global_position.z > 12.5, "the gate blocks the road (z=%.2f)" % player.global_position.z)

	# notice
	await _place3(Vector3(21.25, 0.05, 13.1))
	check(player.target != null and player.target.label == "Notice", "notice is targeted")
	check(ui.hud.prompt_text().contains("Notice"), "HUD prompt shows '%s'" % ui.hud.prompt_text())
	check(player.try_interact() and Dialogue.active, "interacting opens dialogue")
	var at: Vector3 = player.global_position
	Input.action_press(&"move_down")
	await _frames(10)
	Input.action_release(&"move_down")
	check(player.global_position.distance_to(at) < 0.05, "player cannot walk during dialogue")
	await _talk([])
	check(Journal.has_clue("closure_notice"), "notice records a clue")
	check(Journal.objective_state("quiet_mine", "notice") == Journal.DONE, "notice objective done")

	# guard before the driller: no way to press
	await _place3(Vector3(26.4, 0.05, 14.3))
	check(player.target != null and player.target.label == "Gate guard", "gate guard is targeted")
	player.try_interact()
	check(Dialogue.active, "guard dialogue starts")
	await _talk(["The crew was pulled"])
	check(not Journal.has_clue("power_cut"), "guard cannot be pressed without the driller's account")

	# driller
	await _place3(Vector3(16.8, 0.05, 31.0))
	check(player.target != null and player.target.label == "Driller", "driller is targeted")
	player.try_interact()
	await _talk(["What happened at the mine", "Who gave"])
	check(Journal.has_clue("early_recall"), "driller records a clue")

	# guard again
	await _place3(Vector3(26.4, 0.05, 14.3))
	player.try_interact()
	await _talk(["The crew was pulled", "another way"])
	check(Journal.has_clue("power_cut"), "pressing the guard records a clue")
	check(Journal.objective_state("quiet_mine", "way_in") == Journal.ACTIVE, "guard reveals the hidden objective")

	# puzzle: wrong branch first
	var cart: OreCart3D = map.get_node("Entities/OreCart")
	await _place3(Vector3(40, 0.05, 30.2))
	check(player.target != null and player.target.label == "Ore cart", "cart is targeted")
	player.try_interact()
	await _until(func() -> bool: return not cart.moving)
	check(cart.state() == "buffer", "points at A: cart rolls to the buffer")
	await _talk([])
	await _place3(Vector3(40, 0.05, 18.4))
	Input.action_press(&"move_up")
	await _frames(60)
	Input.action_release(&"move_up")
	check(player.global_position.z > 17.0 and player.global_position.y > -0.2, "washout blocks the spur (z=%.2f)" % player.global_position.z)
	await _place3(Vector3(43.4, 0.05, 19.3))
	check(player.target != null and player.target.label == "Ore cart", "cart at the buffer is targeted")
	player.try_interact()
	await _until(func() -> bool: return not cart.moving)
	check(cart.state() == "start", "cart can be hauled back")
	# lever, then the right branch
	await _place3(Vector3(38.6, 0.05, 23.4))
	check(player.target != null and player.target.label == "Points lever", "lever is targeted")
	player.try_interact()
	check(str(GameState.get_flag("anjabi.spur_switch")) == "b", "lever sets the points to B")
	await _place3(Vector3(40, 0.05, 30.2))
	player.try_interact()
	await _until(func() -> bool: return not cart.moving)
	check(cart.state() == "trench", "points at B: cart drops into the washout")
	await _talk([])
	check(Journal.objective_state("quiet_mine", "way_in") == Journal.DONE, "bridging completes the objective")
	await _place3(Vector3(40, 0.05, 18.4))
	Input.action_press(&"move_up")
	await _frames(80)
	Input.action_release(&"move_up")
	check(player.global_position.z < 14.8 and player.global_position.y > -0.2, "player can cross the cart bridge (z=%.2f y=%.2f)" % [player.global_position.z, player.global_position.y])
	Input.action_press(&"move_up")
	Input.action_press(&"move_left")
	await _frames(60)
	Input.action_release(&"move_up")
	Input.action_release(&"move_left")
	check(player.global_position.z < 12.4, "the corridor behind the washout opens into the inner yard (z=%.2f)" % player.global_position.z)

	# mine door
	await _place3(Vector3(24, 0.05, 6.6))
	check(player.target != null and player.target.label == "Mine door", "mine door is targeted")
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
	await _place3(Vector3(30, 0.05, 9))
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
	check(str(main.get("map_id")) == "anjabi_mine" and player.global_position.distance_to(Vector3(30, 0.05, 9)) < 0.3, "load restores the player position")
	check(Journal.clues.size() == 4 and Journal.is_complete("quiet_mine"), "load restores the journal")
	check(cart.state() == "trench" and cart.global_position.distance_to(Vector3(40, 0, 16)) < 0.1, "load restores the puzzle state")
	await _place3(Vector3(40, 0.05, 14.0))
	Input.action_press(&"move_down")
	await _frames(80)
	Input.action_release(&"move_down")
	check(player.global_position.z > 17.5 and player.global_position.y > -0.2, "bridge is still walkable after load (z=%.2f)" % player.global_position.z)
	# follow-up dialogue reacts to state
	await _place3(Vector3(16.8, 0.05, 31.0))
	player.try_interact()
	await _talk([])
	check(GameState.get_flag("driller.told_seal") == true, "driller reacts to the sealed door")


func _town() -> void:
	# travel: mine -> town -> mine
	await _place3(Vector3(8, 6.05, 1.0))
	check(player.target is MapExit3D, "the Estate stairs are an exit")
	player.try_interact()
	await _frames(4)
	player = main.get("player")
	check(str(main.get("map_id")) == "anjabi_town" and player is Player3D, "the mine stairs lead up into the town")
	await _frames(10)
	player = main.get("player")
	var town = main.get("map")
	check(town is GameMap3D and player is Player3D, "the town is a 3D map with a 3D player")
	var meshes: int = town.find_children("*", "GeometryInstance3D", true, false).size()
	check(meshes > 300, "the town is built from real meshes (%d)" % meshes)
	await _frames(20)
	check(player.is_on_floor(), "player arrives standing on the town ground (y=%.2f)" % player.global_position.y)
	check(player.target is MapExit3D, "arrives beside the way back to the mine")
	# every landmark from the greybox is on solid, walkable ground
	var landmarks := {"Steps": Vector2(880, 415), "Forest": Vector2(230, 110), "Garden": Vector2(200, 345),
		"Estate": Vector2(240, 578), "Mine": Vector2(212, 700), "Airpad": Vector2(450, 800),
		"Beach": Vector2(650, 640), "Tion Tower": Vector2(515, 465), "Tavern": Vector2(760, 350),
		"Pods": Vector2(580, 70), "Guard Tower": Vector2(945, 130), "Docks": Vector2(1170, 460),
		"Shop": Vector2(930, 385), "Tram": Vector2(970, 465), "Rainforest": Vector2(1380, 325)}
	var bad := []
	for k: String in landmarks:
		var at: Vector3 = town.nearest_walk(landmarks[k])
		await _place3(at + Vector3(0, 0.3, 0))
		await _frames(10)
		if not player.is_on_floor() or absf(player.global_position.y - at.y) > 0.6:
			bad.append(k)
	check(bad.is_empty(), "the player stands at all 15 landmarks %s" % ("" if bad.is_empty() else str(bad)))
	# the Steps: district title, walking, real height differences across town
	await _place3(town.nearest_walk(Vector2(880, 415)) + Vector3(0, 0.1, 0))
	await _frames(20)
	check(main.get_node("UI").hud._title.text.contains("THE STEPS"), "district title shows '%s'" % main.get_node("UI").hud._title.text)
	var x0: float = player.global_position.x
	Input.action_press(&"move_left")
	await _frames(40)
	Input.action_release(&"move_left")
	check(player.global_position.x < x0 - 1.0, "player walks in town")
	var hp: float = town.nearest_walk(Vector2(580, 70)).y
	var hb: float = town.nearest_walk(Vector2(650, 640)).y
	check(hp - hb > 10.0, "the pods stand %.1f m above the beach" % (hp - hb))
	# leave the Steps west along the walkway toward Tion Tower: the ground rises
	var zw: float = _walk_z(town, O.x - 14.5, -9, 9)
	await _place3(Vector3(O.x - 14.5, town.ground(O.x - 14.5, O.z + zw) + 0.1, O.z + zw))
	await _frames(10)
	var y0: float = player.global_position.y
	Input.action_press(&"move_left")
	await _frames(240)
	Input.action_release(&"move_left")
	await _frames(10)
	check(player.global_position.y > y0 + 0.5 and player.is_on_floor(), "walkways climb from the Steps (%.2f -> %.2f m)" % [y0, player.global_position.y])
	# the sea stops the player on the beach
	await _place3(town.nearest_walk(Vector2(650, 640)) + Vector3(0, 0.1, 0))
	Input.action_press(&"move_right")
	Input.action_press(&"move_down")
	await _frames(600)
	Input.action_release(&"move_right")
	Input.action_release(&"move_down")
	check(player.global_position.y > -6.6 and player.is_on_floor(), "the sea stops the player on the beach (y=%.2f)" % player.global_position.y)
	await _place3(town.nearest_walk(Vector2(880, 415)) + Vector3(0, 0.1, 0))
	check(SaveManager.save_game("test"), "save in town")
	var at_save: Vector3 = player.global_position
	main.call("new_game")
	await _frames(3)
	check(SaveManager.load_game("test"), "load in town")
	await _frames(3)
	player = main.get("player")
	check(str(main.get("map_id")) == "anjabi_town" and player.global_position.distance_to(at_save) < 0.3, "load restores map and position")
	town = main.get("map")
	await _place3(town.nearest_walk(Vector2(212, 692)) + Vector3(0, 0.1, 0))
	player.try_interact()
	await _frames(4)
	player = main.get("player")
	check(str(main.get("map_id")) == "anjabi_mine", "the mine yard in town leads back to the mine map")
	await _place3(Vector3(43.6, 0.05, 32.2))
	check(player.target is MapExit3D, "the airpad path is an exit")
	player.try_interact()
	await _frames(10)
	player = main.get("player")
	check(str(main.get("map_id")) == "anjabi_town" and player.is_on_floor(), "the airpad path arrives on the ground in town")
	check(player.target is MapExit3D, "arrives beside the way back")
	player.try_interact()
	await _frames(4)
	player = main.get("player")
	check(str(main.get("map_id")) == "anjabi_mine" and player.global_position.distance_to(Vector3(43.3, 0.05, 32.2)) < 0.3, "and returns to the east side of the mine")


## The Steps: the detailed insert (plaza, stairs, tavern terrace) inside the town map.
const O := Vector3(101.52, 0, 45.72)


func _district() -> void:
	player = main.get("player")
	var map: Node = main.get("map")
	check(str(main.get("map_id")) == "anjabi_town", "new game starts in the town")
	check(map is GameMap3D and player is Player3D, "the town is a 3D map with a 3D player")
	check(player.global_position.distance_to(O + Vector3(2, 0.05, 5)) < 0.5, "new game starts on the Steps plaza")
	var meshes: int = map.find_children("*", "GeometryInstance3D", true, false).size()
	var bodies: int = map.find_children("*", "StaticBody3D", true, false).size()
	check(meshes > 300 and bodies > 50, "the town is built from real meshes and colliders (%d meshes, %d bodies)" % [meshes, bodies])
	check(map.find_children("*", "Npc3D", true, false).size() >= 1, "the Steps insert is part of the town")
	var cam: Camera3D = player.camera
	check(cam.current and cam.projection == Camera3D.PROJECTION_PERSPECTIVE and absf(cam.rotation_degrees.y) < 0.01, "fixed-orientation follow camera is current")
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
	var p0: Vector3 = player.global_position
	Input.action_press(&"move_right")
	Input.action_press(&"move_down")
	await _frames(20)
	Input.action_release(&"move_right")
	Input.action_release(&"move_down")
	var d: Vector3 = player.global_position - p0
	check(d.x > 0.3 and d.z > 0.3, "diagonal movement")
	x0 = player.global_position.x
	var ui: GameUi = main.get_node("UI")
	ui.touch.vector = Vector2.LEFT
	await _frames(30)
	ui.touch.vector = Vector2.ZERO
	check(player.global_position.x < x0 - 0.8, "touch stick moves the 3D player")
	# the terrace wall blocks, the stairs climb
	await _place3(O + Vector3(-6, 0.05, -7))
	Input.action_press(&"move_up")
	await _frames(60)
	Input.action_release(&"move_up")
	check(player.global_position.z > O.z - 10.2 and player.global_position.y < 0.5, "terrace wall blocks the plaza")
	await _place3(O + Vector3(0, 0.05, -2))
	Input.action_press(&"move_up")
	await _frames(150)
	Input.action_release(&"move_up")
	await _frames(10)
	check(player.global_position.y > 2.8 and player.is_on_floor(), "stairs carry the player up to the tavern terrace (y=%.2f)" % player.global_position.y)
	# tavern keeper
	await _place3(O + Vector3(-7.2, 3.05, -10.9))
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
	# the insert joins the town seamlessly: walk off the plaza east and west
	for side: float in [1.0, -1.0]:
		var edge_x: float = O.x + (20.5 if side > 0 else -12.5)
		var zl: float = _walk_z(map, edge_x + side * 2.0, -9, 9)
		check(not is_nan(zl), "a town walkway meets the plaza's %s edge" % ("east" if side > 0 else "west"))
		if is_nan(zl):
			continue
		await _place3(Vector3(edge_x - side * 3.0, 0.05, O.z + zl))
		Input.action_press(&"move_right" if side > 0 else &"move_left")
		await _frames(150)
		Input.action_release(&"move_right" if side > 0 else &"move_left")
		await _frames(10)
		var past: float = (player.global_position.x - edge_x) * side
		check(past > 4.0 and player.is_on_floor(), "the plaza runs into the town's walkway (%s, %.1f m past the edge)" % ["east" if side > 0 else "west", past])
	# from the terrace west onto the town's paths at the same level
	await _place3(O + Vector3(-20, 3.05, -20))
	Input.action_press(&"move_left")
	await _frames(150)
	Input.action_release(&"move_left")
	await _frames(10)
	check(player.global_position.x < O.x - 26.0 and player.is_on_floor(), "the terrace runs into the town's paths (x=%.1f)" % (player.global_position.x - O.x))
	# B-17 among the town's pods, and the sign by the mine
	var b17: Node3D = map.get_node("PodB17Door")
	await _place3(Vector3(b17.global_position.x, map.ground(b17.global_position.x, b17.global_position.z + 1.0) + 0.1, b17.global_position.z + 0.6))
	await _frames(10)
	check(player.target != null and player.target.label == "Pod B-17", "B-17's door is in the town")
	player.try_interact()
	await _talk([])
	# save / load
	await _place3(O + Vector3(10, 0.05, 6))
	check(SaveManager.save_game("test"), "save on the Steps")
	main.call("load_map", "anjabi_mine", "default")
	await _frames(3)
	check(SaveManager.load_game("test"), "load on the Steps")
	await _frames(3)
	player = main.get("player")
	check(player is Player3D and player.global_position.distance_to(O + Vector3(10, 0.05, 6)) < 0.2, "load restores map and position")
	# a save from the retired district map resumes on the Steps
	main.call("restore_world", {"map": "anjabi_district", "dim": 3, "x": -30.0, "y": -2.95, "z": 4.0})
	await _frames(3)
	player = main.get("player")
	check(str(main.get("map_id")) == "anjabi_town" and player.global_position.distance_to(O + Vector3(2, 0.05, 5)) < 0.5, "old district saves resume on the Steps")
	# to the mine and back
	var exit: Node3D = map.get_node("ToMineRoad") if is_instance_valid(map) else null
	map = main.get("map")
	exit = map.get_node("ToMineRoad")
	await _place3(exit.global_position - Vector3(0, 0.7, 0))
	await _frames(6)
	check(player.target is MapExit3D, "the mine path is an exit")
	player.try_interact()
	await _frames(4)
	player = main.get("player")
	check(str(main.get("map_id")) == "anjabi_mine" and player is Player3D, "the path leads into the 3D mine yard")


## Local z (relative to O) of the town walk cell at world x nearest the plaza centre line, or NAN.
func _walk_z(map: Node, x: float, z0: int, z1: int) -> float:
	var best := NAN
	for z in range(z0, z1 + 1):
		var cx := int(x)
		var cz := int(O.z + z)
		var t: int = map.cls[cz * map.w + cx]
		if t == 1 or t == 2 or t == 3:
			var local := (cz + 0.5) - O.z
			if is_nan(best) or absf(local) < absf(best):
				best = local
	return best


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


## World clock, calendar, weather, lighting, persistence and sprint.
func _world() -> void:
	main.call("new_game")
	await _frames(5)
	player = main.get("player")
	var hud: Hud = main.get("ui").hud
	WorldTime.minutes_per_second = 0.0
	check(WorldTime.date_text() == "Autumn 12 · Thursday" and WorldTime.time_text() == "6:40 PM", "new game starts on Autumn 12, Thursday, 6:40 PM (%s, %s)" % [WorldTime.date_text(), WorldTime.time_text()])
	check(hud.clock_text().contains("Autumn 12") and hud.clock_text().contains("6:40 PM"), "the clock HUD shows date and 12-hour time")
	check(WorldTime.period() == "evening" and Weather.current == "rain", "it is a rainy evening")

	# midnight rollover
	var got := {"days": 0, "periods": [], "seasons": 0, "years": 0, "jumps": 0}
	var on_day := func(_c: WorldCalendar) -> void: got["days"] += 1
	var on_period := func(p: String, _prev: String) -> void: (got["periods"] as Array).append(p)
	var on_season := func(_s: int) -> void: got["seasons"] += 1
	var on_year := func(_y: int) -> void: got["years"] += 1
	WorldTime.day_changed.connect(on_day)
	WorldTime.period_changed.connect(on_period)
	WorldTime.season_changed.connect(on_season)
	WorldTime.year_changed.connect(on_year)
	WorldTime.set_time(23, 58)
	WorldTime.advance_minutes(3)
	check(WorldTime.hour == 0 and WorldTime.minute == 1 and WorldTime.calendar.day == 13 and got["days"] == 1, "midnight rolls the clock over and advances one day")
	check(WorldTime.calendar.weekday_name() == "Friday" and WorldTime.time_text() == "12:01 AM", "the weekday follows and midnight reads 12:01 AM")
	(got["periods"] as Array).clear()
	WorldTime.set_time(4, 59)
	WorldTime.advance_minutes(1)
	check(got["periods"] == ["dawn"] and WorldTime.period() == "dawn", "dawn begins at 05:00 and announces itself once")
	WorldTime.set_time(12, 0)
	check(WorldTime.time_text() == "12:00 PM" and WorldTime.period() == "midday" and WorldTime.is_between(9, 17) and not WorldTime.is_between(22, 6), "noon reads 12:00 PM; opening-hours query works")
	# season and year rollover
	WorldTime.set_date(1, 2, 28)
	WorldTime.set_time(23, 59)
	WorldTime.advance_minutes(1)
	check(WorldTime.calendar.season_name() == "Winter" and WorldTime.calendar.day == 1 and got["seasons"] == 1, "day 28 of Autumn rolls into Winter 1")
	WorldTime.set_date(1, 3, 28)
	WorldTime.set_time(23, 59)
	WorldTime.advance_minutes(1)
	check(WorldTime.calendar.year == 2 and WorldTime.calendar.season_name() == "Spring" and got["years"] == 1, "the end of Winter starts year 2 in Spring")
	# long skips and sleeping
	var d0 := WorldTime.calendar.total_days()
	WorldTime.advance_minutes(3 * 1440 + 30)
	check(WorldTime.calendar.total_days() == d0 + 3 and WorldTime.minute == 30, "skipping three days and thirty minutes lands exactly")
	WorldTime.set_time(22, 15)
	d0 = WorldTime.calendar.total_days()
	WorldTime.sleep_until(6)
	check(WorldTime.hour == 6 and WorldTime.minute == 0 and WorldTime.calendar.total_days() == d0 + 1, "sleeping until 6 wakes the next morning")
	WorldTime.calendar.add_event("test_event", WorldTime.calendar.season, WorldTime.calendar.day + 1)
	var due: Array = []
	var on_event := func(e: Dictionary) -> void: due.append(e["id"])
	WorldTime.event_due.connect(on_event)
	WorldTime.sleep_until(0, 5)
	check(due == ["test_event"], "a scheduled calendar event fires on its day")
	WorldTime.event_due.disconnect(on_event)
	WorldTime.calendar.events.clear()
	for pair: Array in [[WorldTime.day_changed, on_day], [WorldTime.period_changed, on_period], [WorldTime.season_changed, on_season], [WorldTime.year_changed, on_year]]:
		(pair[0] as Signal).disconnect(pair[1])

	# running and pausing
	WorldTime.set_time(10, 0)
	WorldTime.minutes_per_second = 120.0
	await _frames(30)
	var ran := WorldTime.minute_of_day() - 600
	check(ran > 10, "time passes during play (%d minutes in 30 frames at test speed)" % ran)
	WorldTime.pause("test")
	var m0 := WorldTime.total_minutes()
	await _frames(20)
	check(WorldTime.total_minutes() == m0 and WorldTime.is_paused(), "a registered pause stops the clock")
	WorldTime.resume("test")
	get_tree().paused = true
	m0 = WorldTime.total_minutes()
	await _frames(20)
	get_tree().paused = false
	check(WorldTime.total_minutes() == m0, "menus (paused tree) stop the clock")
	await _frames(10)
	check(WorldTime.total_minutes() > m0, "and it runs again afterwards")
	WorldTime.minutes_per_second = 0.0

	# weather
	WorldTime.set_date(1, 2, 12)
	WorldTime.set_time(8, 0)
	Weather.reset(42)
	var f1 := str(Weather.forecast(24))
	Weather.reset(42)
	check(str(Weather.forecast(24)) == f1 and Weather.forecast(24).size() >= 2, "the same seed plans the same forecast")
	var fc := Weather.forecast(24)
	check(int(fc[fc.size() - 1]["until"]) - WorldTime.total_minutes() == 24 * 60, "the forecast covers the next 24 hours")
	var changes := {"n": 0}
	var on_weather := func(_t: String, _p: String) -> void: changes["n"] += 1
	Weather.weather_changed.connect(on_weather)
	for i in 24:
		WorldTime.advance_minutes(60)
	check(changes["n"] >= 2 and changes["n"] <= 9, "weather changes a few times a day, not every minute (%d in 24 h)" % changes["n"])
	Weather.set_weather("fog", 60)
	check(Weather.current == "fog", "weather can be overridden")
	WorldTime.advance_minutes(61)
	check(Weather.override == "" and Weather.current == str(Weather.schedule[0]["type"]), "a timed override hands back to the forecast")
	WorldTime.set_date(1, 3, 2)
	Weather.reset(7)
	var seen := {}
	for i in 24 * 20:
		WorldTime.advance_minutes(60)
		seen[Weather.current] = true
	check(seen.has("snow") and not seen.has("heavy_rain"), "winter brings snow and no storms (%s)" % str(seen.keys()))
	WorldTime.set_date(1, 1, 2)
	Weather.reset(7)
	seen.clear()
	for i in 24 * 20:
		WorldTime.advance_minutes(60)
		seen[Weather.current] = true
	check(seen.has("clear") and not seen.has("snow"), "summer is mostly clear and never snows (%s)" % str(seen.keys()))
	Weather.weather_changed.disconnect(on_weather)

	# lighting follows the clock
	var ctl: EnvironmentController = main.get("map").environment
	check(ctl != null and ctl.env != null, "the map has an environment controller")
	Weather.set_weather("clear")
	WorldTime.set_time(13, 0)
	await _frames(3)
	var day_sun := ctl.sun.light_energy
	var day_bg := ctl.env.background_color.get_luminance()
	var lamp: Light3D = get_tree().get_nodes_in_group(&"lamp_lights")[0]
	check(not lamp.visible, "street lamps are off at midday")
	var e0 := ctl.env.ambient_light_energy
	WorldTime.advance_minutes(1)
	await _frames(2)
	check(absf(ctl.env.ambient_light_energy - e0) < 0.02, "light changes smoothly from minute to minute")
	WorldTime.set_time(23, 0)
	await _frames(3)
	check(ctl.env.background_color.get_luminance() < day_bg * 0.4 and lamp.visible and lamp.light_energy > 1.0, "night is dark and the lamps are lit")
	check(ctl.sun.light_energy < day_sun and ctl.sun.light_color.b > ctl.sun.light_color.r, "the moon is dimmer and bluer than the sun")
	WorldTime.set_time(18, 40)
	await _frames(3)
	check(ctl.sun.light_color.r > ctl.sun.light_color.b * 1.3, "golden hour is warm")
	# weather presentation: blends, then indoor override
	WorldTime.set_time(13, 0)
	await _frames(3)
	var clear_sun := ctl.sun.light_energy
	Weather.set_weather("heavy_rain")
	await _frames(5)
	check(float(ctl.w["rain"]) > 0.0 and float(ctl.w["rain"]) < 0.5, "weather blends in gradually (rain %.2f after 5 frames)" % float(ctl.w["rain"]))
	ctl.snap()
	check(is_equal_approx(float(ctl.w["rain"]), 1.0) and ctl.sun.light_energy < clear_sun * 0.6, "heavy rain darkens the day")
	var rain: Rain3D = get_tree().get_nodes_in_group(&"precipitation")[0]
	check(rain.emitting, "rain falls")
	Weather.set_weather("snow")
	ctl.snap()
	check(not rain.emitting and (rain.get_child(1) as GPUParticles3D).emitting, "snow replaces rain")
	ctl.indoor = true
	ctl.snap()
	check(ctl.sun.light_energy == 0.0 and not (rain.get_child(1) as GPUParticles3D).emitting and lamp.visible, "indoors ignores sun and weather")
	ctl.indoor = false
	ctl.snap()
	check(ctl.sun.light_energy > 0.0, "back outdoors the sun returns")

	# persistence
	WorldTime.set_date(3, 3, 17)
	WorldTime.set_time(21, 7)
	Weather.reset(99)
	Weather.set_weather("snow", 300)
	var sched := str(Weather.schedule)
	check(SaveManager.save_game("test"), "save with clock and weather")
	main.call("new_game")
	await _frames(3)
	check(WorldTime.calendar.year == 1 and Weather.current == "rain", "a new game resets the clock and weather")
	check(SaveManager.load_game("test"), "load with clock and weather")
	check(WorldTime.calendar.year == 3 and WorldTime.calendar.season_name() == "Winter" and WorldTime.calendar.day == 17 and WorldTime.hour == 21 and WorldTime.minute == 7, "load restores year, season, day, hour and minute")
	check(Weather.current == "snow" and Weather.override == "snow" and str(Weather.schedule) == sched, "load restores the weather, its override and the forecast")
	await _frames(3)
	ctl = main.get("map").environment
	check(is_equal_approx(float(ctl.w["snow"]), 1.0) and is_equal_approx(float(ctl.w["cover"]), 1.0), "the loaded world is lit for its time and weather at once")
	WorldTime.advance_minutes(301)
	check(Weather.override == "", "the restored override still expires on time")

	# sprint
	main.call("new_game")
	await _frames(10)
	WorldTime.minutes_per_second = 0.0
	player = main.get("player")
	await _place3(O + Vector3(-8, 0.05, 6))
	Input.action_press(&"move_right")
	await _frames(40)
	var x0: float = player.global_position.x
	await _frames(40)
	var walked: float = player.global_position.x - x0
	check(not player.sprinting, "walking is not sprinting")
	Input.action_press(&"sprint")
	await _frames(25)
	x0 = player.global_position.x
	await _frames(40)
	var ran_d: float = player.global_position.x - x0
	check(player.sprinting and ran_d > walked * 1.5, "holding sprint runs faster (%.2f m vs %.2f m)" % [ran_d, walked])
	Input.action_release(&"sprint")
	await _frames(25)
	check(not player.sprinting and absf(Vector3(player.velocity.x, 0, player.velocity.z).length() - player.walk_speed) < 0.3, "releasing sprint returns to a walk")
	Input.action_release(&"move_right")
	await _frames(20)
	player.touch.sprint = true
	Input.action_press(&"move_left")
	await _frames(30)
	check(player.sprinting, "the RUN toggle sprints without the key")
	Input.action_release(&"move_left")
	player.touch.sprint = false
	WorldTime.minutes_per_second = 1.0


## The Golden Sun-style 2D prototype (maps/anjabi/steps_2d.tscn, baked by tools/bake_2d.gd).
func _proto2d() -> void:
	main.call("new_game", "anjabi_steps_2d")
	await _frames(5)
	WorldTime.minutes_per_second = 0.0
	var map: Map2D = main.get("map")
	player = main.get("player")
	check(map is Map2D and player is Player2D and str(main.get("map_id")) == "anjabi_steps_2d", "the 2D prototype loads as a 2D map with a 2D player")
	var S := float(map.S)
	check(absf(map.height_at(Vector2(2, 5) * S)) < 0.2 and absf(map.height_at(Vector2(-6, -15) * S) - 3.0) < 0.2, "the baked heights put the plaza at 0 m and the terrace at 3 m")
	check(map.entities.get_child_count() > 30, "buildings, lamps and trees are y-sorted sprites (%d)" % map.entities.get_child_count())
	player.position = Vector2(2, 5) * S
	await _frames(2)
	var x0: float = player.position.x
	Input.action_press(&"move_right")
	await _frames(30)
	Input.action_release(&"move_right")
	check(player.position.x - x0 > 20.0, "the player walks on the plaza")
	# the terrace wall: walking north from the plaza beside the stairs is blocked
	player.position = Vector2(-6, -8) * S
	await _frames(2)
	Input.action_press(&"move_up")
	await _frames(60)
	Input.action_release(&"move_up")
	check(player.position.y > -10.5 * S and absf(map.height_at(player.position)) < 0.3, "the terrace wall stops the player (y = %.1f m)" % (player.position.y / S))
	# the stairs climb to the terrace
	player.position = Vector2(0, -3.5) * S
	await _frames(2)
	Input.action_press(&"move_up")
	await _frames(90)
	Input.action_release(&"move_up")
	check(map.height_at(player.position) > 2.8, "the stairs lead up to the terrace (h = %.2f m)" % map.height_at(player.position))
	var keeper: Person2D = null
	for n in map.entities.get_children():
		if n is Person2D and not n is Player2D and (n as Person2D).interactable != null:
			keeper = n
	check(keeper != null, "the tavern keeper stands on the terrace")
	player.position = keeper.position + Vector2(0, 14)
	await _frames(4)
	check(player.target == keeper.interactable and player.try_interact() and Dialogue.active, "walking up to the keeper offers Talk, and talking opens the dialogue")
	Dialogue.cancel()
	await _frames(2)
	# lighting follows the clock
	var tint: CanvasModulate = map.find_children("*", "CanvasModulate", true, false)[0]
	Weather.set_weather("clear")
	WorldTime.set_time(13, 0)
	await _frames(2)
	var day := tint.color.get_luminance()
	WorldTime.set_time(23, 0)
	await _frames(2)
	check(tint.color.get_luminance() < day * 0.6 and tint.color.b > tint.color.r, "night tints the 2D map dark blue")
	# save and load in 2D
	var at: Vector2 = player.position
	check(SaveManager.save_game("test"), "save in the 2D prototype")
	main.call("new_game")
	await _frames(3)
	check(SaveManager.load_game("test"), "load the 2D prototype")
	await _frames(3)
	player = main.get("player")
	check(player is Player2D and player.position.distance_to(at) < 2.0, "load restores the 2D map and position")
	WorldTime.minutes_per_second = 1.0
