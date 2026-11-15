@tool
class_name ProvBlock
extends StaticBody2D
## PROVISIONAL ART. A solid piece of the world drawn in code, in 3/4 view.
## The node origin is the bottom-centre of the footprint (its front edge), so
## y-sorting works. `size` is the footprint (width x depth); `height` is how far
## the front face rises. Replace with authored art; keep the footprints.

@export var size := Vector2(48, 24):
	set(v):
		size = v
		queue_redraw()
@export var height := 20.0:
	set(v):
		height = v
		queue_redraw()
@export_enum("pod", "hut", "rock", "fence", "gate", "crate", "lamp", "tree", "pit", "adit", "sign", "none") var style := "crate":
	set(v):
		style = v
		queue_redraw()
@export var lit := false:
	set(v):
		lit = v
		queue_redraw()
@export var solid := true
@export var tint := Color(1, 1, 1):
	set(v):
		tint = v
		queue_redraw()

static var _light_tex: GradientTexture2D

var _shape: CollisionShape2D
var _solid_now := true


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	collision_layer = 1
	collision_mask = 0
	if solid:
		var rect := RectangleShape2D.new()
		rect.size = size
		_shape = CollisionShape2D.new()
		_shape.shape = rect
		_shape.position = Vector2(0, -size.y * 0.5)
		_shape.disabled = not _solid_now
		add_child(_shape)
	if lit:
		_add_light()


func set_solid(v: bool) -> void:
	_solid_now = v
	if _shape != null:
		_shape.set_deferred("disabled", not v)


static func light_texture() -> GradientTexture2D:
	if _light_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(0, 0, 0, 0))
		_light_tex = GradientTexture2D.new()
		_light_tex.gradient = g
		_light_tex.width = 128
		_light_tex.height = 128
		_light_tex.fill = GradientTexture2D.FILL_RADIAL
		_light_tex.fill_from = Vector2(0.5, 0.5)
		_light_tex.fill_to = Vector2(1.0, 0.5)
	return _light_tex


func _add_light() -> void:
	var l := PointLight2D.new()
	l.texture = light_texture()
	l.color = Color(1.0, 0.6, 0.3)
	l.energy = 1.1
	if style == "lamp":
		l.position = Vector2(3, -height + 4)
		l.texture_scale = 1.9
	else:
		l.position = Vector2(size.x * 0.5 - 15, -height * 0.5 + 6)
		l.texture_scale = 1.2
	add_child(l)


func _draw() -> void:
	var w := size.x
	var d := size.y
	var h := height
	var l := -w * 0.5
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(position))
	match style:
		"pod", "hut":
			var wall := (Color(0.4, 0.45, 0.48) if style == "pod" else Color(0.3, 0.36, 0.33)) * tint
			var roof := wall.lightened(0.14)
			draw_rect(Rect2(l, -d - h, w, d), roof)
			for i in range(1, int(w / 8.0)):
				draw_line(Vector2(l + i * 8, -d - h), Vector2(l + i * 8, -h), roof.darkened(0.14), 1.0)
			draw_rect(Rect2(l, -h, w, h), wall)
			draw_rect(Rect2(l, -h, w, 1), wall.darkened(0.35))
			draw_rect(Rect2(l, -2, w, 2), wall.darkened(0.4))
			draw_rect(Rect2(l, -h + 3, w, 1), Color(0.72, 0.4, 0.2, 0.75))
			draw_rect(Rect2(l + 6, -13, 8, 13), wall.darkened(0.5))
			draw_rect(Rect2(l + w - 23, -h + 6, 15, 8), wall.darkened(0.5))
			draw_rect(Rect2(l + w - 22, -h + 7, 13, 6), Color(1.0, 0.8, 0.45) if lit else Color(0.1, 0.14, 0.18))
			for i in 3:
				var x := l + rng.randf() * w
				draw_line(Vector2(x, -h + 4), Vector2(x, -h + 4 + rng.randf_range(4, 12)), Color(0.45, 0.27, 0.18, 0.5), 1.0)
		"rock":
			var face := Color(0.19, 0.22, 0.25) * tint
			draw_rect(Rect2(l, -d - h, w, d), Color(0.24, 0.28, 0.29) * tint)
			draw_rect(Rect2(l, -h, w, h), face)
			for i in int(w / 12.0):
				var p := Vector2(l + rng.randf() * w, -h + rng.randf() * h)
				draw_line(p, p + Vector2(rng.randf_range(6, 20), rng.randf_range(-2, 2)), face.lightened(0.1), 1.0)
				var q := Vector2(l + rng.randf() * w, -h + rng.randf() * h)
				draw_line(q, q + Vector2(rng.randf_range(-3, 3), rng.randf_range(5, 14)), face.darkened(0.3), 1.0)
			draw_rect(Rect2(l, -h - 1, w, 3), Color(0.15, 0.26, 0.2))
		"fence":
			var c := Color(0.37, 0.31, 0.27) * tint
			if w >= d:
				var n := maxi(1, int(w / 16.0))
				draw_rect(Rect2(l, -h + 2, w, h - 3), Color(c, 0.16))
				draw_line(Vector2(l, -h + 2), Vector2(l + w, -h + 2), c.lightened(0.15), 1.0)
				draw_line(Vector2(l, -h * 0.5), Vector2(l + w, -h * 0.5), c, 1.0)
				for i in n + 1:
					draw_rect(Rect2(l + i * (w / n) - 1, -h, 2, h), c)
			else:
				var n := maxi(1, int(d / 16.0))
				draw_line(Vector2(0, -h + 2), Vector2(0, -d - h + 2), c.lightened(0.15), 1.0)
				draw_line(Vector2(0, -h * 0.5), Vector2(0, -d - h * 0.5), c, 1.0)
				for i in n + 1:
					draw_rect(Rect2(-1, -i * (d / n) - h, 2, h), c)
		"gate":
			var c := Color(0.3, 0.33, 0.36)
			draw_rect(Rect2(l, -h, w, h), Color(c, 0.5))
			for i in range(1, int(w / 5.0)):
				draw_line(Vector2(l + i * 5, -h), Vector2(l + i * 5, 0), c, 1.0)
			draw_rect(Rect2(l, -h, w, 2), c.lightened(0.1))
			draw_rect(Rect2(l, -2, w, 2), c)
			draw_rect(Rect2(l, -h - 3, 3, h + 3), c.darkened(0.2))
			draw_rect(Rect2(l + w - 3, -h - 3, 3, h + 3), c.darkened(0.2))
			for i in int(w / 6.0):
				draw_rect(Rect2(l + i * 6, -h * 0.6, 6, 4), Color(0.8, 0.62, 0.15) if i % 2 == 0 else Color(0.08, 0.08, 0.09))
		"crate":
			var c := Color(0.55, 0.53, 0.47) * tint
			draw_rect(Rect2(l, -d - h, w, d), c.lightened(0.1))
			draw_rect(Rect2(l, -h, w, h), c.darkened(0.15))
			draw_line(Vector2(l, -h), Vector2(l + w, -h), c.darkened(0.4), 1.0)
			for i in range(1, 3):
				draw_line(Vector2(l, -h - d * i / 3.0), Vector2(l + w, -h - d * i / 3.0), c.darkened(0.2), 1.0)
		"lamp":
			var c := Color(0.2, 0.22, 0.24)
			draw_rect(Rect2(-1, -h, 2, h), c)
			draw_rect(Rect2(-1, -h, 6, 2), c)
			draw_rect(Rect2(2, -h + 2, 4, 2), Color(1.0, 0.82, 0.5) if lit else Color(0.12, 0.13, 0.15))
		"tree":
			var s := rng.randf_range(0.85, 1.2)
			var g := Color(0.08, 0.19, 0.16).lightened(rng.randf_range(0.0, 0.06)) * tint
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
			draw_circle(Vector2.ZERO, 11.0 * s, Color(0, 0, 0, 0.3))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			draw_rect(Rect2(-2, -12, 4, 12), Color(0.19, 0.14, 0.11))
			var tiers := 4
			var step := (h - 10.0) / tiers
			for i in tiers:
				var y0 := -9.0 - step * i
				var y1 := y0 - step * 1.7
				var hw := 15.0 * s * (1.0 - i * 0.2)
				draw_colored_polygon(PackedVector2Array([Vector2(-hw, y0), Vector2(hw, y0), Vector2(0, y1)]), g.lightened(0.05 * i))
				draw_colored_polygon(PackedVector2Array([Vector2(1, y0), Vector2(hw, y0), Vector2(1, y1)]), g.darkened(0.28))
		"pit":
			draw_rect(Rect2(l, -d, w, d), Color(0.035, 0.045, 0.055))
			draw_rect(Rect2(l, -d, w, 7), Color(0.14, 0.13, 0.12))
			draw_rect(Rect2(l, -d + 7, w, 2), Color(0.08, 0.08, 0.08))
			draw_rect(Rect2(l, -9, w, 5), Color(0.09, 0.15, 0.19))
		"adit":
			draw_rect(Rect2(l - 4, -h - 4, w + 8, h + 4), Color(0.25, 0.19, 0.14))
			draw_rect(Rect2(l, -h, w, h), Color(0.3, 0.33, 0.35))
			draw_line(Vector2(0, -h), Vector2(0, 0), Color(0.2, 0.22, 0.24), 1.0)
			draw_rect(Rect2(l, -h, w, h), Color(0.82, 0.84, 0.8), false, 1.0)
			for i in 4:
				draw_rect(Rect2(l + 4 + i * (w - 9) / 3.0, -h + 4, 1, 1), Color(0.15, 0.16, 0.18))
				draw_rect(Rect2(l + 4 + i * (w - 9) / 3.0, -5, 1, 1), Color(0.15, 0.16, 0.18))
		"sign":
			draw_rect(Rect2(l, -h, w, h - 5), Color(0.8, 0.78, 0.7))
			for i in 3:
				draw_line(Vector2(l + 1, -h + 2 + i * 2), Vector2(l + w - 1, -h + 2 + i * 2), Color(0.25, 0.22, 0.2), 1.0)
		_:
			pass
