"""Prepare the Anjabi tileset art for Godot.

Reads the untouched originals in art/source/anjabi_v0.1/ and writes, into
art/tilesets/anjabi/:
  anjabi_ground.png          4 materials x 4 interchangeable seamless 32 px tiles
  anjabi_<category>.png      one packed atlas per category, on a 32 px grid
  anjabi_tiles.json          what is where: atlas cell, size, solid cells, lamp, flags
and, into the folder given as the second argument (optional), preview sheets.

  python3 tools/anjabi/prepare.py [project_root] [preview_folder]

Then run tools/build_anjabi_tileset.gd in Godot to turn these into TileSets.
The list of sprites (names, source boxes, sizes, footprints) is manifest.py.
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from components import label  # noqa: E402
from manifest import ATLASES, GROUNDS, GROUND_PLACEHOLDERS, GROUND_SWATCHES, SPRITES  # noqa: E402

T = 32
ROOT = sys.argv[1] if len(sys.argv) > 1 else "."
PREVIEW = sys.argv[2] if len(sys.argv) > 2 else ""
SRC = os.path.join(ROOT, "art/source/anjabi_v0.1")
OUT = os.path.join(ROOT, "art/tilesets/anjabi")
CATEGORIES = ["terrain", "nature", "architecture", "industrial", "props"]
ATLAS_CELLS_W = 16
BASE_SCALE = 0.5
MIN_SCALE = 0.44


# --- ground --------------------------------------------------------------------------

def find_grid(profile, p0):
    """Period and phase of the art's own pixel grid along one axis."""
    best = (-1.0, p0, 0.0)
    n = len(profile)
    for p in np.arange(p0 * 0.94, p0 * 1.06, 0.004):
        for ph in np.arange(0.0, p, 0.34):
            idx = np.round(ph + np.arange(0, int((n - ph - 1) / p)) * p).astype(int)
            s = profile[idx].mean()
            if s > best[0]:
                best = (s, p, ph)
    return best[1], best[2]


def to_logical(img, p0):
    """Resample a generated 'pixel art' texture to one sample per art pixel."""
    a = np.asarray(img.convert("RGB")).astype(np.float64)
    ex = np.abs(np.diff(a, axis=1)).sum(axis=(0, 2))
    ey = np.abs(np.diff(a, axis=0)).sum(axis=(1, 2))
    px, phx = find_grid(ex, p0)
    py, phy = find_grid(ey, p0)
    # edges fall between pixel i and i+1, so a cell starts at phase + 1
    xs = phx + 1 + np.arange(0, int((a.shape[1] - phx - 1) / px)) * px
    ys = phy + 1 + np.arange(0, int((a.shape[0] - phy - 1) / py)) * py
    out = np.zeros((len(ys), len(xs), 3))
    for j, y in enumerate(ys):
        y0, y1 = int(round(y + py * 0.25)), max(int(round(y + py * 0.75)), int(round(y + py * 0.25)) + 1)
        band = a[y0:y1].mean(axis=0)
        for i, x in enumerate(xs):
            x0, x1 = int(round(x + px * 0.25)), max(int(round(x + px * 0.75)), int(round(x + px * 0.25)) + 1)
            out[j, i] = band[x0:x1].mean(axis=0)
    return out, (px, py)


def flatten(a, sigma):
    """Remove slow brightness drift so a small tile does not repeat as blotches."""
    img = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))
    low = np.asarray(img.filter(ImageFilter.GaussianBlur(sigma))).astype(np.float64)
    return a - low + a.mean(axis=(0, 1))


def seam_path(err):
    """Cheapest top-to-bottom path through an (n, m) error strip."""
    n, m = err.shape
    cost = err.copy()
    for i in range(1, n):
        prev = cost[i - 1]
        left = np.concatenate(([np.inf], prev[:-1]))
        right = np.concatenate((prev[1:], [np.inf]))
        cost[i] += np.minimum(prev, np.minimum(left, right))
    path = np.zeros(n, int)
    path[-1] = int(cost[-1].argmin())
    for i in range(n - 2, -1, -1):
        j = path[i + 1]
        lo, hi = max(0, j - 1), min(m, j + 2)
        path[i] = lo + int(cost[i, lo:hi].argmin())
    return path


def wrap_h(c, size, m):
    """c is (rows, size + m, ch). Returns (rows, size, ch) that tiles left-right."""
    own = c[:, :m]
    cont = c[:, size:size + m]  # what follows the right edge
    err = ((own - cont) ** 2).sum(axis=2)
    path = seam_path(err)
    out = c[:, :size].copy()
    for i, p in enumerate(path):
        out[i, :p] = cont[i, :p]
    return out


def make_seamless(crop, size, m):
    h = wrap_h(crop, size, m)
    v = wrap_h(np.transpose(h, (1, 0, 2)), size, m)
    return np.transpose(v, (1, 0, 2))


def ring_mask(size, r):
    m = np.zeros((size, size), bool)
    m[:r] = m[-r:] = True
    m[:, :r] = m[:, -r:] = True
    return m


def ground_tiles(name, p0, colours, rng):
    src, _ = to_logical(Image.open(os.path.join(SRC, "ground_%s.png" % name)), p0)
    return ground_from(src, colours, rng, 12)


def swatch_tiles(atlas, box, scale, colours, rng):
    """Ground tiles from a small framed swatch on a sprite sheet (e.g. deck planks)."""
    rgb = atlas[0]
    x0, y0, x1, y1 = box
    c = Image.fromarray(rgb[y0:y1, x0:x1])
    w, h = int(round((x1 - x0) * scale)), int(round((y1 - y0) * scale))
    a = np.asarray(c.resize((w, h), Image.LANCZOS)).astype(np.float64)
    return ground_from(a[5:-5, 5:-5], colours, rng, 4)


def water_tiles(rng):
    """Stand-in water: flat deep teal with a few wave flecks, kept off the border."""
    deep, mid, hi = (22, 54, 80), (30, 72, 100), (70, 128, 148)
    tiles = []
    for _ in range(4):
        t = np.zeros((T, T, 3), np.uint8)
        t[:] = deep
        for colour, count in ((mid, 7), (hi, 3)):
            for _ in range(count):
                x, y, n = int(rng.integers(3, T - 9)), int(rng.integers(3, T - 3)), int(rng.integers(3, 7))
                t[y, x:x + n] = colour
                if colour == mid:
                    t[y + 1, x + 1:x + n - 1] = colour
        tiles.append(t)
    return np.concatenate(tiles, axis=1)


def ground_from(src, colours, rng, min_sep):
    """Four interchangeable seamless 32 px tiles from a texture at one sample per art pixel."""
    flat = flatten(src, 10.0 if T >= 32 else 5.0)
    n = min(flat.shape[0], flat.shape[1])
    m = 8 if T >= 32 else 4
    # base tile: the crop whose opposite edges already agree best and which is even
    best = None
    step = 2 if n > 80 else 1
    for y in range(0, flat.shape[0] - T - m + 1, step):
        for x in range(0, flat.shape[1] - T - m + 1, step):
            c = flat[y:y + T + m, x:x + T + m]
            e = np.abs(c[:, :m] - c[:, T:T + m]).mean() + np.abs(c[:m] - c[T:T + m]).mean()
            q = c[:T, :T].reshape(4, T // 4, 4, T // 4, 3).mean(axis=(1, 3, 4))
            score = e + 2.0 * q.std()
            if best is None or score < best[0]:
                best = (score, x, y)
    _, bx, by = best
    base = make_seamless(flat[by:by + T + m, bx:bx + T + m], T, m)
    # variants: other crops whose border ring is closest to the base's, so any
    # variant can sit next to any other; the ring itself is taken from the base
    ring = ring_mask(T, 3)
    cands = []
    for y in range(0, flat.shape[0] - T + 1, 1):
        for x in range(0, flat.shape[1] - T + 1, 1):
            if abs(x - bx) < min_sep and abs(y - by) < min_sep:
                continue
            c = flat[y:y + T, x:x + T]
            cands.append((np.abs(c[ring] - base[ring]).mean(), x, y))
    cands.sort()
    chosen = []
    for _, x, y in cands:
        if all(abs(x - cx) >= min_sep or abs(y - cy) >= min_sep for cx, cy in chosen):
            chosen.append((x, y))
        if len(chosen) == 3:
            break
    yy, xx = np.mgrid[0:T, 0:T]
    d = np.minimum(np.minimum(xx, T - 1 - xx), np.minimum(yy, T - 1 - yy))
    tiles = [base]
    for x, y in chosen:
        v = flat[y:y + T, x:x + T]
        take_v = (d - 1.5) / 4.0 > rng.random((T, T))
        tiles.append(np.where(take_v[..., None], v, base))
    while len(tiles) < 4:  # a small swatch may not hold three distinct variants
        tiles.append(tiles[len(tiles) % max(1, len(tiles) - 1)] if len(tiles) > 1 else base)
    strip = np.clip(np.concatenate(tiles, axis=1), 0, 255).astype(np.uint8)
    q = Image.fromarray(strip).quantize(colors=colours, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    return np.asarray(q.convert("RGB"))


def grass_edges(grass, rng):
    """Fringe tiles that let grass creep over a neighbouring ground material.

    The source art has no transition tiles, so these are cut from the seamless grass
    tile with a ragged edge. One tile per combination of sides the grass lies on
    (n, e, s, w), plus four for a lone diagonal neighbour. They go on the non-grass
    cell, in a layer above the ground.
    """
    def profile():
        p = np.full(T, 5.0)
        v = 5.0
        for i in range(2, T - 2):
            v = min(8.0, max(2.0, v + rng.choice([-1.0, 0.0, 0.0, 1.0])))
            p[i] = v
        for i in range(2, 8):  # ease back to the shared depth at both ends
            p[T - 1 - i] = p[T - 1 - i] + (5.0 - p[T - 1 - i]) * (8 - i) / 6.0
        return np.round(p)
    prof = {k: profile() for k in "nesw"}
    yy, xx = np.mgrid[0:T, 0:T]
    side = {
        "n": yy < prof["n"][xx], "s": yy > T - 1 - prof["s"][xx],
        "w": xx < prof["w"][yy], "e": xx > T - 1 - prof["e"][yy],
    }
    corner = {
        "ne": (xx - (T - 0.5)) ** 2 + (yy + 0.5) ** 2 < 30, "nw": (xx + 0.5) ** 2 + (yy + 0.5) ** 2 < 30,
        "se": (xx - (T - 0.5)) ** 2 + (yy - (T - 0.5)) ** 2 < 30, "sw": (xx + 0.5) ** 2 + (yy - (T - 0.5)) ** 2 < 30,
    }
    dark = grass.reshape(-1, 3)[grass.reshape(-1, 3).sum(axis=1).argmin()]
    out = []

    def tile(name, mask):
        rgba = np.zeros((T, T, 4), np.uint8)
        rgba[..., :3] = grass
        # a one-pixel shadow where the turf ends gives it a little thickness
        pad = np.pad(mask, 1, constant_values=True)
        rim = mask & ~(pad[:-2, 1:-1] & pad[2:, 1:-1] & pad[1:-1, :-2] & pad[1:-1, 2:])
        rgba[rim, :3] = dark
        rgba[..., 3] = np.where(mask, 255, 0)
        rgba[~mask] = 0
        out.append(("grass_edge_" + name, rgba))

    for bits in range(1, 16):
        name = "".join(k for i, k in enumerate("nesw") if bits >> i & 1)
        mask = np.zeros((T, T), bool)
        for k in name:
            mask |= side[k]
        tile(name, mask)
    for k, m in corner.items():
        tile("corner_" + k, m)
    return out


def pier_edges(deck):
    """Edge tiles for water beside a deck or platform: the timber face, piles and
    shadow below a deck to the north, a dark rim on the other sides. Cut from the deck
    tile (the art has no pier edge), laid on the water cell in a layer above the ground.
    """
    d = deck.astype(np.float64)
    out = []
    for bits in range(1, 16):
        name = "".join(k for i, k in enumerate("nesw") if bits >> i & 1)
        rgba = np.zeros((T, T, 4), np.float64)
        if "s" in name:
            rgba[T - 3:, :, :3] = d[:3] * 0.5
            rgba[T - 3:, :, 3] = 255
            rgba[T - 4, :] = (10, 12, 18, 150)
        if "e" in name:
            rgba[:, T - 3:, :3] = d[:, :3] * 0.5
            rgba[:, T - 3:, 3] = 255
            rgba[:, T - 4] = (10, 12, 18, 150)
        if "w" in name:
            rgba[:, :3, :3] = d[:, T - 3:] * 0.5
            rgba[:, :3, 3] = 255
            rgba[:, 3] = (10, 12, 18, 150)
        if "n" in name:
            rgba[:9, :, :3] = d[T - 9:] * 0.42
            rgba[:9, :, 3] = 255
            rgba[9, :] = (8, 8, 12, 255)
            for i in range(6):  # shadow on the water, fading out
                rgba[10 + i, :] = (6, 10, 18, 130 - i * 20)
            for x0 in (4, 20):  # piles
                rgba[:22, x0:x0 + 6, :3] = d[T - 22:, x0:x0 + 6] * 0.3
                rgba[:22, x0, :3] = d[T - 22:, x0] * 0.5
                rgba[:22, x0:x0 + 6, 3] = 255
                rgba[22, x0:x0 + 6] = (8, 8, 12, 255)
        out.append(("pier_edge_" + name, np.clip(rgba, 0, 255).astype(np.uint8)))
    return out


# --- sprites -------------------------------------------------------------------------

def norm_alpha(a):
    return np.clip((a.astype(np.float64) - 8.0) / 236.0, 0.0, 1.0)


def resize_rgba(rgb, alpha, w, h):
    """Area-correct resize with premultiplied alpha; returns rgb (float) and alpha 0..1."""
    pm = rgb * alpha[..., None]
    chans = []
    for k in range(3):
        chans.append(np.asarray(Image.fromarray(pm[..., k].astype(np.float32)).resize((w, h), Image.LANCZOS)))
    al = np.asarray(Image.fromarray(alpha.astype(np.float32)).resize((w, h), Image.LANCZOS))
    al = np.clip(al, 0.0, 1.0)
    out = np.stack(chans, axis=2) / np.maximum(al, 1e-3)[..., None]
    return np.clip(out, 0, 255), al


def snap_cells(px):
    """How many cells a length should take: a little over a whole number snaps down."""
    c = px / T
    f = int(np.floor(c))
    return f if f >= 1 and c - f < 0.25 else int(np.ceil(c))


def cut_sprite(atlas, box, opts):
    rgb, alpha, lab, cents = atlas
    x0, y0, x1, y1 = box
    # every connected blob whose centre lies in the box belongs to this sprite
    ids = [i for i, (cx, cy, cnt) in cents.items() if x0 <= cx < x1 and y0 <= cy < y1 and cnt >= 20]
    mask = np.isin(lab, ids)
    ys, xs = np.nonzero(mask)
    x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    inset = opts.get("inset", 0)
    if inset:
        x0, x1 = x0 + inset, x1 - inset
    a = np.where(mask[y0:y1, x0:x1], alpha[y0:y1, x0:x1], 0.0)
    c = rgb[y0:y1, x0:x1].astype(np.float64)
    sw, sh = x1 - x0, y1 - y0
    if "size" in opts:
        w, h = opts["size"]
    elif "fit_w" in opts:
        w = opts["fit_w"] * T
        h = int(round(sh * w / sw))
    else:
        w, h = sw * BASE_SCALE, sh * BASE_SCALE
        cw, ch = snap_cells(w), snap_cells(h)
        s = max(MIN_SCALE, min(BASE_SCALE, cw * T / sw, ch * T / sh))
        w, h = int(round(sw * s)), int(round(sh * s))
    extra = 8 if opts.get("hwrap") else 0
    out, al = resize_rgba(c, a, w + extra, h)
    if extra:
        both = np.concatenate([out, al[..., None] * 255.0], axis=2)
        both = wrap_h(both, w, extra)
        out, al = both[..., :3], both[..., 3] / 255.0
    rgba = np.zeros((h, w, 4), np.uint8)
    rgba[..., :3] = out.astype(np.uint8)
    rgba[..., 3] = np.where(al >= 0.5, 255, 0)
    rgba[rgba[..., 3] == 0] = 0
    return rgba, (sw, sh)


def layout(name, rgba, opts):
    """Pad a sprite to whole cells (bottom-aligned, centred) and work out its footprint."""
    h, w = rgba.shape[:2]
    cw, ch = int(np.ceil(w / T)), int(np.ceil(h / T))
    flat = bool(opts.get("flat", False))
    if "cells" in opts:
        cells = [list(c) for c in opts["cells"]]
    elif flat or ("solid" in opts and opts["solid"] is None):
        cells = []
    else:
        fw, fh = opts.get("solid", (cw, 1))
        fw = min(fw, max(cw, fw))
        if fw > cw:
            cw = fw
        if (cw - fw) % 2:
            cw += 1
        fh = min(fh, ch)
        c0 = (cw - fw) // 2
        cells = [[c0 + i, j] for j in range(fh) for i in range(fw)]
    canvas = np.zeros((ch * T, cw * T, 4), np.uint8)
    ox = (cw * T - w) // 2
    canvas[ch * T - h:, ox:ox + w] = rgba
    return canvas, cw, ch, cells


def pack(items):
    """Shelf-pack (canvas, cw, ch) into an atlas ATLAS_CELLS_W cells wide."""
    order = sorted(range(len(items)), key=lambda i: (-items[i][2], -items[i][1]))
    pos = {}
    x = y = shelf = 0
    for i in order:
        _, cw, ch = items[i]
        if x + cw > ATLAS_CELLS_W:
            x, y, shelf = 0, y + shelf, 0
        pos[i] = (x, y)
        x += cw
        shelf = max(shelf, ch)
    rows = y + shelf
    atlas = np.zeros((rows * T, ATLAS_CELLS_W * T, 4), np.uint8)
    for i, (px, py) in pos.items():
        c, cw, ch = items[i]
        atlas[py * T:(py + ch) * T, px * T:(px + cw) * T] = c
    return atlas, pos


def quantize(atlas, colours):
    rgb = Image.fromarray(atlas[..., :3])
    q = np.asarray(rgb.quantize(colors=colours, method=Image.Quantize.MEDIANCUT, kmeans=2, dither=Image.Dither.NONE).convert("RGB"))
    out = atlas.copy()
    out[..., :3] = q
    out[atlas[..., 3] == 0] = 0
    return out


def save_preview(arr, path, zoom, bg=(46, 40, 52)):
    img = Image.fromarray(arr)
    if img.mode == "RGBA":
        back = Image.new("RGBA", img.size, bg + (255,))
        back.alpha_composite(img)
        img = back.convert("RGB")
    img.resize((img.width * zoom, img.height * zoom), Image.NEAREST).save(path)


def main():
    os.makedirs(OUT, exist_ok=True)
    rng = np.random.default_rng(7)
    meta = {"tile_size": T, "ground": {"texture": "anjabi_ground.png", "materials": [], "variants": 4}, "categories": {}}

    atlases = {}
    for key, fname in ATLASES.items():
        a = np.asarray(Image.open(os.path.join(SRC, fname)).convert("RGBA"))
        lab, cents = label(a[..., 3] > 128)
        atlases[key] = (a[..., :3], norm_alpha(a[..., 3]), lab, cents)
        print("labelled", fname, len(cents))

    rows = []
    for name, p0, colours in GROUNDS:
        rows.append(ground_tiles(name, p0, colours, rng))
        meta["ground"]["materials"].append(name)
        print("ground", name)
    for name, key, box, scale, colours in GROUND_SWATCHES:
        rows.append(swatch_tiles(atlases[key], box, scale, colours, rng))
        meta["ground"]["materials"].append(name)
        print("ground", name, "(from a swatch)")
    meta["ground"]["solid"] = []
    meta["ground"]["flags"] = {}
    for name, solid, note in GROUND_PLACEHOLDERS:
        rows.append(water_tiles(rng))
        meta["ground"]["materials"].append(name)
        meta["ground"]["flags"][name] = note
        if solid:
            meta["ground"]["solid"].append(name)
        print("ground", name, "(placeholder)")
    ground = np.concatenate(rows, axis=0)
    Image.fromarray(ground).save(os.path.join(OUT, "anjabi_ground.png"))
    if PREVIEW:
        prng = np.random.default_rng(3)
        sheets = []
        for r in range(len(rows)):
            sheet = np.zeros((6 * T, 10 * T, 3), np.uint8)  # 10 x 6 tiles of each material
            for y in range(6):
                for x in range(10):
                    v = int(prng.integers(0, 4))
                    sheet[y * T:(y + 1) * T, x * T:(x + 1) * T] = ground[r * T:(r + 1) * T, v * T:(v + 1) * T]
            sheets.append(sheet)
        pairs = [np.concatenate(sheets[i:i + 2], axis=1) for i in range(0, len(sheets) - 1, 2)]
        save_preview(np.concatenate(pairs, axis=0), os.path.join(PREVIEW, "preview_ground.png"), 2)

    by_cat = {c: [] for c in CATEGORIES}
    for name, cat, key, box, opts in SPRITES:
        rgba, src_size = cut_sprite(atlases[key], box, opts)
        canvas, cw, ch, cells = layout(name, rgba, opts)
        by_cat[cat].append({"name": name, "canvas": canvas, "cw": cw, "ch": ch, "cells": cells, "opts": opts,
            "px": [int(rgba.shape[1]), int(rgba.shape[0])], "scale": [round(rgba.shape[1] / src_size[0], 3), round(rgba.shape[0] / src_size[1], 3)]})
    grass_row = meta["ground"]["materials"].index("grass")
    deck_row = meta["ground"]["materials"].index("wood_deck")
    derived = grass_edges(ground[grass_row * T:(grass_row + 1) * T, 0:T], rng) + pier_edges(ground[deck_row * T:(deck_row + 1) * T, 0:T])
    for name, rgba in derived:
        by_cat["terrain"].append({"name": name, "canvas": rgba, "cw": 1, "ch": 1, "cells": [], "opts": {"flat": True},
            "px": [T, T], "scale": [1.0, 1.0], "exact": True})
    for cat in CATEGORIES:
        entries = by_cat[cat]
        atlas, pos = pack([(e["canvas"], e["cw"], e["ch"]) for e in entries])
        atlas = quantize(atlas, 160)
        for i, e in enumerate(entries):
            if e.get("exact"):  # generated from the ground tiles: keep their exact colours
                px, py = pos[i]
                atlas[py * T:(py + 1) * T, px * T:(px + 1) * T] = e["canvas"]
        fname = "anjabi_%s.png" % cat
        Image.fromarray(atlas).save(os.path.join(OUT, fname))
        tiles = []
        for i, e in enumerate(entries):
            o = e["opts"]
            tiles.append({"name": e["name"], "atlas": list(pos[i]), "size": [e["cw"], e["ch"]], "solid": e["cells"],
                "flat": bool(o.get("flat", False)), "lamp": int(o.get("lamp", 0)), "px": e["px"], "scale": e["scale"],
                "flag": o.get("flag", "")})
        meta["categories"][cat] = {"texture": fname, "tiles": tiles}
        print(cat, len(entries), "sprites, atlas", atlas.shape[1], "x", atlas.shape[0])
        if PREVIEW:
            save_preview(atlas, os.path.join(PREVIEW, "preview_%s.png" % cat), 2)
    with open(os.path.join(OUT, "anjabi_tiles.json"), "w") as f:
        json.dump(meta, f, indent=1)


if __name__ == "__main__":
    main()
