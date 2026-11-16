class_name SettlementKit
## The settlement art direction as reusable pieces (PROJECT_LOG entry 20): weathered
## ashlar, dusty-rose and ochre plaster, indigo slate, verdigris and aged brass, warm
## windows, striped canvas, climbing plants, and the quiet technology of an old
## spacefaring culture (armillary instruments, star-chart terminals, brass inlays).
## Every function builds into a MapBuilder3D `b`; plain primitives are merged by
## b.merge_static(), so a whole street costs a handful of draws.

const STONE_WALL := preload("res://art/shaders/stone_wall.gdshader")
const INLAY := preload("res://art/shaders/compass_inlay.gdshader")


## Adds the kit's materials to b.M (once per map).
static func materials(b: MapBuilder3D) -> void:
	if b.M.has("ashlar"):
		return
	var M: Dictionary = b.M
	M.ashlar = wall_mat(Color(0.54, 0.47, 0.45))
	M.ashlar_dark = wall_mat(Color(0.4, 0.35, 0.36))
	M.plaster_rose = _m(Color(0.66, 0.46, 0.44), 0.9)
	M.plaster_ochre = _m(Color(0.68, 0.53, 0.36), 0.9)
	M.plaster_teal = _m(Color(0.36, 0.5, 0.5), 0.9)
	M.slate = _m(Color(0.2, 0.19, 0.3), 0.7, 0.1)
	M.verdigris = _m(Color(0.3, 0.55, 0.5), 0.55, 0.35)
	M.brass = _m(Color(0.66, 0.48, 0.24), 0.35, 0.85)
	M.brass_dark = _m(Color(0.36, 0.25, 0.14), 0.45, 0.8)
	M.copper_pipe = _m(Color(0.52, 0.3, 0.2), 0.45, 0.7)
	M.wood_warm = _m(Color(0.34, 0.2, 0.13), 0.8)
	M.canvas_rose = _m(Color(0.56, 0.2, 0.24), 0.95)
	M.canvas_cream = _m(Color(0.82, 0.72, 0.6), 0.95)
	M.canvas_teal2 = _m(Color(0.18, 0.4, 0.42), 0.95)
	M.rug = _m(Color(0.45, 0.16, 0.18), 1.0)
	M.interior = _m(Color(0.16, 0.09, 0.07), 0.9, 0.0, Color(1.0, 0.55, 0.25), 0.55)
	M.window_warm = _m(Color(1.0, 0.75, 0.42), 0.3, 0.0, Color(1.0, 0.64, 0.3), 2.6)
	M.window_dark = _m(Color(0.1, 0.1, 0.16), 0.2, 0.3)
	M.lantern_glass = _m(Color(1.0, 0.82, 0.5), 0.3, 0.0, Color(1.0, 0.72, 0.36), 3.0)
	M.screen = _m(Color(0.2, 0.8, 0.85), 0.3, 0.0, Color(0.25, 0.85, 0.95), 2.4)
	M.core = _m(Color(1.0, 0.7, 0.45), 0.2, 0.0, Color(1.0, 0.62, 0.35), 5.0)
	M.leaf = _m(Color(0.2, 0.36, 0.2), 0.9)
	M.blossom = _m(Color(0.92, 0.9, 0.86), 0.8, 0.0, Color(0.9, 0.88, 0.85), 0.25)
	M.lavender = _m(Color(0.55, 0.4, 0.78), 0.85)
	M.pot = _m(Color(0.6, 0.36, 0.24), 0.8)
	b.M.stone = M.ashlar


static func wall_mat(c: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = STONE_WALL
	m.set_shader_parameter("base_color", c)
	m.set_shader_parameter("noise_tex", MapBuilder3D.detail_textures()[0])
	return m


static func _m(c: Color, rough: float, metal := 0.0, emit := Color.BLACK, emit_e := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	if emit_e > 0.0:
		m.emission_enabled = true
		m.emission = emit
		m.emission_energy_multiplier = emit_e
	return m


## A primitive mesh placed with a transform, visual only.
static func mesh(b: Node3D, m: Mesh, mat: Material, x: Transform3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	mi.transform = x
	b.add_child(mi)
	return mi


static func torus(r: float, t: float) -> TorusMesh:
	var tm := TorusMesh.new()
	tm.inner_radius = r - t
	tm.outer_radius = r + t
	tm.rings = 24
	tm.ring_segments = 6
	return tm


# --- landmarks ------------------------------------------------------------------

## The plaza's brass compass rose set into the paving (walkable, no collider).
static func compass_inlay(b: MapBuilder3D, at: Vector3, radius: float) -> void:
	var c := CylinderMesh.new()
	c.top_radius = radius
	c.bottom_radius = radius
	c.height = 0.02
	c.radial_segments = 40
	c.rings = 0
	var m := ShaderMaterial.new()
	m.shader = INLAY
	m.set_shader_parameter("radius", radius)
	var mi := MeshInstance3D.new()
	mi.mesh = c
	mi.material_override = m
	mi.position = at + Vector3(0, 0.012, 0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	b.add_child(mi)


## An armillary sphere of aged brass on a fluted stone column; its rings turn slowly
## round a glowing core. `s` scales the whole instrument.
static func armillary(b: MapBuilder3D, at: Vector3, column_h := 2.4, s := 1.0) -> void:
	b.cyl(at, 0.55, 0.7, 0.35, b.M.ashlar)
	b.cyl(at + Vector3(0, 0.35, 0), 0.3, 0.36, column_h - 0.6, b.M.ashlar)
	b.cyl(at + Vector3(0, column_h - 0.25, 0), 0.5, 0.34, 0.25, b.M.brass, false, 12)
	var top := at + Vector3(0, column_h + 0.85 * s, 0)
	var spin := Spinner.new()
	spin.position = top
	b.add_child(spin)
	for k in 3:
		var r := (0.82 - k * 0.12) * s
		var ring := MeshInstance3D.new()
		ring.mesh = torus(r, 0.035 * s)
		ring.material_override = b.M.brass
		ring.rotation = [Vector3(PI * 0.5, 0, 0), Vector3(PI * 0.5, PI * 0.5, 0), Vector3(0.41, 0, 0)][k]
		spin.add_child(ring)
	var band := MeshInstance3D.new()
	band.mesh = torus(0.95 * s, 0.05 * s)
	band.material_override = b.M.brass_dark
	band.position = top
	band.rotation = Vector3(0.41, 0, 0.2)
	b.add_child(band)
	var core := SphereMesh.new()
	core.radius = 0.2 * s
	core.height = 0.4 * s
	core.radial_segments = 12
	core.rings = 6
	mesh(b, core, b.M.core, Transform3D(Basis(), top))
	b.warm_light(top + Vector3(0, 0.2, 0), 1.6, 7.0)


# --- architecture ---------------------------------------------------------------

## Stone balustrade from a to c (any slope): base course, pillars every ~1.8 m, a brass
## handrail, and a 1.3 m collider. Lantern caps on the end posts if `lanterns`.
static func balustrade(b: MapBuilder3D, a: Vector3, c: Vector3, lanterns := false) -> void:
	var d := c - a
	var flat := Vector2(d.x, d.z).length()
	var n := maxi(1, roundi(flat / 1.8))
	var yaw := atan2(d.x, d.z)
	for i in n + 1:
		var p := a.lerp(c, float(i) / n)
		b.box(p + Vector3(0, 0.5, 0), Vector3(0.34, 1.0, 0.34), b.M.ashlar, false, yaw)
		b.box(p + Vector3(0, 1.05, 0), Vector3(0.42, 0.1, 0.42), b.M.ashlar_dark, false, yaw)
		if lanterns and (i == 0 or i == n):
			lantern(b, p + Vector3(0, 1.1, 0))
	for i in n:
		var p := a.lerp(c, (i + 0.5) / n)
		var q0 := a.lerp(c, float(i) / n)
		var q1 := a.lerp(c, float(i + 1) / n)
		# balusters
		for k in 4:
			var bp := q0.lerp(q1, (k + 1.0) / 5.0)
			b.cyl(bp, 0.06, 0.08, 0.85, b.M.ashlar, false, 6)
		b.beam(q0 + Vector3(0, 0.85, 0), q1 + Vector3(0, 0.85, 0), 0.08, 0.2, b.M.ashlar_dark)
		b.beam(q0 + Vector3(0, 0.93, 0), q1 + Vector3(0, 0.93, 0), 0.05, 0.06, b.M.brass)
		b.beam(q0, q1, 0.12, 0.3, b.M.ashlar)
	b.beam(a, c, 1.3, 0.3, null, true)


## A small lantern: brass cage, warm glass, cap. Visual only.
static func lantern(b: MapBuilder3D, at: Vector3, s := 1.0) -> void:
	b.box(at + Vector3(0, 0.05, 0) * s, Vector3(0.22, 0.06, 0.22) * s, b.M.brass_dark, false)
	b.box(at + Vector3(0, 0.22, 0) * s, Vector3(0.17, 0.26, 0.17) * s, b.M.lantern_glass, false)
	var cap := PrismMesh.new()
	cap.size = Vector3(0.26, 0.14, 0.26) * s
	mesh(b, cap, b.M.brass_dark, Transform3D(Basis(), at + Vector3(0, 0.42, 0) * s))


## A lantern on an iron bracket out from a wall facing `out` (unit, horizontal).
static func wall_lantern(b: MapBuilder3D, at: Vector3, out: Vector3, light := true) -> void:
	b.beam(at, at + out * 0.45, 0.04, 0.04, b.M.brass_dark)
	lantern(b, at + out * 0.45 + Vector3(0, -0.45, 0))
	if light:
		b.warm_light(at + out * 0.6 + Vector3(0, -0.2, 0), 0.9, 5.0)


## One arcade bay on a wall face: stone pilasters, a voussoir ring, a warm shopfront
## recessed behind (door and lit windows), a striped awning and a lantern. `x` is the
## bay centre on a wall facing +Z at z = `face`, standing on `y`.
static func arcade_bay(b: MapBuilder3D, x: float, face: float, y: float, w: float, stripes: Array, lit := true) -> void:
	var open_w := w * 0.62
	var r := open_w * 0.5
	var spring := y + 1.75
	# shopfront panel behind the arch: dark warm interior with glowing windows
	b.box(Vector3(x, y + 1.2, face + 0.03), Vector3(open_w, 2.4, 0.06), b.M.interior, false)
	var disc := CylinderMesh.new()
	disc.top_radius = r
	disc.bottom_radius = r
	disc.height = 0.06
	disc.radial_segments = 16
	disc.rings = 0
	mesh(b, disc, b.M.interior, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(x, spring, face + 0.03)))
	b.box(Vector3(x - open_w * 0.22, y + 1.0, face + 0.07), Vector3(open_w * 0.28, 1.0, 0.04), b.M.window_warm if lit else b.M.window_dark, false)
	b.box(Vector3(x + open_w * 0.2, y + 0.95, face + 0.08), Vector3(open_w * 0.3, 1.9, 0.05), b.M.wood_warm, false)
	b.box(Vector3(x + open_w * 0.31, y + 0.95, face + 0.11), Vector3(0.05, 0.05, 0.04), b.M.brass, false)
	# arch ring and pilasters
	var ring := torus(r + 0.12, 0.13)
	mesh(b, ring, b.M.ashlar_dark, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(x, spring, face + 0.1)))
	b.box(Vector3(x, spring + r + 0.18, face + 0.14), Vector3(0.26, 0.34, 0.12), b.M.ashlar, false)
	for s: float in [-1.0, 1.0]:
		b.box(Vector3(x + s * w * 0.5, y + 1.5, face + 0.16), Vector3(0.36, 3.0, 0.32), b.M.ashlar, false)
	# striped awning sloping out over the shopfront
	var n := stripes.size() * 2
	for i in n:
		var sx := x - open_w * 0.6 + (i + 0.5) * open_w * 1.2 / n
		var strip := b.box(Vector3(sx, spring + 0.25, face + 0.6), Vector3(open_w * 1.2 / n + 0.01, 0.04, 1.1), stripes[i % stripes.size()], false)
		strip.rotation.x = 0.38
	if lit:
		wall_lantern(b, Vector3(x, spring + r + 0.5, face + 0.2), Vector3(0, 0, 1), false)


## A market stall facing +Z (turned by yaw): counter with goods, four poles, striped
## canopy, a rug in front, a hanging lantern. Solid counter.
static func stall(b: MapBuilder3D, at: Vector3, yaw: float, stripes: Array, goods := "wares") -> void:
	var basis := Basis(Vector3.UP, yaw)
	var P := func(v: Vector3) -> Vector3: return at + basis * v
	b.box(P.call(Vector3(0, 0.45, 0)), Vector3(2.6, 0.9, 1.0), b.M.wood_warm, true, yaw)
	b.box(P.call(Vector3(0, 0.92, 0.05)), Vector3(2.7, 0.06, 1.1), b.M.timber, false, yaw)
	for sx: float in [-1.25, 1.25]:
		for sz: float in [-0.6, 0.55]:
			b.cyl(P.call(Vector3(sx, 0, sz)), 0.045, 0.05, 2.4 if sz < 0 else 2.1, b.M.timber, false, 6)
	var n := stripes.size() * 3
	for i in n:
		var sx := -1.4 + (i + 0.5) * 2.8 / n
		var strip := b.box(P.call(Vector3(sx, 2.28, 0.0)), Vector3(2.8 / n + 0.01, 0.04, 1.6), stripes[i % stripes.size()], false, yaw)
		strip.rotation = Vector3(0.2, yaw, 0)
	b.box(P.call(Vector3(0, 0.01, 1.4)), Vector3(2.4, 0.02, 1.4), b.M.rug, false, yaw)
	lantern(b, P.call(Vector3(0.9, 1.75, 0.6)), 0.9)
	b.warm_light(P.call(Vector3(0.9, 1.9, 1.0)), 1.2, 5.0)
	match goods:
		"instruments":
			# a small armillary on the counter, brass dishes, a chart case
			for k in 2:
				var tr := MeshInstance3D.new()
				tr.mesh = torus(0.22, 0.015)
				tr.material_override = b.M.brass
				tr.position = P.call(Vector3(-0.7, 1.22, 0))
				tr.rotation = Vector3(PI * 0.5 * k, yaw + 0.6 * k, 0.3)
				b.add_child(tr)
			b.cyl(P.call(Vector3(-0.7, 0.95, 0)), 0.06, 0.09, 0.05, b.M.brass_dark, false, 8)
			b.cyl(P.call(Vector3(0.1, 0.95, 0.1)), 0.18, 0.18, 0.04, b.M.brass, false, 12)
			b.box(P.call(Vector3(0.6, 1.0, -0.15)), Vector3(0.5, 0.12, 0.35), b.M.wood_warm, false, yaw)
		_:
			for k in 4:
				b.cyl(P.call(Vector3(-1.0 + k * 0.6, 0.95, 0.1 * (k % 2))), 0.14, 0.1, 0.24, b.M.pot, false, 8)
			b.box(P.call(Vector3(0.9, 1.06, -0.2)), Vector3(0.5, 0.28, 0.4), b.M.timber, false, yaw + 0.2)
	# crates beside it
	b.box(P.call(Vector3(1.75, 0.3, -0.1)), Vector3(0.6, 0.6, 0.6), b.M.timber, true, yaw + 0.3)
	b.box(P.call(Vector3(1.7, 0.75, -0.1)), Vector3(0.45, 0.3, 0.45), b.M.wood_warm, false, yaw + 0.1)


## A terraced townhouse facing +Z: an ashlar ground floor with an arched door, plaster
## upper floors with arched windows (some lit), an optional balcony, and a roof
## ("pitched" slate, or "dome" of verdigris). Solid. Returns the door point.
static func townhouse(b: MapBuilder3D, base: Vector3, w: float, d: float, floors: int, plaster: Material, roof := "pitched", seed := 1) -> Vector3:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var fh := 2.6
	var h := fh * floors
	var front := base.z + d * 0.5
	b.box(base + Vector3(0, fh * 0.5, 0), Vector3(w, fh, d), b.M.ashlar)
	if floors > 1:
		b.box(base + Vector3(0, fh + (h - fh) * 0.5, 0), Vector3(w - 0.1, h - fh, d - 0.1), plaster)
	# string course between the floors
	for f in range(1, floors):
		b.box(base + Vector3(0, f * fh, d * 0.5 + 0.06), Vector3(w + 0.1, 0.14, 0.14), b.M.ashlar_dark, false)
	# door: timber in an arched stone surround
	var dx := -w * 0.25 + rng.randf_range(-0.3, 0.3)
	b.box(Vector3(base.x + dx, base.y + 1.05, front + 0.03), Vector3(1.1, 2.1, 0.06), b.M.wood_warm, false)
	var ring := torus(0.62, 0.1)
	mesh(b, ring, b.M.ashlar_dark, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(base.x + dx, base.y + 2.05, front + 0.06)))
	b.box(Vector3(base.x + dx + 0.38, base.y + 1.05, front + 0.08), Vector3(0.05, 0.05, 0.04), b.M.brass, false)
	b.box(Vector3(base.x + dx, base.y + 0.06, front + 0.4), Vector3(1.4, 0.12, 0.7), b.M.ashlar_dark, false)
	# ground-floor window
	_window(b, Vector3(base.x + w * 0.22, base.y + 1.3, front), 0.9, 1.2, rng.randf() < 0.75)
	# upper windows
	for f in range(1, floors):
		var count := maxi(1, int(w / 2.0))
		for i in count:
			var wx := base.x - w * 0.5 + (i + 0.5) * w / count
			var wy := base.y + f * fh + 1.2
			_window(b, Vector3(wx, wy, front), 0.8, 1.25, rng.randf() < 0.6)
			# window box with flowers
			if rng.randf() < 0.6:
				b.box(Vector3(wx, wy - 0.7, front + 0.18), Vector3(0.9, 0.18, 0.28), b.M.pot, false)
				b.box(Vector3(wx, wy - 0.55, front + 0.18), Vector3(0.8, 0.16, 0.2), b.M.lavender if rng.randf() < 0.5 else b.M.leaf, false)
	# balcony on the second floor
	if floors >= 3 and rng.randf() < 0.8:
		var by := base.y + fh * 2
		b.box(Vector3(base.x, by + 0.05, front + 0.55), Vector3(w * 0.6, 0.12, 1.1), b.M.ashlar_dark, false)
		b.beam(Vector3(base.x - w * 0.3, by, front + 1.08), Vector3(base.x + w * 0.3, by, front + 1.08), 0.95, 0.04, b.M.brass_dark)
		b.box(Vector3(base.x, by + 0.95, front + 1.08), Vector3(w * 0.6, 0.05, 0.08), b.M.brass, false)
	# roof
	var top := base.y + h
	if roof == "dome":
		b.box(Vector3(base.x, top + 0.2, base.z), Vector3(w + 0.2, 0.4, d + 0.2), b.M.ashlar_dark, false)
		var dm := b.dome(Vector3(base.x, top + 0.4, base.z), minf(w, d) * 0.42, b.M.verdigris, 1.0)
		dm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		# ribs and a brass finial
		for k in 4:
			var rib := torus(minf(w, d) * 0.42, 0.04)
			var mi := mesh(b, rib, b.M.brass_dark, Transform3D(Basis(Vector3.UP, k * PI * 0.25) * Basis(Vector3.RIGHT, PI * 0.5), Vector3(base.x, top + 0.4, base.z)))
			mi.scale = Vector3(1, 1, 1)
		b.cyl(Vector3(base.x, top + 0.4 + minf(w, d) * 0.42, base.z), 0.03, 0.08, 0.7, b.M.brass, false, 6)
	else:
		var pr := PrismMesh.new()
		pr.size = Vector3(w + 0.5, 1.8, d + 0.4)
		# gable end to the street, slopes to the sides
		mesh(b, pr, b.M.slate, Transform3D(Basis(), Vector3(base.x, top + 0.9, base.z)))
		b.box(Vector3(base.x + w * 0.3, top + 1.3, base.z - d * 0.15), Vector3(0.5, 1.4, 0.5), b.M.ashlar, false)
	# copper downpipe
	b.box(Vector3(base.x + w * 0.5 - 0.15, base.y + h * 0.5, front + 0.12), Vector3(0.1, h, 0.1), b.M.copper_pipe, false)
	return Vector3(base.x + dx, base.y, front + 0.9)


static func _window(b: MapBuilder3D, c: Vector3, w: float, h: float, lit: bool) -> void:
	b.box(c + Vector3(0, 0, 0.03), Vector3(w, h, 0.05), b.M.window_warm if lit else b.M.window_dark, false)
	var ring := torus(w * 0.5, 0.06)
	mesh(b, ring, b.M.ashlar_dark, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), c + Vector3(0, h * 0.5 - w * 0.1, 0.05)))
	b.box(c + Vector3(0, 0, 0.07), Vector3(0.04, h, 0.03), b.M.brass_dark, false)
	b.box(c + Vector3(0, -h * 0.5 - 0.05, 0.1), Vector3(w + 0.2, 0.08, 0.16), b.M.ashlar_dark, false)


## Things left by a front door: a pot of lavender, boots, a crate or a broom.
static func doorstep(b: MapBuilder3D, at: Vector3, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	pot(b, at + Vector3(-0.9, 0, -0.1), "lavender" if rng.randf() < 0.5 else "leaf")
	if rng.randf() < 0.6:
		for s: float in [-0.08, 0.08]:
			b.box(at + Vector3(0.75 + s, 0.09, -0.2), Vector3(0.1, 0.18, 0.24), b.M.wood_warm, false, 0.2)
	if rng.randf() < 0.5:
		b.box(at + Vector3(1.05, 0.22, -0.35), Vector3(0.45, 0.44, 0.4), b.M.timber, false, rng.randf())
	else:
		b.cyl(at + Vector3(1.0, 0, -0.45), 0.02, 0.02, 1.2, b.M.timber, false, 4)


## A clay pot with lavender or a leafy plant.
static func pot(b: MapBuilder3D, at: Vector3, kind := "lavender", s := 1.0) -> void:
	b.cyl(at, 0.24 * s, 0.17 * s, 0.4 * s, b.M.pot, false, 10)
	if kind == "lavender":
		for k in 5:
			var a := k * TAU / 5.0
			b.cyl(at + Vector3(cos(a) * 0.1, 0.4, sin(a) * 0.1) * s, 0.025 * s, 0.01 * s, 0.5 * s, b.M.lavender, false, 4)
	else:
		var sp := SphereMesh.new()
		sp.radius = 0.3 * s
		sp.height = 0.45 * s
		sp.radial_segments = 8
		sp.rings = 4
		mesh(b, sp, b.M.leaf, Transform3D(Basis(), at + Vector3(0, 0.55 * s, 0)))


## A bench of timber slats on stone feet, facing +Z turned by yaw. Solid.
static func bench(b: MapBuilder3D, at: Vector3, yaw: float) -> void:
	var bs := Basis(Vector3.UP, yaw)
	for sx: float in [-0.85, 0.85]:
		b.box(at + bs * Vector3(sx, 0.22, 0), Vector3(0.25, 0.44, 0.5), b.M.ashlar, false, yaw)
	for k in 3:
		b.box(at + bs * Vector3(0, 0.47, -0.16 + k * 0.16), Vector3(2.1, 0.05, 0.13), b.M.wood_warm, false, yaw)
	b.box(at + bs * Vector3(0, 0.8, -0.3), Vector3(2.1, 0.35, 0.06), b.M.wood_warm, false, yaw)
	b.box(at + Vector3(0, 0.4, 0), Vector3(2.2, 0.8, 0.6), null, true, yaw)


## A public terminal: a stone housing with a brass frame and a softly glowing star
## chart screen. Examinable.
static func terminal(b: MapBuilder3D, at: Vector3, yaw: float, dialogue_id: String) -> void:
	var bs := Basis(Vector3.UP, yaw)
	b.box(at + Vector3(0, 0.7, 0), Vector3(0.9, 1.4, 0.6), b.M.ashlar, true, yaw)
	b.box(at + bs * Vector3(0, 1.45, 0.05), Vector3(1.0, 0.12, 0.7), b.M.ashlar_dark, false, yaw)
	var scr := b.box(at + bs * Vector3(0, 1.05, 0.32), Vector3(0.66, 0.5, 0.04), b.M.screen, false, yaw)
	scr.rotation.x = -0.25
	b.box(at + bs * Vector3(0, 1.05, 0.3), Vector3(0.78, 0.62, 0.04), b.M.brass_dark, false, yaw)
	b.box(at + bs * Vector3(0, 0.62, 0.34), Vector3(0.6, 0.06, 0.18), b.M.brass, false, yaw)
	var l := OmniLight3D.new()
	l.position = at + bs * Vector3(0, 1.1, 0.7)
	l.light_color = Color(0.4, 0.85, 1.0)
	l.light_energy = 0.8
	l.omni_range = 3.0
	b.add_child(l)
	var it := Interactable3D.new()
	it.prompt = "Look"
	it.label = "Terminal"
	it.dialogue_id = dialogue_id
	it.radius = 1.3
	it.position = at + bs * Vector3(0, 0.9, 0.7)
	b.add_child(it)


## A string of small lights hanging between two points with a sag. One MultiMesh.
static func string_lights(b: MapBuilder3D, a: Vector3, c: Vector3, sag: float, count := 11) -> void:
	var xs: Array[Transform3D] = []
	var prev := a
	for i in count + 1:
		var t := float(i) / count
		var p := a.lerp(c, t) + Vector3(0, -sag * 4.0 * t * (1.0 - t), 0)
		if i > 0:
			b.beam(prev - Vector3(0, 0.01, 0), p - Vector3(0, 0.01, 0), 0.015, 0.015, b.M.brass_dark)
		if i > 0 and i < count:
			xs.append(Transform3D(Basis(), p + Vector3(0, -0.08, 0)))
		prev = p
	var sp := SphereMesh.new()
	sp.radius = 0.035
	sp.height = 0.07
	sp.radial_segments = 6
	sp.rings = 3
	sp.material = b.M.lantern_glass
	b.multimesh_cells(sp, xs, false, "string_lights")


## Climbing and trailing plants along a wall top from a to c, hanging down the face
## (facing `out`): leaf clusters and white blossom. Two MultiMeshes.
static func vines(b: MapBuilder3D, a: Vector3, c: Vector3, out: Vector3, drop: float, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var leaves: Array[Transform3D] = []
	var blooms: Array[Transform3D] = []
	var n := int(a.distance_to(c) * 6.0)
	for i in n:
		var p := a.lerp(c, rng.randf()) + out * rng.randf_range(0.02, 0.2)
		var hang := rng.randf() * drop * rng.randf()
		var q := p + Vector3(0, -hang, 0)
		var s := rng.randf_range(0.12, 0.26)
		leaves.append(Transform3D(Basis(Vector3(rng.randf(), rng.randf(), rng.randf()).normalized(), rng.randf() * TAU).scaled(Vector3(s, s * 0.6, s)), q))
		if rng.randf() < 0.45:
			blooms.append(Transform3D(Basis().scaled(Vector3.ONE * rng.randf_range(0.5, 0.9)), q + out * 0.08))
	var leaf := SphereMesh.new()
	leaf.radius = 0.5
	leaf.height = 1.0
	leaf.radial_segments = 5
	leaf.rings = 3
	leaf.material = b.M.leaf
	b.multimesh_cells(leaf, leaves, false, "vine_leaves")
	var bloom := SphereMesh.new()
	bloom.radius = 0.05
	bloom.height = 0.1
	bloom.radial_segments = 5
	bloom.rings = 2
	bloom.material = b.M.blossom
	b.multimesh_cells(bloom, blooms, false, "vine_blooms")


# --- the wider world --------------------------------------------------------------

## The world beyond the settlement, far to the north: a plateau with gothic spires and
## lit windows, an aqueduct across the valley, a citadel on a far ridge. Unshaded
## silhouettes already hazed by distance, so fog and light cost nothing; beyond the
## gameplay camera's far plane, so only the arrival shot ever draws them.
static func skyline(b: MapBuilder3D, center: Vector3) -> void:
	var near_m := _flat(Color(0.12, 0.1, 0.17))
	var mid_m := _flat(Color(0.22, 0.18, 0.28))
	var far_m := _flat(Color(0.34, 0.27, 0.38))
	var lit := _flat(Color(1.0, 0.72, 0.4))
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var root := Node3D.new()
	root.name = "Skyline"
	b.add_child(root)
	# valley floor and the plateau edges
	_sb(root, center + Vector3(0, -30, -330), Vector3(1400, 2, 520), near_m)
	_sb(root, center + Vector3(-260, 0, -300), Vector3(300, 70, 120), mid_m)
	_sb(root, center + Vector3(240, 10, -420), Vector3(360, 90, 140), far_m)
	_sb(root, center + Vector3(-10, -10, -470), Vector3(900, 60, 80), far_m)
	# spires on the near plateau
	for i in 9:
		var x := -380.0 + rng.randf() * 260.0
		var h := rng.randf_range(30.0, 85.0)
		var p := center + Vector3(x, 35, -300 + rng.randf_range(-40, 40))
		_sb(root, p + Vector3(0, h * 0.5, 0), Vector3(rng.randf_range(6, 12), h, rng.randf_range(6, 12)), mid_m)
		_cone(root, p + Vector3(0, h, 0), rng.randf_range(3, 6), rng.randf_range(12, 26), mid_m)
		for k in 4:
			if rng.randf() < 0.7:
				_sb(root, p + Vector3(rng.randf_range(-2, 2), rng.randf_range(4, h - 4), 7), Vector3(1.2, 1.8, 0.5), lit)
	# the citadel on the far ridge, right
	for i in 7:
		var p := center + Vector3(180 + i * 22 + rng.randf_range(-6, 6), 55, -400)
		var h := rng.randf_range(20.0, 70.0) * (1.6 if i == 3 else 1.0)
		_sb(root, p + Vector3(0, h * 0.5, 0), Vector3(14, h, 14), far_m)
		_cone(root, p + Vector3(0, h, 0), 7, 22 if i == 3 else 12, far_m)
		_sb(root, p + Vector3(0, h * 0.6, 8), Vector3(2, 3, 0.5), lit)
	# the aqueduct across the valley
	var ay := 22.0
	for i in 16:
		var x := -120.0 + i * 18.0
		_sb(root, center + Vector3(x, ay * 0.5 - 30, -250), Vector3(4, ay + 30, 6), near_m)
	_sb(root, center + Vector3(15, ay, -250), Vector3(300, 5, 7), near_m)
	_sb(root, center + Vector3(15, ay - 8, -250), Vector3(300, 2, 6.5), near_m)
	# scattered lights of a far settlement in the valley
	for i in 40:
		_sb(root, center + Vector3(rng.randf_range(-300, 320), -26 + rng.randf() * 6, rng.randf_range(-420, -220)), Vector3(1.5, 1.5, 1.5), lit)


static func _flat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c
	m.disable_fog = true
	return m


static func _sb(root: Node3D, c: Vector3, s: Vector3, m: Material) -> void:
	var bm := BoxMesh.new()
	bm.size = s
	var mi := MeshInstance3D.new()
	mi.mesh = bm
	mi.material_override = m
	mi.position = c
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)


static func _cone(root: Node3D, base: Vector3, r: float, h: float, m: Material) -> void:
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = 6
	cm.rings = 0
	var mi := MeshInstance3D.new()
	mi.mesh = cm
	mi.material_override = m
	mi.position = base + Vector3(0, h * 0.5, 0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)


## Turns its children slowly about Y (the armillary's rings).
class Spinner:
	extends Node3D

	func _process(delta: float) -> void:
		rotate_y(delta * 0.12)
		rotate_object_local(Vector3.RIGHT, delta * 0.05)
