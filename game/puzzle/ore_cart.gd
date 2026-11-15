class_name OreCart
extends StaticBody2D
## A cart on a rail spur. Pushed from its start it rolls to the junction and takes
## whichever branch the points are set to: branch A ends at a buffer (haul it back
## and try again), branch B ends in the washout, where the cart wedges and becomes
## a bridge. State lives in GameState so it survives save/load.
## PROVISIONAL ART (drawn in code).

@export var state_key := "anjabi.cart"
@export var switch_key := "anjabi.spur_switch"
@export var rail_main: NodePath
@export var rail_a: NodePath
@export var rail_b: NodePath
## ProvBlock pit segment whose collision is removed once the cart bridges it.
@export var gap: NodePath
@export var bridge_position := Vector2.ZERO
@export var roll_speed := 70.0
@export var dialogue_buffer := ""
@export var dialogue_bridge := ""
@export var on_bridged: Array[Dictionary] = []

var moving := false

var _interactable: Interactable
var _shape: CollisionShape2D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var rect := RectangleShape2D.new()
	rect.size = Vector2(18, 10)
	_shape = CollisionShape2D.new()
	_shape.shape = rect
	_shape.position = Vector2(0, -5)
	add_child(_shape)
	_interactable = Interactable.new()
	_interactable.label = "Ore cart"
	_interactable.radius = 16.0
	_interactable.position = Vector2(0, -5)
	add_child(_interactable)
	_interactable.interacted.connect(_on_interacted)
	_apply_state()


func state() -> String:
	return str(GameState.get_flag(state_key, "start"))


func _points(path: NodePath) -> PackedVector2Array:
	var rail := get_node(path) as ProvRail
	var out := PackedVector2Array()
	for p in rail.points:
		out.append(rail.to_global(p))
	return out


func _apply_state() -> void:
	var s := state()
	var bridged := s == "trench"
	match s:
		"buffer":
			var a := _points(rail_a)
			global_position = a[a.size() - 1]
		"trench":
			global_position = bridge_position
		_:
			global_position = _points(rail_main)[0]
	_shape.set_deferred("disabled", bridged)
	z_index = -4 if bridged else 0
	_interactable.enabled = not bridged
	_interactable.prompt = "Haul back" if s == "buffer" else "Push"
	var pit := get_node_or_null(gap) as ProvBlock
	if pit != null:
		pit.set_solid(not bridged)
	queue_redraw()


func _on_interacted(_by: Node2D) -> void:
	if moving:
		return
	var route := PackedVector2Array()
	var next := "start"
	var main := _points(rail_main)
	if state() == "start":
		var to_trench := str(GameState.get_flag(switch_key, "a")) == "b"
		route.append_array(main.slice(1))
		route.append_array(_points(rail_b if to_trench else rail_a).slice(1))
		if to_trench:
			route.append(bridge_position)
		next = "trench" if to_trench else "buffer"
	elif state() == "buffer":
		var a := _points(rail_a)
		a.reverse()
		route.append_array(a.slice(1))
		main.reverse()
		route.append_array(main.slice(1))
	else:
		return
	_roll(route, next)


func _roll(route: PackedVector2Array, next: String) -> void:
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


func _draw() -> void:
	var rust := Color(0.5, 0.29, 0.18)
	if state() == "trench" and not moving:
		# Wedged in the washout, bed up: a short steel deck.
		draw_rect(Rect2(-13, -42, 26, 44), Color(0.23, 0.2, 0.19))
		draw_rect(Rect2(-12, -41, 24, 42), rust.darkened(0.2))
		for i in 6:
			draw_line(Vector2(-12, -38 + i * 7), Vector2(12, -38 + i * 7), rust.darkened(0.45), 1.0)
		return
	draw_rect(Rect2(-8, -3, 4, 3), Color(0.1, 0.1, 0.11))
	draw_rect(Rect2(4, -3, 4, 3), Color(0.1, 0.1, 0.11))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-11, -15), Vector2(11, -15), Vector2(8, -3), Vector2(-8, -3)]), rust)
	draw_rect(Rect2(-11, -17, 22, 3), rust.lightened(0.12))
	draw_rect(Rect2(-9, -16, 18, 1), Color(0.08, 0.08, 0.09))
	draw_line(Vector2(-3, -13), Vector2(-4, -5), rust.darkened(0.3), 1.0)
	draw_line(Vector2(5, -13), Vector2(4, -6), rust.darkened(0.3), 1.0)
