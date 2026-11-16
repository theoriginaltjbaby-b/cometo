extends MapBuilder3D
## Anjabi central district in 3D, built in code from reusable pieces (PROVISIONAL
## geometry and materials, to be replaced by authored meshes on the same footprints).
##
## Units are metres. +X east, -Z north, +Y up. Levels:
##   pods 6  ·  tavern terrace 3  ·  the Steps plaza 0  ·  mine approach -3  ·  beach -6  ·  sea -7
## Layout follows Greybox Study 01 around the Steps: tavern up and to the north-west,
## living pods further north over a ravine (reached by a raised walkway), shop to the
## east, the drop to the beach and sea south, the way to the mine going down west.

const PLAZA := 0.0
const TERRACE := 3.0
const PODS := 6.0
const MINE := -3.0
const BEACH := -6.0
const SEA := -7.0



## When true this is the detailed Steps insert inside the town map: only the plaza,
## the tavern terrace, their stairs, buildings, props and people are built.
@export var insert := false


func _ready() -> void:
	if insert:
		_materials()
		SettlementKit.materials(self)
		slab(Vector3(-12, -12, -10), Vector3(20, PLAZA, 10), M.paving)
		_plaza_feature()
		slab(Vector3(-24, -12, -28), Vector3(12, TERRACE, -10), M.stone)
		slab(Vector3(-24, TERRACE - 0.02, -28), Vector3(12, TERRACE + 0.01, -10), M.paving, false)
		stairs(Vector3(0, PLAZA, -4), Vector3(0, 0, -1), TERRACE - PLAZA, 6.0, 4.0, M.stone)
		SettlementKit.balustrade(self, Vector3(-11.8, TERRACE, -10.25), Vector3(-2.2, TERRACE, -10.25), true)
		SettlementKit.balustrade(self, Vector3(2.2, TERRACE, -10.25), Vector3(11.8, TERRACE, -10.25), true)
		_tavern()
		_shop()
		_props(true)
		_people()
		_insert_dressing()
		_market_quarter()
		return
	_materials()
	_environment()
	_ground()
	_stairs_and_walkways()
	_railings()
	_tavern()
	_shop()
	_pods()
	_mine_approach()
	_coast()
	_backdrop()
	_props()
	_people()


func _ground() -> void:
	# the Steps plaza
	slab(Vector3(-12, -12, -10), Vector3(20, PLAZA, 10), M.paving)
	_plaza_feature()
	# tavern terrace, retaining wall faces the plaza
	slab(Vector3(-24, -12, -28), Vector3(12, TERRACE, -10), M.stone)
	slab(Vector3(-24, TERRACE - 0.02, -28), Vector3(12, TERRACE + 0.01, -10), M.paving, false)
	# pod level beyond the ravine
	slab(Vector3(-20, -12, -50), Vector3(16, PODS, -34), M.stone)
	slab(Vector3(-20, PODS - 0.02, -50), Vector3(16, PODS + 0.01, -34), M.moss, false)
	# ravine floor
	slab(Vector3(-24, -12, -34), Vector3(16, -4, -28), M.rock_dark)
	# mine approach, a shelf below the plaza
	slab(Vector3(-44, -14, -8), Vector3(-12, MINE, 12), M.concrete)
	# beach
	slab(Vector3(-14, -14, 16), Vector3(40, BEACH, 36), M.sand)
	# cliff face below the plaza
	slab(Vector3(-12, -14, 10), Vector3(22, -1.5, 16), M.rock)


func _plaza_feature() -> void:
	if insert:
		# the compass rose of the Steps and the armillary that stands on its boss
		SettlementKit.compass_inlay(self, Vector3(2, 0, 1), 4.2)
		SettlementKit.armillary(self, Vector3(2, 0, 1), 2.3, 1.15)
		return
	var ring := CylinderMesh.new()
	ring.top_radius = 4.5
	ring.bottom_radius = 4.5
	ring.height = 0.04
	ring.radial_segments = 32
	ring.rings = 0
	var rm := MeshInstance3D.new()
	rm.mesh = ring
	rm.material_override = M.paving_light
	rm.position = Vector3(2, 0.02, 1)
	add_child(rm)
	cyl(Vector3(2, 0, 1), 1.2, 1.4, 0.5, M.stone, true, 12)  # plinth
	cyl(Vector3(2, 0.5, 1), 0.25, 0.3, 2.2, M.copper, true, 10)  # beacon column
	box(Vector3(2, 2.85, 1), Vector3(0.6, 0.3, 0.6), M.lamp, false)
	warm_light(Vector3(2, 3.2, 1), 1.8, 9.0)


func _stairs_and_walkways() -> void:
	# plaza -> tavern terrace (north)
	stairs(Vector3(0, PLAZA, -4), Vector3(0, 0, -1), TERRACE - PLAZA, 6.0, 4.0, M.stone)
	# terrace -> raised walkway (north), then the bridge over the ravine to the pods
	stairs(Vector3(8.5, TERRACE, -20), Vector3(0, 0, -1), PODS - TERRACE, 6.0, 3.0, M.stone)
	slab(Vector3(7, PODS - 0.4, -34.2), Vector3(10, PODS, -26.0), M.steel)
	for z: float in [-27.0, -30.5, -33.5]:
		box(Vector3(8.5, (PODS + -4) * 0.5 - 0.2, z), Vector3(0.5, PODS + 4 - 0.4, 0.5), M.steel_dark, false)
	# plaza -> mine approach (down to the west)
	stairs(Vector3(-18, MINE, 2), Vector3(1, 0, 0), PLAZA - MINE, 6.0, 4.0, M.stone)
	slab(Vector3(-18, -14, -8), Vector3(-12, MINE, 12), M.concrete)


func _railings() -> void:
	var P := PLAZA
	# plaza: south over the cliff, east end, west edge (gap for the mine stairs)
	railing(Vector3(-12, P, 9.8), Vector3(20, P, 9.8))
	railing(Vector3(19.8, P, -10), Vector3(19.8, P, 10))
	railing(Vector3(-11.8, P, -10), Vector3(-11.8, P, 0))
	railing(Vector3(-11.8, P, 4), Vector3(-11.8, P, 10))
	# terrace: south edge (gap for the plaza stairs), north edge, east edge
	var T := TERRACE
	railing(Vector3(-24, T, -10.2), Vector3(-2, T, -10.2))
	railing(Vector3(2, T, -10.2), Vector3(12, T, -10.2))
	railing(Vector3(-24, T, -27.8), Vector3(12, T, -27.8))
	railing(Vector3(11.8, T, -28), Vector3(11.8, T, -10))
	# raised stair sides and bridge
	railing(Vector3(7, T, -20), Vector3(7, PODS, -26))
	railing(Vector3(10, T, -20), Vector3(10, PODS, -26))
	railing(Vector3(7, PODS, -26), Vector3(7, PODS, -34))
	railing(Vector3(10, PODS, -26), Vector3(10, PODS, -34))
	# pods: south edge (gap for the bridge), east and west
	railing(Vector3(-20, PODS, -34.2), Vector3(7, PODS, -34.2))
	railing(Vector3(10, PODS, -34.2), Vector3(16, PODS, -34.2))
	railing(Vector3(15.8, PODS, -50), Vector3(15.8, PODS, -34))
	railing(Vector3(-19.8, PODS, -50), Vector3(-19.8, PODS, -34))
	# mine approach: south over the drop, north under the plaza wall
	railing(Vector3(-44, MINE, 11.8), Vector3(-12, MINE, 11.8))
	# west of the terrace: rock wall
	slab(Vector3(-30, -12, -28), Vector3(-24, 9, -10), M.rock)
	# walls the player must not walk off: plaza north beside stairs is the terrace face (solid)
	slab(Vector3(-44, MINE, -10), Vector3(-12, PLAZA + 0.0, -8), M.rock)


func _tavern() -> void:
	var c := Vector3(-10, TERRACE, -20.5)
	model("tavern_v2", c)
	collider_cyl(c, 6.2, 5.0)
	collider_cyl(c + Vector3(4.6, 0, -3.6), 1.95, 9.5)  # silo
	box(c + Vector3(0, 1.8, 6.1), Vector3(3.4, 3.6, 1.4), null, true)  # entrance bay
	sign_text(c + Vector3(0, 4.45, 7.08), "MAIN TAVERN", 0.0, 52, Color(0.98, 0.82, 0.5))
	warm_light(c + Vector3(0, 2.4, 7.6), 2.4, 9.0)
	warm_light(c + Vector3(2.6, 2.2, 8.4), 1.4, 6.0)
	lamp(c + Vector3(-3.4, 0, 8.6))
	lamp(c + Vector3(6.4, 0, 8.6), false)
	for p: Vector3 in [Vector3(1.6, 0, 8.4), Vector3(3.8, 0, 8.2)]:
		model("cafe_table", c + p, 0.4)
		collider_cyl(c + p, 0.5, 0.8)
	for p: Vector3 in [Vector3(-2.8, 0, 7.8), Vector3(-2.2, 0, 8.5)]:
		model("barrel", c + p)
		collider_cyl(c + p, 0.38, 1.0)
	model("planter", c + Vector3(-4.8, 0, 7.6))
	box(c + Vector3(-4.8, 0.3, 7.6), Vector3(1.2, 0.6, 0.6), null, true)
	for x: float in [-2.4, 2.4]:
		model("banner", c + Vector3(x, 0, 7.2), PI if x < 0 else 0.0)


func _shop() -> void:
	var c := Vector3(15, PLAZA, -5)
	model("shop", c)
	box(c + Vector3(0, 2.0, 0), Vector3(7, 4, 6), null)
	sign_text(c + Vector3(0, 3.35, 3.2), "SHOP", 0.0, 56)
	warm_light(c + Vector3(0, 2.0, 4.2), 1.6, 6.0)
	for i in 3:
		box(c + Vector3(-2.8 + i * 0.7, 0.35, 4.4), Vector3(0.6, 0.7, 0.6), M.timber, true)
	# the shop door: the first interior (maps/anjabi/interiors/shop.tscn)
	var door := MapExit3D.new()
	door.name = "ShopDoor"
	door.prompt = "Enter"
	door.label = "Shop"
	door.radius = 1.2
	door.target_map = "anjabi_shop"
	door.target_spawn = "default"
	door.position = c + Vector3(0, 0.9, 3.4)
	add_child(door)


func _pod(at: Vector3, tag := "", _lit := true) -> void:
	model("pod", at, PI if tag == "" and int(at.x) % 2 == 0 else 0.0)
	collider_cyl(at, 2.25, 3.4)
	if tag != "":
		sign_text(at + Vector3(0, 3.0, 2.3), tag, 0.0, 40)


func _pods() -> void:
	var y := PODS
	_pod(Vector3(4, y, -39.5), "B-17")
	_pod(Vector3(-3, y, -41), "", true)
	_pod(Vector3(-10, y, -39), "", false)
	_pod(Vector3(-15, y, -45.5), "", true)
	_pod(Vector3(11, y, -45), "", true)
	_pod(Vector3(2, y, -47), "", false)
	lamp(Vector3(6.6, y, -36))
	lamp(Vector3(-6.5, y, -36), false)
	# walkway paving from the bridge to B-17's door
	slab(Vector3(3.2, y, -38), Vector3(9.8, y + 0.03, -34.2), M.paving, false)
	# B-17 door interactable
	var door := Interactable3D.new()
	door.prompt = "Knock"
	door.label = "Pod B-17"
	door.dialogue_id = "anjabi/pod_b17"
	door.radius = 1.3
	door.position = Vector3(4, y + 0.9, -36.9)
	add_child(door)


func _mine_approach() -> void:
	var y := MINE
	# cliff wall with the mine mouth cut into it
	slab(Vector3(-56, -14, -12), Vector3(-44, 12, 16), M.rock)
	slab(Vector3(-44.01, y, -1.6), Vector3(-43.6, y + 3.6, 5.6), M.rock_dark, false)
	# timber headframe and steel door
	for z: float in [-1.4, 5.4]:
		box(Vector3(-43.4, y + 1.9, z), Vector3(0.4, 3.8, 0.4), M.timber, true)
	box(Vector3(-43.4, y + 3.9, 2), Vector3(0.5, 0.4, 7.4), M.timber, false)
	box(Vector3(-43.75, y + 1.6, 2), Vector3(0.12, 3.2, 6.2), M.steel, true)
	for z: float in [-1.0, 0.6, 2.2, 3.8, 5.0]:
		box(Vector3(-43.66, y + 1.6, z), Vector3(0.06, 3.2, 0.08), M.steel_dark, false)
	# warning stripes across the door
	for i in 6:
		box(Vector3(-43.64, y + 2.1, -0.6 + i * 1.1), Vector3(0.05, 0.3, 0.5), M.warning if i % 2 == 0 else M.steel_dark, false)
	sign_text(Vector3(-43.5, y + 4.5, 2), "NO. 2 WORKING", PI * 0.5, 44)
	# rails running into the mine
	for z: float in [1.3, 2.7]:
		beam(Vector3(-43.6, y, z), Vector3(-30, y, z), 0.08, 0.08, M.steel)
	for i in 14:
		box(Vector3(-43 + i, y + 0.02, 2), Vector3(0.25, 0.05, 2.0), M.timber, false)
	# fence and gate across the approach
	railing(Vector3(-38, y, -8), Vector3(-38, y, 0.0), M.steel)
	railing(Vector3(-38, y, 4.0), Vector3(-38, y, 12), M.steel)
	box(Vector3(-38, y + 1.0, 2), Vector3(0.12, 2.0, 4.0), M.steel_dark, true)
	for i in 5:
		box(Vector3(-37.92, y + 1.2, 0.4 + i * 0.8), Vector3(0.05, 0.25, 0.4), M.warning if i % 2 == 0 else M.steel_dark, false)
	sign_text(Vector3(-37.85, y + 2.4, 2), "DANGER  ·  NO ENTRY", PI * 0.5, 36, Color(0.95, 0.75, 0.3))
	# guard hut
	shed(Vector3(-33, y, -5), Vector3(3.0, 2.8, 2.6))
	warm_light(Vector3(-33, y + 2.0, -3.0), 1.2, 5.0)
	lamp(Vector3(-36.5, y, 5.5))
	lamp(Vector3(-24, y, 9.5))
	# crates and a winch
	box(Vector3(-28, y + 0.45, -6), Vector3(1.2, 0.9, 1.2), M.timber)
	box(Vector3(-26.7, y + 0.35, -6.2), Vector3(0.9, 0.7, 0.9), M.timber)
	cyl(Vector3(-30, y, 9), 0.6, 0.6, 1.2, M.copper_raw, true, 10)
	# notice and the way through to the mine yard
	var notice := Interactable3D.new()
	notice.prompt = "Read"
	notice.label = "Warning sign"
	notice.dialogue_id = "anjabi/mine_approach_sign"
	notice.position = Vector3(-37, y + 1.0, -1.2)
	add_child(notice)
	box(Vector3(-37.85, y + 1.3, -1.2), Vector3(0.05, 0.6, 0.8), M.concrete, false)
	var exit := MapExit3D.new()
	exit.prompt = "Enter"
	exit.label = "Mine yard"
	exit.radius = 1.4
	exit.target_map = "anjabi_mine"
	exit.target_spawn = "default"
	exit.position = Vector3(-36.6, y + 1.0, 2)
	add_child(exit)


func _coast() -> void:
	var sea := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(500, 500)
	sea.mesh = pm
	sea.material_override = M.sea
	sea.position = Vector3(40, SEA, 80)
	add_child(sea)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	for i in 14:
		var p := Vector3(rng.randf_range(-6, 46), SEA - 0.5, rng.randf_range(30, 60))
		var s := rng.randf_range(1.0, 3.2)
		var r := box(p + Vector3(0, s * 0.4, 0), Vector3(s, s * 1.3, s * 0.9), M.rock, false, rng.randf() * TAU)
		r.rotation.x = rng.randf_range(-0.2, 0.2)
	# headland and the cliffs east of the cove
	slab(Vector3(-60, -14, 12), Vector3(-14, -2, 40), M.rock)
	slab(Vector3(40, -14, -20), Vector3(70, 4, 20), M.rock)
	# docks boardwalk east of the plaza, below it
	slab(Vector3(22, -1.4, -6), Vector3(40, -1.0, 6), M.timber, false)
	for x in range(23, 40, 3):
		for z: float in [-5.5, 5.5]:
			box(Vector3(x, -4.2, z), Vector3(0.3, 6.2, 0.3), M.timber, false)
	# Imperial Tower far to the south-east, and its tram line
	var t := Vector3(64, SEA, 82)
	cyl(t, 6, 8, 3, M.concrete, false, 16)
	cyl(t + Vector3(0, 3, 0), 3.2, 4.0, 44, M.steel_dark, false, 12)
	for i in 6:
		box(t + Vector3(0, 8 + i * 6.5, 3.6), Vector3(1.6, 0.4, 0.2), M.blue_light, false)
	cyl(t + Vector3(0, 47, 0), 4.6, 3.2, 3, M.steel, false, 12)
	box(t + Vector3(0, 51, 0), Vector3(1, 3, 1), M.blue_light, false)
	var top := Vector3(24, 9, -8)
	beam(top, t + Vector3(0, 40, 0), 0.12, 0.12, M.steel_dark)
	beam(top + Vector3(0, -0.6, 0), t + Vector3(0, 39.4, 0), 0.08, 0.08, M.steel_dark)
	for f: float in [0.3, 0.6]:
		var p := top.lerp(t + Vector3(0, 40, 0), f)
		box(Vector3(p.x, (p.y + SEA) * 0.5, p.z), Vector3(0.8, p.y - SEA, 0.8), M.steel_dark, false)
		box(p + Vector3(0, 0.3, 0), Vector3(0.4, 0.3, 0.4), M.blue_light, false)
	cyl(Vector3(24, -1.0, -8), 0.5, 0.7, 10.0, M.steel, false, 8)  # tram pylon at the docks


func _backdrop() -> void:
	# forested hill north of the pods, and the west ridge
	slab(Vector3(-70, -14, -90), Vector3(60, 12, -50), M.rock)
	slab(Vector3(-70, 12, -90), Vector3(60, 12.1, -52), M.moss, false)
	slab(Vector3(-70, -14, -50), Vector3(-20, 9, -28), M.rock)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 40:
		tree(Vector3(rng.randf_range(-60, 55), 12, rng.randf_range(-80, -53)), rng.randf_range(1.2, 2.0))
	for i in 10:
		tree(Vector3(rng.randf_range(-60, -24), 9, rng.randf_range(-48, -30)), rng.randf_range(1.0, 1.6))
	# watchtower silhouette north-east (guard tower direction)
	cyl(Vector3(30, 4, -46), 4, 5, 9, M.concrete, false, 8)
	cyl(Vector3(30, 13, -46), 4.6, 4.2, 2, M.panel_violet, false, 8)
	box(Vector3(30, 13.5, -41.7), Vector3(3, 0.8, 0.2), M.window, false)


func _props(core_only := false) -> void:
	# plaza lamps, benches, planters, crates
	for p: Vector3 in [Vector3(-8, 0, 8), Vector3(12, 0, 8), Vector3(-8, 0, -8), Vector3(8, 0, -3)]:
		if insert and p.z < 0.0:
			continue
		lamp(p)
	for p: Vector3 in [Vector3(-4, 0, 7), Vector3(8, 0, 7)]:
		if insert:
			SettlementKit.bench(self, p, PI)
		else:
			box(p + Vector3(0, 0.25, 0), Vector3(2.2, 0.5, 0.6), M.timber)
	for p: Vector3 in [Vector3(-10, 0, -6), Vector3(17, 0, 6)]:
		if insert and p.x < 0.0:
			continue
		box(p + Vector3(0, 0.4, 0), Vector3(1.8, 0.8, 1.8), M.stone)
		tree(p + Vector3(0, 0.8, 0), 0.7)
	box(Vector3(10.5, 0.4, 4), Vector3(0.9, 0.8, 0.9), M.timber)
	box(Vector3(11.3, 0.3, 4.6), Vector3(0.7, 0.6, 0.7), M.timber)
	cyl(Vector3(-6, 0, 3), 0.45, 0.45, 1.0, M.copper_raw, true, 10)
	# terrace lamps, planters
	lamp(Vector3(5, TERRACE, -12.5))
	lamp(Vector3(-20, TERRACE, -12.5), false)
	tree(Vector3(-21, TERRACE, -25), 1.0)
	if not insert:
		tree(Vector3(2, TERRACE, -25.5), 0.9)
	if core_only:
		return
	# coastal vegetation along the plaza's southern lip
	tree(Vector3(-10.8, -1.5, 13), 1.0)
	tree(Vector3(18, -1.5, 14), 1.2)


func _people() -> void:
	var keeper := Npc3D.new()
	keeper.display_name = "Tavern keeper"
	keeper.dialogue_id = "anjabi/tavern_keeper"
	keeper.coat = Color(0.4, 0.22, 0.2)
	keeper.accent = Color(0.85, 0.7, 0.4)
	keeper.skin = Color(0.6, 0.43, 0.33)
	keeper.position = Vector3(-7.2, TERRACE, -12.2)
	keeper.yaw_deg = 180.0
	keeper.look = {"apron": true, "satchel": false, "hair": "short", "hair_color": Color(0.35, 0.3, 0.27)}
	entities.add_child(keeper)


func _insert_dressing() -> void:
	# ferns and flowers along the terrace wall foot and plaza edges; clutter by the shop
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	var ferns: Array[Transform3D] = []
	for i in 6:
		ferns.append(xform(Vector3(rng.randf_range(-2.3, -1.9) * (1 if i % 2 == 0 else -1), PLAZA, -4.0 + rng.randf() * 0.4), rng.randf() * TAU, rng.randf_range(0.8, 1.2)))
	for i in 14:
		ferns.append(xform(Vector3(rng.randf_range(-23.5, -17.0), TERRACE, -27.4 + rng.randf() * 0.8), rng.randf() * TAU, rng.randf_range(0.9, 1.4)))
	scatter("fern", ferns)
	var fl: Array[Transform3D] = []
	for i in 22:
		fl.append(xform(Vector3(rng.randf_range(-23.5, -17.0), TERRACE, -27.3 + rng.randf() * 0.7), rng.randf() * TAU, rng.randf_range(0.9, 1.3)))
	scatter("flowers", fl)
	for p: Vector3 in [Vector3(-11, PLAZA, 9.2), Vector3(18.5, PLAZA, 9.2)]:
		model("planter", p)
	model("crate_stack", Vector3(19, PLAZA, -1.6), 0.3)
	model("barrel", Vector3(18.6, PLAZA, -3.4))
	model("barrel", Vector3(19.3, PLAZA, -4.1))
	for p: Vector3 in [Vector3(-11, PLAZA, -9.0), Vector3(19, PLAZA, -9.0)]:
		model("banner", p)


## The market quarter of the Steps (entry 20): an arcade of shopfronts in the terrace
## wall, market stalls, townhouses along the top of the terrace, a garden with a sun
## instrument, a terminal, string lights, climbing plants and doorstep life.
## Paths kept clear: the stairs (x -2..2), the plaza's east and west exits, the terrace
## west exit (z -22..-18) and the walk in front of the tavern.
func _market_quarter() -> void:
	var K := SettlementKit
	var rose: Array = [M.canvas_rose, M.canvas_cream]
	var teal: Array = [M.canvas_teal2, M.canvas_cream]
	# arcade: three bays either side of the stairs in the terrace wall (face z = -10)
	var bays := [[-10.4, rose, true], [-7.2, teal, false], [-4.0, rose, true], [4.0, teal, true], [7.2, rose, false], [10.4, teal, true]]
	for bay: Array in bays:
		K.arcade_bay(self, bay[0], -10.0, PLAZA, 3.1, bay[1], bay[2])
	warm_light(Vector3(-8.8, 2.2, -8.6), 1.4, 6.0)
	warm_light(Vector3(8.8, 2.2, -8.6), 1.4, 6.0)
	# vines trailing from the terrace balustrade down over the arcade
	K.vines(self, Vector3(-11.8, TERRACE + 0.1, -9.95), Vector3(-2.4, TERRACE + 0.1, -9.95), Vector3(0, 0, 1), 1.6, 3)
	K.vines(self, Vector3(2.4, TERRACE + 0.1, -9.95), Vector3(11.8, TERRACE + 0.1, -9.95), Vector3(0, 0, 1), 1.6, 4)
	# stair side balustrades with lantern newels, lavender at the foot
	for sx: float in [-2.25, 2.25]:
		K.balustrade(self, Vector3(sx, PLAZA, -4.1), Vector3(sx, TERRACE, -9.9), true)
		K.pot(self, Vector3(sx * 1.25, PLAZA, -3.6), "lavender", 1.2)
	# market stalls in front of the arcade, out of the stairs' way
	K.stall(self, Vector3(-8.6, PLAZA, -6.9), 0.0, rose, "instruments")
	K.stall(self, Vector3(7.4, PLAZA, -7.0), 0.0, teal, "wares")
	K.pot(self, Vector3(-11.2, PLAZA, -8.6), "lavender", 1.3)
	K.pot(self, Vector3(11.0, PLAZA, -8.7), "leaf", 1.3)
	# the public terminal beside the foot of the stairs
	K.terminal(self, Vector3(3.6, PLAZA, -4.5), 0.0, "anjabi/public_terminal")
	# string lights from the balustrade to the plaza lamps
	K.string_lights(self, Vector3(-11.8, TERRACE + 1.15, -10.25), Vector3(-8, 3.0, 8), 0.9)
	K.string_lights(self, Vector3(11.8, TERRACE + 1.15, -10.25), Vector3(12, 3.0, 8), 0.9)
	# townhouses along the top of the terrace, east of the tavern, facing the Steps
	var d1 := K.townhouse(self, Vector3(1.2, TERRACE, -26.3), 5.4, 3.4, 2, M.plaster_rose, "pitched", 5)
	var d2 := K.townhouse(self, Vector3(7.6, TERRACE, -26.3), 6.8, 3.4, 3, M.plaster_ochre, "dome", 9)
	for i in 2:
		var d: Vector3 = [d1, d2][i]
		K.doorstep(self, d, 20 + i)
		var door := Interactable3D.new()
		door.prompt = "Knock"
		door.label = "Townhouse"
		door.dialogue_id = "anjabi/townhouse_door"
		door.radius = 1.1
		door.position = d + Vector3(0, 0.9, -0.4)
		add_child(door)
	K.wall_lantern(self, Vector3(1.2 - 2.7, TERRACE + 2.4, -24.55), Vector3(0, 0, 1))
	K.wall_lantern(self, Vector3(7.6 + 1.5, TERRACE + 2.4, -24.55), Vector3(0, 0, 1))
	K.vines(self, Vector3(-1.4, TERRACE + 5.2, -24.55), Vector3(3.8, TERRACE + 5.2, -24.55), Vector3(0, 0, 1), 2.6, 6)
	# west terrace garden: bench, planting and a brass sun instrument
	K.bench(self, Vector3(-20.5, TERRACE, -25.2), 0.0)
	for p: Vector3 in [Vector3(-23.3, TERRACE, -24.8), Vector3(-17.6, TERRACE, -25.0), Vector3(-23.2, TERRACE, -15.6)]:
		K.pot(self, p, "lavender" if p.z < -20 else "leaf", 1.3)
	K.armillary(self, Vector3(-19.2, TERRACE, -15.4), 1.0, 0.6)
	# people living here: two merchants at the stalls, two talking by the terminal
	townsfolk([to_global(Vector3(-8.6, PLAZA, -7.9))], Color(0.42, 0.2, 0.22), Color(0.7, 0.55, 0.3), Color(0.7, 0.52, 0.4), false, 180.0, {"hat": "brim", "satchel": false})
	townsfolk([to_global(Vector3(7.4, PLAZA, -8.0))], Color(0.2, 0.32, 0.34), Color(0.75, 0.6, 0.35), Color(0.55, 0.4, 0.3), false, 180.0, {"hair": "long", "apron": true, "satchel": false})
	townsfolk([to_global(Vector3(5.2, PLAZA, -3.6))], Color(0.36, 0.3, 0.44), Color(0.7, 0.52, 0.3), Color(0.76, 0.58, 0.46), false, 250.0, {"hair": "bun"})
	townsfolk([to_global(Vector3(6.4, PLAZA, -3.9))], Color(0.48, 0.4, 0.3), Color(0.5, 0.35, 0.2), Color(0.6, 0.45, 0.35), true, 110.0, {})
