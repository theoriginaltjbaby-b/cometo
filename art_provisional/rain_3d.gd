class_name Rain3D
extends GPUParticles3D
## Precipitation around the player: rain streaks that catch the lamps, splashes on the
## ground, and snow. Follows its parent (the player); particles stay in world space.
## One set of emitters is reused for every weather: EnvironmentController calls
## set_precipitation(rain, snow) with 0..1 amounts and the emitters thin out or stop.

var _splash: GPUParticles3D
var _snow: GPUParticles3D


func _init() -> void:
	add_to_group(&"precipitation")
	# the handheld view is smaller and low-res: fewer streaks read the same
	amount = 900 if ArtStyle.handheld else 1600
	lifetime = 0.9
	preprocess = 1.0
	local_coords = false
	visibility_aabb = AABB(Vector3(-20, -14, -20), Vector3(40, 30, 40))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(16, 0.5, 16)
	pm.direction = Vector3(-0.15, -1, 0.1)
	pm.spread = 2.0
	pm.initial_velocity_min = 16.0
	pm.initial_velocity_max = 20.0
	pm.gravity = Vector3(0, -6, 0)
	pm.particle_flag_align_y = true
	process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.012, 0.55)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.8, 0.86, 0.95, 0.14)
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	m.billboard_keep_scale = true
	q.material = m
	draw_pass_1 = q
	position = Vector3(0, 12, 0)
	_splash = _splashes()
	add_child(_splash)
	_snow = _snowfall()
	add_child(_snow)
	set_precipitation(0.5, 0.0)


## rain and snow are 0..1: 0 stops the emitter, 1 is the heaviest fall.
func set_precipitation(rain: float, snow: float) -> void:
	_level(self, rain)
	_level(_splash, rain)
	_level(_snow, snow)


## Drop every live particle (used when the weather is set instantly, not blended).
func clear_particles() -> void:
	for p: GPUParticles3D in [self, _splash, _snow]:
		p.restart()


static func _level(p: GPUParticles3D, level: float) -> void:
	var on := level > 0.02
	if p.emitting != on:
		p.emitting = on
	if on:
		p.amount_ratio = clampf(level, 0.05, 1.0)


## Droplets bursting on the ground around the player.
static func _splashes() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = 240 if ArtStyle.handheld else 460
	p.lifetime = 0.35
	p.local_coords = false
	p.position = Vector3(0, -11.9, 0)
	p.visibility_aabb = AABB(Vector3(-16, -2, -16), Vector3(32, 4, 32))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(11, 0.02, 11)
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 35.0
	pm.initial_velocity_min = 0.6
	pm.initial_velocity_max = 1.3
	pm.gravity = Vector3(0, -9, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.2
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.035, 0.035)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.85, 0.9, 1.0, 0.35)
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	q.material = m
	p.draw_pass_1 = q
	return p


## Slow drifting flakes.
static func _snowfall() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = 420 if ArtStyle.handheld else 700
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.local_coords = false
	p.emitting = false
	p.visibility_aabb = AABB(Vector3(-20, -14, -20), Vector3(40, 30, 40))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(16, 0.5, 16)
	pm.direction = Vector3(-0.2, -1, 0.1)
	pm.spread = 14.0
	pm.initial_velocity_min = 1.5
	pm.initial_velocity_max = 2.4
	pm.gravity = Vector3(-0.15, -0.1, 0)
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.5
	pm.turbulence_noise_scale = 2.5
	pm.scale_min = 0.6
	pm.scale_max = 1.4
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.06, 0.06)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.95, 0.97, 1.0, 0.8)
	# soft round flake
	var g := Gradient.new()
	g.set_color(0, Color.WHITE)
	g.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.width = 16
	tex.height = 16
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	m.albedo_texture = tex
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	q.material = m
	p.draw_pass_1 = q
	return p
