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



func _ready() -> void:
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
	var ring := CylinderMesh.new()
	ring.top_radius = 4.5
	ring.bottom_radius = 4.5
	ring.height = 0.04
	ring.radial_segments = 32
	var rm := MeshInstance3D.new()
	rm.mesh = ring
	rm.material_override = M.paving_light
	rm.position = Vector3(2, 0.02, 1)
	add_child(rm)
	cyl(Vector3(2, 0, 1), 1.2, 1.4, 0.5, M.stone, true, 12)  # plinth
	cyl(Vector3(2, 0.5, 1), 0.25, 0.3, 2.2, M.copper, true, 10)  # beacon column
	box(Vector3(2, 2.85, 1), Vector3(0.6, 0.3, 0.6), M.lamp, false)
	warm_light(Vector3(2, 3.2, 1), 1.8, 9.0)
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
	var c := Vector3(-10, TERRACE, -19)
	model("tavern", c)
	collider_cyl(c, 6.2, 5.0)
	blocker(c + Vector3(5.25, 0, -2.0), c + Vector3(9.75, 3.6, 4.0))  # annex
	var door := c + Vector3(0, 0, 6.1)
	sign_text(door + Vector3(0, 4.3, 0.75), "TAVERN", 0.0, 64)
	warm_light(door + Vector3(0, 2.2, 1.6), 2.2, 8.0)
	lamp(door + Vector3(-3.6, 0, 2.0))
	lamp(door + Vector3(3.6, 0, 2.0), false)
	# outside seating
	for p: Vector3 in [Vector3(-4.6, 0, 7.4), Vector3(4.8, 0, 7.2)]:
		cyl(c + p, 0.6, 0.6, 0.75, M.timber, true, 10)
		box(c + p + Vector3(0, 0.25, 0.9), Vector3(1.4, 0.5, 0.35), M.timber, true)


func _shop() -> void:
	var c := Vector3(15, PLAZA, -5)
	model("shop", c)
	box(c + Vector3(0, 2.0, 0), Vector3(7, 4, 6), null)
	sign_text(c + Vector3(0, 3.35, 3.2), "SHOP", 0.0, 56)
	warm_light(c + Vector3(0, 2.0, 4.2), 1.6, 6.0)
	for i in 3:
		box(c + Vector3(-2.8 + i * 0.7, 0.35, 4.4), Vector3(0.6, 0.7, 0.6), M.timber, true)


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


func _props() -> void:
	# plaza lamps, benches, planters, crates
	for p: Vector3 in [Vector3(-8, 0, 8), Vector3(12, 0, 8), Vector3(-8, 0, -8), Vector3(8, 0, -3)]:
		lamp(p)
	for p: Vector3 in [Vector3(-4, 0, 7), Vector3(8, 0, 7)]:
		box(p + Vector3(0, 0.25, 0), Vector3(2.2, 0.5, 0.6), M.timber)
	for p: Vector3 in [Vector3(-10, 0, -6), Vector3(17, 0, 6)]:
		box(p + Vector3(0, 0.4, 0), Vector3(1.8, 0.8, 1.8), M.stone)
		tree(p + Vector3(0, 0.8, 0), 0.7)
	box(Vector3(10.5, 0.4, 4), Vector3(0.9, 0.8, 0.9), M.timber)
	box(Vector3(11.3, 0.3, 4.6), Vector3(0.7, 0.6, 0.7), M.timber)
	cyl(Vector3(-6, 0, 3), 0.45, 0.45, 1.0, M.copper_raw, true, 10)
	# terrace lamps, planters
	lamp(Vector3(5, TERRACE, -12.5))
	lamp(Vector3(-20, TERRACE, -12.5), false)
	tree(Vector3(-21, TERRACE, -25), 1.0)
	tree(Vector3(2, TERRACE, -25.5), 0.9)
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
	entities.add_child(keeper)
