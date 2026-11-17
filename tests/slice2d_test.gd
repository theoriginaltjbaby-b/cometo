extends Node
## Headless test of the 2D tile-based vertical slice (branch 2d): the Steps and the
## shop. Grid movement, turning, running, collision, depth sorting, the NPC and its
## dialogue, the quest step, doors in and out, lighting, saves, and the title flow.
##   Godot --headless --path . res://tests/slice2d_test.tscn

const DIR := "user://test_slice2d"

var _fails := 0
var _checks := 0
var main: Node
var p: GridPlayer
var world: TileWorld


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	SaveManager.dir = DIR
	SaveManager.autosave_enabled = false
	SaveManager.boot_from_autosave = false
	main = (load("res://game/main.tscn") as PackedScene).instantiate()
	main.set("start_map", "anjabi_steps")
	add_child(main)
	await _frames(6)
	WorldTime.minutes_per_second = 0.0
	world = main.get("map")
	p = main.get("player")
	check(world is TileWorld and p is GridPlayer and str(main.get("map_id")) == "anjabi_steps", "a new game starts on the 2D Steps with a grid player")
	check(world.size == Vector2i(40, 30), "the Steps map is 40 x 30 tiles")
	check(p.tile == Vector2i(19, 22) and p.dir_name() == "up", "the player spawns south of the compass facing it")
	var vp := world.get_viewport() as SubViewport
	var box := vp.get_parent() as SubViewportContainer
	check(vp != null and vp.size.x == 240 and box.stretch_shrink == 2, "the world renders 240 px (15 tiles) wide and is scaled up 2x (%s)" % str(vp.size if vp else ""))
	check(Journal.quests.has("quiet_mine"), "the opening quest begins")

	# a tap turns without moving; holding walks one tile per step, smoothly
	await _tap(&"move_left", 2)
	check(p.tile == Vector2i(19, 22) and p.dir_name() == "left", "a tap turns in place")
	var mid := false
	Input.action_press(&"move_left")
	var t_end := Time.get_ticks_msec() + 600
	while Time.get_ticks_msec() < t_end:
		await get_tree().process_frame
		if p.is_moving() and fposmod(p.position.x - 8.0, 16.0) > 2.0 and fposmod(p.position.x - 8.0, 16.0) < 14.0:
			mid = true
	Input.action_release(&"move_left")
	await _settle()
	check(mid, "a step glides between tiles")
	check(p.tile.y == 22 and p.tile.x <= 17 and p.tile.x >= 15, "holding walks tile by tile (now at %s)" % str(p.tile))
	check(fposmod(p.position.x - 8.0, 16.0) < 0.01, "the player stops exactly on a tile")
	# running covers more ground in the same time
	p.place(Vector2i(10, 21), "right")
	await _frames(2)
	var x0 := p.tile.x
	await _hold(&"move_right", 0.5)
	var walked := p.tile.x - x0
	p.place(Vector2i(10, 21), "right")
	await _frames(2)
	Input.action_press(&"sprint")
	await _hold(&"move_right", 0.5)
	Input.action_release(&"sprint")
	var ran := p.tile.x - 10
	check(ran > walked, "running covers more tiles than walking (%d vs %d)" % [ran, walked])

	# collision: the terrace wall, the balustrade, props, the map edge
	p.place(Vector2i(10, 13), "up")
	await _hold(&"move_up", 0.6)
	check(p.tile == Vector2i(10, 13), "the terrace wall blocks")
	p.place(Vector2i(20, 21), "up")
	await _hold(&"move_up", 0.4)
	check(p.tile == Vector2i(20, 20) or p.tile == Vector2i(20, 21), "the armillary's plinth blocks (at %s)" % str(p.tile))
	check(world.is_solid(Vector2i(19, 19)) and world.is_solid(Vector2i(8, 17)), "landmark and lamps are solid")
	p.place(Vector2i(10, 24), "down")
	await _hold(&"move_down", 0.4)
	check(p.tile == Vector2i(10, 24), "the south balustrade blocks")
	# the stairs climb to the terrace under the arch
	p.place(Vector2i(19, 13), "up")
	await _hold(&"move_up", 1.6)
	check(p.tile.y <= 9 and p.tile.x == 19, "the stairs lead up to the terrace (at %s)" % str(p.tile))
	var arch: TileMapLayer = world.get_node("Over")
	check(arch.get_cell_source_id(Vector2i(19, 10)) >= 0 and arch.z_index > p.z_index, "an arch over the stairs is drawn above the player")

	# depth sorting: north of a lamp the player is drawn behind it, south in front
	var lamp: Node2D = null
	for n in world.entities.get_children():
		if n.name.begins_with("Prop_lamp") and world.tile_of(n.position) == Vector2i(8, 17):
			lamp = n
	check(lamp != null and world.entities.y_sort_enabled, "props and people share a y-sorted layer")
	p.place(Vector2i(8, 16), "down")
	check(p.position.y < lamp.position.y, "standing north of the lamp sorts behind it")
	p.place(Vector2i(8, 18), "up")
	check(p.position.y > lamp.position.y, "standing south of the lamp sorts in front of it")

	# the tavern keeper: talk, dialogue, the quest step
	var keeper: GridNpc = world.entities.get_node("Npc_tavern_keeper")
	check(keeper != null and keeper.tile == Vector2i(9, 8), "the tavern keeper stands on the terrace")
	check(not world.can_enter(Vector2i(9, 8)), "people block their tile")
	p.place(Vector2i(9, 9), "up")
	await _frames(3)
	check(p.target == keeper.interactable and main.get("ui").hud.prompt_text().contains("Tavern keeper"), "facing the keeper offers Talk")
	p.try_interact()
	await _frames(2)
	check(Dialogue.active and keeper.dir_name() == "down", "talking opens the dialogue and the keeper turns to the player")
	await _talk(["Where"])
	check(Journal.has_clue("mine_directions") and GameState.get_flag("tavern_keeper.met") == true, "asking the way records a clue in the journal (quest step)")

	# the shop door: in, look, out
	p.place(Vector2i(35, 18), "up")
	await _frames(3)
	check(p.target != null and p.target.label == "Shop", "the shop door offers Enter")
	await _hold(&"move_up", 0.4)
	await _frames(6)
	p = main.get("player")
	world = main.get("map")
	check(str(main.get("map_id")) == "anjabi_steps_shop" and p.tile == Vector2i(5, 8), "stepping into the door enters the shop")
	check(world.indoor and world.lighting.indoor, "the shop is lit as an interior")
	p.place(Vector2i(2, 3), "up")
	await _frames(3)
	check(p.target != null and p.target.label == "Shelves", "the shelves can be examined")
	p.place(Vector2i(5, 8), "down")
	await _hold(&"move_down", 0.4)
	await _frames(6)
	p = main.get("player")
	world = main.get("map")
	check(str(main.get("map_id")) == "anjabi_steps" and p.tile == Vector2i(35, 18) and p.dir_name() == "down", "the mat leads back out in front of the shop door")

	# lighting follows the clock
	var tint: CanvasModulate = world.find_children("*", "CanvasModulate", true, false)[0]
	Weather.set_weather("clear")
	WorldTime.set_time(13, 0)
	await _frames(3)
	var day := tint.color.get_luminance()
	WorldTime.set_time(23, 0)
	await _frames(3)
	var lamps := world.find_children("*", "PointLight2D", true, false)
	check(tint.color.get_luminance() < day * 0.6 and lamps.size() >= 6 and (lamps[0] as PointLight2D).visible, "night darkens the Steps and the lamps light")

	# save and load
	p.place(Vector2i(12, 20), "left")
	await _frames(2)
	check(SaveManager.save_game("s2"), "save on the 2D Steps")
	main.call("load_map", "anjabi_steps_shop", "default")
	await _frames(4)
	check(SaveManager.load_game("s2"), "load the save")
	await _frames(4)
	p = main.get("player")
	check(str(main.get("map_id")) == "anjabi_steps" and p.tile == Vector2i(12, 20) and Journal.has_clue("mine_directions"), "load restores map, tile and journal")

	# the title starts the 2D slice
	main.queue_free()
	await _frames(3)
	var app: Node = (load("res://game/app.tscn") as PackedScene).instantiate()
	app.set("animate", false)
	app.set("fade_time", 0.0)
	app.set("start_map", "anjabi_steps")  # NEW GAME now starts in the coast village (entry 30)
	add_child(app)
	await _frames(4)
	var title: TitleScreen = app.get("title")
	title.choose("NEW GAME")
	await _frames(4)
	(app.get("creation") as CharacterCreation).done.emit({"player_name": "", "player_look": {"hair": "long", "coat": "#1f3555"}})
	await _frames(8)
	var m2: Node = app.get("main")
	check(m2 != null and str(m2.get("map_id")) == "anjabi_steps" and m2.get("player") is GridPlayer, "NEW GAME from the title starts the 2D slice")
	app.queue_free()
	await _frames(2)
	SaveManager.delete_save("s2")
	print("\n%d checks, %d failed" % [_checks, _fails])
	get_tree().quit(1 if _fails > 0 else 0)


func _tap(a: StringName, frames: int) -> void:
	Input.action_press(a)
	await _frames(frames)
	Input.action_release(a)
	await _settle()


func _hold(a: StringName, seconds: float) -> void:
	Input.action_press(a)
	await get_tree().create_timer(seconds).timeout
	Input.action_release(a)
	await _settle()


func _settle() -> void:
	for i in 60:
		await get_tree().process_frame
		if not is_instance_valid(p) or not p.is_moving():
			break
	await _frames(2)


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
			for j in opts.size():
				if not want.is_empty() and opts[j].contains(str(want[0])):
					pick = j
					want.pop_front()
					break
			Dialogue.choose(pick)
		await get_tree().process_frame


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func check(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_fails += 1
	print("%s  %s" % ["PASS" if ok else "FAIL", what])
