"""Draws Explorer's map icons (original artwork) as 64x64 TGA files.

Run: python3 devkit/make_icons.py <output folder>
Everything is drawn at 4x and scaled down for smooth edges.
"""
import math
import sys
from PIL import Image, ImageDraw, ImageFilter

S = 256          # drawing size
OUT = 64         # file size
C = S / 2

GOLD = (233, 186, 92, 255)
GOLD_DARK = (140, 96, 34, 255)
GOLD_LIGHT = (255, 230, 150, 255)


def new():
    return Image.new("RGBA", (S, S), (0, 0, 0, 0))


def badge(fill_top, fill_bottom, r=104, glow=None):
    """Round badge: soft shadow, gold rim, vertical gradient inside."""
    img = new()
    # shadow
    sh = new()
    ImageDraw.Draw(sh).ellipse((C - r - 6, C - r + 2, C + r + 6, C + r + 14), fill=(0, 0, 0, 170))
    img = Image.alpha_composite(img, sh.filter(ImageFilter.GaussianBlur(8)))
    if glow:
        gl = new()
        ImageDraw.Draw(gl).ellipse((C - r - 18, C - r - 18, C + r + 18, C + r + 18), fill=glow)
        img = Image.alpha_composite(img, gl.filter(ImageFilter.GaussianBlur(12)))
    d = ImageDraw.Draw(img)
    # rim: dark outer, gold, light inner line
    d.ellipse((C - r, C - r, C + r, C + r), fill=GOLD_DARK)
    d.ellipse((C - r + 6, C - r + 6, C + r - 6, C + r - 6), fill=GOLD)
    d.ellipse((C - r + 14, C - r + 14, C + r - 14, C + r - 14), fill=GOLD_LIGHT)
    # gradient face
    face = new()
    fd = ImageDraw.Draw(face)
    inner = r - 18
    for i in range(int(2 * inner)):
        t = i / (2 * inner)
        col = tuple(int(fill_top[k] * (1 - t) + fill_bottom[k] * t) for k in range(3)) + (255,)
        fd.line((0, C - inner + i, S, C - inner + i), fill=col)
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).ellipse((C - inner, C - inner, C + inner, C + inner), fill=255)
    img.paste(face, (0, 0), mask)
    # top shine
    shine = new()
    ImageDraw.Draw(shine).ellipse((C - inner + 18, C - inner + 6, C + inner - 18, C - 4), fill=(255, 255, 255, 38))
    img = Image.alpha_composite(img, shine.filter(ImageFilter.GaussianBlur(6)))
    return img


def glyph(img, draw_fn, color, outline=(30, 18, 6, 255)):
    """Draws a glyph with a dark outline under it."""
    g = new()
    draw_fn(ImageDraw.Draw(g), color)
    alpha = g.split()[3]
    out = Image.new("RGBA", (S, S), outline)
    out.putalpha(alpha.filter(ImageFilter.MaxFilter(9)))
    img = Image.alpha_composite(img, out)
    return Image.alpha_composite(img, g)


# ---- glyphs -------------------------------------------------------------

def doorway(d, col):
    # stone arch with steps
    d.rectangle((C - 52, C - 10, C + 52, C + 56), fill=col)
    d.pieslice((C - 52, C - 62, C + 52, C + 42), 180, 360, fill=col)
    # dark opening
    d.rectangle((C - 30, C - 2, C + 30, C + 56), fill=(25, 12, 40, 255))
    d.pieslice((C - 30, C - 40, C + 30, C + 20), 180, 360, fill=(25, 12, 40, 255))
    # portal swirl inside the opening
    for i, rr in enumerate((22, 15, 8)):
        d.arc((C - rr, C + 12 - rr, C + rr, C + 12 + rr), 200 + i * 40, 520 + i * 40,
              fill=(150 + i * 35, 110 + i * 40, 255, 255), width=5)
    # keystone and step
    d.polygon([(C - 9, C - 64), (C + 9, C - 64), (C + 6, C - 46), (C - 6, C - 46)], fill=(255, 240, 200, 255))
    d.rectangle((C - 60, C + 50, C + 60, C + 62), fill=col)


def skull(d, col):
    d.ellipse((C - 50, C - 60, C + 50, C + 30), fill=col)
    d.rounded_rectangle((C - 30, C + 10, C + 30, C + 56), radius=10, fill=col)
    dark = (40, 10, 10, 255)
    d.ellipse((C - 36, C - 22, C - 8, C + 8), fill=dark)
    d.ellipse((C + 8, C - 22, C + 36, C + 8), fill=dark)
    d.polygon([(C, C + 10), (C - 8, C + 24), (C + 8, C + 24)], fill=dark)
    for x in (-18, -6, 6, 18):
        d.line((C + x, C + 36, C + x, C + 56), fill=dark, width=5)


def horns(d, col):
    # horned crown for world bosses
    d.polygon([(C - 62, C - 50), (C - 30, C - 4), (C - 14, C - 44), (C, C - 6),
               (C + 14, C - 44), (C + 30, C - 4), (C + 62, C - 50), (C + 48, C + 30),
               (C - 48, C + 30)], fill=col)
    d.rounded_rectangle((C - 50, C + 26, C + 50, C + 52), radius=8, fill=col)
    for x in (-26, 0, 26):
        d.ellipse((C + x - 8, C + 31, C + x + 8, C + 47), fill=(200, 40, 40, 255))


def ship(d, col):
    # hull
    d.polygon([(C - 66, C + 18), (C + 66, C + 18), (C + 44, C + 50), (C - 46, C + 50)], fill=col)
    # mast and sails
    d.rectangle((C - 4, C - 62, C + 4, C + 20), fill=col)
    d.polygon([(C + 8, C - 56), (C + 52, C + 8), (C + 8, C + 8)], fill=(250, 245, 230, 255))
    d.polygon([(C - 8, C - 40), (C - 46, C + 8), (C - 8, C + 8)], fill=(250, 245, 230, 255))
    d.polygon([(C - 4, C - 62), (C - 4, C - 46), (C - 26, C - 54)], fill=(200, 50, 40, 255))


def zeppelin(d, col):
    d.ellipse((C - 68, C - 52, C + 60, C + 10), fill=col)
    # fins
    d.polygon([(C + 44, C - 20), (C + 72, C - 50), (C + 72, C + 8)], fill=col)
    # bands
    for x in (-34, -4, 26):
        d.line((C + x, C - 48, C + x, C + 6), fill=(120, 70, 30, 255), width=5)
    # gondola
    d.line((C - 22, C + 6, C - 18, C + 26), fill=col, width=5)
    d.line((C + 22, C + 6, C + 18, C + 26), fill=col, width=5)
    d.rounded_rectangle((C - 30, C + 24, C + 30, C + 46), radius=6, fill=col)


def tram(d, col):
    d.rounded_rectangle((C - 54, C - 50, C + 54, C + 30), radius=18, fill=col)
    win = (40, 60, 90, 255)
    for x in (-40, -12, 16):
        d.rounded_rectangle((C + x, C - 36, C + x + 24, C - 8), radius=4, fill=win)
    d.rectangle((C - 54, C + 2, C + 54, C + 10), fill=(120, 70, 30, 255))
    # wheels and rail
    d.ellipse((C - 40, C + 22, C - 16, C + 46), fill=col)
    d.ellipse((C + 16, C + 22, C + 40, C + 46), fill=col)
    d.rectangle((C - 66, C + 46, C + 66, C + 54), fill=col)


ICONS = {
    # name: (top color, bottom color, glyph, glyph color)
    "dungeon": ((70, 52, 120), (28, 18, 52), doorway, (214, 200, 178, 255)),
    "raid": ((130, 30, 26), (50, 8, 8), skull, (240, 232, 214, 255)),
    "worldboss": ((120, 50, 20), (45, 15, 8), horns, (255, 214, 110, 255)),
    "boat": ((40, 90, 140), (12, 34, 62), ship, (186, 128, 70, 255)),
    "zeppelin": ((60, 110, 70), (18, 44, 24), zeppelin, (220, 120, 60, 255)),
    "tram": ((90, 90, 104), (32, 32, 42), tram, (200, 150, 70, 255)),
}


def save(img, path):
    img = img.resize((OUT, OUT), Image.LANCZOS)
    img.save(path, rle=True)


def arrow(path):
    """Player arrow, pointing up (the addon rotates it)."""
    img = new()
    pts = [(C, 16), (C + 62, S - 30), (C, S - 72), (C - 62, S - 30)]
    sh = new()
    ImageDraw.Draw(sh).polygon([(x + 4, y + 8) for x, y in pts], fill=(0, 0, 0, 200))
    img = Image.alpha_composite(img, sh.filter(ImageFilter.GaussianBlur(6)))
    d = ImageDraw.Draw(img)
    d.polygon(pts, fill=(30, 18, 6, 255))
    inner = [(C, 34), (C + 48, S - 42), (C, S - 84), (C - 48, S - 42)]
    d.polygon(inner, fill=(255, 205, 40, 255))
    d.polygon([(C, 34), (C, S - 84), (C - 48, S - 42)], fill=(255, 236, 140, 255))
    img = img.resize((32, 32), Image.LANCZOS)
    img.save(path, rle=True)


def main():
    out = sys.argv[1]
    for name, (top, bottom, fn, col) in ICONS.items():
        img = glyph(badge(top, bottom), fn, col)
        save(img, f"{out}/{name}.tga")
        hl = glyph(badge(tuple(min(255, v + 45) for v in top), tuple(min(255, v + 30) for v in bottom),
                         glow=(255, 220, 120, 150)), fn, col)
        save(hl, f"{out}/{name}-highlight.tga")
    arrow(f"{out}/arrow.tga")


if __name__ == "__main__":
    main()
