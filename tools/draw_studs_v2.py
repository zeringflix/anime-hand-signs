"""Embossed square stud tile (owner reference 2026-11-02): big, subtle, raised rounded-square studs.
One stud per tile; light top-left rim, soft dark bottom-right rim, faint lighter face. Original drawing.
    python3 tools/draw_studs_v2.py  -> assets/textures/studs_v2.png (128x128, tiles seamlessly)"""
import numpy as np
from PIL import Image
N = 128
y, x = np.mgrid[0:N, 0:N].astype(np.float32) + 0.5
c = N / 2
half, rad = 44.0, 11.0  # stud half-size and corner radius (gap of 20 px between studs)
qx, qy = np.abs(x - c) - (half - rad), np.abs(y - c) - (half - rad)
d = np.hypot(np.maximum(qx, 0), np.maximum(qy, 0)) + np.minimum(np.maximum(qx, qy), 0) - rad  # <0 inside
inside = np.clip(-d / 1.2, 0, 1)
rim = np.clip(1 - np.abs(d + 2.5) / 2.5, 0, 1)  # 5px band just inside the edge
# light direction: top-left lit, bottom-right shadowed
lx, ly = (x - c) / half, (y - c) / half
lit = np.clip(-(lx + ly) * 0.7, -1, 1)
rgb = np.ones((N, N, 3), np.float32)
alpha = np.zeros((N, N), np.float32)
# face: faint white
alpha += inside * 0.10
# highlight rim on lit side (white), shadow rim on dark side (black)
hl = rim * np.clip(lit + 0.25, 0, 1)
sh = rim * np.clip(-lit + 0.15, 0, 1)
alpha = np.maximum(alpha, hl * 0.75)
alpha = np.maximum(alpha, sh * 0.45)
dark = sh > hl
rgb[dark] = 0.0
# soft drop shadow outside the bottom-right edge
out = np.clip(1 - np.abs(d - 2.5) / 3.0, 0, 1) * (d > 0) * np.clip(-lit, 0, 1)
m = out * 0.25 > alpha
rgb[m] = 0.0
alpha = np.maximum(alpha, out * 0.25)
img = np.dstack([rgb, alpha[..., None]])
Image.fromarray((np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA").save("assets/textures/studs_v2.png")
# preview on two card colours
prev = Image.new("RGBA", (512, 256))
for i, col in enumerate([(30, 150, 255), (240, 60, 200)]):
    bg = Image.new("RGBA", (256, 256), col + (255,))
    tile = Image.open("assets/textures/studs_v2.png").resize((48, 48), Image.LANCZOS)
    for tx in range(0, 256, 48):
        for ty in range(0, 256, 48):
            bg.alpha_composite(tile, (tx, ty))
    prev.paste(bg, (i * 256, 0))
prev.save("/tmp/claude-0/-home-claude/3940f655-0ad5-5565-a0a0-35cd97e904fe/scratchpad/studs_preview.png")
