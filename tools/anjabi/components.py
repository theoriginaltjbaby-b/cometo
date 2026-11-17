"""Find sprites in an atlas by alpha connected components; print boxes and write a labelled sheet."""
import sys
from PIL import Image, ImageDraw
import numpy as np

def components(mask):
    h, w = mask.shape
    lab = np.zeros((h, w), np.int32)
    boxes = []
    n = 0
    for y0 in range(h):
        row = np.nonzero(mask[y0] & (lab[y0] == 0))[0]
        for x0 in row:
            if lab[y0, x0]:
                continue
            n += 1
            stack = [(y0, x0)]
            lab[y0, x0] = n
            x1 = x2 = x0; y1 = y2 = y0; cnt = 0
            while stack:
                y, x = stack.pop()
                cnt += 1
                if x < x1: x1 = x
                if x > x2: x2 = x
                if y < y1: y1 = y
                if y > y2: y2 = y
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        yy, xx = y + dy, x + dx
                        if 0 <= yy < h and 0 <= xx < w and mask[yy, xx] and not lab[yy, xx]:
                            lab[yy, xx] = n
                            stack.append((yy, xx))
            boxes.append([x1, y1, x2 + 1, y2 + 1, cnt])
    return boxes

def label(mask):
    """Label map of the 8-connected blobs in mask, and {id: (centre x, centre y, pixels)}."""
    h, w = mask.shape
    lab = np.zeros((h, w), np.int32)
    cents = {}
    n = 0
    for y0 in range(h):
        for x0 in np.nonzero(mask[y0] & (lab[y0] == 0))[0]:
            if lab[y0, x0]:
                continue
            n += 1
            stack = [(y0, int(x0))]
            lab[y0, x0] = n
            sx = sy = cnt = 0
            while stack:
                y, x = stack.pop()
                sx += x; sy += y; cnt += 1
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        yy, xx = y + dy, x + dx
                        if 0 <= yy < h and 0 <= xx < w and mask[yy, xx] and not lab[yy, xx]:
                            lab[yy, xx] = n
                            stack.append((yy, xx))
            cents[n] = (sx / cnt, sy / cnt, cnt)
    return lab, cents


def merge(boxes, gap):
    boxes = [b[:] for b in boxes]
    changed = True
    while changed:
        changed = False
        for i in range(len(boxes)):
            for j in range(i + 1, len(boxes)):
                a, b = boxes[i], boxes[j]
                if a[0] - gap < b[2] and b[0] - gap < a[2] and a[1] - gap < b[3] and b[1] - gap < a[3]:
                    boxes[i] = [min(a[0], b[0]), min(a[1], b[1]), max(a[2], b[2]), max(a[3], b[3]), a[4] + b[4]]
                    del boxes[j]
                    changed = True
                    break
            if changed:
                break
    return boxes

if __name__ == '__main__':
    src, out, gap = sys.argv[1], sys.argv[2], int(sys.argv[3])
    im = Image.open(src).convert('RGBA')
    a = np.asarray(im)
    mask = a[..., 3] > 128
    bx = [b for b in components(mask) if b[4] >= 40]
    bx = merge(bx, gap)
    bx.sort(key=lambda b: (round((b[1] + b[3]) / 2 / 100), b[0]))
    bg = Image.new('RGBA', im.size, (60, 0, 60, 255))
    rgba = a.copy(); rgba[..., 3] = np.where(mask, 255, 0)
    bg.alpha_composite(Image.fromarray(rgba))
    d = ImageDraw.Draw(bg)
    for i, b in enumerate(bx):
        d.rectangle(b[:4], outline=(255, 255, 0, 255))
        d.text((b[0] + 2, b[1] + 1), str(i), fill=(255, 255, 255, 255), stroke_width=2, stroke_fill=(0, 0, 0, 255))
        print(i, b[:4], 'w', b[2] - b[0], 'h', b[3] - b[1])
    bg.convert('RGB').save(out)
