class_name EnvironmentController
extends Node
## Lights a 3D map from WorldTime and Weather. MapBuilder3D._environment() creates one
## per map and hands it the Environment, the sun/moon light and the low warm fill light.
##
## Time of day is read as a fraction (0 = midnight, 0.5 = noon) and sampled from the
## Gradients and Curves below, so the look is data: replace or edit any of them
## (controller.sky, controller.sun_energy, ...) to restyle a map. The sample is taken
## every frame from the continuous clock, so lighting drifts instead of stepping.
## Weather is blended on top over `weather_blend` seconds. snap() applies the current
## state at once (used on load, on entering a map and when the clock jumps).
##
## One shadowed DirectionalLight3D serves as sun by day and moon by night; its energy
## passes through zero at dawn and dusk, where it changes sides unseen.
##
## Indoors: set `indoor = true` (GameMap3D.indoor does it) to ignore sky, sun and
## weather and use `indoor_look` instead.

## Fractions of the day where the light changes sides (sun <-> moon).
const SUNRISE := 0.235
const SUNSET := 0.815

var env: Environment
var sun: DirectionalLight3D
var fill: DirectionalLight3D

var sky := Gradient.new()
var ambient := Gradient.new()
var sun_color := Gradient.new()
var fill_color := Gradient.new()
var fog_color := Gradient.new()
var ambient_energy := Curve.new()
var sun_energy := Curve.new()
var fill_energy := Curve.new()
var exposure := Curve.new()
## 0 at night, 1 in full day: scales how much clouds dim and grey the scene.
var daylight := Curve.new()
## 1 when street lamps are lit.
var lamps := Curve.new()

## Seconds for weather to blend in or out.
var weather_blend := 10.0
var indoor := false
var indoor_look := {
	"ambient": Color(0.62, 0.56, 0.5), "ambient_energy": 0.9, "background": Color(0.02, 0.02, 0.03),
	"fog": 0.0, "exposure": 1.2, "lamps": 1.0,
}

## Smoothed weather: rain, snow, cloud, fog, plus ground wetness and snow cover.
var w := {"rain": 0.0, "snow": 0.0, "cloud": 0.0, "fog": 0.0, "wet": 0.0, "cover": 0.0}
var _flash := 0.0
var _lamp_lights: Array[Light3D] = []
var _lamp_level := -1.0
var _lamp_scan := 0.0


func _init() -> void:
	_defaults()


func setup(e: Environment, sun_light: DirectionalLight3D, fill_light: DirectionalLight3D) -> void:
	env = e
	sun = sun_light
	fill = fill_light


func _ready() -> void:
	add_to_group(&"environment_controller")
	WorldTime.time_jumped.connect(snap)
	Weather.lightning.connect(func() -> void: _flash = 1.0)
	snap.call_deferred()


func _enter_tree() -> void:
	# the game is taken out of the tree behind the title screen; relight on return
	if env != null:
		snap.call_deferred()


## Apply the present time and weather immediately, with no blending.
func snap() -> void:
	var p := Weather.profile()
	for k: String in ["rain", "snow", "cloud", "fog"]:
		w[k] = float(p[k])
	w["wet"] = 1.0 if float(p["rain"]) > 0.0 else 0.0
	w["cover"] = 1.0 if float(p["snow"]) > 0.0 else 0.0
	_flash = 0.0
	_lamp_level = -1.0
	if is_inside_tree():
		for n in get_tree().get_nodes_in_group(&"precipitation"):
			n.call(&"clear_particles")
	_collect_lamps()
	_apply()


func _process(delta: float) -> void:
	var p := Weather.profile()
	var k := 1.0 - exp(-delta * 3.0 / maxf(weather_blend, 0.01))
	for key: String in ["rain", "snow", "cloud", "fog"]:
		w[key] = lerpf(w[key], float(p[key]), k)
	# ground soaks quickly and dries slowly; snow settles and melts slowly
	var raining := float(p["rain"]) > 0.0
	w["wet"] = move_toward(w["wet"], 1.0 if raining else 0.0, delta / (8.0 if raining else 60.0))
	var snowing := float(p["snow"]) > 0.0
	w["cover"] = move_toward(w["cover"], 1.0 if snowing else 0.0, delta / (45.0 if snowing else 60.0))
	_flash = move_toward(_flash, 0.0, delta * 4.0)
	_lamp_scan -= delta
	if _lamp_scan <= 0.0:
		_lamp_scan = 2.0
		_collect_lamps()
	_apply()


func _apply() -> void:
	if env == null or not is_inside_tree():
		return
	if indoor:
		_apply_indoor()
		return
	var t := WorldTime.day_fraction()
	var day := daylight.sample(t)
	var cloud: float = w["cloud"]
	# clouds take most of the sun by day, less of the moon by night
	var dim := 1.0 - cloud * lerpf(0.25, 0.65, day)
	var flash := _flash * _flash

	var bg := sky.sample(t)
	var grey := bg.get_luminance() * lerpf(1.0, 0.8, day)
	bg = bg.lerp(Color(grey, grey * 1.02, grey * 1.06), cloud * 0.8)
	env.background_color = bg.lightened(flash * 0.5)
	var amb := ambient.sample(t).lerp(Color(0.7, 0.8, 1.0), float(w["snow"]) * 0.3)
	env.ambient_light_color = amb
	env.ambient_light_energy = ambient_energy.sample(t) * (1.0 - cloud * 0.25 * day) + flash * 1.2
	env.tonemap_exposure = exposure.sample(t)
	env.adjustment_saturation = 1.18 - cloud * 0.3 * day
	var fog_grey := fog_color.sample(t).get_luminance() * (1.0 - cloud * 0.35)
	env.fog_light_color = fog_color.sample(t).lerp(Color(fog_grey, fog_grey * 1.03, fog_grey * 1.08), cloud * 0.85)
	env.fog_density = 0.002 + float(w["rain"]) * 0.007 * (1.0 - 0.4 * float(w["fog"])) + float(w["fog"]) * 0.0065 + float(w["snow"]) * 0.003

	var is_day := t > SUNRISE and t < SUNSET
	if is_day:
		var u := (t - SUNRISE) / (SUNSET - SUNRISE)
		# rises in the east, crosses the south, sets in the west; never lower than 20 degrees
		sun.rotation_degrees = Vector3(-(20.0 + 46.0 * sin(u * PI)), lerpf(100.0, -100.0, u), 0)
	else:
		sun.rotation_degrees = Vector3(-52, -30, 0)
	sun.light_color = sun_color.sample(t).lerp(Color.WHITE, flash)
	sun.light_energy = sun_energy.sample(t) * dim + flash * 2.5
	# the low warm light comes from wherever the sun is near the horizon
	fill.rotation_degrees = Vector3(-12, 100.0 if t < 0.5 else -100.0, 0)
	fill.light_color = fill_color.sample(t)
	fill.light_energy = fill_energy.sample(t) * dim

	_set_lamps(maxf(lamps.sample(t), cloud * 0.6 * day))
	RenderingServer.global_shader_parameter_set(&"weather_wet", float(w["wet"]))
	RenderingServer.global_shader_parameter_set(&"weather_snow", float(w["cover"]))
	for n in get_tree().get_nodes_in_group(&"precipitation"):
		n.call(&"set_precipitation", float(w["rain"]), float(w["snow"]))


func _apply_indoor() -> void:
	env.background_color = indoor_look["background"]
	env.ambient_light_color = indoor_look["ambient"]
	env.ambient_light_energy = indoor_look["ambient_energy"]
	env.tonemap_exposure = indoor_look["exposure"]
	env.adjustment_saturation = 1.18
	env.fog_density = indoor_look["fog"]
	sun.light_energy = 0.0
	fill.light_energy = 0.0
	_set_lamps(float(indoor_look["lamps"]))
	RenderingServer.global_shader_parameter_set(&"weather_wet", 0.0)
	RenderingServer.global_shader_parameter_set(&"weather_snow", 0.0)
	for n in get_tree().get_nodes_in_group(&"precipitation"):
		n.call(&"set_precipitation", 0.0, 0.0)


## Lamps register themselves in the "lamp_lights" group with their lit energy in meta.
func _collect_lamps() -> void:
	if not is_inside_tree():
		return
	var found: Array[Light3D] = []
	for n in get_tree().get_nodes_in_group(&"lamp_lights"):
		found.append(n as Light3D)
	if found.size() != _lamp_lights.size():
		_lamp_level = -1.0
	_lamp_lights = found


func _set_lamps(level: float) -> void:
	if absf(level - _lamp_level) < 0.01:
		return
	_lamp_level = level
	for l in _lamp_lights:
		if is_instance_valid(l):
			l.light_energy = float(l.get_meta(&"lit_energy", 1.0)) * level
			l.visible = level > 0.02


# --- the default look ---------------------------------------------------------------

func _defaults() -> void:
	var n_sky := Color(0.045, 0.06, 0.1)
	_grad(sky, [[0.0, n_sky], [0.2, Color(0.06, 0.08, 0.15)], [0.25, Color(0.5, 0.4, 0.45)], [0.31, Color(0.5, 0.64, 0.8)],
		[0.5, Color(0.44, 0.63, 0.86)], [0.7, Color(0.47, 0.62, 0.8)], [0.775, Color(0.8, 0.54, 0.36)],
		[0.83, Color(0.25, 0.2, 0.32)], [0.875, n_sky], [1.0, n_sky]])
	var n_amb := Color(0.36, 0.42, 0.55)
	_grad(ambient, [[0.0, n_amb], [0.2, Color(0.36, 0.42, 0.58)], [0.25, Color(0.52, 0.54, 0.74)], [0.33, Color(0.74, 0.78, 0.84)],
		[0.5, Color(0.8, 0.83, 0.86)], [0.7, Color(0.82, 0.8, 0.76)], [0.775, Color(0.72, 0.66, 0.7)],
		[0.83, Color(0.52, 0.46, 0.68)], [0.875, n_amb], [1.0, n_amb]])
	var moon := Color(0.52, 0.62, 0.86)
	_grad(sun_color, [[0.0, moon], [SUNRISE - 0.005, moon], [SUNRISE + 0.005, Color(1.0, 0.76, 0.74)], [0.3, Color(1.0, 0.84, 0.72)],
		[0.4, Color(1.0, 0.96, 0.9)], [0.66, Color(1.0, 0.95, 0.86)], [0.76, Color(1.0, 0.8, 0.56)],
		[SUNSET - 0.005, Color(1.0, 0.64, 0.46)], [SUNSET + 0.005, moon], [1.0, moon]])
	var glow := Color(1.0, 0.55, 0.35)
	_grad(fill_color, [[0.0, glow], [0.2, Color(1.0, 0.6, 0.62)], [0.27, Color(1.0, 0.68, 0.6)], [0.5, Color(1.0, 0.9, 0.8)],
		[0.72, Color(1.0, 0.7, 0.42)], [0.8, Color(1.0, 0.55, 0.32)], [1.0, glow]])
	var n_fog := Color(0.2, 0.25, 0.33)
	_grad(fog_color, [[0.0, n_fog], [0.2, n_fog], [0.26, Color(0.56, 0.5, 0.6)], [0.33, Color(0.64, 0.72, 0.8)],
		[0.5, Color(0.66, 0.74, 0.82)], [0.7, Color(0.68, 0.72, 0.76)], [0.775, Color(0.68, 0.5, 0.4)],
		[0.83, Color(0.3, 0.27, 0.38)], [0.875, n_fog], [1.0, n_fog]])
	_curve(ambient_energy, [[0.0, 0.75], [0.2, 0.75], [SUNRISE, 1.3], [0.28, 1.0], [0.5, 1.0], [0.7, 0.95], [0.78, 1.0], [SUNSET, 1.3], [0.85, 0.95], [0.875, 0.75], [1.0, 0.75]])
	_curve(sun_energy, [[0.0, 0.86], [SUNRISE - 0.012, 0.7], [SUNRISE, 0.0], [SUNRISE + 0.012, 0.45], [0.27, 0.7], [0.36, 1.05], [0.5, 1.2], [0.68, 1.1],
		[0.77, 0.95], [SUNSET - 0.012, 0.55], [SUNSET, 0.0], [SUNSET + 0.012, 0.6], [0.86, 0.8], [1.0, 0.86]])
	_curve(fill_energy, [[0.0, 0.35], [0.17, 0.2], [0.2, 0.0], [0.25, 0.32], [0.31, 0.2], [0.4, 0.0], [0.62, 0.0],
		[0.72, 0.25], [0.785, 0.5], [0.83, 0.45], [0.875, 0.4], [1.0, 0.35]])
	_curve(exposure, [[0.0, 1.45], [0.2, 1.45], [0.27, 1.25], [0.36, 1.05], [0.5, 1.0], [0.7, 1.02], [0.78, 1.25], [0.84, 1.4], [0.875, 1.45], [1.0, 1.45]])
	_curve(daylight, [[0.0, 0.0], [0.2, 0.0], [0.3, 1.0], [0.74, 1.0], [0.85, 0.0], [1.0, 0.0]])
	_curve(lamps, [[0.0, 1.0], [0.225, 1.0], [0.255, 0.0], [0.74, 0.0], [0.79, 1.0], [1.0, 1.0]])


static func _grad(g: Gradient, keys: Array) -> void:
	var offsets := PackedFloat32Array()
	var colors := PackedColorArray()
	for k: Array in keys:
		offsets.append(k[0])
		colors.append(k[1])
	g.offsets = offsets
	g.colors = colors


static func _curve(c: Curve, keys: Array) -> void:
	c.clear_points()
	c.min_value = 0.0
	c.max_value = 4.0
	for k: Array in keys:
		c.add_point(Vector2(k[0], k[1]), 0, 0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
