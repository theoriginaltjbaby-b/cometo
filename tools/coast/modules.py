"""Modular pieces for the coast kit, so maps other than the look test can be built.

Cut or derived from the look reference at its own pixel grid:
  roofs      red tile and slate, as nine pieces each (corners, edges, four seamless
             field variants): any width and depth
  walls      plain wall and the two timber ends, two cells tall
  details    porch with door (red and slate), small and wide lit windows, two
             planters, roof units; these sit over walls and roofs
  nature     a pine drawn pixel by pixel in the picture's colours
  props      picket fence that repeats
  edges      kerb lines for road borders and surf for sand beside water, one tile per
             combination of sides
Each returns a dict: name, category, rgba (whole cells), solid cells, sort offset.
"""
import numpy as np
from PIL import Image, ImageDraw

T = 16


def _tile(cat, name, rgba, solid=None, flat=False, sort=None, z=0, lamp=0):
    h = rgba.shape[0]
    ys = np.nonzero(rgba[..., 3].any(axis=1))[0]
    bottom = int(ys.max()) + 1 if len(ys) else h
    return {"name": name, "cat": cat, "canvas": rgba, "cw": rgba.shape[1] // T, "ch": h // T, "solid": solid or [],
        "flat": flat, "lamp": lamp, "z": z, "sort": int(sort if sort is not None else (bottom - 2) - (h - T // 2))}


def _rgba(rgb, mask=None):
    out = np.zeros(rgb.shape[:2] + (4,), np.uint8)
    out[..., :3] = np.clip(rgb, 0, 255)
    out[..., 3] = 255 if mask is None else np.where(mask, 255, 0)
    if mask is not None:
        out[~mask] = 0
    return out


def _on_cells(rgba, cw, ch, x=None, bottom=0):
    """Put a sprite on a cw x ch cell canvas, centred (or at x), `bottom` px above the floor."""
    canvas = np.zeros((ch * T, cw * T, 4), np.uint8)
    h, w = rgba.shape[:2]
    x0 = (cw * T - w) // 2 if x is None else x
    y0 = ch * T - bottom - h
    canvas[y0:y0 + h, x0:x0 + w] = rgba
    return canvas


def roofs(lp, P, rng):
    out = []
    specs = [  # name, left, right, top, field rows, bottom row top, clean x for top edge, clean x for eave
        ("red", 40, 128, 22, (40, 70), 72, 56, 100),
        ("slate", 172, 248, 32, (48, 74), 76, 188, 226),
    ]
    a = lp.astype(np.float64)
    for name, x0, x1, top, (f0, f1), bot, tx, bx in specs:
        tl = a[top:top + T, x0:x0 + T]
        pieces = {
            "tl": tl, "tr": tl[:, ::-1],
            "t": P.wrap_h(a[top:top + T, tx:tx + T + 4], T, 4),
            "l": np.transpose(P.wrap_h(np.transpose(a[f0:f0 + T + 4, x0:x0 + T], (1, 0, 2)), T, 4), (1, 0, 2)),
            "r": np.transpose(P.wrap_h(np.transpose(a[f0:f0 + T + 4, x1 - T:x1], (1, 0, 2)), T, 4), (1, 0, 2)),
            "bl": a[bot:bot + T, x0:x0 + T], "br": a[bot:bot + T, x1 - T:x1],
            "b": P.wrap_h(a[bot:bot + T, bx:bx + T + 4], T, 4),
        }
        field = P.ground_from(a[f0:f1, x0 + 4:x1 - 4], 18, rng, 3)
        for v in range(4):
            pieces["c%d" % v] = field[:, v * T:(v + 1) * T]
        for key, rgb in pieces.items():
            mask = None
            if key in ("tl", "tr", "bl", "br", "t", "l", "r", "b"):
                # the picture's forest shows past the roof's outline: drop it
                d = np.asarray(rgb, np.float64)
                lumi = d[..., 0] * 0.3 + d[..., 1] * 0.59 + d[..., 2] * 0.11
                green = (d[..., 1] > d[..., 0] + 6) & (d[..., 1] > d[..., 2] - 8) if name == "red" else (d[..., 1] > d[..., 0] + 14) & (d[..., 1] > d[..., 2] + 4)
                mask = ~(green & (lumi < 110))
            out.append(_tile("buildings", "roof_%s_%s" % (name, key), _rgba(rgb, mask), solid=[[0, 0]], sort=0))
    return out


def walls(lp):
    a = lp.astype(np.float64)
    strip = a[88:108, 117:121]
    plain = np.zeros((2 * T, T, 3))
    for y in range(2 * T):
        row = strip[min(y, 19)]
        plain[y] = np.tile(row, (4, 1))
    plain[30:] = (40, 32, 46)
    left, right = plain.copy(), plain.copy()
    for y in range(30):
        left[y, 1:7] = a[88 + min(y, 19), 41:47]
        right[y, 9:15] = a[88 + min(y, 19), 121:127]
    solid = [[0, 0], [0, 1]]
    return [_tile("buildings", "wall_plain", _rgba(plain), solid=solid, sort=4), _tile("buildings", "wall_end_l", _rgba(left), solid=solid, sort=4),
        _tile("buildings", "wall_end_r", _rgba(right), solid=solid, sort=4)]


def details(lp):
    a = lp.astype(np.float64)
    out = []

    def poly(x0, y0, x1, y1, pts, rects):
        m = Image.new("1", (x1 - x0, y1 - y0), 0)
        d = ImageDraw.Draw(m)
        d.polygon([(px - x0, py - y0) for px, py in pts], fill=1)
        for rx0, ry0, rx1, ry1 in rects:
            d.rectangle([rx0 - x0, ry0 - y0, rx1 - x0 - 1, ry1 - y0 - 1], fill=1)
        return np.asarray(m, bool)

    # porches: the little gable, its lamp and the door, 3 cells wide and 3 tall
    m = poly(48, 71, 96, 119, [(72, 70), (51, 91), (94, 91)], [(62, 88, 86, 119)])
    out.append(_tile("details", "porch_red", _on_cells(_rgba(a[71:119, 48:96], m), 3, 3), sort=6))
    m = poly(186, 73, 234, 119, [(210, 73), (192, 94), (228, 94)], [(199, 92, 220, 119)])
    out.append(_tile("details", "porch_slate", _on_cells(_rgba(a[73:119, 186:234], m), 3, 3), sort=6))
    # windows sit 3 px under the eave, as on the houses in the picture
    out.append(_tile("details", "window_small", _on_cells(_rgba(a[91:108, 48:63]), 1, 2, bottom=12), sort=5))
    out.append(_tile("details", "window_wide", _on_cells(_rgba(a[91:108, 94:118]), 2, 2, bottom=12), sort=5))
    # planters: everything in the box that is not wall
    for name, (x0, y0, x1, y1), cw in (("planter_small", (41, 107, 62, 127), 2), ("planter_flowers", (88, 105, 127, 127), 3)):
        c = a[y0:y1, x0:x1]
        lumi = c[..., 0] * 0.3 + c[..., 1] * 0.59 + c[..., 2] * 0.11
        wall = (lumi > 118) & (c[..., 0] > c[..., 1]) & (c[..., 0] - c[..., 2] < 60) & (c[..., 1] > 100)
        wall[8:] = False
        out.append(_tile("details", name, _on_cells(_rgba(c, ~wall), cw, 2), sort=7))
    out.append(_tile("details", "roof_unit_a", _on_cells(_rgba(a[15:38, 104:120]), 1, 2), sort=2))
    out.append(_tile("details", "roof_unit_b", _on_cells(_rgba(a[27:46, 227:243]), 1, 2), sort=2))
    return out


def pine(lp, is_dark):
    """Pines drawn pixel by pixel: tiers of boughs lit from the upper left, in five
    greens taken from the picture's own pines. Three sizes."""
    a = lp[0:113, 0:40].astype(np.float64)
    keep = a[~is_dark(a) & (a[..., 1] > a[..., 0])]
    lumi = keep[:, 0] * 0.3 + keep[:, 1] * 0.59 + keep[:, 2] * 0.11
    order = np.argsort(lumi)
    shade = [keep[order[int(len(order) * q)]] for q in (0.12, 0.38, 0.62, 0.84, 0.97)]
    ink = (14, 26, 30)
    out = []
    for name, tiers, step, tall, spread, cells_h, shift in (("pine", 4, 9, 17, 3.3, 3, 0), ("pine_tall", 5, 9, 18, 2.9, 4, 1), ("pine_small", 3, 8, 15, 3.6, 2, -1)):
        w, h = 2 * T, cells_h * T
        idx = np.full((h, w), -1, int)
        cx = 15.5 + shift
        base = h - 4 - (tiers - 1) * step - tall
        for i in range(tiers - 1, -1, -1):
            top, half = base + i * step, 5.0 + i * spread
            for y in range(max(0, top), top + tall):
                f = (y - top + 1) / tall
                hw = max(1.0, half * f)
                for x in range(w):
                    dx = x - cx
                    if abs(dx) > hw or ((y == top + tall - 1) and (x % 4 == 1)) or ((y == top + tall - 2) and (x % 4 == 3) and abs(dx) > hw - 2):
                        continue
                    s = 2
                    if dx < -hw * 0.3:
                        s = 3
                    if dx > hw * 0.35:
                        s = 1
                    if f > 0.82:
                        s = max(0, s - 1)
                    if (dx < -hw * 0.5 and f > 0.3 and (x + y) % 3 == 0) or (y - top < 4 and dx <= 0) or (abs(dx) < 1 and f < 0.6):
                        s = 4
                    if dx > hw * 0.72:
                        s = 0
                    idx[y, x] = s
        rgb = np.zeros((h, w, 3))
        mask = idx >= 0
        for s in range(5):
            rgb[idx == s] = shade[s]
        tx = int(cx) - 1
        rgb[h - 4:h, tx:tx + 4] = (72, 48, 42)
        rgb[h - 4:h, tx + 2:tx + 4] = (50, 34, 36)
        mask[h - 4:h, tx:tx + 4] = True
        pad = np.pad(mask, 1)
        edge = ~mask & (pad[:-2, 1:-1] | pad[2:, 1:-1] | pad[1:-1, :-2] | pad[1:-1, 2:])
        rgb[edge] = ink
        out.append(_tile("nature", name, _rgba(rgb, mask | edge), solid=[[0, 0], [1, 0]]))
    return out


def fence(lp, P):
    a = lp.astype(np.float64)
    c = a[268:284, 48:68]
    brown = (c[..., 0] >= c[..., 1] - 2) & (c[..., 0] > 60)
    both = np.concatenate([c, brown[..., None] * 255.0], axis=2)
    both = P.wrap_h(both, T, 4)
    return [_tile("props", "picket_fence", _rgba(both[..., :3], both[..., 3] > 127), solid=[[0, 0]])]


def _profile(rng):
    p = np.zeros(T)
    v = 0.0
    for i in range(2, T - 2):
        v = min(1.5, max(-1.5, v + rng.choice([-1.0, 0.0, 0.0, 1.0])))
        p[i] = v
    p[T - 4:] *= 0.3
    return np.round(p)


def edges(lp, rng):
    """Kerbs and surf. One tile per combination of sides (n, e, s, w) the other
    surface lies on, plus four for a lone diagonal neighbour of the surf."""
    a = lp.astype(np.float64)
    out = []
    kerb = np.median(a[130:133, 96:136].reshape(-1, 3), axis=0)
    dark = np.median(a[133:135, 96:136].reshape(-1, 3), axis=0) * 0.7
    for bits in range(1, 16):
        name = "".join(k for i, k in enumerate("nesw") if bits >> i & 1)
        rgba = np.zeros((T, T, 4))
        for k in name:
            line, shadow = {"n": ((slice(0, 2), slice(None)), (2, slice(None))), "s": ((slice(T - 2, T), slice(None)), (T - 3, slice(None))),
                "w": ((slice(None), slice(0, 2)), (slice(None), 2)), "e": ((slice(None), slice(T - 2, T)), (slice(None), T - 3))}[k]
            rgba[shadow] = (*dark, 255)
            rgba[line] = (*kerb, 255)
        out.append(_tile("edges", "kerb_" + name, rgba.astype(np.uint8), flat=True))
    sand = np.median(a[248:272, 344:376].reshape(-1, 3), axis=0)
    wet = sand * np.array([0.72, 0.74, 0.86])
    foam = np.array([226.0, 240.0, 248.0])
    shallow = np.array([96.0, 168.0, 200.0])
    prof = {k: _profile(rng) for k in "nesw"}
    yy, xx = np.mgrid[0:T, 0:T]
    dist = {"n": yy + prof["n"][xx], "s": (T - 1 - yy) + prof["s"][xx], "w": xx + prof["w"][yy], "e": (T - 1 - xx) + prof["e"][yy]}
    corner = {"nw": np.hypot(xx + 0.5, yy + 0.5), "ne": np.hypot(T - 0.5 - xx, yy + 0.5), "sw": np.hypot(xx + 0.5, T - 0.5 - yy),
        "se": np.hypot(T - 0.5 - xx, T - 0.5 - yy)}

    def surf(name, d):
        rgba = np.zeros((T, T, 4))
        for limit, colour, alpha in ((11, shallow, 150), (8, shallow, 255), (6, foam, 255), (4, wet, 255), (2.5, sand, 255)):
            m = d < limit
            rgba[m, :3] = colour
            rgba[m, 3] = alpha
        speck = (d >= 6) & (d < 8) & ((xx * 3 + yy * 5) % 7 == 0)
        rgba[speck, :3] = foam
        out.append(_tile("edges", "surf_" + name, rgba.astype(np.uint8), flat=True))

    for bits in range(1, 16):
        name = "".join(k for i, k in enumerate("nesw") if bits >> i & 1)
        surf(name, np.min([dist[k] for k in name], axis=0))
    for k, d in corner.items():
        surf("corner_" + k, d)
    return out


def all_modules(lp, P, rng, is_dark):
    return roofs(lp, P, rng) + walls(lp) + details(lp) + pine(lp, is_dark) + fence(lp, P) + edges(lp, rng)
