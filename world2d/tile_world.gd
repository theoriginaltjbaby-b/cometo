class_name TileWorld
extends GameMap
## A 2D tile map built from a data file (data/maps2d/<name>.json). The file names
## tiles and objects; PixelArt turns the names into pictures; this class builds the
## layers and answers the gameplay questions (can I step here, what is in that tile,
## where does this door go). Nothing here knows how anything is drawn.
##
## Map file:
##   legend   char -> tile name (shared by all layers; " " = empty)
##   ground, build, detail, over   rows of chars, one char per 16 px tile
##     ground: floor; build: walls, roofs, rails (solid per data/maps2d/tiles.json);
##     detail: windows, doors, vines, awnings (drawn on build, never solid);
##     over: drawn above people (eaves, arches you walk under)
##   objects  props, decor, npcs, walkers, warps, signs, lights (see _object())
##   spawns   name -> [x, y, facing]
##   indoor   true for interiors (fixed lamplight, no weather)
##
## Coordinates: tile (x, y); a person or prop stands on its tile's bottom centre, so
## y-sorting by node position puts whoever is further south in front.

const T := 16
const LAYERS := ["ground", "build", "detail", "over"]

@export_file("*.json") var map_file := ""

var data: Dictionary = {}
var size := Vector2i.ZERO
var indoor := false
var lighting: EnvironmentController2D

var _solid := {}
var _blocked := {}
var _actors := {}
var _signs := {}
var _warps := {}
var _layers := {}
static var _catalogue := {}


func _ready() -> void:
	data = Data.load_dict(map_file)
	if _catalogue.is_empty():
		_catalogue = Data.load_dict("res://data/maps2d/tiles.json")
	indoor = bool(data.get("indoor", false))
	if display_name == "":
		display_name = str(data.get("name", ""))
	var rows: Array = data["ground"]
	size = Vector2i(str(rows[0]).length(), rows.size())
	bounds = Rect2(Vector2.ZERO, Vector2(size * T))
	var bg := ColorRect.new()
	bg.color = PixelArt.VOID
	bg.position = Vector2(-T * 20, -T * 20)
	bg.size = Vector2(size * T) + Vector2(T * 40, T * 40)
	bg.z_index = -30
	add_child(bg)
	_build_layers()
	entities.y_sort_enabled = true
	entities.z_index = 0
	for o: Dictionary in data.get("objects", []):
		_object(o)
	var spawns := Node2D.new()
	spawns.name = "Spawns"
	add_child(spawns)
	for k: String in data.get("spawns", {}):
		var s: Array = data["spawns"][k]
		var m := Marker2D.new()
		m.name = k
		m.position = foot(Vector2i(int(s[0]), int(s[1])))
		m.set_meta(&"facing", str(s[2]) if s.size() > 2 else "down")
		spawns.add_child(m)
	lighting = EnvironmentController2D.new()
	lighting.name = "Lighting"
	lighting.indoor = indoor
	add_child(lighting)
	for o: Dictionary in data.get("objects", []):
		if o.has("light"):
			var l: Dictionary = o["light"]
			var at := _tile(o["at"])
			lighting.add_lamp(foot(at) + Vector2(0, -float(l.get("height", 30))), float(l.get("energy", 1.0)), float(l.get("range", 5.0)) * T)


# --- building ---------------------------------------------------------------------

func _build_layers() -> void:
	var legend: Dictionary = data["legend"]
	# one atlas holding every tile the map uses
	var names: Array[String] = []
	for layer: String in LAYERS:
		for row: String in data.get(layer, []):
			for ch in row:
				if ch != " " and legend.has(ch) and not str(legend[ch]) in names:
					names.append(str(legend[ch]))
	var atlas_img := Image.create(T * names.size(), T * 2, false, Image.FORMAT_RGBA8)
	atlas_img.fill(Color(0, 0, 0, 0))
	var has_glow := false
	for i in names.size():
		atlas_img.blit_rect(PixelArt.tile(names[i]), Rect2i(0, 0, T, T), Vector2i(i * T, 0))
		var g := PixelArt.tile_glow(names[i])
		if g != null:
			atlas_img.blit_rect(g, Rect2i(0, 0, T, T), Vector2i(i * T, T))
			has_glow = true
	var ts := TileSet.new()
	ts.tile_size = Vector2i(T, T)
	var src := TileSetAtlasSource.new()
	src.texture = ImageTexture.create_from_image(atlas_img)
	src.texture_region_size = Vector2i(T, T)
	for i in names.size():
		src.create_tile(Vector2i(i, 0))
		src.create_tile(Vector2i(i, 1))
	ts.add_source(src, 0)
	var z := {"ground": -12, "build": -11, "detail": -10, "over": 20}
	for layer: String in LAYERS:
		var tl := TileMapLayer.new()
		tl.name = layer.capitalize()
		tl.tile_set = ts
		tl.z_index = z[layer]
		add_child(tl)
		_layers[layer] = tl
		var rows: Array = data.get(layer, [])
		for y in rows.size():
			var row: String = rows[y]
			for x in row.length():
				var ch := row[x]
				if ch == " " or not legend.has(ch):
					continue
				var name := str(legend[ch])
				tl.set_cell(Vector2i(x, y), 0, Vector2i(names.find(name), 0))
				if layer != "over" and layer != "detail" and bool((_catalogue.get(name, {}) as Dictionary).get("solid", false)):
					_solid[Vector2i(x, y)] = true
	if has_glow:
		# lit windows again, additively, shining against the night tint
		var glow := TileMapLayer.new()
		glow.name = "Glow"
		glow.tile_set = ts
		glow.z_index = -9
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		glow.material = m
		glow.add_to_group(&"night_glow")
		add_child(glow)
		for layer: String in ["build", "detail"]:
			var rows: Array = data.get(layer, [])
			for y in rows.size():
				var row: String = rows[y]
				for x in row.length():
					var ch := row[x]
					if legend.has(ch) and PixelArt.tile_glow(str(legend[ch])) != null:
						glow.set_cell(Vector2i(x, y), 0, Vector2i(names.find(str(legend[ch])), 1))


## Props stand in Entities (y-sorted); decor lies flat under or over everyone.
func _object(o: Dictionary) -> void:
	var at := _tile(o["at"])
	match str(o.get("type", "prop")):
		"prop":
			var foot_size := _tile(o.get("size", [1, 1]))
			var node := Node2D.new()
			node.name = "Prop_" + str(o["sprite"])
			node.position = Vector2(at.x * T + foot_size.x * T * 0.5, (at.y + foot_size.y) * T)
			var tex := PixelArt.prop(str(o["sprite"]))
			var sp := Sprite2D.new()
			sp.texture = tex
			sp.centered = false
			sp.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height()) + _vec(o.get("offset", [0, 0]))
			node.add_child(sp)
			_add_glow(node, str(o["sprite"]), sp.offset)
			entities.add_child(node)
			if bool(o.get("solid", true)):
				for j in foot_size.y:
					for i in foot_size.x:
						_blocked[at + Vector2i(i, j)] = true
		"decor":
			var tex := PixelArt.prop(str(o["sprite"]))
			var sp := Sprite2D.new()
			sp.name = "Decor_" + str(o["sprite"])
			sp.texture = tex
			sp.centered = false
			sp.position = Vector2(at * T) + _vec(o.get("offset", [0, 0]))
			sp.z_index = 21 if str(o.get("layer", "under")) == "over" else -8
			add_child(sp)
			_add_glow(sp, str(o["sprite"]), Vector2.ZERO)
		"npc":
			var def: Dictionary = (Data.load_dict("res://data/npcs2d.json") as Dictionary).get(str(o["id"]), {})
			var npc := GridNpc.new()
			npc.name = "Npc_" + str(o["id"])
			npc.npc_id = str(o["id"])
			npc.display_name = str(def.get("name", "Someone"))
			npc.dialogue_id = str(def.get("dialogue", ""))
			npc.look = def.get("look", {})
			npc.world = self
			npc.place(at, str(o.get("facing", "down")))
			entities.add_child(npc)
		"walker":
			var w := GridNpc.new()
			w.name = "Walker"
			w.look = o.get("look", {})
			w.world = self
			var a: Array = o["area"]
			w.wander = Rect2i(int(a[0]), int(a[1]), int(a[2]), int(a[3]))
			w.place(at, str(o.get("facing", "down")))
			entities.add_child(w)
		"warp":
			_warps[at] = {"map": str(o["to"]), "spawn": str(o.get("spawn", "default"))}
			if o.has("label"):
				_sign(at, str(o.get("prompt", "Enter")), str(o["label"]), "", str(o["to"]), str(o.get("spawn", "default")))
		"sign":
			_sign(at, str(o.get("prompt", "Look")), str(o.get("label", "")), str(o.get("dialogue", "")), "", "")
		"light":
			pass


func _sign(at: Vector2i, prompt: String, label: String, dialogue: String, to_map: String, to_spawn: String) -> void:
	var it := Interactable.new()
	it.name = "Sign_%d_%d" % [at.x, at.y]
	it.prompt = prompt
	it.label = label
	it.dialogue_id = dialogue
	it.position = foot(at) - Vector2(0, 8)
	if to_map != "":
		it.interacted.connect(func(_by: Node2D) -> void: GameState.travel_requested.emit(to_map, to_spawn))
	add_child(it)
	_signs[at] = it


func _add_glow(parent: Node2D, sprite: String, offset: Vector2) -> void:
	var g := PixelArt.prop_glow(sprite)
	if g == null:
		return
	var gs := Sprite2D.new()
	gs.texture = g
	gs.centered = false
	gs.offset = offset
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	gs.material = m
	gs.add_to_group(&"night_glow")
	parent.add_child(gs)


static func _tile(v: Variant) -> Vector2i:
	var a: Array = v
	return Vector2i(int(a[0]), int(a[1]))


static func _vec(v: Variant) -> Vector2:
	var a: Array = v
	return Vector2(float(a[0]), float(a[1]))


# --- gameplay queries -------------------------------------------------------------

## Where a person standing on `t` is drawn from: the tile's bottom centre.
func foot(t: Vector2i) -> Vector2:
	return Vector2(t.x * T + T * 0.5, t.y * T + T - 1)


func tile_of(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / T), floori((p.y - 1) / T))


func in_bounds(t: Vector2i) -> bool:
	return t.x >= 0 and t.y >= 0 and t.x < size.x and t.y < size.y


## True if nothing stops a step onto `t` (walls, props, people, the map edge).
func can_enter(t: Vector2i, who: Node = null) -> bool:
	if not in_bounds(t) or _solid.has(t) or _blocked.has(t):
		return false
	var a: Node = _actors.get(t, null)
	return a == null or a == who or not is_instance_valid(a)


func is_solid(t: Vector2i) -> bool:
	return _solid.has(t) or _blocked.has(t)


## People claim tiles as they step so two never meet in one.
func claim(t: Vector2i, who: Node) -> void:
	_actors[t] = who


func release(t: Vector2i, who: Node) -> void:
	if _actors.get(t, null) == who:
		_actors.erase(t)


func actor_at(t: Vector2i) -> Node:
	var a: Node = _actors.get(t, null)
	return a if is_instance_valid(a) else null


## Whatever can be used on tile `t`: a person's or a sign's Interactable.
func interactable_at(t: Vector2i) -> Interactable:
	var a := actor_at(t)
	if a is GridNpc and (a as GridNpc).interactable != null:
		return (a as GridNpc).interactable
	return _signs.get(t, null)


func warp_at(t: Vector2i) -> Dictionary:
	return _warps.get(t, {})


func spawn_position(spawn: String) -> Vector2:
	var m := get_node_or_null("Spawns/" + spawn) as Node2D
	if m == null:
		m = get_node_or_null("Spawns/default") as Node2D
	return m.position if m != null else foot(Vector2i(1, 1))


func spawn_facing(spawn: String) -> String:
	var m := get_node_or_null("Spawns/" + spawn) as Node2D
	return str(m.get_meta(&"facing", "down")) if m != null else "down"
