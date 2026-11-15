class_name TitleShip
extends Node2D
## PROVISIONAL ART. The lone ship on the title screen, drawn as a dark silhouette with a
## lit core. It drifts and turns by fractions of a degree. Replace with painted art by
## swapping _draw() for a sprite; keep the drift.

var _t := 0.0
var _home := Vector2.ZERO
var _glow: Sprite2D


func _ready() -> void:
	_home = position
	# warm bloom around the core, additive
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	g.colors = PackedColorArray([Color(1.0, 0.55, 0.25, 0.9), Color(1.0, 0.35, 0.12, 0.28), Color(1.0, 0.3, 0.1, 0.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.width = 64
	tex.height = 64
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	_glow = Sprite2D.new()
	_glow.texture = tex
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = m
	_glow.position = Vector2(-2, 2)
	add_child(_glow)


func set_home(p: Vector2) -> void:
	_home = p


func _process(delta: float) -> void:
	_t += delta
	position = _home + Vector2(sin(_t * 0.11) * 5.0 + sin(_t * 0.043) * 3.0, sin(_t * 0.083 + 1.0) * 2.5)
	rotation = sin(_t * 0.07) * 0.03 + sin(_t * 0.031 + 2.0) * 0.015
	var pulse := 0.85 + 0.15 * sin(_t * 0.9) + 0.05 * sin(_t * 2.3)
	_glow.modulate.a = pulse
	_glow.scale = Vector2.ONE * (0.55 + 0.06 * pulse)


func _draw() -> void:
	var hull := Color(0.035, 0.03, 0.055)
	var rim := Color(0.95, 0.62, 0.38, 0.75)
	# long axis: nose to the right, tail left
	_poly([Vector2(-34, 1), Vector2(-20, -3), Vector2(8, -4), Vector2(40, 0), Vector2(8, 5), Vector2(-18, 6)], hull)
	# spire and fins rising from the core
	_poly([Vector2(-4, -4), Vector2(0, -44), Vector2(3, -4)], hull)
	_poly([Vector2(-11, -3), Vector2(-9, -24), Vector2(-6, -3)], hull)
	_poly([Vector2(5, -4), Vector2(9, -27), Vector2(11, -3)], hull)
	_poly([Vector2(-17, -2), Vector2(-16, -14), Vector2(-13, -2)], hull)
	# keel blades
	_poly([Vector2(-6, 5), Vector2(-5, 40), Vector2(-2, 5)], hull)
	_poly([Vector2(-13, 5), Vector2(-13, 22), Vector2(-10, 5)], hull)
	_poly([Vector2(3, 5), Vector2(5, 20), Vector2(7, 5)], hull)
	# swept wing reaching forward and up
	_poly([Vector2(6, -3), Vector2(38, -19), Vector2(41, -17), Vector2(16, 0)], hull)
	_poly([Vector2(-22, 2), Vector2(-40, 7), Vector2(-39, 9), Vector2(-20, 5)], hull)
	# sunlit edges
	draw_polyline(PackedVector2Array([Vector2(-20, -3), Vector2(8, -4), Vector2(40, 0)]), rim, 0.6, true)
	draw_line(Vector2(6, -3), Vector2(38, -19), rim, 0.6, true)
	draw_line(Vector2(0, -44), Vector2(3, -4), Color(rim, 0.5), 0.5, true)
	draw_line(Vector2(9, -27), Vector2(11, -3), Color(rim, 0.4), 0.5, true)
	# core
	draw_circle(Vector2(-2, 2), 7.2, Color(0.1, 0.03, 0.03))
	draw_circle(Vector2(-2, 2), 6.2, Color(0.75, 0.2, 0.08))
	draw_circle(Vector2(-3, 1), 4.2, Color(1.0, 0.45, 0.18))
	draw_circle(Vector2(-4, 0), 1.8, Color(1.0, 0.8, 0.55))
	draw_arc(Vector2(-2, 2), 7.2, 0, TAU, 24, Color(0.02, 0.02, 0.03), 1.0, true)
	draw_line(Vector2(-9, 2), Vector2(5, 2), Color(0.05, 0.02, 0.03, 0.7), 0.6)


func _poly(pts: Array, c: Color) -> void:
	draw_colored_polygon(PackedVector2Array(pts), c)
