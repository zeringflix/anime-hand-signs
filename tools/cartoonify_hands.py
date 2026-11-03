"""Cartoonify the hand-sign art (owner request 2026-11-02): cel-shaded skin, navy ninja sleeves, rim light/shadow
and a thick dark outline, in the chunky style of the +1 icon pack. Input: assets/icons/hand-signs-art/*.png
Output: assets/icons/hand-signs-cartoon/*.png (512x512, transparent)."""
from PIL import Image, ImageFilter, ImageChops
import numpy as np, glob, os, sys
SRC = "assets/icons/hand-signs-art"; DST = sys.argv[1] if len(sys.argv) > 1 else "assets/icons/hand-signs-cartoon"
os.makedirs(DST, exist_ok=True)
SKIN = [(255, 222, 182), (255, 190, 138), (226, 142, 96)]
SLEEVE = [(78, 92, 160), (52, 60, 116), (34, 38, 78)]
INK = (26, 18, 34)
def shift(img, dx, dy):
    return ImageChops.offset(img, dx, dy)
def cartoon(path):
    im = Image.open(path).convert("RGBA")
    W = 640
    im = im.resize((int(im.width * W / max(im.size)), int(im.height * W / max(im.size))), Image.LANCZOS)
    pad = 44
    can = Image.new("RGBA", (im.width + 2 * pad, im.height + 2 * pad), (0, 0, 0, 0)); can.paste(im, (pad, pad)); im = can
    a = np.array(im).astype(float)
    rgb, al = a[..., :3], a[..., 3]
    lum = 0.299 * rgb[..., 0] + 0.587 * rgb[..., 1] + 0.114 * rgb[..., 2]
    r, g = rgb[..., 0], rgb[..., 1]
    sat = np.max(rgb, -1) - np.min(rgb, -1)
    skin = (r > g + 8) & (sat > 25) & (lum > 70)
    ink = lum < 42
    sleeve = (~skin) & (~ink)
    res = np.zeros_like(a)
    for m, c in ((skin & (lum >= 205), SKIN[0]), (skin & (lum < 205) & (lum >= 145), SKIN[1]), (skin & (lum < 145), SKIN[2]),
                 (sleeve & (lum >= 88), SLEEVE[0]), (sleeve & (lum < 88) & (lum >= 62), SLEEVE[1]), (sleeve & (lum < 62), SLEEVE[2])):
        res[m, :3] = c
    res[ink, :3] = INK
    res[..., 3] = al
    body = Image.fromarray(res.astype(np.uint8), "RGBA").filter(ImageFilter.ModeFilter(5))
    A = Image.fromarray(al.astype(np.uint8)).point(lambda v: 255 if v > 100 else 0)
    body.putalpha(A)
    skinM = Image.fromarray((skin * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(3))
    # rim light (top-left inner edge) and rim shadow (bottom-right inner edge), skin only
    light = ImageChops.multiply(ImageChops.subtract(A, shift(A, 7, 7)), skinM).filter(ImageFilter.GaussianBlur(1.2))
    dark = ImageChops.multiply(ImageChops.subtract(A, shift(A, -8, -8)), skinM).filter(ImageFilter.GaussianBlur(1.2))
    lay = Image.new("RGBA", body.size, (255, 246, 226, 0)); lay.putalpha(light.point(lambda v: int(v * 0.85)))
    body = Image.alpha_composite(body, lay)
    lay = Image.new("RGBA", body.size, (200, 110, 70, 0)); lay.putalpha(dark.point(lambda v: int(v * 0.7)))
    body = Image.alpha_composite(body, lay)
    body.putalpha(A)
    thick = A.filter(ImageFilter.MaxFilter(25)).filter(ImageFilter.GaussianBlur(1.5)).point(lambda v: 255 if v > 110 else 0)
    base = Image.new("RGBA", body.size, INK + (0,)); base.putalpha(thick)
    final = Image.alpha_composite(base, body)
    final = final.crop(final.getbbox())
    S = 512; sc = min((S - 16) / final.width, (S - 16) / final.height)
    final = final.resize((int(final.width * sc), int(final.height * sc)), Image.LANCZOS)
    sq = Image.new("RGBA", (S, S), (0, 0, 0, 0)); sq.alpha_composite(final, ((S - final.width) // 2, (S - final.height) // 2))
    return sq
if __name__ == "__main__":
    for f in sorted(glob.glob(os.path.join(SRC, "*.png"))):
        cartoon(f).save(os.path.join(DST, os.path.basename(f)))
        print("ok", os.path.basename(f))
