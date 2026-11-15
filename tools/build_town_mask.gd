extends SceneTree
## Builds the walkable mask for the Anjabi town greybox from the layout image itself.
##   Godot --headless --path . -s tools/build_town_mask.gd
## Walkways, beach, docks (beige) and vegetation (green) are walkable; cliffs,
## buildings and water are not. Light-grey slabs that are meant to be walked on
## cannot be told apart from buildings by colour, so they are listed in SLABS.
## Re-run after replacing maps/anjabi/town_greybox.png.

const SRC := "res://maps/anjabi/town_greybox.png"
const OUT := "res://maps/anjabi/town_walk.res"
const DEBUG := "res://docs/reference/town_walkable_debug.png"
const FRAME := Rect2i(34, 34, 1380, 902)
const GREEN_WALKABLE := true
const CLOSE_RADIUS := 3
## Image-pixel polygons forced walkable (mine yard, airpad).
const SLABS := [
	[Vector2(132, 655), Vector2(215, 642), Vector2(295, 668), Vector2(300, 715), Vector2(240, 768), Vector2(150, 755)],
	[Vector2(327, 790), Vector2(357, 750), Vector2(508, 750), Vector2(508, 826), Vector2(425, 850), Vector2(327, 800)],
]
## Landmarks (image pixels) checked for reachability from the first one.
const LANDMARKS := {
	"Steps": Vector2(880, 415), "Forest": Vector2(230, 110), "Garden": Vector2(200, 345),
	"Estate": Vector2(240, 578), "Mine": Vector2(212, 700), "Airpad": Vector2(450, 800),
	"Beach": Vector2(650, 640), "Tion Tower": Vector2(515, 465), "Tavern": Vector2(760, 350),
	"Pods": Vector2(580, 70), "Guard Tower": Vector2(945, 130), "Docks": Vector2(1170, 460),
	"Shop": Vector2(930, 385), "Tram": Vector2(970, 465), "Rainforest": Vector2(1380, 325),
}

var w := 0
var h := 0


func _init() -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path(SRC))
	img.convert(Image.FORMAT_RGB8)
	w = img.get_width()
	h = img.get_height()
	var px := img.get_data()
	var m := PackedByteArray()
	m.resize(w * h)
	for y in range(FRAME.position.y, FRAME.end.y):
		for x in range(FRAME.position.x, FRAME.end.x):
			var i := (y * w + x) * 3
			var r := px[i]
			var g := px[i + 1]
			var b := px[i + 2]
			var beige := r > 205 and g > 185 and b < 228 and r - b > 22 and r >= g
			var green := g > r + 12 and g > b + 25
			if beige or (GREEN_WALKABLE and green):
				m[y * w + x] = 1
	for poly: Array in SLABS:
		var pts := PackedVector2Array(poly)
		var box := Rect2(pts[0], Vector2.ZERO)
		for p in pts:
			box = box.expand(p)
		for y in range(int(box.position.y), int(box.end.y) + 1):
			for x in range(int(box.position.x), int(box.end.x) + 1):
				if Geometry2D.is_point_in_polygon(Vector2(x, y), pts):
					m[y * w + x] = 1
	# close small gaps: label text, stair treads, outlines
	m = _spread(m, CLOSE_RADIUS, 1)
	m = _spread(m, CLOSE_RADIUS, 0)
	for y in h:
		for x in w:
			if not FRAME.has_point(Vector2i(x, y)):
				m[y * w + x] = 0

	var bm := BitMap.new()
	bm.create(Vector2i(w, h))
	var dbg := Image.load_from_file(ProjectSettings.globalize_path(SRC))
	dbg.convert(Image.FORMAT_RGB8)
	var reach := _flood(m, _nearest(m, LANDMARKS["Steps"]))
	for y in h:
		for x in w:
			var i := y * w + x
			if m[i] == 1:
				bm.set_bit(x, y, true)
				dbg.set_pixel(x, y, Color(0.2, 0.9, 0.4) if reach[i] == 1 else Color(0.95, 0.2, 0.7))
			else:
				dbg.set_pixel(x, y, dbg.get_pixel(x, y).darkened(0.55))
	ResourceSaver.save(bm, OUT)
	dbg.save_png(ProjectSettings.globalize_path(DEBUG))
	for k: String in LANDMARKS:
		var p := _nearest(m, LANDMARKS[k])
		var ok := p.x >= 0 and reach[p.y * w + p.x] == 1
		print("%-12s %s  (snapped %.0f px)" % [k, "reachable" if ok else "NOT REACHABLE", Vector2(p).distance_to(LANDMARKS[k])])
	quit()


## Separable box dilation of cells equal to `value`.
func _spread(src: PackedByteArray, r: int, value: int) -> PackedByteArray:
	var tmp := src.duplicate()
	for y in h:
		var run := 0
		for x in range(-r, w):
			var add := x + r
			if add < w and src[y * w + add] == value:
				run += 1
			var drop := x - r - 1
			if drop >= 0 and src[y * w + drop] == value:
				run -= 1
			if x >= 0 and run > 0:
				tmp[y * w + x] = value
	var out := tmp.duplicate()
	for x in w:
		var run := 0
		for y in range(-r, h):
			var add := y + r
			if add < h and tmp[add * w + x] == value:
				run += 1
			var drop := y - r - 1
			if drop >= 0 and tmp[drop * w + x] == value:
				run -= 1
			if y >= 0 and run > 0:
				out[y * w + x] = value
	return out


func _nearest(m: PackedByteArray, at: Vector2) -> Vector2i:
	var c := Vector2i(at)
	for r in range(0, 60):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var p := c + Vector2i(dx, dy)
				if p.x >= 0 and p.y >= 0 and p.x < w and p.y < h and m[p.y * w + p.x] == 1:
					return p
	return Vector2i(-1, -1)


func _flood(m: PackedByteArray, start: Vector2i) -> PackedByteArray:
	var seen := PackedByteArray()
	seen.resize(w * h)
	if start.x < 0:
		return seen
	var stack := PackedInt32Array([start.y * w + start.x])
	seen[stack[0]] = 1
	while not stack.is_empty():
		var i := stack[stack.size() - 1]
		stack.remove_at(stack.size() - 1)
		var x := i % w
		for n: int in [i - 1, i + 1, i - w, i + w]:
			if n < 0 or n >= w * h or seen[n] == 1 or m[n] == 0:
				continue
			if (n == i - 1 and x == 0) or (n == i + 1 and x == w - 1):
				continue
			seen[n] = 1
			stack.append(n)
	return seen
