class_name FollowCamera
extends Camera3D
## Fixed-orientation elevated RPG camera. Never rotates: north is always up the
## screen. Orthographic by default; `size` is the visible height in metres.

@export var pitch_deg := 50.0
@export var distance := 40.0
@export var ortho_size := 14.0
@export var follow_speed := 6.0
## Aim slightly ahead of the feet so the player sits a little below centre.
@export var look_height := 1.0

var target: Node3D


func _ready() -> void:
	top_level = true
	projection = PROJECTION_ORTHOGONAL
	size = ortho_size
	near = 0.5
	far = 160.0
	rotation_degrees = Vector3(-pitch_deg, 0, 0)
	current = true
	reset_smoothing()


func _offset() -> Vector3:
	var p := deg_to_rad(pitch_deg)
	return Vector3(0, sin(p), cos(p)) * distance + Vector3(0, look_height, 0)


func reset_smoothing() -> void:
	if target != null and target.is_inside_tree():
		global_position = target.global_position + _offset()


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var want := target.global_position + _offset()
	global_position = global_position.lerp(want, 1.0 - exp(-follow_speed * delta))
