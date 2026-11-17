"""Draw the chibi player sheet for the coast look test, pixel by pixel.

A small hooded figure in a yellow raincoat, 16 px wide and 25 tall, in the format
GridActor expects (see PixelArt.character): 9 columns (idle, walk 1-4, run 1-4) by
4 rows (down, up, left, right) of 16 x 32 frames, feet on the bottom row.
  python3 tools/coast/make_chibi.py [project_root]
Writes art/pixel/chars/chibi_raincoat.png.
"""
import os
import sys

import numpy as np
from PIL import Image

ROOT = sys.argv[1] if len(sys.argv) > 1 else "."
C = {
    ".": (0, 0, 0, 0), "o": (30, 26, 44, 255), "Y": (238, 180, 46, 255), "y": (198, 132, 34, 255),
    "h": (252, 216, 104, 255), "H": (44, 52, 92, 255), "s": (246, 204, 166, 255), "d": (222, 158, 132, 255),
    "e": (34, 30, 52, 255), "t": (64, 176, 172, 255), "p": (74, 84, 128, 255), "b": (70, 58, 80, 255),
    "B": (112, 98, 124, 255),
}
HEAD_DOWN = [
    "....oooooooo....", "..ooYYYYYYYYoo..", ".oYYhhYYYYYYYYo.", ".oYhYYYYYYYYYYo.", "oYYYYYYYYYYYYYYo",
    "oYYoHHHHHHHHoYYo", "oYoHHHHHHHHHHoYo", "oYoHHsHHHHsHHoYo", "oYossessssessoYo", "oYossessssessoYo",
    "oYosdssssssdsoYo", ".oYossssssssoYo.", ".oYYooooooooYYo.",
]
HEAD_UP = [
    "....oooooooo....", "..ooYYYYYYYYoo..", ".oYYYYYYYYYYYYo.", ".oYYYYYYYYYYYYo.", "oYYYYYYYYYYYYYYo",
    "oYYYYYYYYYYYYYYo", "oYYYYYYyyYYYYYYo", "oYYYYYYyyYYYYYYo", "oYYYYYYyyYYYYYYo", "oyYYYYYyyYYYYYyo",
    "oyYYYYYYYYYYYYyo", ".oyYYYYYYYYYYyo.", ".oyyyyyyyyyyyyo.",
]
HEAD_LEFT = [
    "....oooooooo....", "..ooYYYYYYYYoo..", ".oYYhhYYYYYYYYo.", ".oYhYYYYYYYYYYo.", "oYYYYYYYYYYYYYYo",
    "oYoHHHHHoYYYYYYo", "ooHHHHHHHoYYYYYo", "osHHsHHHHoYYYYYo", "osesssHHHoYYYYyo", "osesssHHoYYYYYyo",
    "osssdsssoYYYYYyo", ".osssssoYYYYYyo.", ".ooooooYYYYyyyo.",
]
BODY_DOWN = [
    "..oYYYttttYYYo..", ".oYYYYYYYYYYYYo.", ".oYyYYYYYYYYyYo.", ".osyYYYYYYYYyso.", ".ooyYYYYYYYYyoo.",
    "..oyYYYYYYYYyo..", "..oyyyyyyyyyyo..",
]
BODY_UP = [
    "..oYYYYYYYYYYo..", ".oYYYYYYYYYYYYo.", ".oYyYYYYYYYYyYo.", ".osyYYYYYYYYyso.", ".ooyYYYYYYYYyoo.",
    "..oyYYYYYYYYyo..", "..oyyyyyyyyyyo..",
]
BODY_LEFT = [
    "...oYttYYYYYo...", "..oYYYYYYYYYo...", "..oYYyYYYYYYo...", "..oYsyYYYYYYo...", "..oYoyYYYYYYo...",
    "..oyYYYYYYYyo...", "..oyyyyyyyyyo...",
]
BODY_LEFT_SWING = [
    "...oYttYYYYYo...", "..oYYYYYYYYYo...", "..oYyYYYYYYYo...", ".osyYYYYYYYYo...", ".ooyYYYYYYYYo...",
    "..oyYYYYYYYyo...", "..oyyyyyyyyyo...",
]
LEGS = {  # front and back
    "stand": ["...oppo..oppo...", "...oppo..oppo...", "...obbo..obbo...", "..oBbbo..obbBo..", "..ooooo..ooooo.."],
    "left": ["...oppo..oppo...", "...oppo..obbo...", "...obbo..oooo...", "..oBbbo.........", "..ooooo........."],
    "right": ["...oppo..oppo...", "...obbo..oppo...", "...oooo..obbo...", ".........obbBo..", ".........ooooo.."],
}
LEGS_SIDE = {
    "stand": ["....oppppo......", "....oppppo......", "....obbbbo......", "...oBbbbbo......", "...ooooooo......"],
    "stride": ["...oppoopppo....", "..oppo..oppo....", "..obbo..obbo....", ".oBbbo..obbbo...", ".ooooo..ooooo..."],
}


def frame(head, body, legs, bob=0):
    rows = head + body + legs
    assert all(len(r) == 16 for r in rows), [r for r in rows if len(r) != 16]
    f = np.zeros((32, 16, 4), np.uint8)
    top = 32 - len(rows)
    for j, r in enumerate(rows):
        # the legs stay planted; only the head and body dip on a step
        y = top + j + (bob if j < len(head) + len(body) else 0)
        for i, ch in enumerate(r):
            if ch != ".":
                f[y, i] = C[ch]
    return f


def row_frames(head, body, body_swing, stand, a, b):
    idle = frame(head, body, stand)
    walk = [frame(head, body_swing, a, 1), idle, frame(head, body_swing, b, 1), idle]
    run = [frame(head, body_swing, a, 2), frame(head, body, stand, 1), frame(head, body_swing, b, 2), frame(head, body, stand, 1)]
    return [idle] + walk + run


def main():
    down = row_frames(HEAD_DOWN, BODY_DOWN, BODY_DOWN, LEGS["stand"], LEGS["left"], LEGS["right"])
    up = row_frames(HEAD_UP, BODY_UP, BODY_UP, LEGS["stand"], LEGS["right"], LEGS["left"])
    left = row_frames(HEAD_LEFT, BODY_LEFT, BODY_LEFT_SWING, LEGS_SIDE["stand"], LEGS_SIDE["stride"], LEGS_SIDE["stride"])
    right = [f[:, ::-1] for f in left]
    sheet = np.concatenate([np.concatenate(r, axis=1) for r in (down, up, left, right)], axis=0)
    out = os.path.join(ROOT, "art/pixel/chars/chibi_raincoat.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    Image.fromarray(sheet).save(out)
    print("wrote", out, sheet.shape[1], "x", sheet.shape[0])


if __name__ == "__main__":
    main()
