"""Original raised-stud UI tile (owner reference 2026-11-02: big rounded square studs, light top edge, soft shadow).
One stud per 128 px tile, white/black in alpha so it brightens/shades any card colour. python3 vfx/ui_studs.py"""
import os, sys, numpy as np
sys.path.insert(0, os.path.expanduser("~/.claude/skills/roblox-vfx/scripts"))
import vfxtex as vt
vt.OUTPUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out_ui")
N = 128
def tile(size):
    x, y = vt.tex_coords(size)
    def rbox(px, py, half, r):
        qx, qy = np.abs(px) - (half - r), np.abs(py) - (half - r)
        return np.hypot(np.maximum(qx, 0), np.maximum(qy, 0)) + np.minimum(np.maximum(qx, qy), 0) - r  # <0 inside
    d = rbox(x, y, 0.66, 0.2)
    shadow = rbox(x - 0.07, y + 0.09, 0.66, 0.2)
    inside = vt.tex_edge(-d, 0, 0.012)
    sh = vt.tex_edge(-shadow, 0, 0.03) * (1 - inside)
    rim_top = inside * vt.tex_edge(-(d + 0.08), 0, 0.01) * 0 + inside * (1 - vt.tex_edge(-(d + 0.075), 0, 0.012))  # outer ring of stud
    lit = rim_top * np.clip((y - x) * 0.8 + 0.5, 0, 1)          # ring lit on the top-left
    dark = rim_top * np.clip((x - y) * 0.8 + 0.1, 0, 1)         # ring shaded bottom-right
    face = inside * (1 - rim_top)
    rgb = np.ones((size, size, 3), np.float32)
    a = np.zeros((size, size), np.float32)
    a += face * 0.16 + lit * 0.55
    # darkening layers are black
    dk = sh * 0.22 + dark * 0.35
    rgb *= (a / np.maximum(a + dk, 1e-6))[..., None]
    a = np.clip(a + dk, 0, 1)
    return np.dstack([rgb, a])
print(vt.draw_texture("UIStud", tile, size=N))
