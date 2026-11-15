extends SceneTree
## Builds the cell grid for the 3D town from the director's greybox and its walk mask.
##   Godot --headless --path . -s tools/build_town_3d.gd
## One cell per metre (0.12 m per greybox pixel). Each cell gets a type (water, path,
## grass, sand, slab, cliff), a visual height and a collision height. Walkable heights
## are interpolated (Laplace) between district anchor heights, so walkways become
## gentle slopes between levels. Cliffs and slabs are raised walls in the collider.
## Writes maps/anjabi/town_3d_cells.res (Image, RGBF: r = visual h, g = type,
## b = collision h) and docs/reference/town_3d_heights_debug.png.
## Re-run after changing the greybox, the mask, or ANCHORS.

const SRC := "res://maps/anjabi/town_greybox.png"
const MASK := "res://maps/anjabi/town_walk.res"
const OUT := "res://maps/anjabi/town_3d_cells.res"
const DEBUG := "res://docs/reference/town_3d_heights_debug.png"
const ORIGIN := Vector2(34, 34)
const PX := 0.12
const W := 166
const H := 109
const SEA := -7.0
const WATER := 0
const PATH := 1
const GRASS := 2
const SAND := 3
const SLAB := 4
const CLIFF := 5
## Image px -> height (m). Walk cells within ANCHOR_R of each are fixed.
const ANCHORS := [
	[Vector2(880, 415), 0.0],    # the Steps
	[Vector2(930, 385), 0.0],    # shop front
	[Vector2(760, 350), 3.0],    # tavern
	[Vector2(650, 250), 4.0],    # pods approach
	[Vector2(580, 70), 6.0],     # pods
	[Vector2(945, 130), 6.0],    # guard tower
	[Vector2(230, 110), 6.0],    # forest
	[Vector2(200, 345), 3.0],    # garden
	[Vector2(240, 578), 3.0],    # estate
	[Vector2(515, 465), 2.0],    # Tion Tower walk
	[Vector2(212, 700), -3.0],   # mine
	[Vector2(450, 800), -3.0],   # airpad
	[Vector2(650, 640), -6.0],   # beach
	[Vector2(1170, 460), -1.0],  # docks
	[Vector2(970, 465), -1.0],   # tram
	[Vector2(1380, 325), 0.0],   # rainforest approach
]
const ANCHOR_R := 4.0

var cls := PackedByteArray()
var hv := PackedFloat32Array()
var hc := PackedFloat32Array()


func _init() -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path(SRC))
	img.convert(Image.FORMAT_RGB8)
	var mask: BitMap = load(MASK)
	cls.resize(W * H)
	hv.resize(W * H)
	hc.resize(W * H)
	var counts := [0, 0, 0, 0, 0, 0]
	for z in H:
		for x in W:
			var p := ORIGIN + (Vector2(x, z) + Vector2(0.5, 0.5)) / PX
			var votes := 0
			for o: Vector2 in [Vector2.ZERO, Vector2(2.5, 0), Vector2(-2.5, 0), Vector2(0, 2.5), Vector2(0, -2.5)]:
				var q := Vector2i(p + o)
				if mask.get_bitv(q):
					votes += 1
			var c := img.get_pixelv(Vector2i(p))
			var t := CLIFF
			if votes >= 3:
				t = GRASS if (c.g8 > c.r8 + 12 and c.g8 > c.b8 + 25) else PATH
			elif c.b8 > c.r8 + 30 and c.b8 > 170:
				t = WATER
			elif absi(c.r8 - c.g8) < 14 and absi(c.g8 - c.b8) < 16 and c.r8 > 168:
				t = SLAB
			cls[z * W + x] = t
			counts[t] += 1
	print("cells: water %d path %d grass %d sand %d slab %d cliff %d" % counts)
	_heights()
	_report()
	var out := Image.create(W, H, false, Image.FORMAT_RGBF)
	var dbg := Image.create(W, H, false, Image.FORMAT_RGB8)
	for z in H:
		for x in W:
			var i := z * W + x
			out.set_pixel(x, z, Color(hv[i], float(cls[i]), hc[i]))
			var k := clampf((hv[i] + 7.0) / 20.0, 0.0, 1.0)
			var col := Color(0.1, 0.25, 0.6) if cls[i] == WATER else Color(k, k, k)
			if _walk(cls[i]):
				col = Color(0.2 + k * 0.8, 0.6 * k + 0.2, 0.2)
			dbg.set_pixel(x, z, col)
	ResourceSaver.save(out, OUT)
	dbg.resize(W * 6, H * 6, Image.INTERPOLATE_NEAREST)
	dbg.save_png(ProjectSettings.globalize_path(DEBUG))
	print("wrote %s and %s" % [OUT, DEBUG])
	quit()


static func _walk(t: int) -> bool:
	return t == PATH or t == GRASS or t == SAND


func _heights() -> void:
	var fixed := PackedByteArray()
	fixed.resize(W * H)
	for a: Array in ANCHORS:
		var c := (a[0] as Vector2 - ORIGIN) * PX
		for z in range(int(c.y - ANCHOR_R), int(c.y + ANCHOR_R) + 1):
			for x in range(int(c.x - ANCHOR_R), int(c.x + ANCHOR_R) + 1):
				if x < 0 or z < 0 or x >= W or z >= H:
					continue
				var i := z * W + x
				if _walk(cls[i]) and Vector2(x + 0.5, z + 0.5).distance_to(c) <= ANCHOR_R:
					fixed[i] = 1
					hv[i] = a[1]
	# successive over-relaxation over walk cells only
	for it in 4000:
		var worst := 0.0
		for z in H:
			for x in W:
				var i := z * W + x
				if fixed[i] == 1 or not _walk(cls[i]):
					continue
				var s := 0.0
				var n := 0
				if x > 0 and _walk(cls[i - 1]):
					s += hv[i - 1]; n += 1
				if x < W - 1 and _walk(cls[i + 1]):
					s += hv[i + 1]; n += 1
				if z > 0 and _walk(cls[i - W]):
					s += hv[i - W]; n += 1
				if z < H - 1 and _walk(cls[i + W]):
					s += hv[i + W]; n += 1
				if n == 0:
					continue
				var nv: float = hv[i] + 1.9 * (s / n - hv[i])
				worst = maxf(worst, absf(nv - hv[i]))
				hv[i] = nv
		if worst < 0.0005:
			print("relaxed in %d iterations" % it)
			break
	for i in W * H:
		if cls[i] == PATH and hv[i] < -4.6:
			cls[i] = SAND
	# non-walk cells: BFS from walk cells carrying the source height
	var base := PackedFloat32Array()
	base.resize(W * H)
	var dist := PackedInt32Array()
	dist.resize(W * H)
	dist.fill(-1)
	var q := PackedInt32Array()
	for i in W * H:
		if _walk(cls[i]):
			dist[i] = 0
			base[i] = hv[i]
			hc[i] = hv[i]
			q.append(i)
	var head := 0
	while head < q.size():
		var i := q[head]
		head += 1
		var x := i % W
		for n: int in [i - 1, i + 1, i - W, i + W]:
			if n < 0 or n >= W * H or dist[n] != -1:
				continue
			if (n == i - 1 and x == 0) or (n == i + 1 and x == W - 1):
				continue
			dist[n] = dist[i] + 1
			base[n] = base[i]
			q.append(n)
	for i in W * H:
		var t := cls[i]
		if _walk(t):
			continue
		var b := base[i] if dist[i] >= 0 else 0.0
		hc[i] = b + 4.0
		match t:
			WATER:
				hv[i] = SEA
			SLAB:
				hv[i] = b + 0.15
			_:
				hv[i] = b + minf(2.2 + dist[i] * 0.5, 5.0)


func _report() -> void:
	var worst := 0.0
	for z in H:
		for x in W - 1:
			var i := z * W + x
			if _walk(cls[i]) and _walk(cls[i + 1]):
				worst = maxf(worst, absf(hv[i] - hv[i + 1]))
			if z < H - 1 and _walk(cls[i]) and _walk(cls[i + W]):
				worst = maxf(worst, absf(hv[i] - hv[i + W]))
	print("steepest walkable step between neighbouring cells: %.2f m (%.0f deg)" % [worst, rad_to_deg(atan(worst))])
