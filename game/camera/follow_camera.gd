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

## Set by the player: widens the lens a touch and leads the view while running.
var sprint := false
@export var sprint_fov_add := 2.5
@export var sprint_lead := 1.6

var target: Node3D
var _lead := Vector3.ZERO
## Arrival shot (play_intro): 0..1 progress, < 0 when not playing.
var _intro := -1.0
var _intro_len := 6.0
const INTRO_PITCH := 3.0
const INTRO_DISTANCE := 9.0
const INTRO_FOV := 56.0
const INTRO_HEIGHT := 2.4


func _ready() -> void:
	if ArtStyle.handheld:
		pitch_deg = ArtStyle.CAM_PITCH
		distance = ArtStyle.CAM_DISTANCE
		fov_deg = ArtStyle.CAM_FOV
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
	var v := _view()
	var p := deg_to_rad(v.x)
	return Vector3(0, sin(p), cos(p)) * v.y + Vector3(0, v.w, 0)


## Current (pitch, distance, fov, look height), blended during the arrival shot.
func _view() -> Vector4:
	if _intro < 0.0:
		return Vector4(pitch_deg, distance, fov_deg, look_height)
	# hold on the sky, then sweep down to the play view
	var k := smoothstep(0.3, 1.0, _intro)
	return Vector4(lerpf(INTRO_PITCH, pitch_deg, k), lerpf(INTRO_DISTANCE, distance, k), lerpf(INTRO_FOV, fov_deg, k), lerpf(INTRO_HEIGHT, look_height, k))


## The arrival shot: starts low behind the player looking out over the settlement to
## the horizon and the ringed planet, holds, then sweeps down to the play camera.
## Any input hurries it along. Only the arrival shot draws past `far` 220 m.
func play_intro(seconds := 6.0) -> void:
	_intro = 0.0
	_intro_len = seconds
	far = 1600.0
	reset_smoothing()


func is_playing_intro() -> bool:
	return _intro >= 0.0


func reset_smoothing() -> void:
	_lead = Vector3.ZERO
	if target != null and target.is_inside_tree():
		global_position = target.global_position + _offset()


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var ahead := Vector3.ZERO
	if sprint and target is CharacterBody3D:
		var v := (target as CharacterBody3D).velocity
		ahead = Vector3(v.x, 0, v.z).limit_length(1.0) * sprint_lead
	_lead = _lead.lerp(ahead, 1.0 - exp(-3.0 * delta))
	if _intro >= 0.0:
		_intro = minf(_intro + delta / _intro_len, 1.0)
		var v := _view()
		rotation_degrees = Vector3(-v.x, 0, 0)
		fov = v.z
		global_position = target.global_position + _offset()
		if _intro >= 1.0:
			_intro = -1.0
			far = 220.0
		return
	var want := target.global_position + _offset() + _lead
	global_position = global_position.lerp(want, 1.0 - exp(-follow_speed * delta))
	if perspective:
		fov = lerpf(fov, fov_deg + (sprint_fov_add if sprint else 0.0), 1.0 - exp(-4.0 * delta))


func _unhandled_input(event: InputEvent) -> void:
	if _intro >= 0.0 and _intro < 0.3 and event.is_pressed() and not event.is_echo():
		_intro = 0.3
