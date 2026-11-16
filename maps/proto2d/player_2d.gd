class_name Player2D
extends Person2D
## The player on a Map2D. Same outward interface as Player and Player3D (target,
## facing, try_interact, setup, camera, sprinting) so main, HUD and saves drive it alike.
## Moves in ground space, blocked by the map's height grid; slides along edges.

signal target_changed(target: Interactable)

@export var walk_speed := 4.2
@export var run_speed := 7.4
## Camera zoom: 2 shows about 15 x 8 m, close to a handheld screen.
@export var zoom := 2.0

var touch: TouchControls
var target: Interactable
var sprinting := false
var camera: Camera2D
var _vel := Vector2.ZERO
var _cam_pos := Vector2.ZERO


func _init() -> void:
	sheet = load("res://art/baked2d/chars/player.png")


func setup(touch_controls: TouchControls, m: Map2D) -> void:
	touch = touch_controls
	map = m
	camera = Camera2D.new()
	camera.zoom = Vector2(zoom, zoom)
	camera.top_level = true
	camera.limit_left = int(m.bounds.position.x)
	camera.limit_top = int(m.bounds.position.y)
	camera.limit_right = int(m.bounds.end.x)
	camera.limit_bottom = int(m.bounds.end.y)
	add_child(camera)
	camera.make_current()
	_height = m.height_at(position)
	_cam_pos = _screen()
	camera.position = _cam_pos


func _physics_process(delta: float) -> void:
	if map == null:
		return
	var dir := Vector2.ZERO
	if not Dialogue.active:
		dir = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
		if dir == Vector2.ZERO and touch != null:
			dir = touch.vector
	var moving := dir.length() > 0.1
	sprinting = moving and (Input.is_action_pressed(&"sprint") or (touch != null and touch.sprint))
	var top := (run_speed if sprinting else walk_speed) * map.S
	var want := dir.limit_length(1.0) * top if moving else Vector2.ZERO
	_vel = _vel.move_toward(want, (28.0 if moving else 36.0) * map.S * delta)
	var step := _vel * delta
	if step != Vector2.ZERO:
		var to := position + step
		if map.can_step(position, to):
			position = to
		elif step.x != 0.0 and map.can_step(position, position + Vector2(step.x, 0)):
			position.x += step.x
			_vel.y = 0.0
		elif step.y != 0.0 and map.can_step(position, position + Vector2(0, step.y)):
			position.y += step.y
			_vel.x = 0.0
		else:
			_vel = Vector2.ZERO
	if moving:
		facing = dir.normalized()
	show_pose(_vel.length() > 0.3 * map.S, _vel.length() > walk_speed * 1.25 * map.S, delta * _vel.length() / (walk_speed * map.S) if _vel.length() < walk_speed * 1.25 * map.S else delta)
	_update_target()


func _process(delta: float) -> void:
	if map == null:
		return
	var h := map.height_at(position)
	if map.is_ground(h):
		_height = lerpf(_height, h, 1.0 - exp(-20.0 * delta))
	visual.position = Vector2(0, -roundf(_height * map.S))
	if camera == null:
		return
	var want := _screen()
	if _cam_pos.distance_to(want) > 120.0:
		_cam_pos = want
	_cam_pos = _cam_pos.lerp(want, 1.0 - exp(-8.0 * delta))
	# whole art pixels only, so the pixel art never shimmers
	camera.position = _cam_pos.round()


func _screen() -> Vector2:
	return position + Vector2(0, -_height * map.S - 12.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"interact") and try_interact():
		get_viewport().set_input_as_handled()


func try_interact() -> bool:
	if Dialogue.active or target == null or not target.is_available():
		return false
	target.interact(self)
	return true


func face_now() -> void:
	show_pose(false, false, 0.0)


func _update_target() -> void:
	var best: Interactable = null
	var best_d := INF
	for n in get_tree().get_nodes_in_group(&"interactables_2d"):
		var it := n as Interactable
		if it == null or not it.is_available() or not it.is_inside_tree():
			continue
		var d := position.distance_to(it.global_position)
		if d < it.radius + 14.0 and d < best_d:
			best_d = d
			best = it
	if best != target:
		target = best
		target_changed.emit(target)
