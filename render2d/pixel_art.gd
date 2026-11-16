class_name PixelArt
## The 2D art provider. Gameplay and map data only ever name things ("cobble",
## "lamp", "stall_rose", a character look); this class turns names into textures.
##
## Replacing the art: drop a PNG into res://art/pixel/ with the same name
## (tiles: art/pixel/tiles/<name>.png, 16x16; props: art/pixel/props/<name>.png;
## characters: art/pixel/chars/<id>.png, 16x32 frames in the sheet layout below) and it
## is used instead of the generated placeholder. No gameplay code changes.
##
## PLACEHOLDER ART: everything generated here is temporary programmer art in the
## Anjabi settlement palette (dusty rose, warm stone, ochre, muted teal, verdigris,
## indigo slate, aged brass, deep violet, warm amber light).

const T := 16
const OVERRIDE := "res://art/pixel/"

## Character sheet layout: 16x32 frames; columns idle, walk 1-4, run 1-4;
## rows facing down, up, left, right.
const FRAME := Vector2i(16, 32)
const COLS := 9
const DIRS := ["down", "up", "left", "right"]

# --- palette --------------------------------------------------------------------
const INK := Color("1c1622")
const STONE_HI := Color("a6948f")
const STONE := Color("85746f")
const STONE_LO := Color("62545a")
const MORTAR := Color("3e3340")
const COBBLE := Color("8b7a79")
const COBBLE_LO := Color("6d5f62")
const PAVE := Color("9e8c84")
const ROSE := Color("a8716c")
const ROSE_LO := Color("865a5c")
const OCHRE := Color("ae8a5a")
const OCHRE_LO := Color("8a6a46")
const TEAL := Color("5d8582")
const TEAL_LO := Color("466866")
const SLATE := Color("3d3754")
const SLATE_HI := Color("57507a")
const SLATE_LO := Color("2a253c")
const VERD := Color("4f8c7e")
const VERD_HI := Color("74b09e")
const BRASS := Color("aa7e3e")
const BRASS_HI := Color("dcb064")
const BRASS_LO := Color("5e4322")
const WOOD := Color("5c3a28")
const WOOD_HI := Color("7c5136")
const CANVAS_ROSE := Color("8e3542")
const CANVAS_TEAL := Color("2f6a6c")
const CREAM := Color("d6c29c")
const GLASS := Color("ffcf7a")
const GLASS_CORE := Color("fff0c0")
const GLASS_DARK := Color("2b2840")
const GRASS := Color("3f5f50")
const GRASS_HI := Color("547a63")
const GRASS_LO := Color("2e4a40")
const WATER := Color("1f2d46")
const WATER_HI := Color("35507a")
const LEAF := Color("3d6a48")
const LEAF_HI := Color("5a8a5a")
const BLOSSOM := Color("ece4d6")
const LAVENDER := Color("8d6bb6")
const POT := Color("9c5c3c")
const SCREEN := Color("5fe0ea")
const VOID := Color("0c0a12")

static var _tiles := {}
static var _props := {}
static var _sheets := {}


# --- public ---------------------------------------------------------------------

## A 16x16 tile image by name (override PNG if present, else generated).
static func tile(name: String) -> Image:
	if not _tiles.has(name):
		var img := _load_override("tiles/" + name)
		if img == null:
			img = _blank(T, T)
			_draw_tile(img, name)
		_tiles[name] = img
	return _tiles[name]


## The emissive part of a tile (windows, shopfronts) or null.
static func tile_glow(name: String) -> Image:
	return _glow_of(tile(name)) if name in GLOW_TILES else null


const GLOW_TILES := ["window_lit", "window_lit_rose", "window_lit_ochre", "window_lit_teal", "shop_window"]


## A prop texture by name, origin at the bottom-centre of its footprint.
static func prop(name: String) -> Texture2D:
	if not _props.has(name):
		var img := _load_override("props/" + name)
		if img == null:
			img = _draw_prop(name)
		_props[name] = ImageTexture.create_from_image(img)
	return _props[name]


## The emissive part of a prop (lantern glass, screens), or null.
static func prop_glow(name: String) -> Texture2D:
	var key := name + "#glow"
	if not _props.has(key):
		var src := (prop(name) as ImageTexture).get_image()
		var g := _glow_of(src)
		_props[key] = ImageTexture.create_from_image(g) if g != null else null
	return _props[key]


## A character sheet for a look: {coat, skin, hair, hair_color, long_coat, accent,
## hat, apron}. Colours may be Color or HTML strings. `id` names an override file.
static func character(look: Dictionary, id := "") -> Texture2D:
	var key := id if id != "" else str(look)
	if not _sheets.has(key):
		var img: Image = null
		if id != "":
			img = _load_override("chars/" + id)
		if img == null:
			img = _draw_character(look)
		_sheets[key] = ImageTexture.create_from_image(img)
	return _sheets[key]


# --- helpers --------------------------------------------------------------------

static func _load_override(rel: String) -> Image:
	var path := OVERRIDE + rel + ".png"
	if ResourceLoader.exists(path):
		var t := load(path) as Texture2D
		if t != null:
			return t.get_image()
	return null


static func _blank(w: int, h: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


static func h2(x: int, y: int, s: int = 0) -> float:
	var n := x * 374761393 + y * 668265263 + s * 2246822519
	n = (n ^ (n >> 13)) * 1274126177
	return float((n ^ (n >> 16)) & 0xffff) / 65535.0


static func px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		if c.a >= 0.999:
			img.set_pixel(x, y, c)
		elif c.a > 0.0:
			img.set_pixel(x, y, img.get_pixel(x, y).blend(c))


static func rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for j in h:
		for i in w:
			px(img, x + i, y + j, c)


static func hline(img: Image, x: int, y: int, w: int, c: Color) -> void:
	rect(img, x, y, w, 1, c)


static func vline(img: Image, x: int, y: int, h: int, c: Color) -> void:
	rect(img, x, y, 1, h, c)


static func ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				px(img, x, y, c)


static func ring(img: Image, cx: float, cy: float, rx: float, ry: float, w: float, c: Color) -> void:
	for y in range(int(cy - ry) - 2, int(cy + ry) + 3):
		for x in range(int(cx - rx) - 2, int(cx + rx) + 3):
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			var d := sqrt(dx * dx + dy * dy)
			if absf(d - 1.0) * minf(rx, ry) <= w * 0.5:
				px(img, x, y, c)


## A dark one-pixel outline around every opaque shape.
static func outline(img: Image, c: Color = INK) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var src := img.duplicate() as Image
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a > 0.5:
				continue
			for o: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx := x + o.x
				var ny := y + o.y
				if nx >= 0 and ny >= 0 and nx < w and ny < h and src.get_pixel(nx, ny).a > 0.5:
					img.set_pixel(x, y, c)
					break


## Keeps only bright warm or cyan pixels (lamp glass, lit windows, screens).
static func _glow_of(src: Image) -> Image:
	var g := _blank(src.get_width(), src.get_height())
	var any := false
	for y in src.get_height():
		for x in src.get_width():
			var c := src.get_pixel(x, y)
			if c.a > 0.5 and c.get_luminance() > 0.68 and (c.r > 0.9 or c.b > 0.85) and c.s > 0.25:
				g.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0))
				any = true
	return g if any else null


# --- tiles ----------------------------------------------------------------------

static func _draw_tile(img: Image, name: String) -> void:
	match name:
		"cobble":
			_cobbles(img, COBBLE, COBBLE_LO, MORTAR, 0)
		"cobble_warm":
			_cobbles(img, Color("94807a"), COBBLE_LO, MORTAR, 3)
		"plaza_band":
			_flags(img, PAVE, STONE_LO, 1)
		"terrace":
			_flags(img, Color("8f7d7a"), MORTAR, 2)
		"grass":
			img.fill(GRASS)
			for i in 26:
				var x := int(h2(i, 1, 7) * 16)
				var y := int(h2(i, 2, 7) * 16)
				px(img, x, y, GRASS_HI if i % 3 else GRASS_LO)
				if i % 5 == 0:
					px(img, x, y - 1, GRASS_HI)
		"flowers":
			_draw_tile(img, "grass")
			for i in 7:
				var x := 1 + int(h2(i, 3, 9) * 14)
				var y := 1 + int(h2(i, 4, 9) * 14)
				px(img, x, y, [LAVENDER, BLOSSOM, ROSE, LAVENDER][i % 4])
				px(img, x, y + 1, LEAF)
		"stairs":
			for y in 16:
				var k := y % 4
				var c := STONE_HI if k == 0 else (STONE if k < 3 else MORTAR)
				hline(img, 0, y, 16, c)
			for y in range(0, 16, 4):
				for x in 16:
					if h2(x, y, 5) < 0.15:
						px(img, x, y + 1, STONE_LO)
		"water":
			img.fill(WATER)
			for i in 10:
				var x := int(h2(i, 5, 11) * 14)
				var y := int(h2(i, 6, 11) * 16)
				hline(img, x, y, 2 + i % 3, WATER_HI)
		"floor_wood":
			for y in 16:
				var plank := y / 4
				var c := WOOD_HI if plank % 2 == 0 else WOOD
				hline(img, 0, y, 16, c)
				if y % 4 == 3:
					hline(img, 0, y, 16, Color("3e2618"))
			for p in 4:
				vline(img, int(h2(p, 8, 2) * 15), p * 4, 3, Color("3e2618"))
		"floor_tile":
			_flags(img, Color("6e6070"), Color("4a3e4c"), 4)
		"mat":
			img.fill(CANVAS_ROSE)
			rect(img, 1, 1, 14, 14, Color("a64454"))
			rect(img, 3, 3, 10, 10, CANVAS_ROSE)
		"void":
			img.fill(VOID)
		"wall_face":
			_ashlar(img, STONE, STONE_LO, MORTAR)
		"wall_face_dark":
			_ashlar(img, STONE_LO, Color("4a3e46"), MORTAR)
		"wall_top":
			img.fill(STONE_HI)
			hline(img, 0, 13, 16, STONE)
			hline(img, 0, 14, 16, STONE_LO)
			hline(img, 0, 15, 16, MORTAR)
			for x in range(0, 16, 8):
				vline(img, x + int(h2(x, 0, 3) * 3), 0, 13, STONE)
		"plaster_rose", "plaster_ochre", "plaster_teal":
			var base: Color = {"plaster_rose": ROSE, "plaster_ochre": OCHRE, "plaster_teal": TEAL}[name]
			var lo: Color = {"plaster_rose": ROSE_LO, "plaster_ochre": OCHRE_LO, "plaster_teal": TEAL_LO}[name]
			img.fill(base)
			for i in 14:
				px(img, int(h2(i, 1, 13) * 16), int(h2(i, 2, 13) * 16), lo)
			hline(img, 0, 15, 16, lo)
		"interior_wall":
			img.fill(Color("5a4a5e"))
			for y in range(0, 16, 4):
				hline(img, 0, y, 16, Color("4a3c50"))
			hline(img, 0, 13, 16, WOOD)
			hline(img, 0, 14, 16, WOOD_HI)
			hline(img, 0, 15, 16, Color("3e2618"))
		"roof_slate":
			img.fill(SLATE)
			for row in 4:
				var y := row * 4
				hline(img, 0, y + 3, 16, SLATE_LO)
				var off := (row % 2) * 4
				for x in range(off, 16, 8):
					vline(img, x, y, 3, SLATE_LO)
				hline(img, 0, y, 16, SLATE_HI if row % 2 == 0 else SLATE)
		"roof_ridge":
			_draw_tile(img, "roof_slate")
			rect(img, 0, 0, 16, 3, SLATE_HI)
			hline(img, 0, 3, 16, SLATE_LO)
			for x in range(1, 16, 4):
				px(img, x, 1, BRASS_LO)
		"roof_eave":
			img.fill(Color(0, 0, 0, 0))
			rect(img, 0, 0, 16, 6, SLATE)
			hline(img, 0, 0, 16, SLATE_HI)
			hline(img, 0, 5, 16, SLATE_LO)
			hline(img, 0, 6, 16, BRASS_LO)
			rect(img, 0, 7, 16, 3, Color(0.05, 0.03, 0.08, 0.45))
		"roof_verdigris":
			img.fill(VERD)
			for row in 4:
				hline(img, 0, row * 4 + 3, 16, Color("3e7064"))
				for x in range((row % 2) * 3, 16, 6):
					px(img, x, row * 4 + 1, VERD_HI)
		"window_lit", "window_lit_rose", "window_lit_ochre", "window_lit_teal", "window_dark", "window_dark_rose", "window_dark_ochre", "window_dark_teal":
			var lit := name.begins_with("window_lit")
			var wall := ""
			if name.ends_with("rose"):
				wall = "plaster_rose"
			elif name.ends_with("ochre"):
				wall = "plaster_ochre"
			elif name.ends_with("teal"):
				wall = "plaster_teal"
			if wall != "":
				img.blit_rect(tile(wall), Rect2i(0, 0, 16, 16), Vector2i.ZERO)
			_window(img, lit)
		"door":
			rect(img, 3, 2, 10, 14, MORTAR)
			ellipse(img, 8, 5, 5, 4, MORTAR)
			rect(img, 4, 4, 8, 12, WOOD)
			ellipse(img, 8, 5.5, 4, 3, WOOD)
			for x in [6, 9]:
				vline(img, x, 3, 13, Color("3e2618"))
			px(img, 10, 10, BRASS_HI)
			hline(img, 2, 15, 12, STONE_HI)
		"shop_window":
			rect(img, 1, 3, 14, 11, MORTAR)
			rect(img, 2, 4, 12, 9, GLASS)
			rect(img, 4, 6, 8, 5, GLASS_CORE)
			vline(img, 8, 4, 9, BRASS_LO)
			hline(img, 2, 8, 12, BRASS_LO)
			for i in 3:
				px(img, 4 + i * 3, 11, POT)
		"vines":
			for i in 22:
				var x := int(h2(i, 1, 21) * 16)
				var y := int(pow(h2(i, 2, 21), 1.6) * 16)
				px(img, x, y, LEAF if i % 3 else LEAF_HI)
				px(img, x + 1, y, LEAF)
				if i % 4 == 0:
					px(img, x, y + 1, BLOSSOM)
			for x in range(0, 16, 5):
				vline(img, x + 1, 0, 3 + int(h2(x, 3, 21) * 8), LEAF)
		"awning_rose", "awning_teal":
			var c := CANVAS_ROSE if name == "awning_rose" else CANVAS_TEAL
			for x in 16:
				var stripe := (x / 4) % 2 == 0
				vline(img, x, 0, 9, c if stripe else CREAM)
				px(img, x, 9, c if stripe else CREAM)
			for x in range(0, 16, 4):
				px(img, x + 2, 10, c)
			hline(img, 0, 0, 16, Color(1, 1, 1, 0.15))
			rect(img, 0, 11, 16, 3, Color(0.05, 0.03, 0.08, 0.35))
		"balustrade", "balustrade_v":
			# top view of a stone balustrade: a capped rail and its shadow
			if name == "balustrade":
				rect(img, 0, 5, 16, 5, STONE_HI)
				hline(img, 0, 5, 16, Color("bfaea8"))
				hline(img, 0, 9, 16, STONE_LO)
				hline(img, 0, 7, 16, BRASS)
				rect(img, 0, 10, 16, 3, STONE)
				for x in range(1, 16, 4):
					vline(img, x, 10, 3, STONE_LO)
				rect(img, 0, 13, 16, 2, Color(0.05, 0.03, 0.08, 0.4))
			else:
				rect(img, 5, 0, 5, 16, STONE_HI)
				vline(img, 7, 0, 16, BRASS)
				vline(img, 10, 0, 16, Color(0.05, 0.03, 0.08, 0.4))
		"counter":
			rect(img, 0, 2, 16, 4, WOOD_HI)
			hline(img, 0, 2, 16, Color("9a6a46"))
			rect(img, 0, 6, 16, 10, WOOD)
			for x in range(2, 16, 5):
				vline(img, x, 7, 8, Color("3e2618"))
			hline(img, 0, 15, 16, Color("3e2618"))
		"shelf":
			img.fill(WOOD)
			for y in [4, 9, 14]:
				hline(img, 0, y, 16, WOOD_HI)
			for i in 9:
				var x := 1 + (i * 5) % 14
				var y: int = [1, 6, 11][i % 3]
				rect(img, x, y, 2, 3, [POT, BRASS, TEAL, CREAM, LAVENDER][i % 5])
		_:
			img.fill(Color("ff00ff"))


static func _cobbles(img: Image, base: Color, lo: Color, mortar: Color, s: int) -> void:
	img.fill(mortar)
	# stones of 4-6 px in staggered rows, each with a lit top-left and a dark lip
	var y := 0
	var row := 0
	while y < 16:
		var hgt := 4 + int(h2(row, s, 1) * 2)
		var x := -int(h2(row, s, 2) * 4)
		while x < 16:
			var wid := 4 + int(h2(x + 20, row, s) * 3)
			var c := base.lerp(lo, h2(x + 7, row + 3, s) * 0.7)
			c = c.lerp(ROSE, 0.12 * h2(x, row, s + 9))
			rect(img, x + 1, y + 1, wid - 1, hgt - 1, c)
			hline(img, x + 1, y + 1, wid - 2, c.lightened(0.12))
			hline(img, x + 1, y + hgt - 1, wid - 1, c.darkened(0.18))
			x += wid
		y += hgt
		row += 1


static func _flags(img: Image, base: Color, joint: Color, s: int) -> void:
	img.fill(base)
	for i in 30:
		px(img, int(h2(i, 1, s) * 16), int(h2(i, 2, s) * 16), base.darkened(0.08 + 0.08 * h2(i, 3, s)))
	hline(img, 0, 15, 16, joint)
	vline(img, 15, 0, 8, joint)
	vline(img, 7, 8, 8, joint)
	hline(img, 0, 7, 16, joint.lerp(base, 0.4))


static func _ashlar(img: Image, base: Color, lo: Color, mortar: Color) -> void:
	img.fill(mortar)
	for row in 3:
		var y := row * 5 + 1
		var off := (row % 2) * 5
		var x := off - 10
		while x < 16:
			var wid := 9 + int(h2(x + 30, row, 4) * 2)
			var c := base.lerp(lo, h2(x, row, 6) * 0.6)
			rect(img, x + 1, y, wid - 1, 4, c)
			hline(img, x + 1, y, wid - 2, c.lightened(0.1))
			x += wid
	for i in 6:
		px(img, int(h2(i, 9, 4) * 16), int(h2(i, 8, 4) * 16), lo.darkened(0.2))


static func _window(img: Image, lit: bool) -> void:
	# arched window in a stone surround with a brass mullion and a sill
	ellipse(img, 8, 5, 4.5, 4, MORTAR)
	rect(img, 3, 5, 10, 8, MORTAR)
	var g := GLASS if lit else GLASS_DARK
	ellipse(img, 8, 5.5, 3.5, 3, g)
	rect(img, 4, 5, 8, 7, g)
	if lit:
		rect(img, 6, 6, 4, 4, GLASS_CORE)
	else:
		px(img, 5, 6, Color("4a4670"))
	vline(img, 8, 3, 9, BRASS_LO)
	hline(img, 4, 8, 8, BRASS_LO)
	hline(img, 2, 13, 12, STONE_HI)
	hline(img, 2, 14, 12, STONE_LO)


# --- props ----------------------------------------------------------------------

static func _draw_prop(name: String) -> Image:
	match name:
		"lamp":
			var img := _blank(16, 48)
			rect(img, 6, 40, 4, 6, BRASS_LO)
			rect(img, 5, 45, 6, 2, STONE_LO)
			vline(img, 7, 14, 28, BRASS_LO)
			vline(img, 8, 14, 28, BRASS)
			rect(img, 4, 4, 8, 10, BRASS_LO)
			rect(img, 5, 5, 6, 8, GLASS)
			rect(img, 6, 7, 4, 4, GLASS_CORE)
			rect(img, 3, 2, 10, 2, BRASS)
			px(img, 7, 1, BRASS_HI)
			px(img, 8, 1, BRASS_HI)
			outline(img)
			return img
		"stall_rose", "stall_teal":
			return _stall(CANVAS_ROSE if name == "stall_rose" else CANVAS_TEAL, name == "stall_rose")
		"armillary":
			var img := _blank(32, 56)
			# plinth and fluted column
			rect(img, 7, 48, 18, 6, STONE_LO)
			rect(img, 8, 47, 16, 2, STONE_HI)
			rect(img, 12, 26, 8, 22, STONE)
			for x in [13, 16, 19]:
				vline(img, x, 27, 20, STONE_LO)
			rect(img, 10, 24, 12, 3, BRASS)
			# brass rings round a glowing core
			ring(img, 16, 13, 11, 11, 1.4, BRASS)
			ring(img, 16, 13, 11, 4, 1.2, BRASS_HI)
			ring(img, 16, 13, 4, 11, 1.2, BRASS)
			ring(img, 16, 13, 8, 9, 1.0, BRASS_LO)
			ellipse(img, 16, 13, 3.2, 3.2, GLASS)
			ellipse(img, 16, 13, 1.8, 1.8, GLASS_CORE)
			outline(img)
			return img
		"compass":
			return _compass()
		"tree":
			var img := _blank(32, 44)
			rect(img, 14, 30, 4, 12, WOOD)
			ellipse(img, 16, 18, 13, 13, LEAF)
			for i in 40:
				var a := h2(i, 1, 31) * TAU
				var r := h2(i, 2, 31) * 11.0
				px(img, int(16 + cos(a) * r), int(18 + sin(a) * r * 0.95), LEAF_HI if sin(a) < 0.2 else GRASS_LO)
			for i in 6:
				px(img, int(8 + h2(i, 3, 31) * 16), int(9 + h2(i, 4, 31) * 16), BLOSSOM)
			ellipse(img, 16, 41, 7, 2.5, Color(0.05, 0.03, 0.08, 0.35))
			outline(img)
			return img
		"cypress":
			var img := _blank(16, 44)
			rect(img, 7, 36, 2, 6, WOOD)
			for y in 34:
				var w := sin(float(y) / 34.0 * PI) * 5.5 + 1.0
				hline(img, int(8 - w), y + 2, int(w * 2), LEAF if y % 3 else GRASS_LO)
				px(img, int(8 - w + 1), y + 2, LEAF_HI)
			outline(img)
			return img
		"barrel":
			var img := _blank(16, 20)
			rect(img, 3, 4, 10, 14, WOOD)
			for x in [5, 8, 11]:
				vline(img, x, 5, 12, WOOD_HI)
			for y in [6, 15]:
				hline(img, 3, y, 10, BRASS_LO)
			ellipse(img, 8, 4, 5, 2, Color("6e4630"))
			outline(img)
			return img
		"crates":
			var img := _blank(16, 22)
			rect(img, 1, 9, 14, 11, WOOD)
			rect(img, 4, 2, 9, 8, WOOD_HI)
			for c: Rect2i in [Rect2i(1, 9, 14, 11), Rect2i(4, 2, 9, 8)]:
				hline(img, c.position.x, c.position.y, c.size.x, Color("9a6a46"))
				vline(img, c.position.x + c.size.x / 2, c.position.y, c.size.y, Color("3e2618"))
			outline(img)
			return img
		"pot_lavender", "pot_leaf":
			var img := _blank(16, 24)
			rect(img, 4, 15, 8, 8, POT)
			hline(img, 3, 15, 10, Color("b8714a"))
			vline(img, 5, 16, 6, Color("b8714a"))
			if name == "pot_lavender":
				for i in 9:
					var x := 4 + i
					var hgt := 6 + int(h2(i, 1, 41) * 6)
					vline(img, x, 15 - hgt, hgt, LEAF)
					rect(img, x, 15 - hgt, 1, 3, LAVENDER)
			else:
				ellipse(img, 8, 10, 6, 5, LEAF)
				ellipse(img, 7, 9, 3, 2, LEAF_HI)
			outline(img)
			return img
		"bench":
			var img := _blank(32, 16)
			rect(img, 2, 10, 4, 5, STONE)
			rect(img, 26, 10, 4, 5, STONE)
			rect(img, 1, 6, 30, 4, WOOD_HI)
			for x in range(1, 31, 5):
				vline(img, x, 6, 4, WOOD)
			rect(img, 1, 2, 30, 3, WOOD)
			outline(img)
			return img
		"terminal":
			var img := _blank(16, 32)
			rect(img, 2, 8, 12, 22, STONE)
			rect(img, 1, 6, 14, 3, STONE_HI)
			rect(img, 3, 10, 10, 8, BRASS_LO)
			rect(img, 4, 11, 8, 6, SCREEN)
			for i in 5:
				px(img, 5 + int(h2(i, 1, 51) * 6), 12 + int(h2(i, 2, 51) * 4), Color("e0ffff"))
			rect(img, 4, 20, 8, 2, BRASS)
			outline(img)
			return img
		"arcade_bay":
			return _arcade_bay()
		"banner_rose", "banner_teal":
			var img := _blank(12, 30)
			var c := CANVAS_ROSE if name == "banner_rose" else CANVAS_TEAL
			hline(img, 0, 0, 12, BRASS)
			rect(img, 1, 1, 10, 25, c)
			for y in range(26, 29):
				hline(img, 1 + (y - 26), y, 10 - (y - 26) * 2, c)
			ring(img, 6, 11, 3, 3, 1.0, BRASS_HI)
			px(img, 6, 11, BRASS_HI)
			vline(img, 6, 16, 6, BRASS_HI)
			return img
		"dome":
			var img := _blank(64, 40)
			rect(img, 4, 32, 56, 6, STONE_HI)
			hline(img, 4, 37, 56, STONE_LO)
			for y in 30:
				var w := sqrt(maxf(0.0, 1.0 - pow((30.0 - y) / 30.0, 2.0))) * 26.0
				hline(img, int(32 - w), y + 2, int(w * 2), VERD)
				px(img, int(32 - w), y + 2, Color("3e7064"))
				px(img, int(32 - w + 3), y + 2, VERD_HI)
			for k in [-16, 0, 16]:
				for y in 30:
					var x := 32 + int(k * sqrt(maxf(0.0, 1.0 - pow((30.0 - y) / 30.0, 2.0))))
					px(img, x, y + 2, BRASS_LO)
			vline(img, 32, 0, 4, BRASS_HI)
			outline(img)
			return img
		"string_lights":
			var img := _blank(160, 24)
			for x in 160:
				var t := float(x) / 159.0
				var y := int(3 + 14.0 * 4.0 * t * (1.0 - t))
				px(img, x, y, BRASS_LO)
				if x % 10 == 5:
					px(img, x, y + 1, GLASS)
					px(img, x, y + 2, GLASS_CORE)
			return img
		"rug":
			var img := _blank(48, 32)
			rect(img, 0, 0, 48, 32, CANVAS_ROSE)
			rect(img, 2, 2, 44, 28, Color("a64454"))
			rect(img, 5, 5, 38, 22, CANVAS_ROSE)
			for i in 4:
				ring(img, 24, 16, 6 + i * 3, 4 + i * 2, 0.8, CREAM if i % 2 else BRASS)
			return img
		"notice":
			var img := _blank(16, 24)
			vline(img, 3, 8, 15, WOOD)
			vline(img, 12, 8, 15, WOOD)
			rect(img, 1, 2, 14, 10, WOOD_HI)
			rect(img, 2, 3, 12, 8, CREAM)
			for y in [5, 7, 9]:
				hline(img, 4, y, 8, STONE_LO)
			outline(img)
			return img
		"shadow_arch":
			var img := _blank(48, 16)
			rect(img, 0, 0, 48, 16, Color(0.05, 0.03, 0.1, 0.35))
			return img
	var bad := _blank(16, 16)
	bad.fill(Color("ff00ff"))
	return bad


static func _stall(c: Color, instruments: bool) -> Image:
	var img := _blank(48, 44)
	# counter
	rect(img, 3, 26, 42, 14, WOOD)
	rect(img, 2, 24, 44, 3, WOOD_HI)
	for x in range(6, 44, 8):
		vline(img, x, 27, 12, Color("3e2618"))
	# goods on the counter
	if instruments:
		ring(img, 12, 19, 5, 5, 1.0, BRASS_HI)
		ring(img, 12, 19, 5, 2, 1.0, BRASS)
		px(img, 12, 19, GLASS)
		rect(img, 21, 20, 8, 4, BRASS_LO)
		hline(img, 21, 20, 8, BRASS_HI)
		ellipse(img, 35, 22, 4, 2, BRASS)
	else:
		for i in 5:
			rect(img, 6 + i * 8, 18, 5, 6, [POT, TEAL, CREAM, POT, LAVENDER][i])
			hline(img, 6 + i * 8, 18, 5, Color(1, 1, 1, 0.25))
	# poles and striped canopy
	vline(img, 3, 6, 34, WOOD_HI)
	vline(img, 44, 6, 34, WOOD_HI)
	for x in 48:
		var stripe := (x / 6) % 2 == 0
		vline(img, x, 2, 9, c if stripe else CREAM)
		if x % 6 == 3:
			px(img, x, 11, c if stripe else CREAM)
	hline(img, 0, 2, 48, Color(1, 1, 1, 0.2))
	rect(img, 0, 12, 48, 3, Color(0.05, 0.03, 0.08, 0.35))
	# hanging lantern
	vline(img, 40, 11, 3, BRASS_LO)
	rect(img, 38, 14, 5, 6, BRASS_LO)
	rect(img, 39, 15, 3, 4, GLASS)
	outline(img)
	return img


static func _compass() -> Image:
	var img := _blank(80, 80)
	var c := Vector2(40, 40)
	for y in 80:
		for x in 80:
			var d := Vector2(x + 0.5, y + 0.5) - c
			var r := d.length() / 38.0
			if r > 1.0:
				continue
			var col := Color("6e6066")
			if r > 0.78 and r < 0.93:
				col = Color("3a3040")
				var a := atan2(d.y, d.x)
				if absf(fposmod(a / (TAU / 32.0), 1.0) - 0.5) > 0.38 and r > 0.82 and r < 0.9:
					col = BRASS
			for rr: float in [0.78, 0.93, 0.99, 0.36]:
				if absf(r - rr) < 0.018:
					col = BRASS_HI
			# eight-point star
			var ang := atan2(d.y, d.x)
			var k := TAU / 8.0
			var idx := int(floor((ang + k * 0.5) / k))
			var sa := fposmod(ang + k * 0.5, k) - k * 0.5
			var len := 0.76 if posmod(idx, 2) == 0 else 0.46
			var width := (1.0 - r / len) * 0.21
			if r < len and absf(sa) * r * 2.6 < width:
				col = BRASS if sa > 0.0 else BRASS_LO
			if r < 0.07:
				col = BRASS_HI
			img.set_pixel(x, y, col)
	return img


static func _arcade_bay() -> Image:
	# one bay of the terrace arcade, 48x32: pilasters, an arch, a warm shopfront
	var img := _blank(48, 32)
	# recess: dark warm interior
	rect(img, 9, 8, 30, 24, Color("2a1a18"))
	ellipse(img, 24, 10, 15, 9, Color("2a1a18"))
	# lit window, door
	rect(img, 12, 14, 11, 10, GLASS)
	rect(img, 14, 16, 7, 6, GLASS_CORE)
	vline(img, 17, 14, 10, BRASS_LO)
	rect(img, 27, 12, 9, 20, WOOD)
	ellipse(img, 31.5, 13, 4.5, 3, WOOD)
	px(img, 34, 22, BRASS_HI)
	# arch ring and keystone
	ring(img, 24, 10, 16, 10, 2.0, STONE_HI)
	rect(img, 22, 0, 4, 3, STONE_HI)
	# pilasters
	for x0 in [0, 41]:
		rect(img, x0, 0, 7, 32, STONE)
		vline(img, x0, 0, 32, STONE_HI)
		vline(img, x0 + 6, 0, 32, STONE_LO)
		for y in range(4, 32, 6):
			hline(img, x0, y, 7, MORTAR)
	# striped awning across the arch
	for x in range(8, 40):
		var stripe := (x / 4) % 2 == 0
		vline(img, x, 6, 5, CANVAS_ROSE if stripe else CREAM)
	rect(img, 8, 11, 32, 2, Color(0.05, 0.03, 0.08, 0.35))
	return img


# --- characters -----------------------------------------------------------------

static func _col(v: Variant, fallback: Color) -> Color:
	if v is Color:
		return v
	if v is String and str(v) != "":
		return Color.html(str(v))
	return fallback


## A 16x32 adult figure in 4 directions x (idle, walk 1-4, run 1-4).
static func _draw_character(look: Dictionary) -> Image:
	var sheet := _blank(FRAME.x * COLS, FRAME.y * 4)
	var spec := {
		"coat": _col(look.get("coat", null), Color("80211c")),
		"accent": _col(look.get("accent", null), BRASS),
		"skin": _col(look.get("skin", null), Color("c89a7a")),
		"hair_color": _col(look.get("hair_color", null), Color("1a0f0d")),
		"hair": str(look.get("hair", "bun")),
		"long": bool(look.get("long_coat", true)),
		"hat": str(look.get("hat", "")),
		"apron": bool(look.get("apron", false)),
	}
	for d in 4:
		for col in COLS:
			var f := _blank(FRAME.x, FRAME.y)
			var run := col >= 5
			var step := 0 if col == 0 else (col - 1) % 4
			_figure(f, spec, DIRS[d], col == 0, run, step)
			outline(f)
			sheet.blit_rect(f, Rect2i(Vector2i.ZERO, FRAME), Vector2i(col * FRAME.x, d * FRAME.y))
	return sheet


static func _figure(img: Image, s: Dictionary, dir: String, idle: bool, run: bool, step: int) -> void:
	var coat: Color = s["coat"]
	var coat_lo := coat.darkened(0.3)
	var coat_hi := coat.lightened(0.15)
	var skin: Color = s["skin"]
	var skin_lo := skin.darkened(0.18)
	var hair: Color = s["hair_color"]
	var accent: Color = s["accent"]
	var boot := Color("231a1c")
	var trouser := Color("2e2834")
	# gait: steps 0 and 2 are contact poses (legs apart), 1 and 3 are passing (bob up)
	var bob := 0 if idle else (1 if step % 2 == 1 else 0)
	var spread := 0 if idle or step % 2 == 1 else (2 if run else 1)
	var lead := 1 if step == 0 else -1
	var lean := 1 if run and not idle else 0
	var y0 := 2 - bob
	var side := dir == "left" or dir == "right"
	var flip := dir == "left"
	var X := func(x: int) -> int: return 15 - x if flip else x
	# shadow
	ellipse(img, 8, 30.5, 5, 1.6, Color(0.05, 0.03, 0.08, 0.4))
	# legs and boots
	if side:
		var fx := 7 + lean
		var a := fx + spread * lead
		var b := fx - spread * lead
		for lx: int in [b, a]:
			rect(img, X.call(lx), y0 + 20, 2, 7, trouser)
			rect(img, X.call(lx) - (1 if flip else 0), y0 + 26, 3, 2, boot)
	else:
		var l_off := spread * lead
		rect(img, 5, y0 + 20 + maxi(0, -l_off), 2, 7 - absi(l_off), trouser)
		rect(img, 9, y0 + 20 + maxi(0, l_off), 2, 7 - absi(l_off), trouser)
		rect(img, 5, y0 + 26, 2, 2, boot)
		rect(img, 9, y0 + 26, 2, 2, boot)
	# coat body and skirt
	var skirt := 7 if s["long"] else 4
	if side:
		rect(img, X.call(5 + lean) - (4 if flip else 0), y0 + 10, 5, 10, coat)
		rect(img, X.call(4 + lean) - (6 if flip else 0), y0 + 18, 7, skirt, coat)
		vline(img, X.call(4 + lean), y0 + 18, skirt, coat_lo)
		vline(img, X.call(8 + lean), y0 + 11, 7 + skirt, coat_hi)
	else:
		rect(img, 4, y0 + 10, 8, 10, coat)
		rect(img, 3, y0 + 18, 10, skirt, coat)
		vline(img, 3, y0 + 18, skirt, coat_lo)
		vline(img, 12, y0 + 18, skirt, coat_lo)
		vline(img, 4, y0 + 11, 7, coat_hi)
		if dir == "down":
			# lapels, belt, buttons
			vline(img, 7, y0 + 11, 7, coat_lo)
			vline(img, 8, y0 + 11, 7, coat_lo)
			hline(img, 4, y0 + 17, 8, accent.darkened(0.2))
			px(img, 8, y0 + 13, accent)
			px(img, 8, y0 + 15, accent)
			if s["apron"]:
				rect(img, 5, y0 + 17, 6, 7, CREAM)
		else:
			vline(img, 8, y0 + 18, skirt, coat_lo)
	# shoulders and arms
	var swing := 0 if idle else (2 if run else 1) * (1 if step < 2 else -1) * (0 if step % 2 == 1 else 1)
	if side:
		var ax: int = X.call(7 + lean + (swing if not flip else -swing))
		rect(img, ax, y0 + 11, 2, 7 if not run else 5, coat_lo)
		rect(img, ax, y0 + (18 if not run else 16), 2, 2, skin)
	else:
		rect(img, 2, y0 + 11 + maxi(0, swing), 2, 7, coat_lo)
		rect(img, 12, y0 + 11 + maxi(0, -swing), 2, 7, coat_lo)
		rect(img, 2, y0 + 18 + maxi(0, swing), 2, 2, skin)
		rect(img, 12, y0 + 18 + maxi(0, -swing), 2, 2, skin)
	# scarf / collar
	rect(img, 5 if not side else X.call(5 + lean) - (4 if flip else 0), y0 + 9, 6 if not side else 5, 2, accent)
	# head (adult proportions: about a fifth of the height)
	var hx := 5 + (lean if side else 0)
	if side and flip:
		hx = 16 - hx - 6
	rect(img, hx, y0 + 2, 6, 7, skin)
	vline(img, hx + (0 if flip else 5) if side else hx + 5, y0 + 3, 6, skin_lo)
	var style: String = s["hair"]
	if dir == "up":
		rect(img, hx, y0 + 1, 6, 7, hair)
		if style == "bun":
			rect(img, hx + 2, y0, 2, 2, hair)
		elif style == "long":
			rect(img, hx, y0 + 7, 6, 4, hair)
	else:
		rect(img, hx, y0 + 1, 6, 2, hair)
		if dir == "down":
			px(img, hx, y0 + 3, hair)
			px(img, hx + 5, y0 + 3, hair)
			px(img, hx + 1, y0 + 5, INK)
			px(img, hx + 4, y0 + 5, INK)
			px(img, hx + 2, y0 + 7, skin_lo)
			px(img, hx + 3, y0 + 7, skin_lo)
			if style == "long":
				vline(img, hx - 1, y0 + 2, 8, hair)
				vline(img, hx + 6, y0 + 2, 8, hair)
		else:
			var back := hx + (5 if flip else 0)
			vline(img, back, y0 + 2, 5, hair)
			rect(img, hx + (4 if flip else 0), y0 + 1, 2, 2, hair)
			var eye := hx + (1 if flip else 4)
			px(img, eye, y0 + 5, INK)
			px(img, hx + (-1 if flip else 6), y0 + 5, skin)
			if style == "long":
				vline(img, back, y0 + 7, 4, hair)
		if style == "bun" and dir != "up":
			rect(img, hx + (4 if flip else 0) if side else hx + 2, y0, 2, 2, hair)
	match s["hat"]:
		"hardhat":
			rect(img, hx - 1, y0, 8, 3, Color("d8a020"))
			hline(img, hx - 1, y0 + 3, 8, Color("a87818"))
			if dir != "up":
				px(img, hx + 3, y0 + 1, GLASS_CORE)
		"brim", "cap":
			rect(img, hx - (1 if s["hat"] == "brim" else 0), y0 + 1, 8 if s["hat"] == "brim" else 6, 1, accent.darkened(0.4))
			rect(img, hx, y0 - 1, 6, 2, accent.darkened(0.3))
