class_name EnvironmentController2D
extends EnvironmentController
## Day, night and weather for a Map2D. Same clock, weather and gradients as the 3D
## EnvironmentController; drawn with a CanvasModulate tint, PointLight2D lamps, the
## baked glow layers (windows, signs) and the screen-space rain, snow and mist in
## game/main.tscn's Weather layer.

var _tint: CanvasModulate
var _lamps2d: Array[PointLight2D] = []
static var _lamp_tex: GradientTexture2D


func _init() -> void:
	super._init()
	_tint = CanvasModulate.new()


func _ready() -> void:
	super._ready()
	get_parent().add_child.call_deferred(_tint)


func add_lamp(at: Vector2, energy: float, range_px: float) -> void:
	if _lamp_tex == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.45), Color(1, 1, 1, 0)])
		_lamp_tex = GradientTexture2D.new()
		_lamp_tex.gradient = g
		_lamp_tex.width = 128
		_lamp_tex.height = 128
		_lamp_tex.fill = GradientTexture2D.FILL_RADIAL
		_lamp_tex.fill_from = Vector2(0.5, 0.5)
		_lamp_tex.fill_to = Vector2(1.0, 0.5)
	var l := PointLight2D.new()
	l.texture = _lamp_tex
	l.texture_scale = range_px / 64.0 * 0.9
	l.position = at
	l.color = Color(1.0, 0.66, 0.36)
	l.set_meta(&"lit_energy", clampf(energy * 0.35, 0.3, 1.0))
	l.blend_mode = Light2D.BLEND_MODE_ADD
	get_parent().add_child.call_deferred(l)
	_lamps2d.append(l)


func _apply() -> void:
	if not is_inside_tree():
		return
	if indoor:
		# interiors: steady lamplight, no sky or weather, glow on
		_tint.color = Color(0.82, 0.74, 0.8)
		for l in _lamps2d:
			l.energy = float(l.get_meta(&"lit_energy"))
			l.visible = true
		for n in get_tree().get_nodes_in_group(&"night_glow"):
			(n as CanvasItem).modulate = Color(1, 1, 1, 0.5)
			(n as CanvasItem).visible = true
		for n in get_tree().get_nodes_in_group(&"precipitation"):
			n.call(&"set_precipitation", 0.0, 0.0)
		for n in get_tree().get_nodes_in_group(&"fog_overlay"):
			var fm := (n as CanvasItem).material as ShaderMaterial
			if fm != null:
				fm.set_shader_parameter("fog_amount", 0.0)
		return
	var t := WorldTime.day_fraction()
	var day := daylight.sample(t)
	var cloud: float = w["cloud"]
	var dim := 1.0 - cloud * lerpf(0.25, 0.65, day)
	var flash := _flash * _flash
	var sunc := sun_color.sample(t) * sun_energy.sample(t) * dim * 0.5
	var amb := ambient.sample(t) * ambient_energy.sample(t) * 0.55
	var c := Color(sunc.r + amb.r, sunc.g + amb.g, sunc.b + amb.b)
	var grey := c.get_luminance()
	c = c.lerp(Color(grey, grey * 1.02, grey * 1.08), cloud * 0.5 * day)
	c = c.lerp(Color(0.78, 0.84, 0.95), float(w["snow"]) * 0.15)
	c = Color(minf(c.r + flash, 1.0), minf(c.g + flash, 1.0), minf(c.b + flash, 1.0))
	_tint.color = c
	var lit := maxf(lamps.sample(t), cloud * 0.6 * day)
	for l in _lamps2d:
		l.energy = float(l.get_meta(&"lit_energy")) * lit
		l.visible = lit > 0.02
	# glow layers bypass the tint, so they shine against the dark
	for n in get_tree().get_nodes_in_group(&"night_glow"):
		(n as CanvasItem).modulate = Color(1, 1, 1, lit * 0.9)
		(n as CanvasItem).visible = lit > 0.02
	for n in get_tree().get_nodes_in_group(&"precipitation"):
		n.call(&"set_precipitation", float(w["rain"]), float(w["snow"]))
	for n in get_tree().get_nodes_in_group(&"fog_overlay"):
		var m := (n as CanvasItem).material as ShaderMaterial
		if m != null:
			m.set_shader_parameter("fog_amount", 0.03 + float(w["fog"]) * 0.32 + float(w["rain"]) * 0.05 + float(w["snow"]) * 0.05)
