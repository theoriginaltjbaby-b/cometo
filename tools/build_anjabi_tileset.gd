extends SceneTree
## Builds the Anjabi TileSet library and the tileset test scene from the prepared art.
##   python3 tools/anjabi/prepare.py . && Godot --headless --path . --import
##   Godot --headless --path . -s tools/build_anjabi_tileset.gd
## Writes art/tilesets/anjabi/Anjabi_<Category>.tres (six TileSets) and
## world2d/maps/Anjabi_Tileset_Test.tscn. Both can then be opened and edited in Godot;
## running this again overwrites them. Real maps have their own builders (for example
## tools/build_anjabi_boardwalk.gd), which use the TileSets saved here.
##
## Every TileSet: 32 px cells, one atlas source (id 0), physics layer 0, and custom
## data name (String), solid_cells (Array of Vector2i: x right, y up from the tile's
## cell), flat (bool: lies on the floor), lamp (int px), flag (String: cleanup note).
## A multi-cell tile is placed by its bottom-left cell.

const T := 32
const DIR := "res://art/tilesets/anjabi/"
const SCENE := "res://world2d/maps/Anjabi_Tileset_Test.tscn"

var sets := {}


func _initialize() -> void:
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIR + "anjabi_tiles.json"))
	_ground_set(meta["ground"])
	for cat: String in meta["categories"]:
		_object_set(cat, meta["categories"][cat])
	_scene()
	var flags := 0
	for m: String in meta["ground"].get("flags", {}):
		flags += 1
		print("FLAG ground/%s: %s" % [m, meta["ground"]["flags"][m]])
	for cat: String in meta["categories"]:
		for t: Dictionary in meta["categories"][cat]["tiles"]:
			if str(t["flag"]) != "":
				flags += 1
				print("FLAG %s/%s: %s" % [cat, t["name"], t["flag"]])
	print("built %d tilesets, %d tiles flagged for cleanup, scene %s" % [sets.size(), flags, SCENE])
	quit()


func _new_set() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(T, T)
	ts.add_physics_layer()
	var defs := [["name", TYPE_STRING], ["solid_cells", TYPE_ARRAY], ["flat", TYPE_BOOL], ["lamp", TYPE_INT], ["flag", TYPE_STRING]]
	for i in defs.size():
		ts.add_custom_data_layer()
		ts.set_custom_data_layer_name(i, defs[i][0])
		ts.set_custom_data_layer_type(i, defs[i][1])
	return ts


func _save(cat: String, ts: TileSet) -> void:
	var path := DIR + "Anjabi_%s.tres" % cat.capitalize()
	var err := ResourceSaver.save(ts, path)
	assert(err == OK, "could not save " + path)
	ts.take_over_path(path)
	sets[cat] = ts


func _ground_set(g: Dictionary) -> void:
	var ts := _new_set()
	var src := TileSetAtlasSource.new()
	src.texture = load(DIR + str(g["texture"]))
	src.texture_region_size = Vector2i(T, T)
	ts.add_source(src, 0)
	var mats: Array = g["materials"]
	var solid: Array = g.get("solid", [])
	var flags: Dictionary = g.get("flags", {})
	for r in mats.size():
		for v in int(g["variants"]):
			src.create_tile(Vector2i(v, r))
			var td := src.get_tile_data(Vector2i(v, r), 0)
			td.set_custom_data("name", str(mats[r]))
			td.set_custom_data("flat", true)
			td.set_custom_data("flag", str(flags.get(mats[r], "")))
			if mats[r] in solid:  # water: nobody walks on it
				td.set_custom_data("solid_cells", [Vector2i.ZERO])
				td.add_collision_polygon(0)
				td.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-16, -16), Vector2(16, -16), Vector2(16, 16), Vector2(-16, 16)]))
	_save("ground", ts)


func _object_set(cat: String, c: Dictionary) -> void:
	var ts := _new_set()
	ts.set_physics_layer_collision_layer(0, 1)
	var src := TileSetAtlasSource.new()
	src.texture = load(DIR + str(c["texture"]))
	src.texture_region_size = Vector2i(T, T)
	ts.add_source(src, 0)
	for t: Dictionary in c["tiles"]:
		var at := Vector2i(int(t["atlas"][0]), int(t["atlas"][1]))
		var sz := Vector2i(int(t["size"][0]), int(t["size"][1]))
		src.create_tile(at, sz)
		var td := src.get_tile_data(at, 0)
		# the tile's own cell is the bottom-left cell of its picture
		td.texture_origin = Vector2i(T / 2 - sz.x * T / 2, sz.y * T / 2 - T / 2)
		var flat := bool(t["flat"])
		var cells: Array = []
		for s: Array in t["solid"]:
			cells.append(Vector2i(int(s[0]), int(s[1])))
		# flat things sort behind anyone standing on them; hanging things in front
		td.y_sort_origin = -sz.y * T if flat else (16 if cells.is_empty() else 12)
		td.set_custom_data("name", str(t["name"]))
		td.set_custom_data("solid_cells", cells)
		td.set_custom_data("flat", flat)
		td.set_custom_data("lamp", int(t["lamp"]))
		td.set_custom_data("flag", str(t["flag"]))
		for i in cells.size():
			var o := Vector2(cells[i].x * T, -cells[i].y * T)
			td.add_collision_polygon(0)
			td.set_collision_polygon_points(0, i, PackedVector2Array([o + Vector2(-16, -16), o + Vector2(16, -16), o + Vector2(16, 16), o + Vector2(-16, 16)]))
	_save(cat, ts)


# --- the test scene ---------------------------------------------------------------

func _scene() -> void:
	var p := AnjabiPainter.new("anjabi_tileset_test", "Anjabi tileset test", Vector2i(44, 30), 20261116)
	p.root.name = "AnjabiTilesetTest"

	# ground: jungle floor everywhere, then the four materials
	p.fill("grass", Rect2i(0, 0, 44, 30))
	p.fill("concrete", Rect2i(2, 7, 9, 5))        # station apron
	p.fill("metal", Rect2i(11, 7, 24, 4))          # railway platform
	p.fill("concrete", Rect2i(13, 11, 19, 11))     # plaza
	p.fill("red_dirt", Rect2i(32, 11, 3, 15))      # road south from the platform
	p.fill("red_dirt", Rect2i(0, 23, 44, 3))       # road along the south
	p.fill("red_dirt", Rect2i(35, 15, 7, 3))       # spur to the mine
	p.edges()

	# railway: track along the north, a train standing at the platform
	for i in 8:
		p.put("industrial", "guideway_long", 2 + i * 5, 6)
	for o: Array in [
		["industrial", "train", 18, 5], ["architecture", "station_building", 2, 10], ["architecture", "ticket_booth", 12, 8],
		["props", "route_board", 25, 7], ["props", "bench_seats", 31, 7], ["props", "vending_machine", 16, 8],
		["props", "lamp_teal", 11, 10], ["props", "lamp_teal", 23, 10], ["props", "lamp_teal", 34, 10],
		["industrial", "turnstiles", 27, 10], ["terrain", "concrete_steps", 20, 11],
		# plaza: a prefab building of four modules, lamps, cargo
		["architecture", "wall_window_wide", 14, 14], ["architecture", "wall_door", 17, 14], ["architecture", "wall_plain", 19, 14],
		["architecture", "wall_pipes", 21, 14], ["industrial", "ac_unit", 23, 14], ["props", "terminal_kiosk", 27, 14],
		["props", "sign_gantry", 28, 20], ["props", "street_lamp", 13, 16], ["props", "street_lamp", 25, 16],
		["props", "bollard_lamp", 13, 21], ["props", "bollard_lamp", 31, 21], ["props", "bollard_lamp", 31, 12],
		["props", "crate_stack", 14, 20], ["props", "cargo_cases", 18, 21], ["props", "jerrycan_crate", 24, 14],
		["props", "luggage_cart", 22, 21],
		# mine corner: the entrance and the machinery beside the spur
		["industrial", "mine_entrance", 37, 14], ["props", "flood_lamp", 34, 14], ["industrial", "utility_pole", 41, 18],
		["industrial", "fence_panel", 36, 19], ["industrial", "fence_panel", 38, 19], ["industrial", "pipes_valve", 36, 21],
		["industrial", "tanks", 39, 21], ["industrial", "duct_elbow", 36, 13], ["terrain", "mud_tracks", 36, 17],
		["terrain", "puddle_small", 39, 17],
		# the road: worn patches, standing water
		["terrain", "puddle_large", 33, 20], ["terrain", "dirt_cracked", 20, 25], ["terrain", "mud_tracks", 9, 25],
		["terrain", "puddle_small", 26, 25], ["terrain", "dirt_rocks_a", 4, 25], ["terrain", "dirt_rocks_b", 15, 24],
		["terrain", "dirt_wet", 38, 25],
		# grass clearing west of the plaza: a low cliff behind it, a paved path in
		["terrain", "cliff_face", 2, 13], ["terrain", "cliff_face", 4, 13], ["terrain", "cliff_face", 6, 13], ["terrain", "cliff_face", 8, 13],
		["terrain", "paving_c", 11, 18], ["terrain", "paving_b", 9, 18], ["terrain", "paving_a", 7, 19],
		["terrain", "leaf_litter", 3, 17], ["terrain", "roots", 8, 22], ["nature", "tree_vines_a", 1, 17],
		["nature", "tree_canopy", 7, 22], ["nature", "glowplant_teal", 5, 16], ["nature", "mushrooms_blue", 2, 21],
		["nature", "lily_bush", 10, 15], ["nature", "heliconia", 4, 22],
	]:
		p.put(o[0], o[1], o[2], o[3])

	# jungle border: undergrowth blocks and trees wherever nothing else stands
	var bushes := ["broadleaf", "fern", "heliconia", "lily_bush", "ginger_red", "undergrowth_glow", "mushroom_grotto", "fern", "broadleaf"]
	var trees := ["tree_vines_a", "tree_canopy", "tree_vines_b"]
	for s: Rect2i in [Rect2i(0, 0, 44, 4), Rect2i(0, 26, 44, 4), Rect2i(0, 6, 2, 17), Rect2i(42, 6, 2, 17)]:
		p.scatter(bushes, s)
	for at: Vector2i in [Vector2i(3, 3), Vector2i(12, 2), Vector2i(21, 3), Vector2i(30, 2), Vector2i(38, 3), Vector2i(6, 29), Vector2i(17, 28), Vector2i(27, 29), Vector2i(36, 28)]:
		(p.layers["nature"] as TileMapLayer).set_cell(at, 0, p.index["nature"][trees[p.rng.randi() % trees.size()]]["at"])
	p.spawn("default", Vector2i(22, 17), "down")
	p.save(SCENE)
