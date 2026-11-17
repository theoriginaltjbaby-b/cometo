extends Node
## Headless test of the coast look test (coast_look_test): the 16 px kit, the chibi
## player at about a tenth of the screen height, HeartGold-style stepping, what can
## and cannot be walked on.
##   Godot --headless --path . res://tests/coast_look_test.tscn

var _fails := 0
var _checks := 0
var main: Node
var p: GridPlayer
var world: TileWorld


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("user://test_coast")
	SaveManager.dir = "user://test_coast"
	SaveManager.autosave_enabled = false
	SaveManager.boot_from_autosave = false
	for n: String in ["Ground", "Edges", "Terrain", "Nature", "Buildings", "Details", "Props"]:
		var ts := load("res://art/tilesets/coast/Coast_%s.tres" % n) as TileSet
		check(ts != null and ts.tile_size == Vector2i(16, 16) and (ts.get_source(0) as TileSetAtlasSource).get_tiles_count() > 0, "Coast_%s loads with 16 px cells" % n)
	main = (load("res://game/main.tscn") as PackedScene).instantiate()
	main.set("start_map", "coast_look_test")
	add_child(main)
	await _frames(6)
	WorldTime.minutes_per_second = 0.0
	world = main.get("map")
	p = main.get("player")
	check(world is TilesetWorld and p is GridPlayer and world.size == Vector2i(33, 18), "the look test loads: 33 x 18 tiles")
	var vp := world.get_viewport() as SubViewport
	check((world as TilesetWorld).cell == 16 and vp.size.x == 480, "16 px cells in the full 480 px wide view (30 tiles across)")

	# the chibi player: its own sheet, at its own size, about a tenth of the screen
	var img := p.sprite.texture.get_image()
	var top := 32
	for y in 32:
		for x in 16:
			if img.get_pixel(x, y).a > 0.5:
				top = mini(top, y)
	var tall := 32 - top
	check(p.sheet_id == "chibi_raincoat" and img.get_size() == Vector2i(144, 128) and p.sprite.scale == Vector2.ONE, "the player wears the chibi sheet at its own size")
	check(tall >= 22 and tall <= 28, "the player is %d px tall: %.1f%% of the screen height" % [tall, tall * 100.0 / 270.0])
	check(p.tile == Vector2i(16, 9), "the player starts on the road")

	# stepping: a tap turns, holding glides one 16 px tile at a time, running is faster
	var before := p.tile
	Input.action_press(&"move_right")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release(&"move_right")
	await _settle()
	check(p.dir_name() == "right" and (p.tile - before).length() <= 1, "a tap turns (or takes one step at most)")
	p.place(Vector2i(4, 9), "right")
	await _frames(2)
	await _hold(&"move_right", 1.0)
	var walked := p.tile.x - 4
	check(walked >= 3 and walked <= 5 and int(p.position.x) % 16 == 8, "walking covers about 4 tiles a second and stops on the grid (%d)" % walked)
	p.place(Vector2i(4, 9), "right")
	await _frames(2)
	Input.action_press(&"sprint")
	await _hold(&"move_right", 1.0)
	Input.action_release(&"sprint")
	check(p.tile.x - 4 > walked + 1, "running is faster (%d tiles)" % (p.tile.x - 4))

	# where you can go
	var reach := {Vector2i(16, 9): true}
	var todo: Array[Vector2i] = [Vector2i(16, 9)]
	while not todo.is_empty():
		var c: Vector2i = todo.pop_back()
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if not reach.has(c + d) and world.can_enter(c + d, p):
				reach[c + d] = true
				todo.append(c + d)
	for s: Array in [["the west end of the road", Vector2i(0, 9)], ["the lane north", Vector2i(9, 0)], ["the end of the pier", Vector2i(30, 9)],
			["the red house's doorstep", Vector2i(4, 7)], ["the slate house's doorstep", Vector2i(13, 7)], ["the shop front", Vector2i(20, 7)]]:
		check(reach.has(s[1]), "%s can be walked to" % s[0])
	var gl := world.get_node("Ground") as TileMapLayer
	var bad := 0
	for c: Vector2i in reach:
		if str(gl.get_cell_tile_data(c).get_custom_data("name")) in ["water", "forest_floor"]:
			bad += 1
	check(bad == 0, "nobody walks on the sea or through the forest")
	check(world.is_solid(Vector2i(5, 5)) and world.is_solid(Vector2i(19, 4)) and world.is_solid(Vector2i(2, 8)), "houses, the shop and the lamp post block")
	check(not reach.has(Vector2i(22, 14)) and not reach.has(Vector2i(31, 3)), "the beach below the wall and the open sea are out of reach")
	p.place(Vector2i(4, 8), "up")
	await _hold(&"move_up", 0.5)
	check(p.tile == Vector2i(4, 7), "the doorstep is as far as the house lets you go")
	check(get_tree().get_nodes_in_group(&"night_glow").size() >= 1 and (world.lighting.get("_lamps2d") as Array).size() >= 2, "windows glow and lamps cast light at night")

	# the modular pieces, and the village built only from them
	var names := {}
	for n: String in ["Buildings", "Details", "Nature", "Edges", "Props"]:
		var src := (load("res://art/tilesets/coast/Coast_%s.tres" % n) as TileSet).get_source(0) as TileSetAtlasSource
		for i in src.get_tiles_count():
			names[str(src.get_tile_data(src.get_tile_id(i), 0).get_custom_data("name"))] = true
	var want := ["wall_plain", "wall_end_l", "wall_end_r", "porch_red", "porch_slate", "window_small", "window_wide", "planter_small",
		"planter_flowers", "pine", "pine_tall", "pine_small", "picket_fence", "kerb_n", "kerb_nesw", "surf_w", "surf_corner_ne"]
	for roof: String in ["red", "slate"]:
		for k: String in ["tl", "t", "tr", "l", "c0", "c1", "c2", "c3", "r", "bl", "b", "br"]:
			want.append("roof_%s_%s" % [roof, k])
	var missing: Array = want.filter(func(n: String) -> bool: return not names.has(n))
	check(missing.is_empty(), "the kit has its modular pieces: roofs, walls, porches, windows, pines, fence, kerbs, surf %s" % str(missing))
	main.call("load_map", "coast_village", "default")
	await _frames(6)
	world = main.get("map")
	p = main.get("player")
	check(world is TilesetWorld and world.size == Vector2i(48, 30) and p.sheet_id == "chibi_raincoat", "the village loads: 48 x 30 tiles, larger than the screen")
	var cam := p.camera
	p.place(Vector2i(2, 15), "right")
	await _frames(4)
	var left_x := cam.get_screen_center_position().x
	p.place(Vector2i(44, 15), "left")
	await _frames(4)
	check(cam.get_screen_center_position().x - left_x > 200.0, "the camera follows the player across the village")
	reach = {Vector2i(22, 15): true}
	todo = [Vector2i(22, 15)]
	while not todo.is_empty():
		var c: Vector2i = todo.pop_back()
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if not reach.has(c + d) and world.can_enter(c + d, p):
				reach[c + d] = true
				todo.append(c + d)
	for s: Array in [["the lane north", Vector2i(22, 0)], ["the pier", Vector2i(44, 15)], ["the back street", Vector2i(30, 25)], ["the lane south", Vector2i(10, 29)]]:
		check(reach.has(s[1]), "village: %s can be walked to" % s[0])
	gl = world.get_node("Ground") as TileMapLayer
	bad = 0
	for c: Vector2i in reach:
		if str(gl.get_cell_tile_data(c).get_custom_data("name")) in ["water", "forest_floor"]:
			bad += 1
	check(bad == 0, "village: nobody walks on the sea or through the forest")
	check(world.is_solid(Vector2i(4, 9)) and world.is_solid(Vector2i(4, 13)) and world.is_solid(Vector2i(14, 12)), "village: roofs and walls of the modular houses block")
	p.place(Vector2i(4, 14), "up")
	await _hold(&"move_up", 0.4)
	check(p.tile == Vector2i(4, 14), "village: a house front stops the player at the street")

	# the lane north leads to the look test, and its lane north leads back
	p.place(Vector2i(22, 1), "up")
	await _hold(&"move_up", 0.4)
	await _frames(8)
	p = main.get("player")
	check(str(main.get("map_id")) == "coast_look_test" and p.tile == Vector2i(9, 1), "the village's lane north leads to the look test")
	p.place(Vector2i(9, 1), "up")
	await _frames(2)
	await _hold(&"move_up", 0.4)
	await _frames(8)
	p = main.get("player")
	check(str(main.get("map_id")) == "coast_village" and p.tile == Vector2i(22, 1), "and the look test's lane north leads back")

	print("%d checks, %d failed" % [_checks, _fails])
	get_tree().quit(1 if _fails > 0 else 0)


func _hold(a: StringName, seconds: float) -> void:
	Input.action_press(a)
	await get_tree().create_timer(seconds).timeout
	Input.action_release(a)
	await _settle()


func _settle() -> void:
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
