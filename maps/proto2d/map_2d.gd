class_name Map2D
extends GameMap
## A 2D map in the Golden Sun-style 3/4 view, built at runtime from a bake made by
## tools/bake_2d.gd (a pre-rendered ground, y-sorted object sprites, a height grid).
##
## Two coordinate spaces, both in pixels (S per metre):
##   ground (x, z): where things stand. Node positions use it, so y-sort is by z.
##   screen (x, z - h): where they are drawn. Visuals are offset up by their height h.
## Walking is limited by the height grid: no cell without ground, no step taller than
## MAX_STEP between neighbours, nothing below the sea. That gives cliffs, terraces,
## stairs and walls the way the 3D colliders defined them.

const MAX_STEP := 0.35

@export_dir var bake_dir := ""

var S := 16
var layout: Dictionary = {}
var lighting: EnvironmentController2D
var _heights: Image
var _grid := 4
var _x0 := 0.0
var _z0 := 0.0
var _sea := -1000.0


func _ready() -> void:
	layout = Data.load_dict(bake_dir.path_join("layout.json"))
	S = int(layout["S"])
	_grid = int(layout["grid"])
	_x0 = float(layout["x0"])
	_z0 = float(layout["z0"])
	_sea = float(layout["sea"])
	_heights = load(bake_dir.path_join("heights.res")) as Image
	var v0 := float(layout["v0"])
	var origin := Vector2(_x0 * S, v0 * S)
	bounds = Rect2(origin, Vector2(float(layout["width"]), float(layout["height"])))
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.06, 0.09)
	bg.position = origin - Vector2(400, 400)
	bg.size = bounds.size + Vector2(800, 800)
	bg.z_index = -20
	add_child(bg)
	var ground := Sprite2D.new()
	ground.texture = load(bake_dir.path_join("ground.png"))
	ground.centered = false
	ground.position = origin
	ground.z_index = -10
	add_child(ground)
	var gglow := bake_dir.path_join("ground_glow.png")
	if ResourceLoader.exists(gglow):
		add_child(_glow_sprite(load(gglow), origin, -9))
	entities.y_sort_enabled = true
	for o: Dictionary in layout["objects"]:
		var r: Array = o["rect"]
		var screen := origin + Vector2(float(r[0]), float(r[1]))
		var node := Node2D.new()
		node.name = "Obj_" + str(o["model"])
		# sort by where the object stands; the sprite hangs from there to its screen spot
		var base := Vector2(screen.x + float(r[2]) * 0.5, float(o["sort_z"]) * S)
		node.position = base
		var sp := Sprite2D.new()
		sp.texture = load(bake_dir.path_join("objects/%s.png" % o["file"]))
		sp.centered = false
		sp.position = screen - base
		node.add_child(sp)
		if o.get("glow", false):
			node.add_child(_glow_sprite(load(bake_dir.path_join("objects/%s_glow.png" % o["file"])), screen - base, 1))
		entities.add_child(node)
	var spawns := Node2D.new()
	spawns.name = "Spawns"
	add_child(spawns)
	for k: String in layout["spawns"]:
		var p: Array = layout["spawns"][k]
		var m := Marker2D.new()
		m.name = k
		m.position = Vector2(float(p[0]), float(p[2])) * S
		spawns.add_child(m)
	for e: Dictionary in layout["interactables"]:
		var it := Interactable.new()
		it.prompt = str(e["prompt"])
		it.label = str(e["label"])
		it.dialogue_id = str(e["dialogue_id"])
		it.radius = float(e["radius"]) * S
		it.position = Vector2(float(e["x"]), float(e["z"])) * S
		if e.has("target_map"):
			var tm := str(e["target_map"])
			var ts := str(e["target_spawn"])
			it.interacted.connect(func(_by: Node2D) -> void: GameState.travel_requested.emit(tm, ts))
		add_child(it)
	for p: Dictionary in layout["people"]:
		var person := Person2D.new()
		person.sheet = load("res://art/baked2d/chars/%s.png" % p["sheet"])
		person.map = self
		var pts := PackedVector2Array()
		for q: Array in p["points"]:
			pts.append(Vector2(float(q[0]), float(q[2])) * S)
		person.points = pts
		var yaw := deg_to_rad(float(p["yaw"]))
		person.facing = Vector2(-sin(yaw), -cos(yaw))
		if str(p["dialogue_id"]) != "":
			person.make_talkable(str(p["name"]), str(p["dialogue_id"]))
		entities.add_child(person)
	lighting = EnvironmentController2D.new()
	lighting.name = "Lighting"
	add_child(lighting)
	for l: Dictionary in layout["lamps"]:
		lighting.add_lamp(Vector2(float(l["x"]), float(l["z"]) - float(l["y"])) * S, float(l["energy"]), float(l["range"]) * S)


func _glow_sprite(tex: Texture2D, at: Vector2, z: int) -> Sprite2D:
	var g := Sprite2D.new()
	g.texture = tex
	g.centered = false
	g.position = at
	g.z_index = z
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	g.material = m
	g.add_to_group(&"night_glow")
	return g


## Ground height in metres under a ground-space pixel position; -1000 off the grid.
func height_at(p: Vector2) -> float:
	var i := int(floor((p.x / S - _x0) * _grid))
	var j := int(floor((p.y / S - _z0) * _grid))
	if i < 0 or j < 0 or i >= _heights.get_width() or j >= _heights.get_height():
		return -1000.0
	return _heights.get_pixel(i, j).r


func is_ground(h: float) -> bool:
	return h > _sea + 0.5


## True if a walker at `from` may stand at `to` (ground px). Checks the footprint.
func can_step(from: Vector2, to: Vector2) -> bool:
	var h0 := height_at(from)
	for o: Vector2 in [Vector2.ZERO, Vector2(0.22, 0), Vector2(-0.22, 0), Vector2(0, 0.12), Vector2(0, -0.12)]:
		var h := height_at(to + o * S)
		if not is_ground(h) or absf(h - h0) > MAX_STEP:
			return false
	return true


## Nearest standable point to a ground px position (spawns, loads).
func nearest_standable(p: Vector2) -> Vector2:
	if is_ground(height_at(p)):
		return p
	for r in range(1, 40):
		for k in 16:
			var q := p + Vector2.from_angle(TAU * k / 16.0) * r * 4.0
			if is_ground(height_at(q)):
				return q
	return p
