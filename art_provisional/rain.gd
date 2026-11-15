class_name Rain
extends Control
## PROVISIONAL ART. Screen-space rain streaks.

@export var count := 110
@export var fall := Vector2(-70.0, 330.0)
@export var streak := 0.035

var _pos := PackedVector2Array()
var _speed := PackedFloat32Array()


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	for i in count:
		_pos.append(Vector2(rng.randf() * 700.0, rng.randf() * 300.0))
		_speed.append(rng.randf_range(0.75, 1.25))


func _process(delta: float) -> void:
	var s := size
	for i in _pos.size():
		var p := _pos[i] + fall * _speed[i] * delta
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
	for i in _pos.size():
		draw_line(_pos[i], _pos[i] + fall * _speed[i] * streak, Color(0.75, 0.84, 0.92, 0.22), 1.0)
