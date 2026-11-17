"""Resample the look reference to one sample per art pixel and save it.
  python3 tools/coast/logical.py src.png out.png [debug_grid.png]
"""
import sys
import numpy as np
from PIL import Image, ImageDraw


def grid(profile, lo, hi):
    best = (-1, 0, 0)
    n = len(profile)
    for p in np.arange(lo, hi, 0.002):
        for ph in np.arange(0, p, 0.2):
            idx = np.round(ph + np.arange(0, int((n - ph - 1) / p)) * p).astype(int)
            s = profile[idx].mean()
            if s > best[0]:
                best = (s, p, ph)
    return best[1], best[2]


def to_logical(a, lo=3.0, hi=3.45):
    ex = np.abs(np.diff(a, axis=1)).sum(axis=(0, 2))
    ey = np.abs(np.diff(a, axis=0)).sum(axis=(1, 2))
    px, phx = grid(ex, lo, hi)
    py, phy = grid(ey, lo, hi)
    xs = phx + 1 + np.arange(0, int((a.shape[1] - phx - 1) / px)) * px
    ys = phy + 1 + np.arange(0, int((a.shape[0] - phy - 1) / py)) * py
    out = np.zeros((len(ys), len(xs), 3))
    for j, y in enumerate(ys):
        yc = min(a.shape[0] - 1, int(y + py / 2))
        for i, x in enumerate(xs):
            xc = min(a.shape[1] - 1, int(x + px / 2))
            out[j, i] = a[yc, xc]
    return out.astype(np.uint8), (px, phx, py, phy)


if __name__ == "__main__":
    a = np.asarray(Image.open(sys.argv[1]).convert("RGB")).astype(np.float64)
    out, g = to_logical(a)
    print("grid", g, "logical size", out.shape[1], "x", out.shape[0])
    Image.fromarray(out).save(sys.argv[2])
    if len(sys.argv) > 3:
        z = 3
        im = Image.fromarray(out).resize((out.shape[1] * z, out.shape[0] * z), Image.NEAREST)
        d = ImageDraw.Draw(im)
        for x in range(0, out.shape[1], 16):
            d.line([(x * z, 0), (x * z, im.height)], fill=(255, 255, 0))
            d.text((x * z + 2, 2), str(x // 16), fill=(255, 255, 255))
        for y in range(0, out.shape[0], 16):
            d.line([(0, y * z), (im.width, y * z)], fill=(255, 255, 0))
            d.text((2, y * z + 2), str(y // 16), fill=(255, 255, 255))
        im.save(sys.argv[3])
