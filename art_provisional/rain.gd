class_name Rain
extends Control
## PROVISIONAL ART. Screen-space precipitation for 2D maps: rain streaks, or slow snow.
## EnvironmentController2D sets the amounts through set_precipitation(rain, snow).

@export var count := 220
@export var fall := Vector2(-70.0, 330.0)
@export var streak := 0.035

var rain := 0.5
var snow := 0.0
var _pos := PackedVector2Array()
var _speed := PackedFloat32Array()


func _ready() -> void:
	add_to_group(&"precipitation")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	for i in count:
		_pos.append(Vector2(rng.randf() * 700.0, rng.randf() * 300.0))
		_speed.append(rng.randf_range(0.75, 1.25))


func set_precipitation(r: float, s: float) -> void:
	rain = r
	snow = s


func clear_particles() -> void:
	pass


func _process(delta: float) -> void:
	if not is_visible_in_tree() or (rain <= 0.02 and snow <= 0.02):
		if not _pos.is_empty():
			queue_redraw()
		return
	var s := size
	var snowing := snow > rain
	for i in _pos.size():
		var v := fall * _speed[i]
		if snowing:
			v = Vector2(-12.0 + sin(Time.get_ticks_msec() * 0.001 + i) * 10.0, 28.0) * _speed[i]
		var p := _pos[i] + v * delta
		if p.y > s.y:
			p.y -= s.y + 10.0
			p.x += 40.0
		if p.x < -10.0:
			p.x += s.x + 20.0
		elif p.x > s.x + 10.0:
			p.x -= s.x + 20.0
		_pos[i] = p
	queue_redraw()


func _draw() -> void:
	if rain <= 0.02 and snow <= 0.02:
		return
	if snow > rain:
		var n := int(_pos.size() * clampf(snow, 0.0, 1.0))
		for i in n:
			draw_rect(Rect2(_pos[i].round(), Vector2(1, 1)), Color(0.95, 0.97, 1.0, 0.85))
		return
	var k := int(_pos.size() * clampf(rain, 0.0, 1.0))
	for i in k:
		var p := _pos[i]
		draw_line(p, p - fall * _speed[i] * streak, Color(0.75, 0.82, 0.92, 0.3), 1.0)
