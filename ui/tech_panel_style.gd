class_name TechPanelStyle
extends StyleBox
## Panel look for the interface: a dark blue translucent field, a hairline outline,
## brighter corner brackets and a short header tick. Drawn, not textured, so it is
## crisp at any size.

var bg := Color(0.02, 0.06, 0.1, 0.86)
var line := Color(0.56, 0.82, 0.94, 0.22)
var bracket := Color(0.56, 0.82, 0.94, 0.9)
var bracket_len := 6.0
var tick := true


func _init(pad: float = 8.0) -> void:
	set_content_margin_all(pad)


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var rs := RenderingServer
	rs.canvas_item_add_rect(to_canvas_item, rect, bg)
	var a := rect.position
	var b := rect.end
	# hairline outline
	for r: Rect2 in [Rect2(a.x, a.y, rect.size.x, 1), Rect2(a.x, b.y - 1, rect.size.x, 1),
			Rect2(a.x, a.y, 1, rect.size.y), Rect2(b.x - 1, a.y, 1, rect.size.y)]:
		rs.canvas_item_add_rect(to_canvas_item, r, line)
	# corner brackets
	var n := minf(bracket_len, minf(rect.size.x, rect.size.y) * 0.4)
	for c: Array in [[a.x, a.y, 1, 1], [b.x, a.y, -1, 1], [a.x, b.y, 1, -1], [b.x, b.y, -1, -1]]:
		var x: float = c[0]
		var y: float = c[1]
		var sx: float = c[2]
		var sy: float = c[3]
		rs.canvas_item_add_rect(to_canvas_item, Rect2(minf(x, x + sx * n), y if sy > 0 else y - 1, n, 1), bracket)
		rs.canvas_item_add_rect(to_canvas_item, Rect2(x if sx > 0 else x - 1, minf(y, y + sy * n), 1, n), bracket)
	if tick and rect.size.x > 40.0:
		rs.canvas_item_add_rect(to_canvas_item, Rect2(a.x + n + 4, a.y, 14, 1), Color(bracket, 0.5))
