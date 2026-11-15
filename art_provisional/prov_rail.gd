@tool
class_name ProvRail
extends Node2D
## PROVISIONAL ART. Narrow-gauge rail drawn along `points`. Also the path data
## that OreCart follows.

@export var points := PackedVector2Array():
	set(v):
		points = v
		queue_redraw()
@export var buffer_start := false
@export var buffer_end := false


func _draw() -> void:
	var tie := Color(0.2, 0.16, 0.13)
	var steel := Color(0.42, 0.43, 0.45)
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		var dir := (b - a).normalized()
		var n := dir.orthogonal()
		var length := a.distance_to(b)
		var s := 0.0
		while s < length:
			var p := a + dir * s
			draw_line(p - n * 6.0, p + n * 6.0, tie, 2.0)
			s += 6.0
		draw_line(a - n * 4.0, b - n * 4.0, steel, 1.0)
		draw_line(a + n * 4.0, b + n * 4.0, steel, 1.0)
	if buffer_start and points.size() > 1:
		_buffer(points[0], (points[0] - points[1]).normalized())
	if buffer_end and points.size() > 1:
		var e := points.size() - 1
		_buffer(points[e], (points[e] - points[e - 1]).normalized())


func _buffer(at: Vector2, out: Vector2) -> void:
	var p := at + out * 12.0
	var n := out.orthogonal()
	draw_line(p - n * 7.0, p + n * 7.0, Color(0.5, 0.2, 0.15), 3.0)
