extends Node
## Headless test of the Anjabi TileSet library and its test yard: the six TileSets,
## their textures and collision data, seamless ground, the 32 px TilesetWorld, the
## existing grid player walking it, collisions, lamps, and leaving for a 16 px map.
##   Godot --headless --path . res://tests/anjabi_tileset_test.tscn

const DIR := "res://art/tilesets/anjabi/"
const SETS := ["Ground", "Terrain", "Nature", "Architecture", "Industrial", "Props"]

var _fails := 0
var _checks := 0
var main: Node
var p: GridPlayer
var world: TileWorld


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("user://test_anjabi_tileset")
	SaveManager.dir = "user://test_anjabi_tileset"
	SaveManager.autosave_enabled = false
	SaveManager.boot_from_autosave = false

	# the library
	var total := 0
	var solid_tiles := 0
	for n: String in SETS:
		var ts := load(DIR + "Anjabi_%s.tres" % n) as TileSet
		var ok := ts != null and ts.tile_size == Vector2i(32, 32) and ts.get_source_count() == 1
		var src: TileSetAtlasSource = ts.get_source(0) if ok else null
		ok = ok and src != null and src.texture != null and src.texture_region_size == Vector2i(32, 32) and src.get_tiles_count() > 0
		ok = ok and ts.get_custom_data_layer_by_name("solid_cells") >= 0 and ts.get_physics_layers_count() == 1
		check(ok, "Anjabi_%s loads: 32 px cells, one textured atlas, %d tiles" % [n, src.get_tiles_count() if src else 0])
		if src == null:
			continue
		var img := src.texture.get_image()
		var fits := img.get_width() % 32 == 0 and img.get_height() % 32 == 0
		var names := {}
		for i in src.get_tiles_count():
			var at := src.get_tile_id(i)
			var td := src.get_tile_data(at, 0)
			var cells: Array = td.get_custom_data("solid_cells")
			var sz := src.get_tile_size_in_atlas(at)
			names[str(td.get_custom_data("name"))] = true
			fits = fits and td.get_collision_polygons_count(0) == cells.size()
			for c: Vector2i in cells:
				fits = fits and c.x >= 0 and c.x < sz.x and c.y >= 0 and c.y < sz.y
			if not cells.is_empty():
				solid_tiles += 1
			if n == "Ground":  # only water stops anyone
				fits = fits and cells.is_empty() == (str(td.get_custom_data("name")) != "water")
			total += 1
		check(fits, "Anjabi_%s: texture on the 32 px grid, collision shapes match the solid cells%s" % [n, ", none on ground but water" if n == "Ground" else ""])
		check(not names.has(""), "Anjabi_%s: every tile is named" % n)
	check(total >= 150 and solid_tiles >= 60, "the library holds %d tiles, %d of them solid" % [total, solid_tiles])
	check(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter") == 0, "textures draw with nearest-neighbour filtering")

	# ground: the four materials, four variants each, interchangeable and seamless
	var gts := load(DIR + "Anjabi_Ground.tres") as TileSet
	var g := gts.get_source(0) as TileSetAtlasSource
	var gi := g.texture.get_image()
	check(gi.get_size() == Vector2i(128, 192) and g.get_tiles_count() == 24, "ground atlas: 6 materials x 4 variants")
	var mats := ["concrete", "grass", "red_dirt", "metal", "wood_deck", "water"]
	for r in mats.size():
		check(str(g.get_tile_data(Vector2i(0, r), 0).get_custom_data("name")) == mats[r], "ground row %d is %s" % [r, mats[r]])
		var same := true
		for v in range(1, 4):
			for i in 32:
				for e: Vector2i in [Vector2i(i, 0), Vector2i(i, 31), Vector2i(0, i), Vector2i(31, i)]:
					same = same and gi.get_pixel(e.x, r * 32 + e.y) == gi.get_pixel(v * 32 + e.x, r * 32 + e.y)
		check(same, "%s: all variants share one border, so any can sit next to any" % mats[r])
		# across the wrap the picture changes no more than it does between neighbours inside
		var seam := 0.0
		var inner := 0.0
		for i in 32:
			seam += _diff(gi.get_pixel(31, r * 32 + i), gi.get_pixel(0, r * 32 + i)) + _diff(gi.get_pixel(i, r * 32 + 31), gi.get_pixel(i, r * 32))
			for k in range(8, 24):
				inner += (_diff(gi.get_pixel(k, r * 32 + i), gi.get_pixel(k + 1, r * 32 + i)) + _diff(gi.get_pixel(i, r * 32 + k), gi.get_pixel(i, r * 32 + k + 1))) / 16.0
		check(seam <= inner * 1.5 + 0.05, "%s repeats without a seam (edge step %.2f vs %.2f inside)" % [mats[r], seam / 64.0, inner / 64.0])

	# the test yard, in the game
	main = (load("res://game/main.tscn") as PackedScene).instantiate()
	main.set("start_map", "anjabi_tileset_test")
	add_child(main)
	await _frames(6)
	WorldTime.minutes_per_second = 0.0
	world = main.get("map")
	p = main.get("player")
	check(world is TilesetWorld and p is GridPlayer and str(main.get("map_id")) == "anjabi_tileset_test", "the test yard loads with the existing grid player")
	check(world.size == Vector2i(44, 30) and world.bounds.size == Vector2(1408, 960), "the yard is 44 x 30 tiles of 32 px")
	var vp := world.get_viewport() as SubViewport
	var box := vp.get_parent() as SubViewportContainer
	check(vp.size.x == 480 and box.stretch_shrink == 1, "32 px maps render the full 480 px (15 tiles) wide (%s)" % str(vp.size))
	check(p.tile == Vector2i(22, 17) and p.sprite.scale == Vector2(2, 2), "the player spawns on the plaza, drawn one tile wide")
	for l: String in ["Ground", "Edges", "Terrain", "Entities/Nature", "Entities/Architecture", "Entities/Industrial", "Entities/Props"]:
		var layer := world.get_node_or_null(l) as TileMapLayer
		check(layer != null and not layer.get_used_cells().is_empty() and layer.y_sort_enabled == l.begins_with("Entities"), "layer %s is painted%s" % [l, " and depth-sorted with people" if l.begins_with("Entities") else ""])
	var seen := {}
	var gl := world.get_node("Ground") as TileMapLayer
	for c in gl.get_used_cells():
		seen[str(gl.get_cell_tile_data(c).get_custom_data("name"))] = true
	check(seen.size() == 4 and gl.get_used_cells().size() == 44 * 30, "the four basic ground materials are used and the ground has no holes")

	# every ground material is walkable
	for s: Array in [["concrete", Vector2i(22, 17)], ["grass", Vector2i(6, 15)], ["red_dirt", Vector2i(33, 13)], ["metal", Vector2i(20, 9)]]:
		var c: Vector2i = s[1]
		check(str(gl.get_cell_tile_data(c).get_custom_data("name")) == s[0] and world.can_enter(c, p), "%s is walkable" % s[0])

	# movement on the 32 px grid
	var mid := false
	Input.action_press(&"move_right")
	var t_end := Time.get_ticks_msec() + 600
	while Time.get_ticks_msec() < t_end:
		await get_tree().process_frame
		if p.is_moving() and fposmod(p.position.x - 16.0, 32.0) > 4.0 and fposmod(p.position.x - 16.0, 32.0) < 28.0:
			mid = true
	Input.action_release(&"move_right")
	await _settle()
	check(mid and p.tile.y == 17 and p.tile.x >= 23, "holding a direction glides tile to tile (now at %s)" % str(p.tile))
	check(fposmod(p.position.x - 16.0, 32.0) < 0.01 and int(p.position.y) % 32 == 31, "the player stops exactly on a 32 px tile")

	# collisions: buildings, props, undergrowth, the track, the map edge
	p.place(Vector2i(18, 15), "up")
	await _hold(&"move_up", 0.5)
	check(p.tile == Vector2i(18, 15), "the prefab building blocks")
	check(world.is_solid(Vector2i(15, 20)) and world.can_enter(Vector2i(15, 19), p), "crates block their own row; the row behind them is free")
	p.place(Vector2i(15, 19), "down")
	await _hold(&"move_down", 0.4)
	check(p.tile == Vector2i(15, 19), "walking into the crates from behind bumps")
	check(world.is_solid(Vector2i(20, 5)) and world.is_solid(Vector2i(10, 6)), "the train and the track are solid")
	check(world.is_solid(Vector2i(0, 1)) and world.is_solid(Vector2i(4, 13)), "undergrowth and the cliff are solid")
	check(not world.is_solid(Vector2i(33, 20)) and not world.is_solid(Vector2i(20, 10)), "puddles and steps lie flat and can be walked on")
	p.place(Vector2i(0, 24), "left")
	await _hold(&"move_left", 0.4)
	check(p.tile == Vector2i(0, 24), "the map edge blocks")
	var lamps: Array = world.lighting.get("_lamps2d")
	check(lamps.size() >= 8, "lamp tiles cast lamplight (%d lamps)" % lamps.size())

	# going to a 16 px map puts the view back
	main.call("load_map", "anjabi_steps", "default")
	await _frames(6)
	var vp2 := (main.get("map") as Node).get_viewport() as SubViewport
	check(vp2.size.x == 240 and (vp2.get_parent() as SubViewportContainer).stretch_shrink == 2, "the Steps still render 240 px wide afterwards")
	p = main.get("player")
	check(p.sprite.scale == Vector2.ONE, "and its people are drawn at their own size")

	print("%d checks, %d failed" % [_checks, _fails])
	get_tree().quit(1 if _fails > 0 else 0)


func _diff(a: Color, b: Color) -> float:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)


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


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func check(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_fails += 1
	print("%s  %s" % ["PASS" if ok else "FAIL", what])
