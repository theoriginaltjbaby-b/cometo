class_name Player3D
extends CharacterBody3D
## The player in 3D maps. Same outward interface as Player (target, facing,
## try_interact, setup, camera.reset_smoothing) so main, HUD and tests can drive
## either. Screen-up is north (-Z); the camera never rotates.

signal target_changed(target: Interactable3D)

@export var walk_speed := 4.2
@export var accel := 28.0
@export var decel := 36.0
@export var gravity := 22.0

var touch: TouchControls
var facing := Vector3(0, 0, 1)
var target: Interactable3D
## Not used in 3D; kept so code written for 2D maps can test it safely.
var walk_mask: Variant = null
var figure: Figure3D
var reach: Area3D
var camera: FollowCamera
## Last place the player stood; used if they ever fall out of the world.
var _safe := Vector3.ZERO
var _has_safe := false


func _init() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.45
	floor_max_angle = deg_to_rad(52.0)
	floor_constant_speed = true
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.28
	cap.height = 1.6
	cs.shape = cap
	cs.position.y = 0.8
	add_child(cs)
	figure = Figure3D.new()
	figure.coat = Color(0.5, 0.13, 0.11)
	figure.accent = Color(0.62, 0.42, 0.2)
	figure.hood = false
	figure.xray = true
	add_child(figure)
	reach = Area3D.new()
	reach.collision_layer = 0
	reach.collision_mask = 4
	reach.monitorable = false
	var rs := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.4
	rs.shape = sphere
	rs.position = Vector3(0, 0.8, 0)
	reach.add_child(rs)
	add_child(reach)
	add_child(Rain3D.new())
	camera = FollowCamera.new()
	camera.target = self
	add_child(camera)


func setup(touch_controls: TouchControls, _bounds: Variant = null) -> void:
	touch = touch_controls
	camera.reset_smoothing()


func _physics_process(delta: float) -> void:
	var dir := Vector2.ZERO
	if not Dialogue.active:
		dir = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
		if dir == Vector2.ZERO and touch != null:
			dir = touch.vector
	var moving := dir.length() > 0.1
	var want := Vector3(dir.x, 0, dir.y).limit_length(1.0) * walk_speed if moving else Vector3.ZERO
	var h := Vector3(velocity.x, 0, velocity.z).move_toward(want, (accel if moving else decel) * delta)
	velocity.x = h.x
	velocity.z = h.z
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravity * delta
	move_and_slide()
	if is_on_floor():
		_safe = global_position
		_has_safe = true
	elif global_position.y < -40.0 and _has_safe:
		global_position = _safe + Vector3(0, 0.3, 0)
		velocity = Vector3.ZERO
	if moving:
		facing = Vector3(dir.x, 0, dir.y).normalized()
	var yaw := atan2(-facing.x, -facing.z)
	figure.rotation.y = lerp_angle(figure.rotation.y, yaw, 1.0 - exp(-14.0 * delta))
	figure.set_motion(h.length() > 0.3, h.length() / walk_speed)
	_update_target()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"interact") and try_interact():
		get_viewport().set_input_as_handled()


func try_interact() -> bool:
	if Dialogue.active or target == null or not target.is_available():
		return false
	target.interact(self)
	return true


func face_now() -> void:
	figure.rotation.y = atan2(-facing.x, -facing.z)


func _update_target() -> void:
	var best: Interactable3D = null
	var best_d := INF
	for a in reach.get_overlapping_areas():
		var it := a as Interactable3D
		if it == null or not it.is_available():
			continue
		var d := global_position.distance_squared_to(it.global_position)
		if d < best_d:
			best_d = d
			best = it
	if best != target:
		target = best
		target_changed.emit(target)
