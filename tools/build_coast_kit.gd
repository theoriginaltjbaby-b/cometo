extends SceneTree
## Builds the coast kit's TileSets and its maps (the look test and the modular village)
## from the art prepared by tools/coast/build_kit.py.
##   python3 tools/coast/build_kit.py . && python3 tools/coast/make_chibi.py .
##   Godot --headless --path . --import
##   Godot --headless --path . -s tools/build_coast_kit.gd
## Writes art/tilesets/coast/Coast_<Category>.tres and world2d/maps/<map id>.tscn for
## each map in coast_maps.json (TilesetWorld scenes at 16 px cells; see
## world2d/tileset_world.gd). Running it again overwrites them.
##
## Same conventions as the Anjabi TileSets: one atlas source (id 0), physics layer 0,
## custom data name, solid_cells, flat, lamp, flag; a multi-cell tile is placed by the
## bottom-left cell of its picture. Each tile also carries its own y-sort origin (where
## its foot is) and flat tiles a z index, so the sea lies under the pier.

const DIR := "res://art/tilesets/coast/"
const SCENES := "res://world2d/maps/%s.tscn"
## Layers under people (flat) and among them (depth-sorted), in drawing order.
const FLAT := {"edges": -11, "terrain": -10}
const SORTED := ["nature", "buildings", "details", "props"]

var T := 16
var sets := {}
var index := {}


func _initialize() -> void:
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIR + "coast_tiles.json"))
	var maps: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIR + "coast_maps.json"))
	T = int(meta["tile_size"])
	_ground_set(meta["ground"])
	for cat: String in meta["categories"]:
		_object_set(cat, meta["categories"][cat])
	for id: String in maps:
		_scene(id, maps[id])
	print("built %d tilesets and %d maps: %s" % [sets.size(), maps.size(), ", ".join(maps.keys())])
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
	var path := DIR + "Coast_%s.tres" % cat.capitalize()
	assert(ResourceSaver.save(ts, path) == OK, "could not save " + path)
	ts.take_over_path(path)
	sets[cat] = ts


func _square(o: Vector2) -> PackedVector2Array:
	var h := T / 2.0
	return PackedVector2Array([o + Vector2(-h, -h), o + Vector2(h, -h), o + Vector2(h, h), o + Vector2(-h, h)])


func _ground_set(g: Dictionary) -> void:
	var ts := _new_set()
	var src := TileSetAtlasSource.new()
	src.texture = load(DIR + str(g["texture"]))
	src.texture_region_size = Vector2i(T, T)
	ts.add_source(src, 0)
	index["ground"] = {}
	var mats: Array = g["materials"]
	for r in mats.size():
		index["ground"][str(mats[r])] = r
		for v in int(g["variants"]):
			src.create_tile(Vector2i(v, r))
			var td := src.get_tile_data(Vector2i(v, r), 0)
			td.set_custom_data("name", str(mats[r]))
			td.set_custom_data("flat", true)
			if mats[r] in g["solid"]:
				td.set_custom_data("solid_cells", [Vector2i.ZERO])
				td.add_collision_polygon(0)
				td.set_collision_polygon_points(0, 0, _square(Vector2.ZERO))
	_save("ground", ts)


func _object_set(cat: String, c: Dictionary) -> void:
	var ts := _new_set()
	var src := TileSetAtlasSource.new()
	src.texture = load(DIR + str(c["texture"]))
	src.texture_region_size = Vector2i(T, T)
	ts.add_source(src, 0)
	index[cat] = {}
	for t: Dictionary in c["tiles"]:
		var at := Vector2i(int(t["atlas"][0]), int(t["atlas"][1]))
		var sz := Vector2i(int(t["size"][0]), int(t["size"][1]))
		src.create_tile(at, sz)
		var td := src.get_tile_data(at, 0)
		td.texture_origin = Vector2i(T / 2 - sz.x * T / 2, sz.y * T / 2 - T / 2)
		var cells: Array = []
		for s: Array in t["solid"]:
			cells.append(Vector2i(int(s[0]), int(s[1])))
		td.y_sort_origin = int(t["sort"])
		td.z_index = int(t.get("z", 0))
		td.set_custom_data("name", str(t["name"]))
		td.set_custom_data("solid_cells", cells)
		td.set_custom_data("flat", bool(t["flat"]))
		td.set_custom_data("lamp", int(t["lamp"]))
		for i in cells.size():
			td.add_collision_polygon(0)
			td.set_collision_polygon_points(0, i, _square(Vector2(cells[i].x * T, -cells[i].y * T)))
		index[cat][str(t["name"])] = at
	_save(cat, ts)


func _layer(parent: Node, root: Node, cat: String, z: int, sorted: bool) -> TileMapLayer:
	var l := TileMapLayer.new()
	l.name = cat.capitalize()
	l.tile_set = sets[cat]
	l.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	l.z_index = z
	l.y_sort_enabled = sorted
	parent.add_child(l)
	l.owner = root
	return l


func _scene(id: String, map: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var size := Vector2i(int(map["size"][0]), int(map["size"][1]))
	var root := Node2D.new()
	root.name = id.to_pascal_case()
	root.set_script(load("res://world2d/tileset_world.gd"))
	root.set("map_id", id)
	root.set("display_name", str(map["name"]))
	root.set("bounds", Rect2(0, 0, size.x * T, size.y * T))
	root.set("player_sheet", "chibi_raincoat")
	var layers := {"ground": _layer(root, root, "ground", -12, false)}
	for cat: String in FLAT:
		layers[cat] = _layer(root, root, cat, FLAT[cat], false)
	var ents := Node2D.new()
	ents.name = "Entities"
	ents.y_sort_enabled = true
	root.add_child(ents)
	ents.owner = root
	for cat: String in SORTED:
		layers[cat] = _layer(ents, root, cat, 0, true)
	var rows: Array = map["ground"]
	for y in size.y:
		for x in size.x:
			var mat := str(map["legend"][str(rows[y])[x]])
			(layers["ground"] as TileMapLayer).set_cell(Vector2i(x, y), 0, Vector2i(rng.randi() % 4, index["ground"][mat]))
	for o: Array in map["objects"]:
		(layers[str(o[0])] as TileMapLayer).set_cell(Vector2i(int(o[2]), int(o[3])), 0, index[str(o[0])][str(o[1])])
	# lit windows, lamps and signs again, added over the night tint
	var glow := Sprite2D.new()
	glow.name = "Glow"
	glow.texture = load(DIR + id + "_glow.png")
	glow.centered = false
	glow.z_index = 4
	var gm := CanvasItemMaterial.new()
	gm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	gm.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	glow.material = gm
	glow.add_to_group(&"night_glow", true)
	root.add_child(glow)
	glow.owner = root
	var spawns := Node2D.new()
	spawns.name = "Spawns"
	root.add_child(spawns)
	spawns.owner = root
	for s: Array in map["spawns"]:
		var m := Marker2D.new()
		m.name = str(s[0])
		m.position = Vector2(int(s[1]) * T + T / 2, int(s[2]) * T + T - 1)
		m.set_meta(&"facing", str(s[3]))
		spawns.add_child(m)
		m.owner = root
	# ways to other maps: stepping onto the tile travels (TilesetWorld reads the meta)
	var signs := Node2D.new()
	signs.name = "Signs"
	root.add_child(signs)
	signs.owner = root
	for wp: Array in map.get("warps", []):
		var d := Marker2D.new()
		d.name = "Warp_%d_%d" % [int(wp[0]), int(wp[1])]
		d.position = Vector2(int(wp[0]) * T + T / 2, int(wp[1]) * T + T - 1)
		d.set_meta(&"to", str(wp[2]))
		d.set_meta(&"spawn", str(wp[3]))
		signs.add_child(d)
		d.owner = root
	var ps := PackedScene.new()
	assert(ps.pack(root) == OK)
	assert(ResourceSaver.save(ps, SCENES % id) == OK, "could not save " + SCENES % id)
	root.free()
