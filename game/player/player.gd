class_name Player
extends CharacterBody2D

signal target_changed(target: Interactable)

@export var walk_speed := 64.0

var touch: TouchControls
var facing := Vector2.DOWN
var target: Interactable
## Optional painted walkable area (maps without collision bodies).
var walk_mask: WalkMask

@onready var sprite: CharSprite = $Sprite
@onready var reach: Area2D = $Reach
@onready var camera: Camera2D = $Camera


func setup(touch_controls: TouchControls, bounds: Rect2) -> void:
	touch = touch_controls
	camera.limit_left = int(bounds.position.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_right = int(bounds.end.x)
	camera.limit_bottom = int(bounds.end.y)
	camera.reset_smoothing()


func _physics_process(_delta: float) -> void:
	var dir := Vector2.ZERO
	if not Dialogue.active:
		dir = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
		if dir == Vector2.ZERO and touch != null:
			dir = touch.vector
	var moving := dir.length() > 0.1
	velocity = _allowed(dir.limit_length(1.0) * walk_speed, _delta) if moving else Vector2.ZERO
	move_and_slide()
	if moving:
		facing = dir.normalized()
	sprite.set_motion(facing, moving)
	_update_target()


func _allowed(v: Vector2, delta: float) -> Vector2:
	if walk_mask == null or not _clear(global_position):
		return v
	if _clear(global_position + v * delta):
		return v
	var vx := Vector2(v.x, 0.0)
	if v.x != 0.0 and _clear(global_position + vx * delta):
		return vx
	var vy := Vector2(0.0, v.y)
	if v.y != 0.0 and _clear(global_position + vy * delta):
		return vy
	return Vector2.ZERO


func _clear(p: Vector2) -> bool:
	return walk_mask.is_walkable(p) and walk_mask.is_walkable(p + Vector2(3, 0)) \
			and walk_mask.is_walkable(p + Vector2(-3, 0)) and walk_mask.is_walkable(p + Vector2(0, -3))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"interact") and try_interact():
		get_viewport().set_input_as_handled()


func try_interact() -> bool:
	if Dialogue.active or target == null or not target.is_available():
		return false
	target.interact(self)
	return true


func _update_target() -> void:
	var best: Interactable = null
	var best_d := INF
	for a in reach.get_overlapping_areas():
		var it := a as Interactable
		if it == null or not it.is_available():
			continue
		var d := global_position.distance_squared_to(it.global_position)
		if d < best_d:
			best_d = d
			best = it
	if best != target:
		target = best
		target_changed.emit(target)
