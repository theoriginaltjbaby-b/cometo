"""Build the 16 px "coast" tile kit and its look-test map from the look reference.

The reference (docs/reference/look_reference_2d_01.png) is resampled to one sample per
art pixel and padded onto a 33 x 18 grid of 16 px tiles. From that picture this script
makes:
  ground tiles     seamless 16 px tiles synthesised from clean patches of each surface
  objects          buildings, trees, rocks, lamps, fences, the pier, the sea, cut out
                   with masks and kept on the grid so they can be placed by cell
  decals           puddles and lamplight glints found on the road by colour
and writes, into art/tilesets/coast/: coast_ground.png, coast_<category>.png,
coast_tiles.json (the catalogue) and coast_map.json (the look-test map: ground grid
and where each object stands). tools/build_coast_kit.gd turns those into TileSets and
a scene.

  python3 tools/coast/build_kit.py [project_root] [preview_folder]
"""
import json
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "anjabi"))
ROOT = sys.argv[1] if len(sys.argv) > 1 else "."
PREVIEW = sys.argv[2] if len(sys.argv) > 2 else ""
sys.argv = [sys.argv[0], ROOT]
import prepare as P  # noqa: E402  (seamless-tile and packing helpers)
from components import label  # noqa: E402
from logical import to_logical  # noqa: E402
import modules as M  # noqa: E402

T = 16
P.T = T
P.ATLAS_CELLS_W = 48
W, H = 33, 18
OUT = os.path.join(ROOT, "art/tilesets/coast")
PAD_TOP, PAD_LEFT = 7, 6

# ---- colour tests (arrays of float RGB -> bool) ----------------------------------

def lum(a):
    return a[..., 0] * 0.3 + a[..., 1] * 0.59 + a[..., 2] * 0.11


def is_dark(a):
    """Forest shadow: very dark and green or teal."""
    return (lum(a) < 46) & (a[..., 1] >= a[..., 0] - 2) & (a[..., 1] >= a[..., 2] - 14)


def is_water(a):
    return (a[..., 2] - a[..., 0] > 26) & (a[..., 1] - a[..., 0] > 6)


def is_rock(a):
    """Shore rock. Its lit faces are the colour of wet sand, so find the dark cores
    (darker than sand, not as blue as the sea) and close the gaps between them."""
    core = (lum(a) < 74) & (a[..., 2] - a[..., 0] < 62) & ~is_dark(a)
    return ~grow(~grow(core, 4), 4)


def is_wood(a):
    return (a[..., 0] - a[..., 2] > 14) & (lum(a) < 86)


def is_blue_puddle(a):
    return (a[..., 2] - a[..., 0] > 44) & (lum(a) > 60)


def is_glint(a):
    return (a[..., 0] - a[..., 2] > 34) & (lum(a) > 62)


# ---- the map: ground classes and what stands where --------------------------------
# Ground classes: f forest floor, r road, a sand, w water, d dock. f and w are solid.
GROUND_RECTS = [
    ("f", 0, 0, W, H), ("r", 0, 7, 25, 4), ("r", 9, 0, 2, 7), ("a", 19, 11, 9, 7), ("a", 24, 0, 4, 7),
    ("w", 28, 0, 5, 11), ("w", 25, 11, 8, 7), ("d", 25, 8, 6, 3),
]
GROUND_SOURCES = {  # clean patches of the picture (x0, y0, x1, y1), palette size
    "r": ((216, 148, 254, 174), 12), "a": ((344, 248, 376, 272), 10), "d": ((404, 141, 430, 163), 10),
    "w": ((478, 206, 522, 282), 12),
}
SOLID_GROUND = ["f", "w"]
GROUND_NAMES = {"f": "forest_floor", "r": "road", "a": "sand", "w": "water", "d": "dock"}
PEOPLE = [(144, 34, 170, 66), (80, 141, 102, 172), (252, 129, 274, 161), (367, 145, 390, 172)]

# Objects: name, category, box in picture px, how to cut, options.
#   cut "rect"     everything in the box (minus "holes": boxes cut away)
#       "rects"    only the listed boxes ("parts")
#       "notdark"  drop forest shadow that touches the box's "open" sides
#       "is"       keep pixels passing a colour test ("test"), plus "also" boxes
#   solid  cells that block, as (x0, y0, x1, y1) inclusive in map cells; "open" cells
#          are taken back out. base: the y its foot is at, for depth sorting.
#   flat   lies on the ground, drawn under people.
OBJECTS = [
    ("sea_north", "terrain", (414, 0, 528, 136), "is", {"test": is_water, "grow": 2, "flat": True}),
    ("sea_south", "terrain", (368, 176, 528, 288), "is", {"test": is_water, "grow": 2, "flat": True}),
    ("sea_east", "terrain", (496, 128, 528, 180), "rect", {"flat": True}),
    ("pier", "terrain", (392, 120, 504, 198), "is", {"test": lambda a: ~is_water(a), "flat": True, "z": 1, "holes": [(392, 120, 400, 136), (392, 176, 398, 198)]}),
    ("pine_stand_nw", "nature", (0, 0, 40, 113), "notdark", {"open": "tlb"}),
    ("pine_stand_sw", "nature", (0, 176, 44, 288), "notdark", {"open": "l"}),
    ("pine_stand_s", "nature", (172, 176, 274, 288), "notdark", {"open": ""}),
    ("pine_stand_se", "nature", (272, 244, 300, 288), "rect", {}),
    ("house_red_a", "buildings", (39, 0, 142, 135), "notdark", {"open": "t", "solid": (2, 0, 8, 7), "walk": [(4, 7)], "base": 127}),
    ("house_slate", "buildings", (166, 0, 250, 135), "notdark", {"open": "t", "solid": (11, 0, 15, 7), "walk": [(13, 7)], "base": 127}),
    ("generator", "props", (250, 0, 271, 135), "notdark", {"open": "t", "solid": (15, 0, 16, 7), "base": 127}),
    ("shop", "buildings", (270, 0, 398, 135), "notdark", {"open": "t", "solid": (16, 0, 24, 7), "walk": [(20, 7), (21, 7)], "base": 127}),
    ("house_red_b", "buildings", (42, 174, 175, 288), "notdark", {"open": "t", "solid": (2, 11, 10, 17)}),
    ("machines", "props", (238, 174, 274, 246), "rect", {"solid": (14, 11, 16, 15)}),
    ("rose_bed", "nature", (272, 180, 320, 246), "rect", {"solid": (17, 11, 19, 15)}),
    ("rock_n", "nature", (398, 0, 450, 122), "is", {"test": is_rock, "min": 40, "split": True, "solid": "auto"}),
    ("rock_s", "nature", (296, 198, 400, 288), "is", {"test": is_rock, "min": 40, "split": True, "solid": "auto"}),
    ("driftwood", "nature", (316, 252, 346, 284), "is", {"test": is_wood, "min": 12, "flat": True}),
    ("seawall", "props", (312, 162, 400, 198), "is", {"test": is_wood, "also": [(312, 176, 400, 198)], "base": 196}),
    ("fence_west", "props", (0, 112, 27, 135), "rect", {"solid": (0, 7, 1, 7), "base": 127}),
    ("lamp_post_a", "props", (24, 98, 42, 145), "rects", {"parts": [(25, 99, 42, 118), (30, 118, 37, 138), (27, 136, 41, 145)], "solid": (2, 8, 2, 8), "lamp": 36}),
    ("lamp_post_b", "props", (294, 156, 312, 193), "rects", {"parts": [(294, 157, 311, 177), (299, 177, 306, 188), (296, 186, 310, 193)], "lamp": 28}),
]
SPAWNS = [["default", 16, 9, "down"], ["north", 9, 1, "down"], ["west", 1, 9, "right"], ["pier", 29, 9, "left"]]
ROAD_AREAS = [(0, 133, 394, 177), (144, 0, 166, 133)]  # where puddles and glints are looked for


def load_picture():
    src = np.asarray(Image.open(os.path.join(ROOT, "docs/reference/look_reference_2d_01.png")).convert("RGB")).astype(np.float64)
    logical, _ = to_logical(src)
    # the picture is a few pixels short of whole tiles: mirror its edges to fill them
    lp = np.pad(logical, ((PAD_TOP, 0), (PAD_LEFT, 0), (0, 0)), mode="reflect")
    lp = np.pad(lp, ((0, max(0, H * T - lp.shape[0])), (0, max(0, W * T - lp.shape[1])), (0, 0)), mode="reflect")
    return lp[:H * T, :W * T]


def despeckle(a):
    """Take rain streaks out of a water patch: replace pixels much brighter than their
    surroundings with the local median."""
    out = a.copy()
    med = np.median(a.reshape(-1, 3), axis=0)
    bright = lum(a) > lum(med[None, None, :])[0, 0] + 26
    for y, x in zip(*np.nonzero(bright)):
        y0, y1, x0, x1 = max(0, y - 3), y + 4, max(0, x - 3), x + 4
        patch = a[y0:y1, x0:x1][~bright[y0:y1, x0:x1]]
        out[y, x] = np.median(patch, axis=0) if len(patch) else med
    return out


def grounds(lp, rng):
    rows, names = [], []
    dark = lp[is_dark(lp.astype(np.float64))].astype(np.float64)
    shades = np.percentile(dark, [25, 50, 75], axis=0)
    strip = np.zeros((T, T * 4, 3), np.uint8)
    for v in range(4):
        t = np.tile(shades[1], (T, T, 1))
        for _ in range(26):
            x, y = int(rng.integers(1, T - 2)), int(rng.integers(1, T - 1))
            t[y, x:x + int(rng.integers(1, 3))] = shades[int(rng.integers(0, 3))]
        strip[:, v * T:(v + 1) * T] = t
    rows.append(strip)
    names.append("f")
    for key, (box, colours) in GROUND_SOURCES.items():
        x0, y0, x1, y1 = box
        patch = lp[y0:y1, x0:x1].astype(np.float64)
        if key == "w":
            patch = despeckle(patch)
        rows.append(P.ground_from(patch, colours, rng, 3))
        names.append(key)
    return np.concatenate(rows, axis=0), names


def flood_from(mask_bg, sides):
    """Pixels of mask_bg connected to the given sides ('t', 'l', 'b', 'r') of the box."""
    h, w = mask_bg.shape
    seen = np.zeros((h, w), bool)
    stack = []
    if "t" in sides:
        stack += [(0, x) for x in range(w)]
    if "b" in sides:
        stack += [(h - 1, x) for x in range(w)]
    if "l" in sides:
        stack += [(y, 0) for y in range(h)]
    if "r" in sides:
        stack += [(y, w - 1) for y in range(h)]
    while stack:
        y, x = stack.pop()
        if y < 0 or x < 0 or y >= h or x >= w or seen[y, x] or not mask_bg[y, x]:
            continue
        seen[y, x] = True
        stack += [(y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)]
    return seen


def grow(mask, n):
    for _ in range(n):
        p = np.pad(mask, 1)
        mask = p[1:-1, 1:-1] | p[:-2, 1:-1] | p[2:, 1:-1] | p[1:-1, :-2] | p[1:-1, 2:]
    return mask


def drop_small(mask, least):
    lab, cents = label(mask)
    keep = [i for i, (_, _, n) in cents.items() if n >= least]
    return np.isin(lab, keep)


def cut(lp, box, how, o):
    x0, y0, x1, y1 = box
    a = lp[y0:y1, x0:x1].astype(np.float64)
    if how == "rect":
        mask = np.ones(a.shape[:2], bool)
    elif how == "rects":
        mask = np.zeros(a.shape[:2], bool)
        for px0, py0, px1, py1 in o["parts"]:
            mask[py0 - y0:py1 - y0, px0 - x0:px1 - x0] = True
        # whatever was behind it in the picture (foliage, forest shadow) stays behind
        mask &= ~((a[..., 1] > a[..., 0] + 3) & (a[..., 1] >= a[..., 2] - 6)) & ~is_dark(a)
    elif how == "notdark":
        dark = is_dark(a)
        mask = ~flood_from(dark, o.get("open", "tlbr"))
    else:
        mask = o["test"](a)
        if "min" in o:
            mask = drop_small(mask, o["min"])
        if "grow" in o:
            mask = grow(mask, o["grow"])
        for px0, py0, px1, py1 in o.get("also", []):
            mask[py0 - y0:py1 - y0, px0 - x0:px1 - x0] = True
    for px0, py0, px1, py1 in o.get("holes", []):
        mask[py0 - y0:py1 - y0, px0 - x0:px1 - x0] = False
    return mask


def to_cells(lp, box, mask):
    """Trim to the mask and pad out to whole cells of the map grid, so the sprite keeps
    its place within its cells. Returns rgba, first cell (x, y), size in cells."""
    x0, y0 = box[0], box[1]
    ys, xs = np.nonzero(mask)
    bx0, bx1, by0, by1 = x0 + xs.min(), x0 + xs.max() + 1, y0 + ys.min(), y0 + ys.max() + 1
    cx0, cy0, cx1, cy1 = bx0 // T, by0 // T, -(-bx1 // T), -(-by1 // T)
    rgba = np.zeros(((cy1 - cy0) * T, (cx1 - cx0) * T, 4), np.uint8)
    m = mask[by0 - y0:by1 - y0, bx0 - x0:bx1 - x0]
    sub = rgba[by0 - cy0 * T:by1 - cy0 * T, bx0 - cx0 * T:bx1 - cx0 * T]
    sub[..., :3] = lp[by0:by1, bx0:bx1]
    sub[..., 3] = np.where(m, 255, 0)
    sub[~m] = 0
    return rgba, (int(cx0), int(cy0)), (int(cx1 - cx0), int(cy1 - cy0)), int(by1)


def glow_layer(lp):
    """Everything that gives off light (windows, lamps, the neon sign, screens), on
    black, for the game to add over the scene at night."""
    a = lp.astype(np.float64)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    warm = (r - b > 80) & (lum(a) > 138)
    neon = (r > 170) & (b > 150) & (g < 150)
    screen = (g > 170) & (b > 170) & (r < 130)
    lit = warm | neon | screen
    lit &= ~is_water(a)
    out = np.zeros(lp.shape, np.uint8)
    out[lit] = (a[lit] * 0.4).astype(np.uint8)
    return out


def decals(lp):
    """Puddles and lamplight glints on the road, each as its own little flat object."""
    found = []
    a = lp.astype(np.float64)
    for kind, test, least in (("puddle", is_blue_puddle, 14), ("glint", is_glint, 10)):
        mask = np.zeros(a.shape[:2], bool)
        for x0, y0, x1, y1 in ROAD_AREAS:
            mask[y0:y1, x0:x1] = test(a[y0:y1, x0:x1])
        for x0, y0, x1, y1 in PEOPLE:
            mask[y0:y1, x0:x1] = False
        if kind == "glint":
            mask = grow(mask, 1) & (a[..., 0] - a[..., 2] > 12)
        lab, cents = label(mask)
        n = 0
        for i, (_, _, cnt) in sorted(cents.items(), key=lambda kv: -kv[1][2]):
            if cnt < least:
                continue
            ys, xs = np.nonzero(lab == i)
            box = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
            n += 1
            found.append(("%s_%02d" % (kind, n), "terrain", box, (lab == i)[box[1]:box[3], box[0]:box[2]], {"flat": True, "z": 1}))
    return found


def village(tiles):
    """A second, larger map made only from the kit's reusable pieces: a village of
    modular houses on two streets, forest of single pines, a beach with surf tiles and
    the pier. Returns the same structure as the look test's map."""
    w, h = 48, 30
    grid = [["f"] * w for _ in range(h)]
    objects = []
    busy = set()
    size = {(t["cat"], t["name"]): (t["cw"], t["ch"]) for t in tiles}

    def fill(k, x0, y0, cw, ch):
        for y in range(y0, y0 + ch):
            for x in range(x0, x0 + cw):
                if 0 <= x < w and 0 <= y < h:
                    grid[y][x] = k

    def put(cat, name, x, y, claim=True):
        cw, ch = size[(cat, name)]
        if claim:
            for j in range(ch):
                for i in range(cw):
                    busy.add((x + i, y - j))
        objects.append([cat, name, x, y])

    def house(x, top, cw, depth, roof, windows, planters, unit=None):
        """cw cells wide; `depth` roof rows; walls take the two rows below."""
        for j in range(depth):
            for i in range(cw):
                col = "l" if i == 0 else "r" if i == cw - 1 else ""
                row = "t" if j == 0 else "b" if j == depth - 1 else ""
                key = (row + col) or "c%d" % ((i * 7 + j * 3) % 4)
                put("buildings", "roof_%s_%s" % (roof, key), x + i, top + j)
        base = top + depth + 1
        for i in range(cw):
            put("buildings", "wall_end_l" if i == 0 else "wall_end_r" if i == cw - 1 else "wall_plain", x + i, base)
        door = x + cw // 2 - 1
        put("details", "porch_" + roof, door, base, False)
        for i in windows:
            put("details", "window_wide" if i < 0 else "window_small", x + abs(i), base, False)
        for i, name in planters:
            put("details", name, x + i, base, False)
        if unit:
            put("details", unit[0], x + unit[1], top + 1, False)

    fill("r", 0, 14, 38, 3)      # the main street
    fill("r", 22, 0, 2, 14)      # lane north
    fill("r", 10, 17, 2, 13)     # lane south
    fill("r", 10, 24, 26, 2)     # back street
    fill("a", 38, 0, 10, h)      # beach, and a shoreline that wanders
    for y in range(h):
        shore = 42 + int(round(1.6 * np.sin(y * 0.42) + 0.9 * np.sin(y * 1.1 + 1.0)))
        fill("w", shore, y, w - shore, 1)
    fill("d", 39, 14, 6, 3)      # the pier's deck
    put("terrain", "pier", 38, 18, False)

    # widths are odd so the porch sits in the middle; windows go on the plain cells
    house(1, 8, 7, 4, "red", [1, 5], [(0, "planter_small"), (5, "planter_small")], ("roof_unit_a", 5))
    house(10, 9, 9, 3, "slate", [-1, -6], [(0, "planter_flowers"), (6, "planter_flowers")], ("roof_unit_b", 7))
    house(25, 8, 5, 4, "red", [], [], None)
    house(31, 9, 7, 3, "slate", [1, 5], [(5, "planter_small")], ("roof_unit_b", 1))
    house(13, 18, 9, 4, "red", [-1, -6], [(0, "planter_small"), (6, "planter_flowers")], ("roof_unit_a", 7))
    house(24, 19, 5, 3, "slate", [], [], None)
    house(30, 18, 7, 4, "red", [1, 5], [(0, "planter_small")], None)

    for x, y in ((8, 14), (20, 14), (36, 14), (12, 26), (22, 26), (34, 26)):
        put("props", "lamp_post_a", x - 1, y)
    for x in range(2, 9):
        put("props", "picket_fence", x, 17)
    for x in range(14, 22):
        put("props", "picket_fence", x, 27)
    rocks = sorted(n for (c, n) in size if c == "nature" and n.startswith("rock") and size[(c, n)][0] <= 3)
    for i, (x, y) in enumerate(((38, 4), (39, 9), (38, 12), (38, 23), (40, 27), (39, 29))):
        put("nature", rocks[(i * 3) % len(rocks)], x, y)
    put("nature", "driftwood", 39, 25, False)
    # puddles and lamplight on the road: only the small ones, only on road cells
    puddles = sorted(n for (c, n) in size if c == "terrain" and n.startswith("puddle") and size[(c, n)][0] <= 2 and size[(c, n)][1] <= 2)
    glints = sorted(n for (c, n) in size if c == "terrain" and n.startswith("glint") and size[(c, n)][0] <= 2 and size[(c, n)][1] <= 2)
    for i, (x, y) in enumerate(((3, 15), (12, 16), (17, 15), (23, 6), (22, 11), (27, 16), (33, 15), (10, 20), (16, 25), (25, 24), (31, 25), (11, 28))):
        pd = puddles[(i * 3) % len(puddles)]
        put("terrain", pd, x, y + size[("terrain", pd)][1] - 1, False)
    for i, (x, y) in enumerate(((4, 15), (14, 15), (27, 15), (34, 15), (17, 25), (26, 25), (33, 25), (7, 15), (19, 15))):
        g = glints[(i * 2) % len(glints)]
        put("terrain", g, x, y + size[("terrain", g)][1] - 1, False)

    # forest: single pines in three sizes, a row every tile, staggered, so they overlap
    # like the picture's; a tree only stands where all its cells are forest floor
    frng = np.random.default_rng(3)
    for y in range(1, h + 2):
        for x in range(-1 + y % 2, w, 2):
            name = ("pine", "pine_tall", "pine_small")[int(frng.choice([0, 0, 1, 2]))]
            cw, ch = size[("nature", name)]
            cells = [(x + i, y - j) for i in range(cw) for j in range(ch)]
            if frng.random() < 0.12 or any((cx, cy) in busy for cx, cy in cells):
                continue
            if any(0 <= cx < w and 0 <= cy < h and grid[cy][cx] != "f" for cx, cy in cells):
                continue
            objects.append(["nature", name, x, y])

    # kerbs along the road, surf where sand meets the sea
    sides = {"n": (0, -1), "e": (1, 0), "s": (0, 1), "w": (-1, 0)}

    def at(x, y):
        return grid[y][x] if 0 <= x < w and 0 <= y < h else None

    for y in range(h):
        for x in range(w):
            if grid[y][x] == "r":
                name = "".join(k for k, (dx, dy) in sides.items() if at(x + dx, y + dy) in ("f", "a"))
                if name:
                    objects.append(["edges", "kerb_" + name, x, y])
            if grid[y][x] == "w":
                name = "".join(k for k, (dx, dy) in sides.items() if at(x + dx, y + dy) == "a")
                if not name:
                    for k in ("ne", "nw", "se", "sw"):
                        if at(x + sides[k[0]][0] + sides[k[1]][0], y + sides[k[0]][1] + sides[k[1]][1]) == "a":
                            name = "corner_" + k
                            break
                if name:
                    objects.append(["edges", "surf_" + name, x, y])
    return {"size": [w, h], "ground": ["".join(r) for r in grid], "legend": GROUND_NAMES, "objects": objects, "name": "Kit test: village",
        "spawns": [["default", 22, 15, "down"], ["north", 22, 1, "down"], ["pier", 44, 15, "left"], ["back", 20, 25, "up"]],
        "warps": [[22, 0, "coast_look_test", "north"], [23, 0, "coast_look_test", "north"]]}


def render(m, tiles, ground, order, seed):
    """Draw a map the way the game will, to check it without opening Godot."""
    prng = np.random.default_rng(seed)
    w, h = m["size"]
    back = {v: k for k, v in m["legend"].items()}
    canvas = np.zeros((h * T, w * T, 3), np.uint8)
    for y in range(h):
        for x in range(w):
            r, v = order.index(m["ground"][y][x]), int(prng.integers(0, 4))
            canvas[y * T:(y + 1) * T, x * T:(x + 1) * T] = ground[r * T:(r + 1) * T, v * T:(v + 1) * T]
    lookup = {(t["cat"], t["name"]): t for t in tiles}

    def key(o):
        t = lookup[(o[0], o[1])]
        flat = t["flat"] or o[0] in ("edges", "terrain")
        return (0, -1 if o[0] == "edges" else t["z"], 0) if flat else (1, o[3] * T + T // 2 + t["sort"], 0)

    for o in sorted(m["objects"], key=key):
        t = lookup[(o[0], o[1])]
        c = t["canvas"]
        x0, y0 = o[2] * T, (o[3] - t["ch"] + 1) * T
        cx0, cy0 = max(0, -x0), max(0, -y0)
        x1, y1 = min(canvas.shape[1], x0 + c.shape[1]), min(canvas.shape[0], y0 + c.shape[0])
        if x1 <= x0 + cx0 or y1 <= y0 + cy0:
            continue
        sub = c[cy0:y1 - y0, cx0:x1 - x0].astype(np.float64)
        dst = canvas[y0 + cy0:y1, x0 + cx0:x1].astype(np.float64)
        al = sub[..., 3:4] / 255.0
        canvas[y0 + cy0:y1, x0 + cx0:x1] = (sub[..., :3] * al + dst * (1 - al)).astype(np.uint8)
    return canvas


def main():
    os.makedirs(OUT, exist_ok=True)
    rng = np.random.default_rng(11)
    lp = load_picture().astype(np.uint8)
    ground, order = grounds(lp, rng)
    Image.fromarray(ground).save(os.path.join(OUT, "coast_ground.png"))

    grid = [["f"] * W for _ in range(H)]
    for k, x, y, w, h in GROUND_RECTS:
        for j in range(y, min(H, y + h)):
            for i in range(x, min(W, x + w)):
                grid[j][i] = k

    items = []
    for n, c, b, how, o in OBJECTS:
        mask = cut(lp, b, how, o)
        if not o.get("split"):
            items.append((n, c, b, mask, o))
            continue
        lab, cents = label(mask)  # every separate blob becomes its own object
        for k, (i, _) in enumerate(sorted(cents.items(), key=lambda kv: -kv[1][2])):
            items.append(("%s_%02d" % (n, k + 1), c, b, lab == i, o))
    items += decals(lp)
    tiles = []
    placements = []
    for name, cat, box, mask, o in items:
        rgba, cell, size, bottom = to_cells(lp, box, mask)
        anchor = (cell[0], cell[1] + size[1] - 1)
        solid = []
        if o.get("solid") == "auto":  # blocks every cell it mostly covers
            for j in range(size[1]):
                for i in range(size[0]):
                    if (rgba[j * T:(j + 1) * T, i * T:(i + 1) * T, 3] > 0).mean() > 0.35:
                        solid.append([i, size[1] - 1 - j])
        elif "solid" in o:
            sx0, sy0, sx1, sy1 = o["solid"]
            for cy in range(sy0, sy1 + 1):
                for cx in range(sx0, sx1 + 1):
                    if (cx, cy) not in o.get("walk", []):
                        solid.append([int(cx - anchor[0]), int(anchor[1] - cy)])
        base = o.get("base", bottom - 2)
        tiles.append({"name": name, "cat": cat, "canvas": rgba, "cw": size[0], "ch": size[1], "solid": solid,
            "flat": bool(o.get("flat", False)), "lamp": int(o.get("lamp", 0)), "z": int(o.get("z", 0)),
            "sort": int(base - (anchor[1] * T + T // 2))})
        placements.append([cat, name, int(anchor[0]), int(anchor[1])])
    tiles += M.all_modules(lp, P, rng, is_dark)

    maps = {
        "coast_look_test": {"size": [W, H], "ground": ["".join(r) for r in grid], "legend": GROUND_NAMES, "objects": placements,
            "spawns": SPAWNS, "name": "Look test: coast", "warps": [[9, 0, "coast_village", "north"], [10, 0, "coast_village", "north"]]},
        "coast_village": village(tiles),
    }
    meta = {"tile_size": T, "ground": {"texture": "coast_ground.png", "materials": [GROUND_NAMES[k] for k in order], "variants": 4,
        "solid": [GROUND_NAMES[k] for k in SOLID_GROUND]}, "categories": {}}
    for cat in sorted({t["cat"] for t in tiles}):
        entries = [t for t in tiles if t["cat"] == cat]
        atlas, pos = P.pack([(e["canvas"], e["cw"], e["ch"]) for e in entries])
        Image.fromarray(atlas).save(os.path.join(OUT, "coast_%s.png" % cat))
        meta["categories"][cat] = {"texture": "coast_%s.png" % cat, "tiles": [
            {"name": e["name"], "atlas": [int(v) for v in pos[i]], "size": [e["cw"], e["ch"]], "solid": e["solid"], "flat": e["flat"],
             "lamp": e["lamp"], "z": e["z"], "sort": e["sort"]} for i, e in enumerate(entries)]}
        print(cat, len(entries), "tiles, atlas", atlas.shape[1], "x", atlas.shape[0])
    json.dump(meta, open(os.path.join(OUT, "coast_tiles.json"), "w"), indent=1)
    json.dump(maps, open(os.path.join(OUT, "coast_maps.json"), "w"), indent=1)
    if os.path.exists(os.path.join(OUT, "coast_map.json")):
        os.remove(os.path.join(OUT, "coast_map.json"))

    for i, (map_id, m) in enumerate(maps.items()):
        canvas = render(m, tiles, ground, order, 5 + i)
        Image.fromarray(glow_layer(canvas)).save(os.path.join(OUT, "%s_glow.png" % map_id))
        if PREVIEW:
            Image.fromarray(canvas).resize((canvas.shape[1] * 2, canvas.shape[0] * 2), Image.NEAREST).save(os.path.join(PREVIEW, map_id + "_built.png"))
        if map_id == "coast_look_test":
            diff = np.abs(canvas.astype(int) - lp.astype(int)).sum(axis=2)
            print("look test: %.1f%% of pixels within 24 of the picture" % (100.0 * (diff <= 24).mean()))
            if PREVIEW:
                both = np.concatenate([canvas, lp], axis=0)
                Image.fromarray(both).resize((both.shape[1] * 2, both.shape[0] * 2), Image.NEAREST).save(os.path.join(PREVIEW, "coast_compare.png"))


if __name__ == "__main__":
    main()
