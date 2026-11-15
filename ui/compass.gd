class_name Compass
extends Control
## Compass, bottom-left: a hairline ring with tick marks and a north pointer. The
## camera never rotates, so north is always up.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(40, 40)


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 3.0
	var line := Color(UiTheme.ACCENT, 0.55)
	draw_arc(c, r, 0.0, TAU, 48, Color(UiTheme.ACCENT, 0.3), 1.0, true)
	# open inner arcs, like an instrument bezel
	for i in 4:
		var a0 := TAU * i / 4.0 + 0.3
		draw_arc(c, r * 0.62, a0, a0 + PI * 0.5 - 0.6, 10, Color(UiTheme.ACCENT, 0.22), 1.0, true)
	for i in 16:
		var d := Vector2.from_angle(TAU * i / 16.0)
		var inner := r - (4.0 if i % 4 == 0 else 2.0)
		draw_line(c + d * inner, c + d * r, line if i % 4 == 0 else Color(line, 0.3), 1.0, true)
	# north pointer and centre mark
	var tip := c + Vector2(0, -r + 5.0)
	draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(2.5, 5), tip + Vector2(-2.5, 5)]), UiTheme.BONE)
	draw_line(c + Vector2(-2, 0), c + Vector2(2, 0), line, 1.0)
	draw_line(c + Vector2(0, -2), c + Vector2(0, 2), line, 1.0)
	var f := UiTheme.caps_font()
	draw_string(f, c + Vector2(-2.5, -r - 1.0), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(UiTheme.BONE, 0.85))
