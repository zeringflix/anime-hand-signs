"""Original particle / beam textures for the lobby training-station VFX (issue #14, owner 2026-11-02).

White shapes with the shape in alpha (the emitter's Color tints them), drawn with numpy via the roblox-vfx
skill's vfxtex helpers. Nothing here is traced or copied from another game. Re-run to redraw:

    python3 vfx/training/textures.py
"""
import os, sys, math
import numpy as np
sys.path.insert(0, os.path.expanduser("~/.claude/skills/roblox-vfx/scripts"))
import vfxtex as vt

vt.OUTPUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out")
E, C, P = vt.tex_edge, vt.tex_coords, vt.tex_polar


def soft(r, radius, power=2.0):
    return np.clip(1 - r / radius, 0, 1) ** power


# 1 Glint: four-point star with a hot core (light family)
def glint(size):
    x, y = C(size); r, a = P(x, y)
    arms = np.maximum(np.exp(-np.abs(y) * 60) * soft(np.abs(x), 1.0, 1.4), np.exp(-np.abs(x) * 60) * soft(np.abs(y), 1.0, 1.4))
    diag = np.exp(-np.abs(x - y) * 70) * soft(r, 0.45, 2) * 0.5 + np.exp(-np.abs(x + y) * 70) * soft(r, 0.45, 2) * 0.5
    return np.clip(arms + diag + soft(r, 0.32, 2.2) * 1.2, 0, 1)


# 2 Glow: soft round glow
def glow(size):
    x, y = C(size); r, _ = P(x, y)
    return np.clip(soft(r, 1.0, 2.6) * 1.1, 0, 1)


# 3 Ring: thin soft shock ring with a slightly brighter inner edge
def ring(size):
    x, y = C(size); r, _ = P(x, y)
    band = np.exp(-((r - 0.82) / 0.06) ** 2) + 0.35 * np.exp(-((r - 0.74) / 0.1) ** 2)
    return np.clip(band, 0, 1)


# 4 Rune circle: double ring, 16 abstract tick-glyphs, inner hexagram of strokes (original geometric sigil)
def rune(size):
    x, y = C(size); r, a = P(x, y)
    out = E(0.02 - np.abs(r - 0.9), 0, 0.006) + E(0.012 - np.abs(r - 0.78), 0, 0.006) + E(0.01 - np.abs(r - 0.42), 0, 0.006)
    seg = (a + math.pi) / (2 * math.pi) * 16
    frac = seg - np.floor(seg)
    idx = np.floor(seg).astype(int)
    tick = (np.abs(frac - 0.5) < 0.07) & (r > 0.8) & (r < 0.88)
    dash = (idx % 2 == 0) & (np.abs(frac - 0.5) < 0.28) & (np.abs(r - 0.84) < 0.012)
    dot = (idx % 2 == 1) & (np.hypot(frac - 0.5, (r - 0.84) * 8) < 0.12)
    out = np.maximum(out, (tick | dash | dot).astype(np.float32))
    for k in range(6):  # hexagram strokes between ring 0.42 and 0.78
        t0 = k * math.pi / 3
        p0 = (0.76 * math.cos(t0), 0.76 * math.sin(t0)); p1 = (0.76 * math.cos(t0 + 2 * math.pi / 3), 0.76 * math.sin(t0 + 2 * math.pi / 3))
        out = np.maximum(out, E(vt.tex_stroke(x, y, np.array([p0, p1]), 0.022), 0, 0.006))
    glowv = 0.25 * np.exp(-((r - 0.84) / 0.12) ** 2)
    return np.clip(out + glowv, 0, 1)


# 5 Swirl: three tapered spiral arms around a bright eye (vortex / chakra spiral seen from above)
def swirl(size):
    x, y = C(size); r, a = P(x, y)
    out = np.zeros_like(x)
    for k in range(3):
        pts = []
        for i in range(40):
            t = i / 39
            ang = k * 2 * math.pi / 3 + t * 3.4
            rr = 0.1 + t * 0.82
            pts.append((rr * math.cos(ang), rr * math.sin(ang)))
        out = np.maximum(out, E(vt.tex_stroke(x, y, np.array(pts), lambda u: 0.16 * (1 - u) + 0.02), 0, 0.02) * (1 - 0.5 * np.clip(r, 0, 1)))
    return np.clip(out + soft(r, 0.3, 1.6), 0, 1)


# 6 Ember: crisp leaning teardrop spark
def ember(size):
    x, y = C(size)
    path = vt.tex_curve([(0, -0.7), (0.05, -0.1), (0, 0.7)], 32)
    return E(vt.tex_stroke(x, y, path, lambda u: 0.42 * np.sin(np.pi * np.clip(u, 0, 1)) ** 0.7), 0, 0.012)


# 7 Flame flipbook: a drawn flame tongue that rises, licks and breaks into two fragments (drawn matter, crisp)
def flame(t, size):
    x, y = C(size)
    wx, wy = vt.tex_warp(x, y, 0.16, 3, 7, t * 0.8)
    grow = vt.tex_ease(min(t / 0.35, 1), 2.4)
    h = 0.35 + 0.55 * grow
    body = vt.tex_stroke(wx, wy, vt.tex_curve([(0, -0.8), (0.14 * math.sin(t * 6), -0.3), (-0.12 * math.sin(t * 5), 0.05 + h * 0.4), (0.06, -0.8 + h * 1.7)], 48),
                         lambda u: (1.25 - 1.1 * u ** 0.8) * (0.62 + 0.38 * grow))
    shape = E(body, 0, 0.012)
    if t > 0.55:  # eat it away from below and split the tip
        eat = (t - 0.55) / 0.45
        shape *= E(wy - (-0.75 + eat * 1.3), 0, 0.03)
        shape *= 1 - E(0.05 - np.abs(wx - 0.02 * math.sin(t * 9)), 0, 0.01) * E(wy - 0.1, 0, 0.05) * min(eat * 2, 1)
    core = E(body - 0.12, 0, 0.012) * shape
    return shape, 0.62 + 0.38 * core


# 8 Smoke flipbook: mottled puff with a crisp silhouette that swells and breaks apart
def smoke(t, size):
    x, y = C(size)
    wx, wy = vt.tex_warp(x, y, 0.12, 3, 11, t * 0.4)
    rad = 0.32 + 0.45 * vt.tex_ease(t, 2.0)
    blob = vt.tex_blob(wx, wy, rad, 7, 0.6, 3)
    a = E(blob, 0, 0.015)
    n = vt.tex_noise(size, 5, 4, 2)
    if t > 0.45:
        a *= E(n - (t - 0.45) * 1.6, 0, 0.04)
    shade = 0.55 + 0.45 * np.clip((wy + 0.4) * 0.8 + (n - 0.5) * 0.6, 0, 1)
    return a * (1 - 0.15 * t), shade


# 9 Sakura petal: notched petal, lighter centre vein
def petal(size):
    x, y = C(size)
    # rounded petal: fat near the top, pointed base, V notch cut into the top edge
    body = vt.tex_stroke(x, y, np.array([(0, -0.82), (0, 0.66)]), lambda u: 1.2 * np.sin(np.pi * np.clip(0.06 + 0.8 * u, 0, 1)) ** 0.7)
    notch = 0.12 * (1 - np.abs(x) / 0.16) - (0.7 - y)
    shape = E(np.minimum(body, -notch), 0, 0.012)
    vein = 0.82 + 0.18 * np.exp(-(x / 0.05) ** 2) * (y < 0.4)
    return shape, vein


# 10 Bolt: horizontal lightning strip for Beams (tiles along U = beam length), forked, glow falloff
def bolt(size):
    x, y = C(size)
    rng = np.random.default_rng(5)
    pts = [(-1.05, 0.0)]
    for i in range(1, 12):
        pts.append((-1.05 + i * 0.19, rng.uniform(-0.45, 0.45)))
    pts.append((1.05, 0.0))
    main = vt.tex_stroke(x, y, np.array(pts), 0.05)
    fork = vt.tex_stroke(x, y, np.array([pts[4], (pts[4][0] + 0.25, pts[4][1] + 0.4), (pts[4][0] + 0.45, pts[4][1] + 0.55)]), 0.03)
    fork2 = vt.tex_stroke(x, y, np.array([pts[8], (pts[8][0] + 0.2, pts[8][1] - 0.38)]), 0.025)
    line = np.maximum(np.maximum(main, fork), fork2)
    core = E(line, 0, 0.01)
    halo = np.exp(-np.maximum(-line, 0) * 14) * 0.55
    return np.clip(core + halo, 0, 1)


# 11 Energy column: beam texture, bright core line along U with drifting streaks (tiles along U)
def column(size):
    x, y = C(size)
    n = vt.tex_noise(size, 3, 3, 9)
    streak = vt.tex_sample(n, x * 0.15 + 0.5, y * 2.5 + 0.5)
    core = np.exp(-(y / 0.12) ** 2)
    body = np.exp(-(y / 0.5) ** 2) * (0.35 + 0.65 * streak)
    edge = np.clip(1 - np.abs(y), 0, 1) ** 0.6
    return np.clip((core + body * 0.8) * edge, 0, 1)


# 12 Shard: crystal fragment, two flat tones (lit facet / shadow facet)
def shard(size):
    x, y = C(size)
    outline = np.array([(0, 0.95), (0.32, 0.15), (0.16, -0.9), (-0.22, -0.55), (-0.3, 0.3)])
    inside = np.ones_like(x, dtype=bool)
    n = len(outline)
    for i in range(n):  # convex polygon test
        ax, ay = outline[i]; bx, by = outline[(i + 1) % n]
        inside &= ((bx - ax) * (y - ay) - (by - ay) * (x - ax)) <= 0
    a = inside.astype(np.float32)
    a = np.maximum(a, 0)  # crisp
    lit = np.where(x > 0.02 + 0.1 * y, 1.0, 0.68)
    return a, lit


# 13 Orb wisp: bright rim + soft core (spirit orb)
def orb(size):
    x, y = C(size); r, _ = P(x, y)
    rim = np.exp(-((r - 0.62) / 0.08) ** 2)
    return np.clip(rim * 0.9 + soft(r, 0.7, 1.4) * 0.65 + soft(r, 0.25, 2) * 0.6, 0, 1)


# 14 Halo: segmented heavenly ring (8 arcs with gaps) + faint outer glow
def halo(size):
    x, y = C(size); r, a = P(x, y)
    seg = ((a + math.pi) / (2 * math.pi) * 8) % 1
    arcs = E(0.035 - np.abs(r - 0.8), 0, 0.008) * E(0.42 - np.abs(seg - 0.5), 0, 0.02)
    inner = E(0.012 - np.abs(r - 0.68), 0, 0.006) * 0.8
    return np.clip(arcs + inner + 0.3 * np.exp(-((r - 0.8) / 0.12) ** 2), 0, 1)


# 15 Mist wisp: soft vertical wisp for rising pool mist / heat
def mist(size):
    x, y = C(size)
    wx, wy = vt.tex_warp(x, y, 0.25, 2, 4)
    body = np.exp(-(wx / 0.32) ** 2) * np.clip(1 - np.abs(wy), 0, 1) ** 1.2
    n = vt.tex_noise(size, 4, 3, 6)
    return np.clip(body * (0.55 + 0.6 * n), 0, 1)


if __name__ == "__main__":
    for name, fn, size in [("Glint", glint, 256), ("Glow", glow, 256), ("Ring", ring, 512), ("Rune", rune, 512), ("Swirl", swirl, 512),
                           ("Ember", ember, 128), ("Petal", petal, 128), ("Bolt", bolt, 512), ("Column", column, 256), ("Shard", shard, 128),
                           ("Orb", orb, 256), ("Halo", halo, 512), ("Mist", mist, 256)]:
        print(vt.draw_texture(name, fn, size=size))
    print(vt.draw_flipbook("Flame", flame, grid=4, fps=20))
    print(vt.draw_flipbook("Smoke", smoke, grid=4, fps=12))
