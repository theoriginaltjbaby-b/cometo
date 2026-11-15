class_name Figure3D
extends Node3D
## PROVISIONAL ART. A person built from primitive meshes, about 1.65 m and four
## heads tall, facing -Z. Procedural walk and idle animation through limb pivots.
## Keep set_motion() as the interface when an authored, rigged model replaces it.

var coat := Color(0.35, 0.4, 0.45)
var accent := Color(0.7, 0.45, 0.2)
var skin := Color(0.78, 0.6, 0.48)
var hood := false
## Look options (see configure()): hair "short" | "bun" | "long" | "bald";
## hat "" | "cap" | "hardhat" | "brim"; long_coat, apron, satchel.
var hair := "short"
var hair_color := Color(0.12, 0.08, 0.06)
var hat := ""
var long_coat := false
var apron := false
var satchel := true
## Draw a faint silhouette wherever the figure is hidden behind scenery (player only).
var xray := false


func configure(look: Dictionary) -> void:
	for k: String in look:
		set(k, look[k])


var _hips: Node3D
var _leg_l: Node3D
var _leg_r: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _torso: Node3D
var _phase := 0.0
var _amount := 0.0
var _speed := 0.0
var _t := 0.0


func _ready() -> void:
	var coat_m := _mat(coat, 0.85)
	var dark_m := _mat(coat.darkened(0.3), 0.9)
	var skin_m := _mat(skin, 0.7)
	var boot_m := _mat(Color(0.1, 0.09, 0.09), 0.6)
	var accent_m := _mat(accent, 0.6, 0.3)
	_hips = Node3D.new()
	_hips.position.y = 0.82
	add_child(_hips)
	_leg_l = _limb(_hips, Vector3(-0.1, 0, 0), 0.075, 0.8, dark_m, boot_m)
	_leg_r = _limb(_hips, Vector3(0.1, 0, 0), 0.075, 0.8, dark_m, boot_m)
	_torso = Node3D.new()
	_hips.add_child(_torso)
	# coat skirt, chest, belt
	var skirt := CylinderMesh.new()
	skirt.top_radius = 0.19
	skirt.bottom_radius = 0.27
	var skirt_h := 0.66 if long_coat else 0.5
	skirt.height = skirt_h
	skirt.bottom_radius = 0.29 if long_coat else 0.27
	skirt.radial_segments = 12
	_part(_torso, skirt, coat_m, Vector3(0, 0.2 - skirt_h * 0.5, 0.01), Vector3(1, 1, 0.85))
	var hem := CylinderMesh.new()
	hem.top_radius = 0.272
	hem.bottom_radius = 0.272
	hem.height = 0.04
	hem.radial_segments = 12
	hem.top_radius = skirt.bottom_radius + 0.003
	hem.bottom_radius = hem.top_radius
	_part(_torso, hem, dark_m, Vector3(0, 0.2 - skirt_h + 0.01, 0.01), Vector3(1, 1, 0.85))
	# lapels and buttons down the front
	var lap := BoxMesh.new()
	lap.size = Vector3(0.07, 0.3, 0.02)
	_part(_torso, lap, dark_m, Vector3(-0.055, 0.45, -0.152)).rotation.z = -0.35
	_part(_torso, lap, dark_m, Vector3(0.055, 0.45, -0.152)).rotation.z = 0.35
	var btn := SphereMesh.new()
	btn.radius = 0.014
	btn.height = 0.028
	var btn_m := _mat(Color(0.75, 0.6, 0.3), 0.4, 0.8)
	for k in 3:
		_part(_torso, btn, btn_m, Vector3(0.0, 0.32 - k * 0.11, -0.158))
	if apron:
		var ap := BoxMesh.new()
		ap.size = Vector3(0.3, 0.55, 0.02)
		_part(_torso, ap, _mat(Color(0.72, 0.66, 0.55), 0.9), Vector3(0, -0.02, -0.2)).rotation.x = 0.1
	var chest := CapsuleMesh.new()
	chest.radius = 0.19
	chest.height = 0.6
	_part(_torso, chest, coat_m, Vector3(0, 0.36, 0), Vector3(1, 1, 0.78))
	var belt := CylinderMesh.new()
	belt.top_radius = 0.2
	belt.bottom_radius = 0.2
	belt.height = 0.05
	_part(_torso, belt, accent_m, Vector3(0, 0.18, 0))
	var collar := CylinderMesh.new()
	collar.top_radius = 0.11
	collar.bottom_radius = 0.17
	collar.height = 0.1
	_part(_torso, collar, accent_m, Vector3(0, 0.6, 0))
	# shoulders, scarf, satchel and strap
	var sh := SphereMesh.new()
	sh.radius = 0.1
	sh.height = 0.16
	_part(_torso, sh, coat_m, Vector3(-0.21, 0.55, 0))
	_part(_torso, sh, coat_m, Vector3(0.21, 0.55, 0))
	var scarf := BoxMesh.new()
	scarf.size = Vector3(0.09, 0.26, 0.04)
	_part(_torso, scarf, accent_m, Vector3(0.06, 0.45, -0.165), Vector3.ONE).rotation.z = 0.12
	var bag_m := _mat(Color(0.3, 0.2, 0.13), 0.8)
	if not satchel:
		bag_m = null
	var bag := BoxMesh.new()
	bag.size = Vector3(0.08, 0.2, 0.24)
	if satchel:
		_part(_torso, bag, bag_m, Vector3(0.27, 0.06, 0.02))
		var strap := BoxMesh.new()
		strap.size = Vector3(0.04, 0.62, 0.02)
		var st := _part(_torso, strap, bag_m, Vector3(0.03, 0.35, -0.155))
		st.rotation.z = -0.62
		var st2 := _part(_torso, strap, bag_m, Vector3(0.03, 0.35, 0.155))
		st2.rotation.z = -0.62
	_arm_l = _limb(_torso, Vector3(-0.25, 0.53, 0), 0.06, 0.56, coat_m, skin_m)
	_arm_r = _limb(_torso, Vector3(0.25, 0.53, 0), 0.06, 0.56, coat_m, skin_m)
	_head()
	for pivot: Node3D in [_torso, _leg_l, _leg_r, _arm_l, _arm_r]:
		_merge(pivot)


## Collapses the primitive parts under one limb pivot into a single mesh with the
## colours in vertex colours: one surface for cloth and skin, one for metal fittings.
## Emissive parts stay separate. Turns ~50 draws per figure into ~6.
func _merge(pivot: Node3D) -> void:
	var groups := {}
	for c in pivot.get_children():
		var mi := c as MeshInstance3D
		if mi == null:
			continue
		var m := mi.material_override as StandardMaterial3D
		if m == null or m.emission_enabled:
			continue
		var key := "metal" if m.metallic > 0.5 else "matte"
		if not groups.has(key):
			groups[key] = []
		(groups[key] as Array).append(mi)
	if groups.is_empty():
		return
	var mesh := ArrayMesh.new()
	for key: String in groups:
		var verts := PackedVector3Array()
		var norms := PackedVector3Array()
		var cols := PackedColorArray()
		var idx := PackedInt32Array()
		for mi: MeshInstance3D in groups[key]:
			var a := mi.mesh.surface_get_arrays(0)
			var x := mi.transform
			var nb := x.basis.inverse().transposed()
			var col := (mi.material_override as StandardMaterial3D).albedo_color
			var base := verts.size()
			var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
			var n: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
			for i in v.size():
				verts.append(x * v[i])
				norms.append((nb * n[i]).normalized())
				cols.append(col)
			var ii: PackedInt32Array = a[Mesh.ARRAY_INDEX]
			if ii.is_empty():
				for i in v.size():
					idx.append(base + i)
			else:
				for i in ii:
					idx.append(base + i)
			mi.queue_free()
			pivot.remove_child(mi)
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = verts
		arr[Mesh.ARRAY_NORMAL] = norms
		arr[Mesh.ARRAY_COLOR] = cols
		arr[Mesh.ARRAY_INDEX] = idx
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		var mat := _mat(Color.WHITE, 0.4 if key == "metal" else 0.78, 0.7 if key == "metal" else 0.05)
		mat.vertex_color_use_as_albedo = true
		mat.vertex_color_is_srgb = true
		mesh.surface_set_material(mesh.get_surface_count() - 1, mat)
	var merged := MeshInstance3D.new()
	merged.name = "Merged"
	merged.mesh = mesh
	pivot.add_child(merged)


func _head() -> void:
	var skin_m := _mat(skin, 0.7)
	var hair_m := _mat(hair_color, 0.75)
	var neck := CylinderMesh.new()
	neck.top_radius = 0.06
	neck.bottom_radius = 0.07
	neck.height = 0.1
	_part(_torso, neck, skin_m, Vector3(0, 0.66, 0))
	var head := SphereMesh.new()
	head.radius = 0.17
	head.height = 0.37
	_part(_torso, head, skin_m, Vector3(0, 0.82, 0), Vector3(0.95, 1, 1))
	# face: eye whites and pupils, brows, nose, mouth, a little colour in the cheeks
	var white := SphereMesh.new()
	white.radius = 0.028
	white.height = 0.04
	var pupil := SphereMesh.new()
	pupil.radius = 0.017
	pupil.height = 0.026
	var white_m := _mat(Color(0.92, 0.9, 0.86), 0.5)
	var pupil_m := _mat(Color(0.07, 0.05, 0.05), 0.3)
	var brow := BoxMesh.new()
	brow.size = Vector3(0.055, 0.012, 0.012)
	for sx: float in [-1.0, 1.0]:
		_part(_torso, white, white_m, Vector3(sx * 0.058, 0.835, -0.148))
		_part(_torso, pupil, pupil_m, Vector3(sx * 0.058, 0.833, -0.166))
		_part(_torso, brow, hair_m, Vector3(sx * 0.06, 0.875, -0.152)).rotation.z = -sx * 0.12
		var cheek := SphereMesh.new()
		cheek.radius = 0.03
		cheek.height = 0.02
		_part(_torso, cheek, _mat(skin.lerp(Color(0.85, 0.4, 0.38), 0.35), 0.8), Vector3(sx * 0.095, 0.79, -0.135))
	var nose := SphereMesh.new()
	nose.radius = 0.022
	nose.height = 0.04
	_part(_torso, nose, _mat(skin.darkened(0.08), 0.7), Vector3(0, 0.8, -0.168))
	var mouth := BoxMesh.new()
	mouth.size = Vector3(0.045, 0.01, 0.01)
	_part(_torso, mouth, _mat(skin.darkened(0.35), 0.7), Vector3(0, 0.755, -0.158))
	if hood:
		var h := SphereMesh.new()
		h.radius = 0.2
		h.height = 0.43
		_part(_torso, h, _mat(coat, 0.85), Vector3(0, 0.84, 0.04), Vector3(1, 1, 0.95))
		var peak := BoxMesh.new()
		peak.size = Vector3(0.33, 0.045, 0.09)
		_part(_torso, peak, _mat(coat, 0.85), Vector3(0, 0.98, -0.14)).rotation.x = 0.35
		return
	if hair != "bald":
		var cap := SphereMesh.new()
		cap.radius = 0.178
		cap.height = 0.24
		cap.is_hemisphere = true
		_part(_torso, cap, hair_m, Vector3(0, 0.85, 0.012), Vector3(0.97, 1, 1))
		var back := SphereMesh.new()
		back.radius = 0.17
		back.height = 0.3
		_part(_torso, back, hair_m, Vector3(0, 0.81, 0.04), Vector3(0.97, 1, 0.9))
		var fringe := BoxMesh.new()
		fringe.size = Vector3(0.24, 0.05, 0.05)
		_part(_torso, fringe, hair_m, Vector3(0, 0.93, -0.13)).rotation.x = -0.4
	if hair == "bun":
		var bun := SphereMesh.new()
		bun.radius = 0.075
		bun.height = 0.15
		_part(_torso, bun, hair_m, Vector3(0, 0.93, 0.15))
	elif hair == "long":
		var fall := BoxMesh.new()
		fall.size = Vector3(0.28, 0.32, 0.08)
		_part(_torso, fall, hair_m, Vector3(0, 0.66, 0.11))
	match hat:
		"cap":
			var crown := CylinderMesh.new()
			crown.top_radius = 0.16
			crown.bottom_radius = 0.18
			crown.height = 0.1
			var m := _mat(accent.darkened(0.3), 0.85)
			_part(_torso, crown, m, Vector3(0, 0.96, 0))
			var bill := BoxMesh.new()
			bill.size = Vector3(0.22, 0.02, 0.12)
			_part(_torso, bill, m, Vector3(0, 0.93, -0.2))
		"hardhat":
			var shell := SphereMesh.new()
			shell.radius = 0.2
			shell.height = 0.22
			shell.is_hemisphere = true
			var y := _mat(Color(0.85, 0.62, 0.12), 0.45)
			_part(_torso, shell, y, Vector3(0, 0.9, 0))
			var rim := CylinderMesh.new()
			rim.top_radius = 0.235
			rim.bottom_radius = 0.235
			rim.height = 0.025
			_part(_torso, rim, y, Vector3(0, 0.9, 0))
			var lamp := CylinderMesh.new()
			lamp.top_radius = 0.035
			lamp.bottom_radius = 0.035
			lamp.height = 0.04
			var lm := _mat(Color(1.0, 0.9, 0.6), 0.3)
			lm.emission_enabled = true
			lm.emission = Color(1.0, 0.85, 0.5)
			lm.emission_energy_multiplier = 2.0
			_part(_torso, lamp, lm, Vector3(0, 0.98, -0.19)).rotation.x = PI * 0.5
		"brim":
			var m2 := _mat(Color(0.14, 0.12, 0.11), 0.85)
			var brim := CylinderMesh.new()
			brim.top_radius = 0.28
			brim.bottom_radius = 0.28
			brim.height = 0.02
			_part(_torso, brim, m2, Vector3(0, 0.92, 0))
			var crown2 := CylinderMesh.new()
			crown2.top_radius = 0.14
			crown2.bottom_radius = 0.16
			crown2.height = 0.14
			_part(_torso, crown2, m2, Vector3(0, 0.99, 0))


func set_motion(moving: bool, speed_ratio: float = 1.0) -> void:
	_speed = clampf(speed_ratio, 0.0, 1.2) if moving else 0.0


func _process(delta: float) -> void:
	_t += delta
	_amount = move_toward(_amount, 1.0 if _speed > 0.05 else 0.0, delta * 6.0)
	_phase += delta * 10.0 * maxf(_speed, 0.4) * _amount
	var s := sin(_phase) * _amount
	_leg_l.rotation.x = s * 0.6
	_leg_r.rotation.x = -s * 0.6
	_arm_l.rotation.x = -s * 0.5
	_arm_r.rotation.x = s * 0.5
	_arm_l.rotation.z = -0.08
	_arm_r.rotation.z = 0.08
	var breathe := sin(_t * 2.0) * 0.012 * (1.0 - _amount)
	_hips.position.y = 0.82 + absf(cos(_phase)) * 0.04 * _amount
	_torso.rotation.x = -0.08 * _amount
	_torso.scale = Vector3(1.0, 1.0 + breathe, 1.0)


func _limb(parent: Node3D, at: Vector3, r: float, length: float, m: Material, end_m: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = at
	parent.add_child(pivot)
	var c := CylinderMesh.new()
	c.top_radius = r * 1.15
	c.bottom_radius = r * 0.85
	c.height = length - r
	c.radial_segments = 8
	_part(pivot, c, m, Vector3(0, -length * 0.5 + r * 0.25, 0))
	var joint := SphereMesh.new()
	joint.radius = r * 1.15
	joint.height = r * 2.3
	_part(pivot, joint, m, Vector3.ZERO)
	if end_m.get_meta("boot", false):
		var b := BoxMesh.new()
		b.size = Vector3(r * 2.2, r * 1.4, r * 3.6)
		_part(pivot, b, end_m, Vector3(0, -length + r * 0.5, -r * 0.7))
		var cuff := CylinderMesh.new()
		cuff.top_radius = r * 1.25
		cuff.bottom_radius = r * 1.15
		cuff.height = r * 2.6
		cuff.radial_segments = 8
		_part(pivot, cuff, end_m, Vector3(0, -length + r * 1.9, 0))
	else:
		var sp := SphereMesh.new()
		sp.radius = r * 1.05
		sp.height = r * 2.1
		_part(pivot, sp, end_m, Vector3(0, -length + r * 0.6, 0))
	return pivot


func _part(parent: Node3D, mesh: Mesh, m: Material, at: Vector3, s: Vector3 = Vector3.ONE) -> MeshInstance3D:
	_lower_poly(mesh)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = at
	mi.scale = s
	parent.add_child(mi)
	return mi


## Godot's primitive defaults (64 segments, 32 rings) cost thousands of triangles per
## eye or button; at handheld scale a few segments read the same. Caps what was not set.
func _lower_poly(mesh: Mesh) -> void:
	var big := 0.0
	if mesh is SphereMesh:
		var sm := mesh as SphereMesh
		big = sm.radius
		sm.radial_segments = mini(sm.radial_segments, 16 if big > 0.1 else (10 if big > 0.04 else 6))
		sm.rings = mini(sm.rings, 10 if big > 0.1 else (6 if big > 0.04 else 4))
	elif mesh is CylinderMesh:
		var cm := mesh as CylinderMesh
		big = maxf(cm.top_radius, cm.bottom_radius)
		cm.radial_segments = mini(cm.radial_segments, 14 if big > 0.15 else (10 if big > 0.04 else 6))
		cm.rings = 0
	elif mesh is CapsuleMesh:
		var cp := mesh as CapsuleMesh
		cp.radial_segments = mini(cp.radial_segments, 12)
		cp.rings = mini(cp.rings, 4)


func _mat(c: Color, rough: float, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	if xray:
		m.stencil_mode = BaseMaterial3D.STENCIL_MODE_XRAY
		m.stencil_color = Color(1.0, 0.72, 0.35, 0.5)
	if c.v < 0.12:
		m.set_meta("boot", true)
	return m
