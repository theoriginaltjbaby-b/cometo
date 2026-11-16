extends Node
## Bakes the 3D Steps district into 2D art for the Golden Sun-style prototype
## (maps/anjabi/steps_2d.tscn). Windowed, because it renders:
##   Godot --path . res://tools/bake_2d.tscn
##
## Projection: an orthographic camera pitched 45 degrees, image stretched vertically by
## sqrt(2), so a point (x, y, z) lands at screen (x, z - y) metres: ground squares stay
## square and walls stand straight up, the classic 3/4 oblique view. S pixels per metre.
##
## Writes res://art/baked2d/steps/:
##   ground.png        everything flat (paving, walls, stairs, sea), with the shadows of
##                     the tall things falling on it; lit for a neutral clear day
##   ground_glow.png   emissive surfaces only (signs, windows), added at night
##   objects/NNN.png   each model (building, lamp, tree, barrel...) alone, plus _glow
##   heights.res       Image (FORMAT_RF): top surface height per 1/4 m, -1000 = nothing
##   layout.json       where everything goes, lamps, interactables, people, spawns
## and res://art/baked2d/chars/<id>.png: 8 directions x (idle, 8 walk, 8 run) sheets.

const OUT := "res://art/baked2d/steps/"
const CHARS := "res://art/baked2d/chars/"
const S := 16
const SS := 2
const X0 := -46.0
const X1 := 46.0
const V0 := -58.0
const V1 := 46.0
const Z0 := -46.0
const Z1 := 40.0
const GRID := 4
const CELL := Vector2i(32, 42)
const CELL_FEET := 35
const DIRS := 8

var district: Node3D
var vp: SubViewport
var cam: Camera3D
var sun: DirectionalLight3D
var env: Environment


func _ready() -> void:
	MapBuilder3D.bake_mode = true
	RenderingServer.directional_shadow_atlas_set_size(8192, true)
	RenderingServer.global_shader_parameter_set(&"weather_wet", 0.35)
	RenderingServer.global_shader_parameter_set(&"weather_snow", 0.0)
	DirAccess.make_dir_recursive_absolute(OUT + "objects")
	DirAccess.make_dir_recursive_absolute(CHARS)
	for d: String in [OUT + "objects", CHARS]:
		var da := DirAccess.open(d)
		for f in da.get_files():
			da.remove(f)

	vp = SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.size = Vector2i(int((X1 - X0) * S * SS), int((V1 - V0) * S * SS / sqrt(2.0)))
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(vp)
	district = (load("res://maps/anjabi/district.tscn") as PackedScene).instantiate()
	vp.add_child(district)
	await get_tree().process_frame
	await get_tree().process_frame

	var layout := {"S": S, "grid": GRID, "x0": X0, "v0": V0, "z0": Z0, "sea": -7.0,
		"width": int((X1 - X0) * S), "height": int((V1 - V0) * S),
		"objects": [], "lamps": [], "interactables": [], "people": [], "spawns": {}}
	_collect_and_strip(layout)
	_setup_view()

	# classify direct children: models become sprites, signs ride with their model
	var objects: Array[Node3D] = []
	var boxes: Array[AABB] = []
	var labels: Array[Label3D] = []
	for c in district.get_children():
		if c is Label3D:
			labels.append(c)
		elif c is Node3D and (c as Node3D).scene_file_path.ends_with(".glb"):
			var b := _aabb(c)
			if b.size.length() > 0.01 and b.get_center().x > X0 - 2 and b.get_center().x < X1 + 2 and b.get_center().z > Z0 - 6 and b.get_center().z < Z1 + 4:
				objects.append(c)
				boxes.append(b)
	var owner_of := {}
	for l in labels:
		for i in objects.size():
			if boxes[i].grow(1.6).has_point(l.global_position):
				owner_of[l] = i
				break
	print("bake: %d objects, %d labels" % [objects.size(), labels.size()])

	# ground: tall things cast shadows but are not drawn
	for o in objects:
		_shadow_only(o, true)
	for l: Label3D in owner_of:
		l.visible = false
	district.entities.visible = false
	var lit := await _render(false)
	lit.save_png(OUT + "ground.png")
	var glow := await _render(true)
	if _bright(glow):
		glow.save_png(OUT + "ground_glow.png")
	for o in objects:
		_shadow_only(o, false)

	# each object alone
	var keep: Array[Node] = []
	for c in district.get_children():
		if c.visible:
			keep.append(c)
	for i in objects.size():
		for c in keep:
			(c as Node3D).visible = c == objects[i] or owner_of.get(c, -1) == i
		var img := await _render(false)
		var used := img.get_used_rect()
		if used.size.x < 1:
			continue
		var name := "%03d" % i
		img.get_region(used).save_png(OUT + "objects/" + name + ".png")
		var entry := {"file": name, "rect": [used.position.x, used.position.y, used.size.x, used.size.y],
			"sort_z": boxes[i].get_center().z, "model": objects[i].scene_file_path.get_file().get_basename()}
		var g := await _render(true)
		var gr := g.get_region(used)
		if _bright(gr):
			gr.save_png(OUT + "objects/" + name + "_glow.png")
			entry["glow"] = true
		(layout["objects"] as Array).append(entry)
	for c in keep:
		(c as Node3D).visible = true

	# heights
	await get_tree().physics_frame
	var heights := _heights()
	ResourceSaver.save(heights, OUT + "heights.res")

	var f := FileAccess.open(OUT + "layout.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(layout, "\t"))
	f.close()

	# character sheets
	await _bake_people(layout)
	f = FileAccess.open(OUT + "layout.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(layout, "\t"))
	f.close()
	print("bake: done")
	get_tree().quit()


# --- scene preparation -----------------------------------------------------------

## Records lamps, interactables, people and spawns, then removes the district's own
## lights, environment and probes so the bake controls the light.
func _collect_and_strip(layout: Dictionary) -> void:
	for n in district.find_children("*", "OmniLight3D", true, false):
		var l := n as OmniLight3D
		var p := l.global_position
		(layout["lamps"] as Array).append({"x": p.x, "y": p.y, "z": p.z, "energy": float(l.get_meta(&"lit_energy", l.light_energy)), "range": l.omni_range})
	for n in district.find_children("*", "Interactable3D", true, false):
		var it := n as Interactable3D
		if it.get_parent() is Npc3D:
			continue
		var p := it.global_position
		var e := {"prompt": it.prompt, "label": it.label, "dialogue_id": it.dialogue_id, "radius": it.radius, "x": p.x, "y": p.y, "z": p.z}
		if it is MapExit3D:
			e["target_map"] = (it as MapExit3D).target_map
			e["target_spawn"] = (it as MapExit3D).target_spawn
		(layout["interactables"] as Array).append(e)
	var people := 0
	for n in district.entities.get_children():
		var d := {}
		if n is Npc3D:
			var npc := n as Npc3D
			d = {"name": npc.display_name, "dialogue_id": npc.dialogue_id, "coat": npc.coat.to_html(), "accent": npc.accent.to_html(),
				"skin": npc.skin.to_html(), "hood": npc.hood, "look": _look_json(npc.look), "yaw": npc.yaw_deg,
				"points": [[npc.global_position.x, npc.global_position.y, npc.global_position.z]]}
		elif n is Townsfolk:
			var t := n as Townsfolk
			var pts := []
			for p in t.points:
				pts.append([p.x, p.y, p.z])
			d = {"name": "", "dialogue_id": "", "coat": t.coat.to_html(), "accent": t.accent.to_html(), "skin": t.skin.to_html(),
				"hood": t.hood, "look": _look_json(t.look), "yaw": t.yaw_deg, "points": pts}
		else:
			continue
		d["sheet"] = "person_%02d" % people
		people += 1
		(layout["people"] as Array).append(d)
	for m in district.get_node("Spawns").get_children():
		var p := (m as Node3D).global_position
		layout["spawns"][str(m.name)] = [p.x, p.y, p.z]
	for t: String in ["OmniLight3D", "DirectionalLight3D", "WorldEnvironment", "ReflectionProbe", "EnvironmentController"]:
		for n in district.find_children("*", t, true, false):
			n.get_parent().remove_child(n)
			n.free()


static func _look_json(look: Dictionary) -> Dictionary:
	var out := {}
	for k: String in look:
		var v: Variant = look[k]
		out[k] = (v as Color).to_html() if v is Color else v
	return out


func _setup_view() -> void:
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.size = (V1 - V0) / sqrt(2.0)
	cam.rotation_degrees = Vector3(-45, 0, 0)
	cam.near = 1.0
	cam.far = 500.0
	var vc := (V0 + V1) * 0.5
	cam.position = Vector3((X0 + X1) * 0.5, 0, vc) + Vector3(0, sin(PI / 4), cos(PI / 4)) * 200.0
	vp.add_child(cam)
	cam.current = true
	sun = _sun()
	vp.add_child(sun)
	env = _env()
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)


static func _sun() -> DirectionalLight3D:
	var l := DirectionalLight3D.new()
	l.rotation_degrees = Vector3(-52, 205, 0)
	l.light_color = Color(1.0, 0.95, 0.86)
	l.light_energy = 1.45
	l.shadow_enabled = true
	l.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	l.directional_shadow_max_distance = 600.0
	l.shadow_blur = 1.5
	return l


static func _env() -> Environment:
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.66, 0.78)
	e.ambient_light_energy = 0.55
	e.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = 1.05
	e.adjustment_enabled = true
	e.adjustment_saturation = 1.15
	e.adjustment_contrast = 1.05
	return e


static func _aabb(n: Node) -> AABB:
	var out := AABB()
	var first := true
	for v in n.find_children("*", "VisualInstance3D", true, false):
		var vi := v as VisualInstance3D
		var b := vi.global_transform * vi.get_aabb()
		out = b if first else out.merge(b)
		first = false
	if n is VisualInstance3D:
		var b := (n as VisualInstance3D).global_transform * (n as VisualInstance3D).get_aabb()
		out = b if first else out.merge(b)
	return out


static func _shadow_only(n: Node, on: bool) -> void:
	for g in n.find_children("*", "GeometryInstance3D", true, false):
		(g as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY if on else GeometryInstance3D.SHADOW_CASTING_SETTING_ON


# --- rendering -------------------------------------------------------------------

## One frame of the map viewport at final size. glow = emissive surfaces only.
func _render(glow: bool) -> Image:
	sun.visible = not glow
	env.ambient_light_energy = 0.0 if glow else 0.55
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	img.resize(int((X1 - X0) * S), int((V1 - V0) * S), Image.INTERPOLATE_LANCZOS)
	return img


static func _bright(img: Image) -> bool:
	var w := img.get_width()
	var h := img.get_height()
	for y in range(0, h, 2):
		for x in range(0, w, 2):
			var c := img.get_pixel(x, y)
			if c.a > 0.3 and c.get_luminance() > 0.12:
				return true
	return false


# --- heights ---------------------------------------------------------------------

## Top surface height every 1/4 m: the highest of five rays (centre and +-0.1 m), so
## thin railings are not missed.
func _heights() -> Image:
	var space := vp.find_world_3d().direct_space_state
	var w := int((X1 - X0) * GRID)
	var h := int((Z1 - Z0) * GRID)
	var img := Image.create(w, h, false, Image.FORMAT_RF)
	var q := PhysicsRayQueryParameters3D.new()
	q.collision_mask = 1
	q.collide_with_areas = false
	var offs: Array[Vector2] = [Vector2.ZERO, Vector2(0.1, 0), Vector2(-0.1, 0), Vector2(0, 0.1), Vector2(0, -0.1)]
	for j in h:
		for i in w:
			var x := X0 + (i + 0.5) / GRID
			var z := Z0 + (j + 0.5) / GRID
			var top := -1000.0
			for o in offs:
				q.from = Vector3(x + o.x, 40.0, z + o.y)
				q.to = Vector3(x + o.x, -20.0, z + o.y)
				var r := space.intersect_ray(q)
				if not r.is_empty():
					top = maxf(top, (r["position"] as Vector3).y)
			img.set_pixel(i, j, Color(top, 0, 0))
	return img


# --- characters ------------------------------------------------------------------

func _bake_people(layout: Dictionary) -> void:
	var cvp := SubViewport.new()
	cvp.own_world_3d = true
	cvp.transparent_bg = true
	cvp.msaa_3d = Viewport.MSAA_4X
	var k := 4
	cvp.size = Vector2i(CELL.x * k, int(CELL.y * k / sqrt(2.0)))
	cvp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(cvp)
	var c := Camera3D.new()
	c.projection = Camera3D.PROJECTION_ORTHOGONAL
	c.keep_aspect = Camera3D.KEEP_HEIGHT
	var top_v := -float(CELL_FEET) / S
	var bot_v := float(CELL.y - CELL_FEET) / S
	c.size = (bot_v - top_v) / sqrt(2.0)
	c.rotation_degrees = Vector3(-45, 0, 0)
	c.position = Vector3(0, 0, (top_v + bot_v) * 0.5) + Vector3(0, sin(PI / 4), cos(PI / 4)) * 20.0
	c.near = 1.0
	c.far = 60.0
	cvp.add_child(c)
	c.current = true
	var l := _sun()
	l.shadow_enabled = false
	cvp.add_child(l)
	var we := WorldEnvironment.new()
	we.environment = _env()
	cvp.add_child(we)
	var specs: Array[Dictionary] = [{"sheet": "player", "coat": Color(0.5, 0.13, 0.11).to_html(), "accent": Color(0.62, 0.42, 0.2).to_html(),
		"skin": Color(0.78, 0.6, 0.48).to_html(), "hood": false, "look": {"hair": "bun", "hair_color": Color(0.1, 0.06, 0.05).to_html(), "long_coat": true}}]
	for p: Dictionary in layout["people"]:
		specs.append(p)
	for spec in specs:
		var f := Figure3D.new()
		f.coat = Color.html(str(spec["coat"]))
		f.accent = Color.html(str(spec["accent"]))
		f.skin = Color.html(str(spec["skin"]))
		f.hood = bool(spec["hood"])
		var look := {}
		for key: String in spec["look"]:
			var v: Variant = spec["look"][key]
			look[key] = Color.html(str(v)) if key == "hair_color" else v
		f.configure(look)
		cvp.add_child(f)
		f.set_process(false)
		await get_tree().process_frame
		var sheet := Image.create(CELL.x * 17, CELL.y * DIRS, false, Image.FORMAT_RGBA8)
		for d in DIRS:
			var a := TAU * d / DIRS
			var dir := Vector2(cos(a), sin(a))
			f.rotation.y = atan2(-dir.x, -dir.y)
			for col in 17:
				_pose(f, col)
				cvp.render_target_update_mode = SubViewport.UPDATE_ONCE
				await RenderingServer.frame_post_draw
				await RenderingServer.frame_post_draw
				var img := cvp.get_texture().get_image()
				img.convert(Image.FORMAT_RGBA8)
				img.resize(CELL.x, CELL.y, Image.INTERPOLATE_LANCZOS)
				_crisp(img)
				sheet.blit_rect(img, Rect2i(Vector2i.ZERO, CELL), Vector2i(col * CELL.x, d * CELL.y))
		sheet.save_png(CHARS + str(spec["sheet"]) + ".png")
		f.queue_free()
		await get_tree().process_frame
	cvp.queue_free()


## Column 0 idle, 1-8 walk, 9-16 run (phase steps of 1/8 cycle).
static func _pose(f: Figure3D, col: int) -> void:
	f._t = 0.0
	if col == 0:
		f._amount = 0.0
		f._run = 0.0
		f._phase = 0.0
		f._speed = 0.0
	else:
		var run := col >= 9
		f._amount = 1.0
		f._run = 1.0 if run else 0.0
		f._speed = 1.8 if run else 1.0
		f._phase = TAU * float((col - 1) % 8) / 8.0
	f._process(0.0)


## Hard alpha edge and a one-pixel dark outline, so sprites read as pixel art.
static func _crisp(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var solid := PackedByteArray()
	solid.resize(w * h)
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			if c.a >= 0.45:
				c.a = 1.0
				img.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0))
				solid[y * w + x] = 1
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	var ink := Color(0.05, 0.04, 0.07, 1.0)
	for y in h:
		for x in w:
			if solid[y * w + x] == 1:
				continue
			for o: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx := x + o.x
				var ny := y + o.y
				if nx >= 0 and ny >= 0 and nx < w and ny < h and solid[ny * w + nx] == 1:
					img.set_pixel(x, y, ink)
					break
