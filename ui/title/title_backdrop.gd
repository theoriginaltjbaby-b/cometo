class_name TitleBackdrop
extends Control
## The planet behind the title: a shader-drawn limb, ground and cloud layers that scroll
## at different speeds, and (added by TitleScreen in front of the title lettering) the
## ship and a layer of near cloud. Nothing here is simulated; it is three flat layers.

const PLANET := preload("res://art/shaders/title_planet.gdshader")
const WISPS := preload("res://art/shaders/title_wisps.gdshader")

var planet: ColorRect
var _mats: Array[ShaderMaterial] = []
static var _noise: NoiseTexture2D


## Seamless cloud noise shared by the layers.
static func noise() -> NoiseTexture2D:
	if _noise == null:
		var n := FastNoiseLite.new()
		n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		n.frequency = 0.012
		n.fractal_octaves = 5
		n.fractal_gain = 0.52
		_noise = NoiseTexture2D.new()
		_noise.width = 256 if OS.has_feature("web") else 512
		_noise.height = _noise.width
		_noise.seamless = true
		_noise.generate_mipmaps = true
		_noise.noise = n
	return _noise


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	planet = _layer(PLANET)
	(planet.material as ShaderMaterial).set_shader_parameter("lite", 1.0 if is_lite() else 0.0)
	resized.connect(_fit)
	_fit()


## Near cloud, to be placed in front of the ship.
func make_wisps() -> ColorRect:
	var w := _layer(WISPS, false)
	_fit()
	return w


## Web and other constrained targets get the lighter planet shader.
static func is_lite() -> bool:
	return OS.has_feature("web")


func _layer(shader: Shader, add := true) -> ColorRect:
	var r := ColorRect.new()
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = shader
	m.set_shader_parameter("noise_tex", noise())
	r.material = m
	_mats.append(m)
	if add:
		add_child(r)
		r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return r


func _fit() -> void:
	var a := size.x / maxf(size.y, 1.0)
	for m in _mats:
		m.set_shader_parameter("aspect", a)
