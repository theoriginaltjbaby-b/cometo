class_name TrackSwitch3D
extends StaticBody3D
## 3D points lever. Flips a GameState flag between "a" and "b"; anything on the
## rails reads that flag. PROVISIONAL ART (primitives).

@export var switch_key := "anjabi.spur_switch"
@export var notify_a := "The points grind across, toward the buffer."
@export var notify_b := "The points grind across, toward the washout."

var _lever: Node3D
var _knob: MeshInstance3D
var _knob_a: StandardMaterial3D
var _knob_b: StandardMaterial3D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = Vector3(0.6, 0.5, 0.4)
	cs.shape = s
	cs.position.y = 0.25
	add_child(cs)
	var base_m := StandardMaterial3D.new()
	base_m.albedo_color = Color(0.2, 0.2, 0.22)
	base_m.metallic = 0.6
	base_m.roughness = 0.5
	var arm_m := StandardMaterial3D.new()
	arm_m.albedo_color = Color(0.55, 0.3, 0.2)
	arm_m.metallic = 0.4
	_knob_a = StandardMaterial3D.new()
	_knob_a.albedo_color = Color(0.85, 0.82, 0.7)
	_knob_b = StandardMaterial3D.new()
	_knob_b.albedo_color = Color(0.85, 0.3, 0.2)
	_knob_b.emission_enabled = true
	_knob_b.emission = Color(0.8, 0.2, 0.1)
	var base := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.6, 0.35, 0.4)
	base.mesh = bm
	base.material_override = base_m
	base.position.y = 0.17
	add_child(base)
	_lever = Node3D.new()
	_lever.position.y = 0.3
	add_child(_lever)
	var arm := MeshInstance3D.new()
	var am := CylinderMesh.new()
	am.top_radius = 0.035
	am.bottom_radius = 0.045
	am.height = 1.0
	arm.mesh = am
	arm.material_override = arm_m
	arm.position.y = 0.5
	_lever.add_child(arm)
	_knob = MeshInstance3D.new()
	var km := SphereMesh.new()
	km.radius = 0.08
	km.height = 0.16
	_knob.mesh = km
	_knob.position.y = 1.02
	_lever.add_child(_knob)
	var it := Interactable3D.new()
	it.prompt = "Throw"
	it.label = "Points lever"
	it.radius = 1.0
	it.position.y = 0.6
	add_child(it)
	it.interacted.connect(_on_interacted)
	GameState.flag_changed.connect(_on_flag_changed)
	_show()


func branch() -> String:
	return str(GameState.get_flag(switch_key, "a"))


func _on_interacted(_by: Node3D) -> void:
	var next := "b" if branch() == "a" else "a"
	GameState.set_flag(switch_key, next)
	GameState.notify(notify_b if next == "b" else notify_a)


func _on_flag_changed(key: String, _value: Variant) -> void:
	if key == switch_key:
		_show()


func _show() -> void:
	var b := branch() == "b"
	_lever.rotation.z = 0.5 if b else -0.5
	_knob.material_override = _knob_b if b else _knob_a
