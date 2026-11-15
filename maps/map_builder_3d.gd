class_name MapBuilder3D
extends GameMap3D
## Shared toolkit for 3D maps built in code: the material palette `M`, primitives
## (box, slab, cyl, dome, beam, stairs, railing, fence, lamp, tree, sign_text) and the
## Anjabi night-rain environment. PROVISIONAL: authored meshes replace the pieces,
## the footprints and colliders stay.

var M := {}

static var _detail: NoiseTexture2D
static var _detail_n: NoiseTexture2D


## Shared surface detail: a seamless noise for albedo variation and a matching
## normal map, applied world-space triplanar so every box and slab lines up.
static func detail_textures() -> Array:
	if _detail == null:
		var n := FastNoiseLite.new()
		n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		n.frequency = 0.03
		n.fractal_octaves = 5
		n.fractal_gain = 0.55
		var g := Gradient.new()
		g.set_color(0, Color(0.6, 0.6, 0.6))
		g.set_color(1, Color(1.05, 1.05, 1.05))
		_detail = NoiseTexture2D.new()
		_detail.width = 256
		_detail.height = 256
		_detail.seamless = true
		_detail.noise = n
		_detail.color_ramp = g
		_detail_n = NoiseTexture2D.new()
		_detail_n.width = 256
		_detail_n.height = 256
		_detail_n.seamless = true
		_detail_n.as_normal_map = true
		_detail_n.bump_strength = 4.0
		_detail_n.noise = n
	return [_detail, _detail_n]


static func add_detail(m: StandardMaterial3D, scale := 0.4) -> void:
	var t := detail_textures()
	m.albedo_texture = t[0]
	m.normal_enabled = true
	m.normal_texture = t[1]
	m.normal_scale = 0.8
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(scale, scale, scale)


# --- materials ------------------------------------------------------------------

const WET_GROUND := preload("res://art/shaders/wet_ground.gdshader")


## Wet ground material (art/shaders/wet_ground.gdshader).
static func ground_mat(c: Color, cobble := 1.0, wet := 0.8, puddles := 0.55, vertex_color := false) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = WET_GROUND
	m.set_shader_parameter("base_color", c)
	m.set_shader_parameter("cobble", cobble)
	m.set_shader_parameter("wetness", wet)
	m.set_shader_parameter("puddles", puddles)
	m.set_shader_parameter("use_vertex_color", vertex_color)
	m.set_shader_parameter("noise_tex", detail_textures()[0])
	return m


func _materials() -> void:
	M.paving = ground_mat(Color(0.42, 0.4, 0.38))
	M.paving_light = ground_mat(Color(0.5, 0.48, 0.45), 1.0, 0.7, 0.3)
	M.stone = _mat(Color(0.36, 0.35, 0.33), 0.8)
	M.rock = _mat(Color(0.2, 0.23, 0.25), 0.95)
	M.rock_dark = _mat(Color(0.13, 0.15, 0.17), 0.95)
	M.moss = ground_mat(Color(0.16, 0.26, 0.17), 0.0, 0.5, 0.15)
	M.concrete = _mat(Color(0.47, 0.47, 0.44), 0.85)
	M.steel = _mat(Color(0.33, 0.35, 0.37), 0.45, 0.6)
	M.steel_dark = _mat(Color(0.17, 0.18, 0.2), 0.5, 0.6)
	M.copper = _mat(Color(0.3, 0.5, 0.45), 0.5, 0.55)
	M.copper_raw = _mat(Color(0.62, 0.36, 0.22), 0.4, 0.75)
	M.panel = _mat(Color(0.42, 0.45, 0.42), 0.7, 0.2)
	M.panel_violet = _mat(Color(0.33, 0.29, 0.36), 0.75, 0.15)
	M.timber = _mat(Color(0.22, 0.15, 0.11), 0.85)
	M.canvas = _mat(Color(0.45, 0.17, 0.17), 0.95)
	M.canvas_teal = _mat(Color(0.2, 0.33, 0.33), 0.95)
	M.window = _mat(Color(1.0, 0.72, 0.38), 0.3, 0.0, Color(1.0, 0.62, 0.28), 2.2)
	M.lamp = _mat(Color(1.0, 0.8, 0.5), 0.3, 0.0, Color(1.0, 0.7, 0.35), 4.0)
	M.warning = _mat(Color(0.8, 0.6, 0.12), 0.6)
	M.sand = _mat(Color(0.55, 0.5, 0.42), 0.9)
	M.sea = ShaderMaterial.new()
	M.sea.shader = preload("res://art/shaders/sea.gdshader")
	M.sea.set_shader_parameter("noise_tex", detail_textures()[0])
	M.foliage = _mat(Color(0.08, 0.2, 0.15), 0.9)
	M.foliage_b = _mat(Color(0.11, 0.24, 0.16), 0.9)
	M.trunk = _mat(Color(0.18, 0.13, 0.1), 0.9)
	M.mesh_fence = _mat(Color(0.25, 0.27, 0.3, 0.45), 0.6, 0.4)
	M.mesh_fence.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	M.mud = ground_mat(Color(0.3, 0.26, 0.22), 0.0, 0.95, 0.75)
	M.gravel = ground_mat(Color(0.4, 0.39, 0.37), 0.0, 0.75, 0.45)
	M.rust = _mat(Color(0.48, 0.27, 0.17), 0.7, 0.5)
	M.blue_light = _mat(Color(0.4, 0.6, 1.0), 0.3, 0.0, Color(0.35, 0.55, 1.0), 3.0)


func _mat(c: Color, rough: float, metal: float = 0.0, emit: Color = Color.BLACK, emit_e: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	if emit_e > 0.0:
		m.emission_enabled = true
		m.emission = emit
		m.emission_energy_multiplier = emit_e
	elif rough >= 0.6 and c.a >= 0.99:
		add_detail(m)
	return m


# --- primitives -------------------------------------------------------------------

func _body() -> StaticBody3D:
	var b := StaticBody3D.new()
	b.collision_layer = 1
	b.collision_mask = 0
	return b


## An authored model from res://art/models (exported from art/source/*.blend).
## Models face +Z (south, toward the camera). Visual only; add colliders separately.
func model(model_name: String, at: Vector3, yaw := 0.0, s: Variant = 1.0) -> Node3D:
	var n := (load("res://art/models/%s.glb" % model_name) as PackedScene).instantiate() as Node3D
	n.position = at
	n.rotation.y = yaw
	n.scale = s if s is Vector3 else Vector3(s, s, s)
	weather_model(n)
	add_child(n)
	return n


## The shed model (native 4 m wide, 3 m tall, 3 m deep) stretched to `size`
## (width, height, depth), standing on `base`, door and window facing +Z, with a box collider.
func shed(base: Vector3, size: Vector3, yaw := 0.0, solid := true) -> Node3D:
	var n := model("shed", base, yaw, Vector3(size.x / 4.0, size.y / 3.0, size.z / 3.0))
	if solid:
		box(base + Vector3(0, size.y * 0.5, 0), size, null, true, yaw)
	return n


static var _weathered := {}


## Gives imported model materials the shared surface detail (once per material) and
## makes foliage double-sided. Emissive glass and smooth metal are left alone.
static func weather_model(root: Node) -> void:
	for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var m := mi.mesh.surface_get_material(i) as StandardMaterial3D
			if m == null or _weathered.has(m):
				continue
			_weathered[m] = true
			var nm := m.resource_name.to_lower()
			if "leaf" in nm or "pine" in nm or "petal" in nm:
				m.cull_mode = BaseMaterial3D.CULL_DISABLED
			if m.emission_enabled or m.roughness < 0.55:
				continue
			add_detail(m, 0.6)


static var _mesh_cache := {}


## The first mesh of a model, for batching with scatter().
static func model_mesh(model_name: String) -> Mesh:
	if not _mesh_cache.has(model_name):
		var n := (load("res://art/models/%s.glb" % model_name) as PackedScene).instantiate()
		weather_model(n)
		var mi := n.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
		_mesh_cache[model_name] = mi.mesh
		n.free()
	return _mesh_cache[model_name]


## Many copies of one model as a single MultiMesh draw (ferns, rocks, clutter).
func scatter(model_name: String, xforms: Array[Transform3D], shadows := false) -> void:
	if xforms.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = model_mesh(model_name)
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)


static func xform(at: Vector3, yaw: float, s: float) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(s, s, s)), at)


## A background inhabitant walking `points` (one point = standing).
func townsfolk(points: Array, coat: Color, accent: Color, skin: Color, hood := false, yaw := 180.0, look := {}) -> void:
	var t := Townsfolk.new()
	t.points = PackedVector3Array(points)
	t.coat = coat
	t.accent = accent
	t.skin = skin
	t.hood = hood
	t.yaw_deg = yaw
	t.look = look
	entities.add_child(t)


## Invisible cylinder collider standing on `base`.
func collider_cyl(base: Vector3, r: float, h: float) -> void:
	var b := _body()
	b.position = base + Vector3(0, h * 0.5, 0)
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = r
	shape.height = h
	cs.shape = shape
	b.add_child(cs)
	add_child(b)


## Box by centre and size. solid adds a matching collider.
func box(center: Vector3, size: Vector3, m: Material, solid := true, yaw := 0.0, parent: Node3D = self) -> Node3D:
	var root: Node3D = _body() if solid else Node3D.new()
	root.position = center
	root.rotation.y = yaw
	parent.add_child(root)
	if m != null:
		var mesh := BoxMesh.new()
		mesh.size = size
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = m
		root.add_child(mi)
	if solid:
		var cs := CollisionShape3D.new()
		var s := BoxShape3D.new()
		s.size = size
		cs.shape = s
		root.add_child(cs)
	return root


## Box spanning min..max corners.
func slab(a: Vector3, b: Vector3, m: Material, solid := true) -> Node3D:
	var lo := Vector3(minf(a.x, b.x), minf(a.y, b.y), minf(a.z, b.z))
	var hi := Vector3(maxf(a.x, b.x), maxf(a.y, b.y), maxf(a.z, b.z))
	return box((lo + hi) * 0.5, hi - lo, m, solid)


func cyl(base: Vector3, r_top: float, r_bot: float, h: float, m: Material, solid := true, sides := 16) -> Node3D:
	var root: Node3D = _body() if solid else Node3D.new()
	root.position = base + Vector3(0, h * 0.5, 0)
	add_child(root)
	var mesh := CylinderMesh.new()
	mesh.top_radius = r_top
	mesh.bottom_radius = r_bot
	mesh.height = h
	mesh.radial_segments = sides
	mesh.rings = 1
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	root.add_child(mi)
	if solid:
		var cs := CollisionShape3D.new()
		var s := CylinderShape3D.new()
		s.radius = maxf(r_top, r_bot)
		s.height = h
		cs.shape = s
		root.add_child(cs)
	return root


func dome(center: Vector3, r: float, m: Material, squash := 1.0) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = r
	mesh.height = r
	mesh.is_hemisphere = true
	mesh.radial_segments = 24
	mesh.rings = 8
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = center
	mi.scale = Vector3(1, squash, 1)
	add_child(mi)
	return mi


## Thin oriented box from a to b (walls, beams, rails). Height measured up from a.y.
func beam(a: Vector3, b: Vector3, h: float, t: float, m: Material, solid := false) -> Node3D:
	var d := b - a
	var flat := Vector3(d.x, 0, d.z)
	var n := box((a + b) * 0.5 + Vector3(0, h * 0.5, 0), Vector3(t, h, flat.length()), m, solid, atan2(d.x, d.z))
	return n


## Stairs: bottom front-centre `start`, climbing along `dir` by `rise` over `run`.
## Visible solid steps plus one smooth invisible ramp collider for traversal.
func stairs(start: Vector3, dir: Vector3, rise: float, run: float, width: float, m: Material) -> void:
	dir = dir.normalized()
	var n := maxi(2, int(round(absf(rise) / 0.2)))
	var step_h := rise / n
	var step_d := run / n
	var yaw := atan2(dir.x, dir.z)
	for i in n:
		var top := start.y + step_h * (i + 1)
		var c := start + dir * step_d * (i + 0.5)
		var depth := top - (start.y - 0.4)
		box(Vector3(c.x, top - depth * 0.5, c.z), Vector3(width, depth, step_d + 0.01), m, false, yaw)
	# ramp collider whose surface runs through the step nosings
	var fwd := (dir * run + Vector3.UP * rise).normalized()
	var side := dir.cross(Vector3.UP).normalized()
	var up := side.cross(fwd).normalized()
	var length := Vector3(run, rise, 0).length() + 0.6
	var thick := 0.3
	var body := _body()
	# surface runs exactly from the bottom edge to the top edge; extra length only below
	body.transform = Transform3D(Basis(side, up, -fwd), start + dir * run * 0.5 + Vector3.UP * rise * 0.5 - fwd * 0.3 - up * thick * 0.5)
	var cs := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = Vector3(width, thick, length)
	cs.shape = s
	body.add_child(cs)
	add_child(body)


## Railing from a to b (feet level): posts, top rail, and an invisible 1.3 m wall.
func railing(a: Vector3, b: Vector3, m: Material = null) -> void:
	if m == null:
		m = M.steel_dark
	var len := a.distance_to(b)
	var posts := maxi(1, int(len / 1.6))
	for i in posts + 1:
		var p := a.lerp(b, float(i) / posts)
		box(p + Vector3(0, 0.5, 0), Vector3(0.08, 1.0, 0.08), m, false)
	beam(a + Vector3(0, 0.95, 0), b + Vector3(0, 0.95, 0), 0.06, 0.07, m)
	beam(a + Vector3(0, 0.5, 0), b + Vector3(0, 0.5, 0), 0.04, 0.05, m)
	beam(a, b, 1.3, 0.12, null, true)


func lamp(at: Vector3, with_light := true, _h := 2.6) -> void:
	model("lantern_post", at)
	collider_cyl(at, 0.15, 3.0)
	if with_light:
		var l := OmniLight3D.new()
		l.position = at + Vector3(0, 3.0, 0)
		l.light_color = Color(1.0, 0.6, 0.28)
		l.light_energy = 2.4
		l.omni_range = 8.5
		l.omni_attenuation = 1.6
		add_child(l)


func warm_light(at: Vector3, energy := 1.4, rng := 6.0) -> void:
	var l := OmniLight3D.new()
	l.position = at
	l.light_color = Color(1.0, 0.6, 0.3)
	l.light_energy = energy * 1.3
	l.omni_range = rng
	add_child(l)


func tree(at: Vector3, s := 1.0) -> void:
	model("pine", at, fmod(at.x * 1.7 + at.z * 0.9, TAU), s * 0.9)


func sign_text(at: Vector3, text: String, yaw := 0.0, px := 48, col := Color(0.95, 0.8, 0.55)) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = at
	l.rotation.y = yaw
	l.pixel_size = 0.01
	l.font_size = px
	l.modulate = col
	l.outline_size = 8
	l.outline_modulate = Color(0.05, 0.05, 0.06)
	add_child(l)
	return l


# --- world ----------------------------------------------------------------------

func _environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.06, 0.08, 0.11)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.36, 0.42, 0.55)
	env.ambient_light_energy = 0.75
	env.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.45
	env.tonemap_white = 6.0
	env.glow_enabled = true
	env.glow_intensity = 0.85
	env.glow_strength = 1.1
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 0.85
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.fog_enabled = true
	env.fog_light_color = Color(0.2, 0.25, 0.33)
	env.fog_light_energy = 1.0
	env.fog_density = 0.0055
	env.fog_sky_affect = 0.0
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 1.18
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	# cool storm moonlight with shadows
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-52, -30, 0)
	moon.light_color = Color(0.52, 0.62, 0.86)
	moon.light_energy = 0.7
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 55.0
	add_child(moon)
	# low warm afterglow from the western horizon, no shadows: warm rims on everything
	var glow := DirectionalLight3D.new()
	glow.rotation_degrees = Vector3(-12, -100, 0)
	glow.light_color = Color(1.0, 0.55, 0.35)
	glow.light_energy = 0.4
	glow.light_specular = 0.6
	add_child(glow)


## A once-baked reflection probe so wet ground and glass catch the lamps.
func reflection_probe(center: Vector3, size: Vector3) -> void:
	var p := ReflectionProbe.new()
	p.position = center
	p.size = size
	p.box_projection = true
	p.update_mode = ReflectionProbe.UPDATE_ONCE
	p.intensity = 0.8
	p.max_distance = 60.0
	add_child(p)


## Chain-link fence from a to b: posts, rails, a dark mesh panel, a 2 m invisible wall.
func fence(a: Vector3, b: Vector3, h := 1.8) -> void:
	var len := a.distance_to(b)
	var posts := maxi(1, int(len / 2.0))
	for i in posts + 1:
		var p := a.lerp(b, float(i) / posts)
		box(p + Vector3(0, h * 0.5, 0), Vector3(0.1, h, 0.1), M.steel_dark, false)
	beam(a + Vector3(0, h - 0.05, 0), b + Vector3(0, h - 0.05, 0), 0.06, 0.08, M.steel)
	beam(a + Vector3(0, 0.15, 0), b + Vector3(0, 0.15, 0), h - 0.25, 0.03, M.mesh_fence)
	beam(a, b, 2.0, 0.14, null, true)


## Invisible collider spanning min..max corners.
func blocker(a: Vector3, b: Vector3) -> StaticBody3D:
	return slab(a, b, null, true) as StaticBody3D
