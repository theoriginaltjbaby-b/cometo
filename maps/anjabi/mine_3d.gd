extends MapBuilder3D
## Anjabi / Collapsed Mine (location 04) in 3D. Replaces the 2D mine.tscn with the
## same layout at 20 px = 1 m: stairs down from the Estate in the north-west (6 m
## drop), a fenced inner yard under the cliff holding the sealed mine door, an outer
## yard with wash-house and sheds, the old spur line and its washout to the east,
## the path east toward the airpad, and the cliff drop to the south.
## Units: metres, +X east, -Z north (2D y -> Z), ground at y 0.

const TOP := 6.0
const TRENCH_FLOOR := -2.5
## Washout: x range and z range of the cut in the ground.
const TR_X0 := 37.2
const TR_X1 := 44.8
const TR_Z0 := 15.0
const TR_Z1 := 17.0


func _ready() -> void:
	_materials()
	SettlementKit.materials(self)
	_environment()
	_ground()
	_walls_and_fences()
	_mine_door()
	_buildings()
	_rails_and_puzzle()
	_props()
	_people()
	_interactables()
	reflection_probe(Vector3(25, 5, 18), Vector3(44, 16, 36))
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var ferns: Array[Transform3D] = []
	for i in 60:
		var side := rng.randi() % 3
		var p := Vector3(rng.randf_range(10.5, 44.5), 0, 34.0 + rng.randf() * 0.4)
		if side == 1:
			p = Vector3(rng.randf_range(10.5, 21.0), 0, 5.6 + rng.randf() * 0.6)
		elif side == 2:
			p = Vector3(5.9 + rng.randf() * 0.4, 0, rng.randf_range(13, 33))
		ferns.append(xform(p, rng.randf() * TAU, rng.randf_range(0.8, 1.4)))
	scatter("fern", ferns)
	for p: Vector3 in [Vector3(14.6, 0, 29.6), Vector3(31.0, 0, 20.4), Vector3(9.0, 0, 24.0)]:
		model("barrel", p)
	model("crate_stack", Vector3(16.5, 0, 25.6), 0.4)


func _ground() -> void:
	# yard floor, with the washout cut out of it
	slab(Vector3(5.6, -1, 0), Vector3(45, 0, TR_Z0), M.gravel)
	slab(Vector3(5.6, -1, TR_Z1), Vector3(45, 0, 35.2), M.paving)
	slab(Vector3(5.6, -1, TR_Z0), Vector3(TR_X0, 0, TR_Z1), M.paving)
	slab(Vector3(TR_X1, -1, TR_Z0), Vector3(45, 0, TR_Z1), M.paving)
	# the washout itself
	slab(Vector3(TR_X0, TRENCH_FLOOR - 1, TR_Z0), Vector3(TR_X1, TRENCH_FLOOR, TR_Z1), M.rock_dark)
	slab(Vector3(TR_X0, TRENCH_FLOOR, TR_Z0 - 0.05), Vector3(TR_X1, 0, TR_Z0), M.rock, false)
	slab(Vector3(TR_X0, TRENCH_FLOOR, TR_Z1), Vector3(TR_X1, 0, TR_Z1 + 0.05), M.rock, false)
	var water := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(TR_X1 - TR_X0, TR_Z1 - TR_Z0)
	water.mesh = pm
	water.material_override = M.sea
	water.position = Vector3((TR_X0 + TR_X1) * 0.5, TRENCH_FLOOR + 0.3, (TR_Z0 + TR_Z1) * 0.5)
	add_child(water)
	# mud paths: haul road, wash-house apron, path east, stair foot
	slab(Vector3(22.7, 0, 12.5), Vector3(25.3, 0.02, 34.5), M.mud, false)
	slab(Vector3(22.8, 0, 5.3), Vector3(25.2, 0.02, 12.5), M.mud, false)
	slab(Vector3(7.5, 0, 29.2), Vector3(22.6, 0.02, 31.2), M.mud, false)
	slab(Vector3(25.4, 0, 31.3), Vector3(45, 0.02, 33.1), M.mud, false)
	slab(Vector3(5.8, 0, 12.5), Vector3(22.6, 0.02, 14.6), M.mud, false)
	# the cliff drop beyond the south fence, and mist below
	slab(Vector3(0, -30, 35.2), Vector3(50, -0.5, 36.5), M.rock_dark)
	var mist := MeshInstance3D.new()
	var mp := PlaneMesh.new()
	mp.size = Vector2(300, 200)
	mist.mesh = mp
	mist.material_override = M.sea
	mist.position = Vector3(24, -24, 120)
	add_child(mist)


func _walls_and_fences() -> void:
	# rock: north cliff over the yard, west wall, the Estate ledge and stair cut
	slab(Vector3(-10, -1, -6), Vector3(60, 12, 0), M.rock)
	slab(Vector3(10, -1, 0), Vector3(60, 9, 5.3), M.rock)
	slab(Vector3(-10, -1, 0), Vector3(6.1, 10, 12.6), M.rock)
	slab(Vector3(-10, -1, 12.6), Vector3(5.6, 8, 36), M.rock)
	slab(Vector3(45, -1, 5.3), Vector3(60, 8, 36), M.rock)
	slab(Vector3(45, 8, 5.3), Vector3(60, 8.1, 36), M.moss, false)
	slab(Vector3(-10, 10, 0), Vector3(6.1, 10.1, 12.6), M.moss, false)
	# the Estate landing at the top of the stairs, then the stairs down
	slab(Vector3(6.1, -1, 0), Vector3(9.95, TOP, 2.0), M.stone)
	stairs(Vector3(8.0, 0, 12.6), Vector3(0, 0, -1), TOP, 10.6, 3.85, M.stone)
	slab(Vector3(9.95, -1, 2.0), Vector3(10.2, TOP + 1.0, 5.3), M.rock)
	blocker(Vector3(9.95, 0, 5.3), Vector3(10.05, TOP + 2.0, 12.6))
	# inner yard fence: west side, front with the gate, east to the corner
	fence(Vector3(10.1, 0, 5.3), Vector3(10.1, 0, 12.5))
	fence(Vector3(10.1, 0, 12.5), Vector3(22.5, 0, 12.5))
	fence(Vector3(25.5, 0, 12.5), Vector3(37.0, 0, 12.5))
	fence(Vector3(37.0, 0, 12.5), Vector3(37.0, 0, 15.0))
	# the gate: closed, solid
	box(Vector3(24, 1.0, 12.5), Vector3(3.0, 2.0, 0.14), M.steel_dark, true)
	for i in 6:
		box(Vector3(22.75 + i * 0.5, 1.15, 12.42), Vector3(0.5, 0.28, 0.04), M.warning if i % 2 == 0 else M.steel_dark, false)
	for x: float in [22.4, 25.6]:
		box(Vector3(x, 1.2, 12.5), Vector3(0.2, 2.4, 0.2), M.steel, false)
	# south fence at the cliff edge, east wall
	railing(Vector3(5.6, 0, 34.5), Vector3(45, 0, 34.5), M.timber)
	# washout: blockers so nobody walks into it; the middle one goes when bridged
	blocker(Vector3(36.9, 0, TR_Z0), Vector3(39.2, 2.0, TR_Z1))
	blocker(Vector3(40.8, 0, TR_Z0), Vector3(TR_X1, 2.0, TR_Z1))


func _mine_door() -> void:
	# timber frame set into the cliff face, steel door welded shut
	var z := 5.3
	slab(Vector3(21.5, 0, z - 0.3), Vector3(26.5, 4.4, z), M.rock_dark, false)
	# timber portal, barred gate and sign (director's key art) in front of the welded door
	model("mine_portal", Vector3(24, 0, z + 0.55))
	warm_light(Vector3(22.05, 3.5, z + 1.3), 1.0, 5.0)
	warm_light(Vector3(25.95, 3.5, z + 1.3), 1.0, 5.0)
	sign_text(Vector3(24, 5.75, z + 1.5), "ANJABI MINE", 0.0, 46, Color(0.9, 0.78, 0.55))
	sign_text(Vector3(24, 5.25, z + 1.5), "LEVELS I–IV", 0.0, 28, Color(0.85, 0.72, 0.5))
	sign_text(Vector3(24.75, 4.75, z + 1.62), "CLOSED", 0.0, 36, Color(1.0, 0.85, 0.75))
	box(Vector3(24, 1.8, z + 0.05), Vector3(4.0, 3.6, 0.12), M.steel, true)
	box(Vector3(24, 1.8, z + 0.12), Vector3(0.05, 3.6, 0.04), M.steel_dark, false)
	# the bright weld bead round the frame
	var weld := _mat(Color(0.9, 0.85, 0.7), 0.3, 0.8, Color(0.6, 0.55, 0.4), 0.4)
	box(Vector3(24, 3.62, z + 0.13), Vector3(4.0, 0.05, 0.03), weld, false)
	box(Vector3(24, 0.05, z + 0.13), Vector3(4.0, 0.05, 0.03), weld, false)
	for x: float in [22.02, 25.98]:
		box(Vector3(x, 1.8, z + 0.13), Vector3(0.05, 3.6, 0.03), weld, false)
	# stacked rescue stretchers, still wrapped
	var wrap := _mat(Color(0.82, 0.8, 0.72), 0.7)
	for i in 3:
		box(Vector3(26.9, 0.12 + i * 0.16, 6.2), Vector3(0.7, 0.14, 2.0), wrap, i == 0, 0.08 * i)


func _shed(center: Vector3, size: Vector3, _m: Material, lit := false, _door_side := 1.0) -> void:
	shed(center, size)
	if lit:
		warm_light(Vector3(center.x + size.x * 0.22, size.y * 0.6, center.z + size.z * 0.5 + 1.0), 1.3, 6.0)


func _buildings() -> void:
	_shed(Vector3(11.5, 0, 27.4), Vector3(6.0, 3.0, 3.6), M.panel, true)  # wash-house
	box(Vector3(11.5, 2.6, 30.0), Vector3(6.4, 0.08, 1.8), M.canvas_teal, false)  # awning
	for x: float in [8.6, 14.4]:
		box(Vector3(x, 1.3, 30.8), Vector3(0.08, 2.6, 0.08), M.steel_dark, false)
	_shed(Vector3(10.0, 0, 21.0), Vector3(3.0, 2.6, 3.0), M.panel_violet)  # store shed
	_shed(Vector3(32.0, 0, 22.4), Vector3(2.8, 2.6, 3.0), M.panel_violet)  # winch house
	cyl(Vector3(33.8, 0, 22.4), 0.5, 0.5, 1.0, M.rust, true, 10)
	_shed(Vector3(29.5, 0, 14.4), Vector3(2.5, 2.7, 2.6), M.panel, true)  # guard hut
	_shed(Vector3(12.5, 0, 9.0), Vector3(2.6, 2.6, 2.6), M.concrete)  # pump shed
	# junction box on the pump shed's east side, breaker pulled
	box(Vector3(13.86, 1.3, 10.0), Vector3(0.12, 0.7, 0.5), M.steel, false)
	box(Vector3(13.95, 1.35, 10.0), Vector3(0.05, 0.12, 0.2), M.warning, false)


func _rail_line(points: PackedVector3Array) -> void:
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		var d := (b - a)
		var side := d.cross(Vector3.UP).normalized() * 0.35
		beam(a + side + Vector3(0, 0.02, 0), b + side + Vector3(0, 0.02, 0), 0.08, 0.07, M.steel)
		beam(a - side + Vector3(0, 0.02, 0), b - side + Vector3(0, 0.02, 0), 0.08, 0.07, M.steel)
		var n := int(a.distance_to(b) / 0.6)
		for j in n:
			var p := a.lerp(b, (j + 0.5) / n)
			box(p + Vector3(0, 0.02, 0), Vector3(1.1, 0.05, 0.22), M.timber, false, atan2(d.x, d.z))


func _rails_and_puzzle() -> void:
	var main := PackedVector3Array([Vector3(40, 0, 28.75), Vector3(40, 0, 22)])
	var a := PackedVector3Array([Vector3(40, 0, 22), Vector3(41.3, 0, 20.6), Vector3(43.4, 0, 19.2), Vector3(43.4, 0, 18.1)])
	var b := PackedVector3Array([Vector3(40, 0, 22), Vector3(40, 0, TR_Z1 + 0.1)])
	_rail_line(main)
	_rail_line(a)
	_rail_line(b)
	# rails still reach a little way out over the gap from the north side
	_rail_line(PackedVector3Array([Vector3(40, 0, TR_Z0 - 0.2), Vector3(40, 0, 12.6)]))
	for p: Vector3 in [Vector3(40, 0, 29.9), Vector3(43.4, 0, 17.4)]:
		box(p + Vector3(0, 0.35, 0), Vector3(1.2, 0.3, 0.25), M.canvas, true)  # buffers
	var gap := blocker(Vector3(39.2, 0, TR_Z0), Vector3(40.8, 2.0, TR_Z1))
	var lever := TrackSwitch3D.new()
	lever.name = "Lever"
	lever.position = Vector3(38.6, 0, 22.4)
	entities.add_child(lever)
	var cart := OreCart3D.new()
	cart.name = "OreCart"
	cart.rail_main = main
	cart.rail_a = a
	cart.rail_b = b
	cart.bridge_position = Vector3(40, 0, (TR_Z0 + TR_Z1) * 0.5)
	cart.gap_blocker = gap.get_child(0) as CollisionShape3D
	cart.dialogue_buffer = "anjabi/cart_buffer"
	cart.dialogue_bridge = "anjabi/cart_bridge"
	cart.on_bridged = [{"objective": "quiet_mine.way_in"}, {"reveal": "quiet_mine.door"}]
	entities.add_child(cart)


func _props() -> void:
	lamp(Vector3(21.9, 0, 13.4))  # gate
	lamp(Vector3(18.5, 0, 29.8))  # wash-house
	lamp(Vector3(10.6, 0, 13.6))  # stair foot
	lamp(Vector3(19.6, 0, 8.8), false)  # yard lamp, dark since the power cut
	lamp(Vector3(42.0, 0, 31.0))  # path east
	for p: Vector3 in [Vector3(28.0, 0, 29.7), Vector3(15.0, 0, 23.2), Vector3(33.0, 0, 7.2)]:
		box(p + Vector3(0, 0.4, 0), Vector3(1.1, 0.8, 1.1), M.timber)
		box(p + Vector3(0.9, 0.3, 0.2), Vector3(0.7, 0.6, 0.7), M.timber)
	# puddles
	var water := _mat(Color(0.2, 0.27, 0.33), 0.05, 0.4)
	for p: Vector3 in [Vector3(23.6, 0, 23.5), Vector3(24.6, 0, 18), Vector3(23.5, 0, 31), Vector3(32, 0, 32.2),
			Vector3(16.5, 0, 30.3), Vector3(15, 0, 8.5), Vector3(32, 0, 10), Vector3(41, 0, 13.5), Vector3(8, 0, 13.6)]:
		var mi := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.6
		cm.bottom_radius = 0.6
		cm.height = 0.02
		cm.radial_segments = 16
		cm.rings = 0
		mi.mesh = cm
		mi.material_override = water
		mi.position = p + Vector3(0, 0.03, 0)
		mi.scale = Vector3(1.0, 1.0, 0.6)
		add_child(mi)
	for p: Vector3 in [Vector3(7.5, 0, 21), Vector3(6.8, 0, 33), Vector3(30, 0, 20.2), Vector3(35, 0, 19.2),
			Vector3(36, 0, 29.8), Vector3(42.8, 0, 30.3), Vector3(46, 8, 7.5), Vector3(46.5, 8, 11.2),
			Vector3(46, 8, 15), Vector3(47.2, 8, 19), Vector3(46, 8, 22.6), Vector3(47, 8, 26.2),
			Vector3(46, 8, 30), Vector3(47.2, 8, 33.6), Vector3(2, 10, 4), Vector3(3, 10, 9), Vector3(1, 8, 20), Vector3(2.5, 8, 28)]:
		tree(p, 1.1 if p.y == 0 else 1.4)
		if p.y == 0:
			blocker(p + Vector3(-0.2, 0, -0.2), p + Vector3(0.2, 1.5, 0.2))


func _npc(n: String, d: String, at: Vector3, coat: Color, accent: Color, skin: Color, hood := false, look := {}) -> void:
	var npc := Npc3D.new()
	npc.name = n.replace(" ", "")
	npc.display_name = n
	npc.dialogue_id = d
	npc.coat = coat
	npc.accent = accent
	npc.skin = skin
	npc.hood = hood
	npc.position = at
	npc.yaw_deg = 180.0
	npc.look = look
	entities.add_child(npc)


func _people() -> void:
	_npc("Driller", "anjabi/driller", Vector3(16.8, 0, 30.0), Color(0.42, 0.33, 0.27), Color(0.8, 0.5, 0.18), Color(0.62, 0.45, 0.36), false,
			{"hat": "hardhat", "satchel": false, "hair_color": Color(0.2, 0.18, 0.16)})
	_npc("Gate guard", "anjabi/guard", Vector3(26.4, 0, 13.3), Color(0.24, 0.3, 0.36), Color(0.75, 0.75, 0.7), Color(0.8, 0.64, 0.52), true,
			{"satchel": false, "long_coat": true})
	# two miners at the portal, as in the key art
	townsfolk([Vector3(21.6, 0, 7.4)], Color(0.4, 0.36, 0.28), Color(0.7, 0.55, 0.2), Color(0.66, 0.5, 0.4), false, 120.0,
			{"hat": "hardhat", "satchel": false})
	townsfolk([Vector3(23.0, 0, 8.1)], Color(0.3, 0.33, 0.36), Color(0.6, 0.6, 0.55), Color(0.5, 0.36, 0.27), false, 250.0,
			{"hat": "hardhat", "satchel": false})


func _look(n: String, prompt: String, label: String, dialogue: String, at: Vector3, enabled_if := {}) -> Interactable3D:
	var it := Interactable3D.new()
	it.name = n
	it.prompt = prompt
	it.label = label
	it.dialogue_id = dialogue
	it.enabled_if = enabled_if
	it.position = at
	add_child(it)
	return it


func _interactables() -> void:
	# the closure notice, cable-tied to the fence by the gate
	box(Vector3(21.25, 1.2, 12.42), Vector3(0.7, 0.5, 0.03), M.concrete, false)
	_look("Notice", "Read", "Notice", "anjabi/notice", Vector3(21.25, 1.0, 12.9))
	_look("MineDoor", "Examine", "Mine door", "anjabi/door", Vector3(24, 1.0, 5.9))
	_look("JunctionBox", "Examine", "Junction box", "anjabi/junction", Vector3(14.3, 1.0, 10.0))
	_look("Trench", "Look", "Washout", "anjabi/trench", Vector3(40, 0.6, 17.6), {"not": {"flag": "anjabi.cart", "eq": "trench"}})
	_look("CliffEdge", "Look", "Cliff edge", "anjabi/cliff_edge", Vector3(24, 1.0, 34.1))
	var up := MapExit3D.new()
	up.name = "StairsToSteps"
	up.prompt = "Climb"
	up.label = "Stairs up to the Steps"
	up.target_map = "anjabi_town"
	up.target_spawn = "mine"
	up.position = Vector3(8, TOP + 0.8, 0.6)
	add_child(up)
	var east := MapExit3D.new()
	east.name = "PathToAirpad"
	east.prompt = "Walk"
	east.label = "Path to the airpad"
	east.target_map = "anjabi_town"
	east.target_spawn = "airpad"
	east.position = Vector3(44.4, 0.8, 32.2)
	add_child(east)
