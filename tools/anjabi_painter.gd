class_name AnjabiPainter
extends RefCounted
## Paints a TilesetWorld scene from code with the Anjabi TileSet library: the layers,
## ground fills, edge tiles, multi-cell objects placed by name, signs and spawns.
## Used by the map builders in tools/ to lay out a first version of a map, which is
## then saved as a normal scene and can be edited in Godot.
##
##   var p := AnjabiPainter.new("anjabi_boardwalk", "Boardwalk", Vector2i(52, 34), 1)
##   p.fill("water", Rect2i(0, 0, 52, 34)); p.fill("wood_deck", Rect2i(14, 8, 24, 13))
##   p.edges()
##   p.put("props", "street_lamp", 14, 10)        # by the bottom-left cell of its picture
##   p.sign(Vector2i(0, 12), "Read", "Way to the Steps", "anjabi/boardwalk_west")
##   p.spawn("default", Vector2i(20, 14), "down")
##   p.save("res://world2d/maps/anjabi_boardwalk.tscn")

const T := 32
const DIR := "res://art/tilesets/anjabi/"
## Ground that stands on piles: water beside it gets a pier edge.
const BUILT := ["wood_deck", "concrete", "metal"]

var size: Vector2i
var root: Node2D
var sets := {}
var index := {}
var layers := {}
var taken := {}
var material := {}
var rng := RandomNumberGenerator.new()
var _signs: Node2D
var _spawns: Node2D


func _init(map_id: String, display_name: String, map_size: Vector2i, seed_value: int) -> void:
	size = map_size
	rng.seed = seed_value
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIR + "anjabi_tiles.json"))
	index["ground"] = {}
	var mats: Array = meta["ground"]["materials"]
	for r in mats.size():
		index["ground"][str(mats[r])] = r
	sets["ground"] = load(DIR + "Anjabi_Ground.tres")
	for cat: String in meta["categories"]:
		sets[cat] = load(DIR + "Anjabi_%s.tres" % cat.capitalize())
		index[cat] = {}
		for t: Dictionary in meta["categories"][cat]["tiles"]:
			index[cat][str(t["name"])] = {"at": Vector2i(int(t["atlas"][0]), int(t["atlas"][1])), "size": Vector2i(int(t["size"][0]), int(t["size"][1]))}
	root = Node2D.new()
	root.name = map_id.to_pascal_case()
	root.set_script(load("res://world2d/tileset_world.gd"))
	root.set("map_id", map_id)
	root.set("display_name", display_name)
	root.set("bounds", Rect2(0, 0, size.x * T, size.y * T))
	_layer(root, "ground", -12, false)
	_layer(root, "edges", -11, false, "terrain")
	_layer(root, "piers", -11, false, "terrain")
	_layer(root, "terrain", -10, false)
	var ents := _node("Entities", root)
	ents.y_sort_enabled = true
	for cat: String in ["nature", "architecture", "industrial", "props"]:
		_layer(ents, cat, 0, true)
	_signs = _node("Signs", root)
	_spawns = _node("Spawns", root)


func _node(node_name: String, parent: Node) -> Node2D:
	var n := Node2D.new()
	n.name = node_name
	parent.add_child(n)
	n.owner = root
	return n


func _layer(parent: Node, cat: String, z: int, sorted: bool, tileset := "") -> void:
	var l := TileMapLayer.new()
	l.name = cat.capitalize()
	l.tile_set = sets[tileset if tileset != "" else cat]
	l.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	l.z_index = z
	l.y_sort_enabled = sorted
	parent.add_child(l)
	l.owner = root
	layers[cat] = l
	taken[cat] = {}


## Cover a rectangle of cells with a ground material (random variants).
func fill(mat: String, r: Rect2i) -> void:
	var row: int = index["ground"][mat]
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if x >= 0 and y >= 0 and x < size.x and y < size.y:
				(layers["ground"] as TileMapLayer).set_cell(Vector2i(x, y), 0, Vector2i(rng.randi() % 4, row))
				material[Vector2i(x, y)] = mat


## Call once after the last fill. Grass creeps a few pixels over whatever it borders,
## and water beside a deck or platform shows the timber face and piles under it. (The
## art has neither; tools/anjabi/prepare.py cuts them from the grass and deck tiles.)
func edges() -> void:
	var sides := {"n": Vector2i(0, -1), "e": Vector2i(1, 0), "s": Vector2i(0, 1), "w": Vector2i(-1, 0)}
	for c: Vector2i in material:
		if material[c] == "grass":
			continue
		var name := ""
		for k: String in sides:
			if material.get(c + sides[k], "") == "grass":
				name += k
		if name == "":
			for k: String in ["ne", "nw", "se", "sw"]:
				if material.get(c + sides[k[0]] + sides[k[1]], "") == "grass":
					name = "corner_" + k
					break
		if name != "":
			(layers["edges"] as TileMapLayer).set_cell(c, 0, index["terrain"]["grass_edge_" + name]["at"])
		if material[c] != "water":
			continue
		name = ""
		for k: String in sides:
			if material.get(c + sides[k], "") in BUILT:
				name += k
		if name != "":
			(layers["piers"] as TileMapLayer).set_cell(c, 0, index["terrain"]["pier_edge_" + name]["at"])


## Place a tile by the bottom-left cell of its picture. With force off it refuses to
## overlap another tile of the same layer (for scatter that must not bury set pieces).
func put(cat: String, name: String, x: int, y: int, force := true) -> bool:
	var t: Dictionary = index[cat][name]
	var sz: Vector2i = t["size"]
	var cells: Array[Vector2i] = []
	for j in sz.y:
		for i in sz.x:
			cells.append(Vector2i(x + i, y - j))
	if not force:
		for c in cells:
			if taken[cat].has(c) or c.x < 0 or c.x >= size.x or c.y >= size.y:
				return false
	for c in cells:
		taken[cat][c] = true
	(layers[cat] as TileMapLayer).set_cell(Vector2i(x, y), 0, t["at"])
	return true


## Scatter 2 x 2 undergrowth blocks over a rectangle, skipping cells already taken.
func scatter(names: Array, r: Rect2i) -> void:
	for y in range(r.position.y + 1, r.end.y, 2):
		for x in range(r.position.x, r.end.x - 1, 2):
			put("nature", str(names[rng.randi() % names.size()]), x, y, false)


## Something to read or use on a tile. Saved as a Marker2D carrying the sign's data;
## TilesetWorld turns it into an Interactable with dialogue when the map loads. (The
## Interactable class cannot be made here: tools run before the autoloads exist.)
func sign(tile: Vector2i, prompt: String, label: String, dialogue: String) -> void:
	var m := Marker2D.new()
	m.name = "Sign_%d_%d" % [tile.x, tile.y]
	m.position = Vector2(tile.x * T + T / 2, tile.y * T + T - 9)
	m.set_meta(&"prompt", prompt)
	m.set_meta(&"label", label)
	m.set_meta(&"dialogue", dialogue)
	_signs.add_child(m)
	m.owner = root


func spawn(spawn_name: String, tile: Vector2i, facing: String) -> void:
	var m := Marker2D.new()
	m.name = spawn_name
	m.position = Vector2(tile.x * T + T / 2, tile.y * T + T - 1)
	m.set_meta(&"facing", facing)
	_spawns.add_child(m)
	m.owner = root


func save(path: String) -> void:
	var ps := PackedScene.new()
	assert(ps.pack(root) == OK)
	assert(ResourceSaver.save(ps, path) == OK, "could not save " + path)
	root.free()
