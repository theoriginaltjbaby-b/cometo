class_name Figure3D
extends Node3D
## PROVISIONAL ART. A person built from primitive meshes, about 1.65 m and four
## heads tall, facing -Z. Procedural walk and idle animation through limb pivots.
## Keep set_motion() as the interface when an authored, rigged model replaces it.

var coat := Color(0.35, 0.4, 0.45)
var accent := Color(0.7, 0.45, 0.2)
var skin := Color(0.78, 0.6, 0.48)
var hood := false

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
	skirt.height = 0.5
	skirt.radial_segments = 12
	_part(_torso, skirt, coat_m, Vector3(0, -0.05, 0.01), Vector3(1, 1, 0.85))
	var hem := CylinderMesh.new()
	hem.top_radius = 0.272
	hem.bottom_radius = 0.272
	hem.height = 0.04
	hem.radial_segments = 12
	_part(_torso, hem, dark_m, Vector3(0, -0.29, 0.01), Vector3(1, 1, 0.85))
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
	var bag := BoxMesh.new()
	bag.size = Vector3(0.08, 0.2, 0.24)
	_part(_torso, bag, bag_m, Vector3(0.27, 0.06, 0.02))
	var strap := BoxMesh.new()
	strap.size = Vector3(0.04, 0.62, 0.02)
	var st := _part(_torso, strap, bag_m, Vector3(0.03, 0.35, -0.155))
	st.rotation.z = -0.62
	var st2 := _part(_torso, strap, bag_m, Vector3(0.03, 0.35, 0.155))
	st2.rotation.z = -0.62
	_arm_l = _limb(_torso, Vector3(-0.25, 0.53, 0), 0.06, 0.56, coat_m, skin_m)
	_arm_r = _limb(_torso, Vector3(0.25, 0.53, 0), 0.06, 0.56, coat_m, skin_m)
	# head
	var head := SphereMesh.new()
	head.radius = 0.19
	head.height = 0.4
	_part(_torso, head, skin_m, Vector3(0, 0.81, 0))
	var eye := BoxMesh.new()
	eye.size = Vector3(0.035, 0.035, 0.02)
	var eye_m := _mat(Color(0.06, 0.05, 0.06), 0.5)
	_part(_torso, eye, eye_m, Vector3(-0.065, 0.83, -0.175))
	_part(_torso, eye, eye_m, Vector3(0.065, 0.83, -0.175))
	if hood:
		var h := SphereMesh.new()
		h.radius = 0.22
		h.height = 0.46
		_part(_torso, h, coat_m, Vector3(0, 0.84, 0.035), Vector3(1, 1, 0.95))
		var face := SphereMesh.new()
		face.radius = 0.17
		face.height = 0.34
		_part(_torso, face, skin_m, Vector3(0, 0.8, -0.05))
		var peak := BoxMesh.new()
		peak.size = Vector3(0.36, 0.05, 0.1)
		_part(_torso, peak, coat_m, Vector3(0, 0.98, -0.17)).rotation.x = 0.35
	else:
		var hair := SphereMesh.new()
		hair.radius = 0.2
		hair.height = 0.26
		hair.is_hemisphere = true
		_part(_torso, hair, _mat(Color(0.12, 0.09, 0.08), 0.8), Vector3(0, 0.85, 0.02))


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
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = at
	mi.scale = s
	parent.add_child(mi)
	return mi


func _mat(c: Color, rough: float, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	if c.v < 0.12:
		m.set_meta("boot", true)
	return m
