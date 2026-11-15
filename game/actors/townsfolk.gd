class_name Townsfolk
extends Node3D
## Background inhabitant: walks a loop of points, pausing at each, or stands idle if
## given one point. Not interactive and not solid, so it never blocks the player.
## Lives in the map's Entities; built entirely from data set before entering the tree.

var points := PackedVector3Array()
var speed := 1.1
var coat := Color(0.3, 0.32, 0.35)
var accent := Color(0.6, 0.45, 0.25)
var skin := Color(0.7, 0.53, 0.42)
var hood := false
## Facing in degrees when standing still with a single point.
var yaw_deg := 180.0
var look := {}

var _fig: Figure3D
var _i := 0
var _wait := 0.0


func _ready() -> void:
	_fig = Figure3D.new()
	_fig.coat = coat
	_fig.accent = accent
	_fig.skin = skin
	_fig.hood = hood
	_fig.configure(look)
	_fig.rotation.y = deg_to_rad(yaw_deg)
	add_child(_fig)
	if not points.is_empty():
		global_position = points[0]
	_wait = randf_range(0.0, 3.0)


func _process(delta: float) -> void:
	if points.size() < 2:
		return
	if _wait > 0.0:
		_wait -= delta
		_fig.set_motion(false)
		return
	var target := points[(_i + 1) % points.size()]
	var to := target - global_position
	var flat := Vector3(to.x, 0, to.z)
	if flat.length() < 0.08:
		_i = (_i + 1) % points.size()
		_wait = randf_range(1.5, 5.0)
		return
	var step := minf(speed * delta, flat.length())
	global_position += flat.normalized() * step
	global_position.y = lerpf(global_position.y, target.y, clampf(step / maxf(flat.length(), 0.01), 0.0, 1.0))
	_fig.rotation.y = lerp_angle(_fig.rotation.y, atan2(-flat.x, -flat.z), 1.0 - exp(-10.0 * delta))
	_fig.set_motion(true, speed / 4.2)
