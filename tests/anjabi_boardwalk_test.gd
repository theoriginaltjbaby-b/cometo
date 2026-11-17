extends Node
## Headless test of the Boardwalk and Tram / Subway Station map (anjabi_boardwalk):
## it loads in the game, every part of it can be walked to, water and buildings
## block, nothing walkable is sealed off, the ways out and the station answer.
##   Godot --headless --path . res://tests/anjabi_boardwalk_test.tscn

var _fails := 0
var _checks := 0
var main: Node
var p: GridPlayer
var world: TileWorld


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("user://test_anjabi_boardwalk")
	SaveManager.dir = "user://test_anjabi_boardwalk"
	SaveManager.autosave_enabled = false
	SaveManager.boot_from_autosave = false
	main = (load("res://game/main.tscn") as PackedScene).instantiate()
	main.set("start_map", "anjabi_boardwalk")
	add_child(main)
	await _frames(6)
	WorldTime.minutes_per_second = 0.0
	world = main.get("map")
	p = main.get("player")
	check(world is TilesetWorld and p is GridPlayer and str(main.get("map_id")) == "anjabi_boardwalk", "the Boardwalk loads with the grid player")
	check(world.display_name == "Boardwalk" and world.size == Vector2i(52, 34), "it is named Boardwalk and is 52 x 34 tiles")
	check(p.tile == Vector2i(18, 13) and p.sprite.scale == Vector2(2, 2), "the player starts on the deck")

	# what the ground is made of
	var gl := world.get_node("Ground") as TileMapLayer
	var count := {}
	var mat := {}
	for c in gl.get_used_cells():
		var m := str(gl.get_cell_tile_data(c).get_custom_data("name"))
		mat[c] = m
		count[m] = int(count.get(m, 0)) + 1
	check(gl.get_used_cells().size() == 52 * 34, "the ground has no holes")
	for m: String in ["water", "wood_deck", "concrete", "metal", "grass"]:
		check(int(count.get(m, 0)) > 20, "%s is part of the map (%d tiles)" % [m, int(count.get(m, 0))])
	check((world.get_node("Piers") as TileMapLayer).get_used_cells().size() > 60, "the decks show their timber edge over the water")

	# everything that should be reachable is, on foot, from the start
	var reach := {p.tile: true}
	var todo: Array[Vector2i] = [p.tile]
	while not todo.is_empty():
		var c: Vector2i = todo.pop_back()
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if not reach.has(c + d) and world.can_enter(c + d, p):
				reach[c + d] = true
				todo.append(c + d)
	for s: Array in [["the walkway from the Steps", Vector2i(1, 12)], ["the walkway to the Rainforest Approach", Vector2i(50, 8)],
			["the station platform", Vector2i(12, 25)], ["the north pier landing", Vector2i(46, 11)], ["the middle pier", Vector2i(40, 16)],
			["the south pier", Vector2i(45, 20)], ["the jetty", Vector2i(20, 30)], ["the market stall", Vector2i(33, 15)]]:
		check(reach.has(s[1]), "%s can be walked to" % s[0])
	for n in ["default", "steps", "rainforest", "station"]:
		var mk := world.get_node_or_null("Spawns/" + n) as Node2D
		check(mk != null and reach.has(world.tile_of(mk.position)), "spawn '%s' stands on reachable ground" % n)
	var wet := 0
	var sealed := 0
	for c: Vector2i in mat:
		if mat[c] == "water" and reach.has(c):
			wet += 1
		if mat[c] in ["wood_deck", "concrete", "metal"] and not world.is_solid(c) and not reach.has(c):
			sealed += 1
	check(wet == 0, "nobody can walk on water")
	check(sealed == 0, "no walkable deck or platform tile is sealed off (%d)" % sealed)

	# collisions
	p.place(Vector2i(18, 20), "down")
	await _hold(&"move_down", 0.4)
	check(p.tile == Vector2i(18, 20), "the deck edge stops at the water")
	p.place(Vector2i(18, 10), "up")
	await _hold(&"move_up", 0.4)
	check(p.tile == Vector2i(18, 10), "the dockside unit blocks")
	check(world.is_solid(Vector2i(28, 8)) and world.is_solid(Vector2i(28, 20)) and world.is_solid(Vector2i(28, 25)), "the tram pylons stand on the deck and in the water")

	# the ways out and the station answer with their names
	for s: Array in [[Vector2i(1, 12), "left", "Way to the Steps"], [Vector2i(50, 8), "right", "Rainforest Approach"],
			[Vector2i(8, 25), "up", "Tram / Subway Station"], [Vector2i(15, 25), "up", "Tram / Subway Station"]]:
		p.place(s[0], s[1])
		await _frames(4)
		check(p.target != null and p.target.label == s[2], "facing %s offers '%s'" % [str(s[0]), s[2]])
	check(p.try_interact() and Dialogue.active, "using the station door opens its (placeholder) text")
	Dialogue.cancel()
	var lamps: Array = world.lighting.get("_lamps2d")
	check(lamps.size() >= 14, "the lamps cast lamplight (%d)" % lamps.size())

	print("%d checks, %d failed" % [_checks, _fails])
	get_tree().quit(1 if _fails > 0 else 0)


func _hold(a: StringName, seconds: float) -> void:
	Input.action_press(a)
	await get_tree().create_timer(seconds).timeout
	Input.action_release(a)
	for i in 60:
		await get_tree().process_frame
		if not p.is_moving():
			break
	await _frames(2)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func check(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_fails += 1
	print("%s  %s" % ["PASS" if ok else "FAIL", what])
