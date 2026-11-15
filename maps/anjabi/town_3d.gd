extends MapBuilder3D
## Anjabi, the whole settlement, in 3D. Terrain, cliffs, water and colliders come
## from maps/anjabi/town_3d_cells.res (built from Greybox Study 01 by
## tools/build_town_3d.gd): one cell per metre, walkway heights interpolated between
## the districts so the paths climb and fall between levels. Landmark buildings are
## placed on their greybox footprints. Announces the district the player is in.
## Greybox pixel p maps to world (p - ORIGIN) * PX metres.

const CELLS := "res://maps/anjabi/town_3d_cells.res"
const ORIGIN := Vector2(34, 34)
const PX := 0.12
const SEA := -7.0
const CHUNK := 16
const WATER := 0
const PATH := 1
const GRASS := 2
const SAND := 3
const SLAB := 4
const CLIFF := 5
const INSERT := 6
## Where the detailed Steps insert (district.tscn) sits; matches tools/build_town_3d.gd.
const INSERT_AT := Vector3(101.52, 0, 45.72)
const INSERT_SCENE := preload("res://maps/anjabi/district.tscn")

## Greybox-pixel rectangles; first match wins (same as the 2D town).
const DISTRICTS := [
	["THE STEPS", Rect2(820, 370, 125, 75)],
	["TRAM STATION", Rect2(940, 440, 180, 210)],
	["SHOPS", Rect2(890, 220, 170, 160)],
	["MAIN TAVERN", Rect2(670, 190, 215, 175)],
	["TION TOWER", Rect2(425, 300, 180, 175)],
	["GUARD TOWER", Rect2(930, 40, 210, 165)],
	["WORKER PODS", Rect2(440, 40, 325, 205)],
	["ESTATE GARDENS", Rect2(95, 320, 215, 100)],
	["ESTATE", Rect2(120, 420, 290, 165)],
	["COLLAPSED MINE", Rect2(60, 630, 250, 180)],
	["PRIVATE AIRPAD", Rect2(320, 735, 200, 130)],
	["BEACH", Rect2(500, 560, 430, 175)],
	["DOCKS AND BOARDWALK", Rect2(1060, 360, 320, 215)],
	["RAINFOREST APPROACH", Rect2(1255, 220, 165, 150)],
	["FOREST", Rect2(40, 40, 330, 215)],
]
## Spawn points and exits, in greybox pixels (the 2D town's positions / 2).
const SPAWNS := {"default": Vector2(880, 415), "mine": Vector2(212, 676), "airpad": Vector2(336, 746)}

var w := 0
var h := 0
var cls := PackedByteArray()
var hv := PackedFloat32Array()
var hc := PackedFloat32Array()
var _district := ""
var _acc := 0.0


func _ready() -> void:
	_load_cells()
	_materials()
	_environment()
	_terrain()
	_collision()
	_sea()
	_landmarks()
	_vegetation_and_lamps()
	_spawns_and_exits()
	reflection_probe(INSERT_AT + Vector3(-2, 6, -8), Vector3(70, 24, 60))


# --- grid ------------------------------------------------------------------------

func _load_cells() -> void:
	var img: Image = load(CELLS)
	w = img.get_width()
	h = img.get_height()
	cls.resize(w * h)
	hv.resize(w * h)
	hc.resize(w * h)
	for z in h:
		for x in w:
			var c := img.get_pixel(x, z)
			var i := z * w + x
			hv[i] = c.r
			cls[i] = int(round(c.g))
			hc[i] = c.b


static func walkable(t: int) -> bool:
	return t == PATH or t == GRASS or t == SAND or t == INSERT


## World position of a greybox pixel, on the ground.
func at_px(p: Vector2) -> Vector3:
	var m := (p - ORIGIN) * PX
	return Vector3(m.x, ground(m.x, m.y), m.y)


func px_of(world: Vector3) -> Vector2:
	return Vector2(world.x, world.z) / PX + ORIGIN


## Visual height of the cell under (x, z).
func ground(x: float, z: float) -> float:
	var cx := clampi(int(x), 0, w - 1)
	var cz := clampi(int(z), 0, h - 1)
	return hv[cz * w + cx]


func nearest_walk(p: Vector2) -> Vector3:
	var m := (p - ORIGIN) * PX
	var c := Vector2i(int(m.x), int(m.y))
	for r in 12:
		for dz in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dz)) != r:
					continue
				var q := c + Vector2i(dx, dz)
				if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h:
					continue
				var i := q.y * w + q.x
				if walkable(cls[i]):
					return Vector3(q.x + 0.5, hv[i], q.y + 0.5)
	return Vector3(m.x, ground(m.x, m.y), m.y)


## Vertex heights: a vertex touching any walkable cell takes their mean, so walk
## surfaces stay exactly where the collider puts them; walls rise inside their cells.
func _vertex(x: int, z: int, collide: bool) -> float:
	var ws := 0.0
	var wn := 0
	var os := 0.0
	var on := 0
	var top := -INF
	for dz in [-1, 0]:
		for dx in [-1, 0]:
			var cx: int = x + dx
			var cz: int = z + dz
			if cx < 0 or cz < 0 or cx >= w or cz >= h:
				continue
			var i := cz * w + cx
			if cls[i] == INSERT:
				if collide:
					top = maxf(top, -30.0)
					continue
				os += hv[i] - 0.5
				on += 1
			elif walkable(cls[i]):
				ws += hv[i]
				wn += 1
			elif collide:
				top = maxf(top, hc[i])
			elif cls[i] != WATER:
				os += hv[i]
				on += 1
	if wn > 0:
		return ws / wn
	if collide:
		return top if top > -INF else 0.0
	return os / on if on > 0 else SEA


func _terrain() -> void:
	var vh := PackedFloat32Array()
	vh.resize((w + 1) * (h + 1))
	for z in h + 1:
		for x in w + 1:
			vh[z * (w + 1) + x] = _vertex(x, z, false)
	var mat := ground_mat(Color.WHITE, 1.0, 0.8, 0.5, true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	for cz0 in range(0, h, CHUNK):
		for cx0 in range(0, w, CHUNK):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			st.set_smooth_group(-1)
			var any := false
			for z in range(cz0, mini(cz0 + CHUNK, h)):
				for x in range(cx0, mini(cx0 + CHUNK, w)):
					var i := z * w + x
					var t := cls[i]
					if t == WATER or t == INSERT:
						continue
					any = true
					var col := _colour(t, rng.randf())
					var a := Vector3(x, vh[z * (w + 1) + x], z)
					var b := Vector3(x + 1, vh[z * (w + 1) + x + 1], z)
					var c := Vector3(x + 1, vh[(z + 1) * (w + 1) + x + 1], z + 1)
					var d := Vector3(x, vh[(z + 1) * (w + 1) + x], z + 1)
					_quad(st, a, b, c, d, col)
					# skirts down to the sea where this cell borders water
					var dark := col.darkened(0.35)
					if z > 0 and cls[i - w] == WATER:
						_quad(st, Vector3(b.x, SEA, b.z), b, a, Vector3(a.x, SEA, a.z), dark)
					if z < h - 1 and cls[i + w] == WATER:
						_quad(st, Vector3(d.x, SEA, d.z), d, c, Vector3(c.x, SEA, c.z), dark)
					if x > 0 and cls[i - 1] == WATER:
						_quad(st, Vector3(a.x, SEA, a.z), a, d, Vector3(d.x, SEA, d.z), dark)
					if x < w - 1 and cls[i + 1] == WATER:
						_quad(st, Vector3(c.x, SEA, c.z), c, b, Vector3(b.x, SEA, b.z), dark)
			if not any:
				continue
			st.generate_normals()
			var mi := MeshInstance3D.new()
			mi.mesh = st.commit()
			mi.material_override = mat
			add_child(mi)


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color) -> void:
	st.set_color(col)
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)
	st.add_vertex(a)
	st.add_vertex(c)
	st.add_vertex(d)


func _colour(t: int, n: float) -> Color:
	# rgb: sRGB colour; a: cobble amount for the wet-ground shader
	var j := (n - 0.5) * 0.05
	match t:
		PATH:
			return Color(0.62 + j, 0.59 + j, 0.55 + j, 1.0)
		GRASS:
			return Color(0.25 + j, 0.36 + j * 1.5, 0.24 + j, 0.0)
		SAND:
			return Color(0.72 + j, 0.65 + j, 0.53 + j, 0.0)
		SLAB:
			return Color(0.6 + j, 0.59 + j, 0.56 + j, 1.0)
	return Color(0.33 + j, 0.36 + j, 0.38 + j, 0.0)


func _collision() -> void:
	var data := PackedFloat32Array()
	data.resize((w + 1) * (h + 1))
	for z in h + 1:
		for x in w + 1:
			data[z * (w + 1) + x] = _vertex(x, z, true)
	var shape := HeightMapShape3D.new()
	shape.map_width = w + 1
	shape.map_depth = h + 1
	shape.map_data = data
	var body := _body()
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = Vector3(w * 0.5, 0, h * 0.5)
	body.add_child(cs)
	add_child(body)
	# frame the map so nothing walks off its edge
	blocker(Vector3(-2, -10, -2), Vector3(0, 20, h + 2))
	blocker(Vector3(w, -10, -2), Vector3(w + 2, 20, h + 2))
	blocker(Vector3(-2, -10, -2), Vector3(w + 2, 20, 0))
	blocker(Vector3(-2, -10, h), Vector3(w + 2, 20, h + 2))


func _sea() -> void:
	var sea := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(600, 500)
	sea.mesh = pm
	sea.material_override = M.sea
	sea.position = Vector3(w * 0.5, SEA + 0.4, h * 0.5)
	add_child(sea)


# --- buildings ---------------------------------------------------------------------

func _pod(p: Vector2, tag := "", _lit := true) -> void:
	var at := at_px(p)
	model("pod", at, 0.0, 1.1)
	if tag != "":
		sign_text(at + Vector3(0, 3.3, 2.55), tag, 0.0, 40)


## Shed model filling a greybox footprint (visual only; the grid already blocks it).
func _shed_px(a: Vector2, b: Vector2, h_m: float) -> void:
	var lo := at_px(Vector2(minf(a.x, b.x), minf(a.y, b.y)))
	var hi := at_px(Vector2(maxf(a.x, b.x), maxf(a.y, b.y)))
	var base := Vector3((lo.x + hi.x) * 0.5, minf(lo.y, hi.y), (lo.z + hi.z) * 0.5)
	shed(base, Vector3(hi.x - lo.x, h_m, hi.z - lo.z), 0.0, false)


func _block(a: Vector2, b: Vector2, h_m: float, m: Material, roof: Material = null, lit := true) -> void:
	var lo := at_px(Vector2(minf(a.x, b.x), minf(a.y, b.y)))
	var hi := at_px(Vector2(maxf(a.x, b.x), maxf(a.y, b.y)))
	var base := minf(lo.y, hi.y)
	var size := Vector3(hi.x - lo.x, h_m, hi.z - lo.z)
	var c := Vector3((lo.x + hi.x) * 0.5, base + h_m * 0.5, (lo.z + hi.z) * 0.5)
	box(c, size, m, false)
	box(c + Vector3(0, h_m * 0.5 + 0.12, 0), size + Vector3(0.5, 0.24, 0.5), roof if roof != null else M.steel_dark, false)
	if lit:
		for i in maxi(1, int(size.x / 4.0)):
			box(Vector3(lo.x + 2.0 + i * 4.0, base + h_m * 0.55, hi.z + 0.04), Vector3(1.2, 0.8, 0.08), M.window, false)


func _landmarks() -> void:
	# 08 Main Tavern and 12 Shop are part of the Steps insert
	var steps := INSERT_SCENE.instantiate()
	steps.set("insert", true)
	steps.position = INSERT_AT
	add_child(steps)
	# 07 Tion Tower
	var tion := at_px(Vector2(515, 390))
	model("tion_tower", tion)
	# 10 Guard Tower
	var gt := at_px(Vector2(1035, 118))
	model("guard_tower", gt)
	warm_light(gt + Vector3(0, 13.5, 7.0), 2.0, 10.0)
	# 09 Living pods
	_pod(Vector2(530, 68), "", true)
	_pod(Vector2(622, 72), "", false)
	_pod(Vector2(508, 128), "", true)
	_pod(Vector2(660, 132), "B-17", true)
	_pod(Vector2(546, 182), "", true)
	for b: Array in [[Vector2(480, 95), Vector2(505, 118)], [Vector2(690, 75), Vector2(730, 108)], [Vector2(718, 112), Vector2(745, 135)],
			[Vector2(592, 272), Vector2(622, 296)]]:
		_shed_px(b[0], b[1], 3.0)
	# 03 Estate and its walls
	model("estate", at_px(Vector2(240, 480)), 0.0, 0.85)
	# 04 Mine yard: headframe over the slab
	var mine := at_px(Vector2(215, 700))
	model("headframe", mine + Vector3(0, 0, -6))
	_shed_px(Vector2(150, 760), Vector2(205, 790), 3.0)
	_shed_px(Vector2(255, 640), Vector2(300, 668), 3.0)
	# 05 Private airpad: pad ring and a parked craft
	var pad := at_px(Vector2(382, 782))
	cyl(pad + Vector3(0, 0.02, 0), 3.6, 3.6, 0.05, M.warning, false, 24)
	cyl(pad + Vector3(0, 0.04, 0), 3.2, 3.2, 0.05, M.concrete, false, 24)
	var craft := at_px(Vector2(450, 790))
	box(craft + Vector3(0, 1.2, 0), Vector3(3.0, 1.6, 7.0), M.steel, false)
	box(craft + Vector3(0, 1.4, 0), Vector3(9.0, 0.25, 2.4), M.steel_dark, false)
	box(craft + Vector3(0, 2.1, -2.2), Vector3(2.0, 0.6, 1.6), M.blue_light, false)
	# 13 Tram / subway station, angled toward the docks
	var tram := at_px(Vector2(1030, 505))
	model("tram_station", tram, deg_to_rad(-33), 0.8)
	warm_light(tram + Vector3(-3, 3, 6), 1.6, 8.0)
	# tram line north-south, and 16 Imperial Tower
	var north := at_px(Vector2(1160, 10)) + Vector3(0, 0, 0)
	var tower := at_px(Vector2(1195, 880))
	north.y = 9.0
	var deck := tower + Vector3(0, 0, 0)
	deck.y = 9.0
	beam(north, deck, 0.15, 0.15, M.steel_dark)
	beam(north + Vector3(0.6, -0.4, 0), deck + Vector3(0.6, -0.4, 0), 0.1, 0.1, M.steel_dark)
	for f in 7:
		var p := north.lerp(deck, (f + 0.5) / 7.0)
		box(Vector3(p.x, (p.y + SEA) * 0.5, p.z), Vector3(1.0, p.y - SEA, 1.0), M.steel_dark, false)
		box(p + Vector3(0, 0.8, 0), Vector3(0.4, 0.3, 0.4), M.blue_light, false)
	var it := Vector3(tower.x, SEA, tower.z)
	model("imperial_tower", it)
	# docks: posts and crates on the boardwalk
	for p: Vector2 in [Vector2(1080, 380), Vector2(1150, 380), Vector2(1240, 400), Vector2(1300, 470), Vector2(1250, 520)]:
		box(at_px(p) + Vector3(0, 0.45, 0), Vector3(1.0, 0.9, 1.0), M.timber, true)


func _vegetation_and_lamps() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	var lamps := 0
	for z in range(1, h - 1):
		for x in range(1, w - 1):
			var i := z * w + x
			var t := cls[i]
			var r := rng.randf()
			if t == CLIFF and r < 0.03 and hv[i] > -2.0 and cls[i - 1] == CLIFF and cls[i + 1] == CLIFF \
					and cls[i - w] == CLIFF and cls[i + w] == CLIFF and cls[i - 2 * w] == CLIFF:
				tree(Vector3(x + 0.5, hv[i], z + 0.5), rng.randf_range(0.7, 1.1))
			elif t == GRASS and r < 0.012:
				var clear := true
				for n: int in [i - 1, i + 1, i - w, i + w, i - 2, i + 2, i - 2 * w, i + 2 * w]:
					if n < 0 or n >= w * h or cls[n] != GRASS:
						clear = false
				if clear:
					var p := Vector3(x + 0.5, hv[i], z + 0.5)
					tree(p, rng.randf_range(0.9, 1.4))
					blocker(p + Vector3(-0.25, 0, -0.25), p + Vector3(0.25, 1.6, 0.25))
			elif t == PATH and r < 0.03 and lamps < 48:
				# lamps stand at path edges, against a wall
				var edge := false
				for n: int in [i - 1, i + 1, i - w, i + w]:
					if cls[n] == CLIFF or cls[n] == SLAB:
						edge = true
				if edge:
					lamps += 1
					lamp(Vector3(x + 0.5, hv[i], z + 0.5), lamps % 2 == 0)


func _spawns_and_exits() -> void:
	var spawns := Node3D.new()
	spawns.name = "Spawns"
	add_child(spawns)
	for k: String in SPAWNS:
		var m := Marker3D.new()
		m.name = k
		m.position = nearest_walk(SPAWNS[k]) + Vector3(0, 0.1, 0)
		if k == "default":
			m.position = INSERT_AT + Vector3(2, 0.05, 5)
		spawns.add_child(m)
	var door := Interactable3D.new()
	door.name = "PodB17Door"
	door.prompt = "Knock"
	door.label = "Pod B-17"
	door.dialogue_id = "anjabi/pod_b17"
	door.radius = 1.4
	door.position = at_px(Vector2(660, 132)) + Vector3(0, 0.9, 3.4)
	add_child(door)
	var sign := Interactable3D.new()
	sign.name = "MineSign"
	sign.prompt = "Read"
	sign.label = "Warning sign"
	sign.dialogue_id = "anjabi/mine_approach_sign"
	sign.position = nearest_walk(Vector2(232, 676)) + Vector3(0, 0.9, 0)
	add_child(sign)
	box(sign.position + Vector3(0, 0.2, -0.4), Vector3(0.8, 0.6, 0.06), M.concrete, false)
	_exit("ToMineRoad", "Enter", "Mine yard", Vector2(212, 692), "anjabi_mine", "default")
	_exit("ToMineFromAirpad", "Walk", "Mine yard", Vector2(322, 745), "anjabi_mine", "east")


func _exit(n: String, prompt: String, label: String, p: Vector2, target: String, spawn: String) -> void:
	var e := MapExit3D.new()
	e.name = n
	e.prompt = prompt
	e.label = label
	e.radius = 1.6
	e.target_map = target
	e.target_spawn = spawn
	e.position = nearest_walk(p) + Vector3(0, 0.8, 0)
	add_child(e)


func _process(delta: float) -> void:
	_acc += delta
	if _acc < 0.25 or player == null:
		return
	_acc = 0.0
	var p := px_of(player.global_position)
	var found := ""
	for d: Array in DISTRICTS:
		if (d[1] as Rect2).has_point(p):
			found = d[0]
			break
	if found != _district:
		_district = found
		if found != "":
			GameState.location_entered.emit("ANJABI  ·  " + found)
