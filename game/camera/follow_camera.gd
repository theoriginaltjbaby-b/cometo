class_name FollowCamera
extends Camera3D
## Fixed-orientation elevated RPG camera. Never rotates: north is always up the
## screen. Narrow-lens perspective by default (orthographic optional).

@export var pitch_deg := 40.0
@export var distance := 30.0
@export var ortho_size := 14.0
## Perspective with a narrow lens reads like the handheld reference (facades visible,
## gentle depth); set false for the old orthographic view.
@export var perspective := true
@export var fov_deg := 32.0
@export var follow_speed := 6.0
## Aim slightly ahead of the feet so the player sits a little below centre.
@export var look_height := 1.0

var target: Node3D


func _ready() -> void:
	top_level = true
	if perspective:
		projection = PROJECTION_PERSPECTIVE
		fov = fov_deg
	else:
		projection = PROJECTION_ORTHOGONAL
		size = ortho_size
	near = 0.5
	far = 220.0
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
