class_name Compass
extends Control
## Compass rose, bottom-left. The camera never rotates, so north is always up.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(40, 40)


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 2.0
	var gold := Color(UiTheme.BONE, 0.85)
	draw_arc(c, r, 0.0, TAU, 40, Color(gold, 0.5), 1.0, true)
	draw_arc(c, r * 0.55, 0.0, TAU, 32, Color(gold, 0.35), 1.0, true)
	for i in 8:
		var a := TAU * i / 8.0 - PI * 0.5
		var long := i % 2 == 0
		var tip := c + Vector2.from_angle(a) * (r if long else r * 0.6)
		var side := Vector2.from_angle(a + PI * 0.5) * (3.0 if long else 2.0)
		var pts := PackedVector2Array([tip, c + side, c - side])
		draw_colored_polygon(pts, gold if i == 0 else Color(gold, 0.6 if long else 0.35))
	draw_circle(c, 1.5, gold)
