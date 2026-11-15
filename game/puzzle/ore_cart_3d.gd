class_name OreCart3D
extends Node3D
## 3D version of OreCart, same rules and the same GameState keys. Pushed from its
## start it rolls to the junction and takes whichever branch the points are set to:
## branch A ends at a buffer (haul it back), branch B ends in the washout, where the
## cart wedges bed-up and becomes a bridge. PROVISIONAL ART (primitives).

@export var state_key := "anjabi.cart"
@export var switch_key := "anjabi.spur_switch"
@export var roll_speed := 3.5
@export var dialogue_buffer := ""
@export var dialogue_bridge := ""
@export var on_bridged: Array[Dictionary] = []

## Rail polylines in world space, set by the map before the cart enters the tree.
var rail_main := PackedVector3Array()
var rail_a := PackedVector3Array()
var rail_b := PackedVector3Array()
var bridge_position := Vector3.ZERO
## Invisible wall across the washout; removed once the cart bridges it.
var gap_blocker: CollisionShape3D

var moving := false

var _body: StaticBody3D
var _shape: CollisionShape3D
var _deck_body: StaticBody3D
var _deck_shape: CollisionShape3D
var _visual: Node3D
var _deck_visual: Node3D
var _interactable: Interactable3D


func _ready() -> void:
	var rust := StandardMaterial3D.new()
	rust.albedo_color = Color(0.5, 0.29, 0.18)
	rust.roughness = 0.65
	rust.metallic = 0.5
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.1, 0.1, 0.11)
	dark.roughness = 0.5
	dark.metallic = 0.6
	_body = StaticBody3D.new()
	_body.collision_layer = 1
	_body.collision_mask = 0
	add_child(_body)
	_shape = CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(1.3, 1.0, 2.2)
	_shape.shape = bs
	_shape.position.y = 0.5
	_body.add_child(_shape)
	_visual = Node3D.new()
	add_child(_visual)
	_mesh(_visual, Vector3(1.2, 0.75, 2.1), rust, Vector3(0, 0.62, 0))
	_mesh(_visual, Vector3(1.0, 0.05, 1.9), dark, Vector3(0, 1.0, 0))
	_mesh(_visual, Vector3(1.3, 0.08, 2.2), rust, Vector3(0, 1.0, 0))
	for x: float in [-0.5, 0.5]:
		for z: float in [-0.65, 0.65]:
			var w := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.2
			cm.bottom_radius = 0.2
			cm.height = 0.1
			cm.radial_segments = 12
			cm.rings = 0
			w.mesh = cm
			w.material_override = dark
			w.position = Vector3(x, 0.2, z)
			w.rotation.z = PI * 0.5
			_visual.add_child(w)
	# wedged in the washout: the tub upside down, its bed level with the ground
	_deck_body = StaticBody3D.new()
	_deck_body.collision_layer = 1
	_deck_body.collision_mask = 0
	_deck_body.top_level = true
	add_child(_deck_body)
	_deck_shape = CollisionShape3D.new()
	var ds := BoxShape3D.new()
	ds.size = Vector3(1.6, 0.3, 2.6)
	_deck_shape.shape = ds
	_deck_shape.position.y = -0.15
	_deck_body.add_child(_deck_shape)
	_deck_visual = Node3D.new()
	_deck_body.add_child(_deck_visual)
	_mesh(_deck_visual, Vector3(1.3, 0.85, 2.4), rust, Vector3(0, -0.45, 0))
	_mesh(_deck_visual, Vector3(1.32, 0.04, 2.42), rust.duplicate(), Vector3(0, -0.01, 0))
	for i in 5:
		_mesh(_deck_visual, Vector3(1.32, 0.03, 0.06), dark, Vector3(0, 0.01, -1.0 + i * 0.5))
	_interactable = Interactable3D.new()
	_interactable.label = "Ore cart"
	_interactable.radius = 1.3
	_interactable.position = Vector3(0, 0.6, 0)
	add_child(_interactable)
	_interactable.interacted.connect(_on_interacted)
	_apply_state()


func state() -> String:
	return str(GameState.get_flag(state_key, "start"))


func _apply_state() -> void:
	var s := state()
	var bridged := s == "trench"
	match s:
		"buffer":
			global_position = rail_a[rail_a.size() - 1]
		"trench":
			global_position = bridge_position
		_:
			global_position = rail_main[0]
	_deck_body.global_position = bridge_position
	_shape.set_deferred("disabled", bridged)
	_deck_shape.set_deferred("disabled", not bridged)
	_visual.visible = not bridged
	_deck_visual.visible = bridged
	_interactable.enabled = not bridged
	_interactable.prompt = "Haul back" if s == "buffer" else "Push"
	if gap_blocker != null:
		gap_blocker.set_deferred("disabled", bridged)


func _on_interacted(_by: Node3D) -> void:
	if moving:
		return
	var route := PackedVector3Array()
	var next := "start"
	if state() == "start":
		var to_trench := str(GameState.get_flag(switch_key, "a")) == "b"
		route.append_array(rail_main.slice(1))
		route.append_array((rail_b if to_trench else rail_a).slice(1))
		if to_trench:
			route.append(bridge_position)
		next = "trench" if to_trench else "buffer"
	elif state() == "buffer":
		var a := rail_a.duplicate()
		a.reverse()
		route.append_array(a.slice(1))
		var m := rail_main.duplicate()
		m.reverse()
		route.append_array(m.slice(1))
	else:
		return
	_roll(route, next)


func _roll(route: PackedVector3Array, next: String) -> void:
	moving = true
	_interactable.enabled = false
	var tween := create_tween()
	var from := global_position
	for i in route.size():
		var t := from.distance_to(route[i]) / roll_speed
		var step := tween.tween_property(self, "global_position", route[i], maxf(t, 0.05))
		if i == 0:
			step.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		from = route[i]
	if next == "trench":
		tween.tween_property(self, "global_position", bridge_position + Vector3(0, -0.9, 0), 0.25)
	await tween.finished
	moving = false
	GameState.set_flag(state_key, next)
	_apply_state()
	if next == "trench":
		GameState.apply(on_bridged)
		if dialogue_bridge != "":
			Dialogue.start(dialogue_bridge)
	elif next == "buffer" and dialogue_buffer != "":
		Dialogue.start(dialogue_buffer)


func _process(_delta: float) -> void:
	if moving:
		var d := Vector3.ZERO
		# face the direction of travel along the rails
		d = global_position - get_meta("last", global_position)
		set_meta("last", global_position)
		d.y = 0.0
		if d.length() > 0.001:
			_visual.rotation.y = atan2(d.x, d.z)


func _mesh(parent: Node3D, size: Vector3, m: Material, at: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = m
	mi.position = at
	parent.add_child(mi)
