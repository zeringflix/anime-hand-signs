"""+1 Anime Hand Signs - 13 ORIGINAL lobby training stations, modelled in Blender (owner request 2026-11-02).

Every station is built from primitives (box / cylinder / ball / wedge) in the blocky, studded "+1 simulator" style,
one collection per station, centred on its own origin with the floor at Z=0 and a 16x16 stud footprint.
Each object carries Roblox metadata as custom properties:
    rbx_kind  Block | Cylinder | Ball | Wedge
    rbx_mat   Plastic | SmoothPlastic | Neon | Glass | Wood | WoodPlanks | Slate | Marble | Metal | Grass | Sand | Brick | Cobblestone | ForceField
    rbx_col   (r, g, b) 0-255        rbx_tr  transparency 0-1        rbx_studs  1 = studded top surface
    rbx_light (r, g, b, range)       rbx_spin  1 = slowly spun in game (client)   rbx_bob 1 = bobbed in game
export_json() writes stations.json (Roblox Y-up space) for ServerStorage.Tools.StationKit.

Run inside Blender:  exec(open(r"<repo>/tools/blender/training_stations.py").read()); build_all(); export_json(path)
"""
import bpy, math, json, os
from mathutils import Vector, Euler, Matrix

SCENE = "TrainingStations"
GOLD, GOLD2 = (255, 204, 60), (255, 232, 130)
INK, STONE, STONE2 = (34, 30, 44), (58, 54, 72), (82, 78, 98)
WHITE = (245, 245, 250)


# ------------------------------------------------------------------ scene + materials
def scene():
    sc = bpy.data.scenes.get(SCENE) or bpy.data.scenes.new(SCENE)
    bpy.context.window.scene = sc
    return sc


_mats = {}
def material(col, mat, tr):
    key = (tuple(col), mat, round(tr, 2))
    if key in _mats:
        return _mats[key]
    m = bpy.data.materials.new(f"RBX_{mat}_{col[0]}_{col[1]}_{col[2]}_{int(tr*100)}")
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    c = [((v / 255) ** 2.2) for v in col] + [1]  # sRGB 0-255 -> linear for the shader
    bsdf.inputs["Base Color"].default_value = c
    bsdf.inputs["Roughness"].default_value = 0.35 if mat in ("Glass", "Metal", "Marble") else 0.6
    if mat == "Neon":
        bsdf.inputs["Emission Color"].default_value = c
        bsdf.inputs["Emission Strength"].default_value = 1.6
    if tr > 0:
        bsdf.inputs["Alpha"].default_value = 1 - tr
        try:
            m.surface_render_method = "BLENDED"
        except Exception:
            pass
    _mats[key] = m
    return m


_coll = None
_origin = Vector((0, 0, 0))


def _finish(obj, col, mat, tr, studs, **extra):
    obj["rbx_col"] = list(col)
    obj["rbx_mat"] = mat
    obj["rbx_tr"] = tr
    obj["rbx_studs"] = 1 if studs else 0
    for k, v in extra.items():
        if v is not None:
            obj["rbx_" + k] = v
    obj.data.materials.append(material(col, mat, tr))
    for c in obj.users_collection:
        c.objects.unlink(obj)
    _coll.objects.link(obj)
    return obj


def _place(obj, loc, rot):
    obj.location = _origin + Vector(loc)
    obj.rotation_euler = Euler([math.radians(a) for a in rot], "XYZ")


def box(size, loc, col, mat="SmoothPlastic", rot=(0, 0, 0), tr=0.0, studs=False, **kw):
    """size = (x, y, z) in studs, loc = CENTRE (x, y, z)."""
    bpy.ops.mesh.primitive_cube_add(size=1)
    o = bpy.context.active_object
    o.scale = size
    _place(o, loc, rot)
    o["rbx_kind"] = "Block"
    return _finish(o, col, mat, tr, studs, **kw)


def blk(size, x, y, z0, col, mat="SmoothPlastic", **kw):
    """box with its BOTTOM at z0 (handy for stacking)."""
    return box(size, (x, y, z0 + size[2] / 2), col, mat, **kw)


def cyl(d, h, loc, col, mat="SmoothPlastic", rot=(0, 0, 0), tr=0.0, studs=False, verts=24, **kw):
    """vertical cylinder (axis = local Z), diameter d, height h, loc = centre."""
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=0.5, depth=1)
    o = bpy.context.active_object
    o.scale = (d, d, h)
    _place(o, loc, rot)
    o["rbx_kind"] = "Cylinder"
    return _finish(o, col, mat, tr, studs, **kw)


def ball(d, loc, col, mat="SmoothPlastic", tr=0.0, scale=None, **kw):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, radius=0.5)
    o = bpy.context.active_object
    o.scale = scale or (d, d, d)
    _place(o, loc, (0, 0, 0))
    o["rbx_kind"] = "Ball"
    return _finish(o, col, mat, tr, False, **kw)


def wedge(size, loc, col, mat="SmoothPlastic", rot=(0, 0, 0), tr=0.0, **kw):
    """Roblox WedgePart convention: high edge at Roblox +Z (= Blender -Y), slope faces Roblox -Z (= Blender +Y)."""
    me = bpy.data.meshes.new("wedge")
    v = [(-.5, -.5, -.5), (.5, -.5, -.5), (.5, .5, -.5), (-.5, .5, -.5), (-.5, -.5, .5), (.5, -.5, .5)]
    f = [(0, 1, 2, 3), (0, 4, 5, 1), (1, 5, 2), (0, 3, 4), (4, 3, 2, 5)]
    me.from_pydata(v, [], f)
    me.update()
    o = bpy.data.objects.new("Wedge", me)
    bpy.context.scene.collection.objects.link(o)
    o.scale = size
    _place(o, loc, rot)
    o["rbx_kind"] = "Wedge"
    return _finish(o, col, mat, tr, False, **kw)


def ring(radius, n, part, z, col, mat="Neon", tilt=0, tr=0.0, cx=0, cy=0, **kw):
    """ring of n small blocks (torus stand-in) around (cx, cy) at height z; tilt rotates the ring about X."""
    out = []
    for i in range(n):
        a = i * 2 * math.pi / n
        p = Vector((math.cos(a) * radius, math.sin(a) * radius, 0))
        p.rotate(Euler((math.radians(tilt), 0, 0)))
        out.append(box(part, (cx + p.x, cy + p.y, z + p.z), col, mat, rot=(tilt, 0, math.degrees(a) + 90), tr=tr, **kw))
    return out


# ================================================================== v2 (owner reference sheet 2026-11-02)
# Shared look from the 8 owner reference renders: thick gold-trimmed square plinth on the lavender floor, glowing
# floor ring, blocky corner lanterns with lit windows, a tall light beam out of the centrepiece, swirl rings,
# banners on poles and sparkles. Roblox-side effects are tagged with rbx_fx and created by StationKit:
#   beam    -> light column extras (rising sparkles)       sparkle -> twinkles around the part
#   fire    -> Fire instance       smoke -> Smoke instance  embers -> rising orange sparks   petals -> falling petals
# Station fronts face Blender -Y (Roblox +Z); the lobby turns each station to face the main road.

PURPLE, PURPLE2 = (120, 50, 190), (90, 30, 150)
DARK = (44, 40, 54)


def lantern_v2(x, y, glow, z0=0.0, post=DARK):
    """reference corner lantern: gold foot, dark post, glowing window block, gold cap + nub."""
    blk((2.0, 2.0, 0.45), x, y, z0, GOLD)
    blk((1.6, 1.6, 0.9), x, y, z0 + 0.45, post)
    blk((1.5, 1.5, 1.5), x, y, z0 + 1.35, glow, "Neon", tr=0.15, light=list(glow) + [10])
    blk((1.9, 1.9, 0.4), x, y, z0 + 2.85, GOLD)
    blk((0.9, 0.9, 0.45), x, y, z0 + 3.25, GOLD)


def base_v2(floor_col, ring_col, glow, floor_mat="Slate", lanterns=4, ring_r=4.6):
    """gold-trimmed plinth (16x16): gold frame, neon underglow, inset themed floor, floor ring, corner lanterns."""
    blk((16, 16, 0.9), 0, 0, 0, GOLD, "SmoothPlastic")
    for s in (-1, 1):  # neon underglow strips on the rim
        blk((16.3, 0.3, 0.25), 0, s * 8.0, 0.05, GOLD2, "Neon")
        blk((0.3, 16.3, 0.25), s * 8.0, 0, 0.05, GOLD2, "Neon")
    blk((14.2, 14.2, 0.35), 0, 0, 0.9, floor_col, floor_mat)
    z = 1.25
    ring(ring_r, 32, (0.9, 0.3, 0.06), z, ring_col, "Neon", fx=None)
    ring(ring_r - 0.9, 28, (0.7, 0.2, 0.05), z, ring_col, "Neon", tr=0.35)
    spots = [(-6.9, -6.9), (6.9, -6.9), (-6.9, 6.9), (6.9, 6.9)] if lanterns == 4 else [(-6.9, -6.9), (6.9, -6.9), (0, -7.3)]
    for (x, y) in spots:
        lantern_v2(x, y, glow, z0=0.9)
    return z


BEAM_SCALE = 0.7  # in-game review 2026-11-02: full-height pillars cluttered the skyline


def light_beam(z0, col, h=34, d=1.6, x=0, y=0):
    h *= BEAM_SCALE
    cyl(d, h, (x, y, z0 + h / 2), col, "Neon", tr=0.45, fx="beam")
    cyl(d * 0.45, h, (x, y, z0 + h / 2), (255, 255, 255), "Neon", tr=0.5)


def swirl(z, r, col, tilt=12, n=22, spin=1, gap=0.3):
    """open spiral ring (skips a few segments so it reads as a swirl, like the references)."""
    for i in range(n):
        if i / n > 1 - gap:
            continue
        a = i * 2 * math.pi / n
        p = Vector((math.cos(a) * r, math.sin(a) * r, 0))
        p.rotate(Euler((math.radians(tilt), 0, 0)))
        box((r * 0.32, 0.22, 0.22), (p.x, p.y, z + p.z), col, "Neon", rot=(tilt, 0, math.degrees(a) + 90), tr=0.1, spin=spin)


def banner(x, y, z0, col, trim=GOLD, h=6.5, w=2.2, pole=(110, 70, 40), face=0):
    """banner on a pole with a gold crossbar and a swallow-tail end. face = yaw in degrees."""
    yaw = math.radians(face)
    def L(dx, dy): return (x + dx * math.cos(yaw) - dy * math.sin(yaw), y + dx * math.sin(yaw) + dy * math.cos(yaw))
    blk((0.5, 0.5, h + 1.4), x, y, z0, pole)
    px, py = L(w / 2 + 0.3, 0)
    box((w + 1.4, 0.35, 0.35), (px, py, z0 + h + 0.9), trim, "Metal", rot=(0, 0, face))
    bx, by = L(w / 2 + 0.3, -0.05)
    box((w, 0.15, h - 1.4), (bx, by, z0 + h + 0.7 - (h - 1.4) / 2), col, rot=(0, 0, face))
    box((w + 0.2, 0.12, 0.25), (bx, by, z0 + h + 0.7 - 0.1), trim, "Neon", rot=(0, 0, face))
    for s in (-1, 1):  # swallow tail
        tx, ty = L(w / 2 + 0.3 + s * w / 4, -0.05)
        box((w / 2, 0.15, 1.2), (tx, ty, z0 + 1.1 + 0.1), col, rot=(0, 0, face))
    for s in (-1, 1):
        tx, ty = L(w / 2 + 0.3 + s * (w / 2 - 0.05), -0.08)
        box((0.12, 0.12, h - 1.0), (tx, ty, z0 + h + 0.7 - (h - 1.0) / 2), trim, "Neon", rot=(0, 0, face))


def arch(cx, cy, z0, span, rise, thick, depth, col, n=9, plane_yaw=0, mat="Slate"):
    """curved stone arch from n blocks (semi-ellipse in the X-Z plane, rotated by plane_yaw)."""
    yaw = math.radians(plane_yaw)
    for i in range(n + 1):
        t = math.pi * i / n
        ax, az = -math.cos(t) * span / 2, math.sin(t) * rise
        nx, nz = -math.cos(t + math.pi / n) * span / 2, math.sin(t + math.pi / n) * rise
        ang = math.degrees(math.atan2(nz - az, nx - ax))
        seg = math.hypot(nx - ax, nz - az) + 0.25
        if i == n:
            continue
        mx, mz = (ax + nx) / 2, (az + nz) / 2
        wx, wy = cx + mx * math.cos(yaw), cy + mx * math.sin(yaw)
        box((seg, depth, thick), (wx, wy, z0 + mz), col, mat, rot=(0, -ang, plane_yaw))


def crystal(x, y, z, h, w, col, tr=0.1, rot_z=0, **kw):
    """faceted crystal: widest a third of the way up, tapering to points at both ends (stacked rotated blocks)."""
    n = 8
    hi = tuple(min(255, int(c * 0.55 + 255 * 0.45)) for c in col)
    for i in range(n):
        t = (i + 0.5) / n
        prof = (t / 0.33) if t < 0.33 else (1 - (t - 0.33) / 0.67)
        ww = max(0.18, w * (0.25 + 0.75 * prof))
        extra = {k: v for k, v in kw.items() if k not in ("light", "fx") or i == n // 3}  # bob/spin on every piece
        box((ww, ww, h / n + 0.02), (x, y, z + t * h), col if i % 2 == 0 else hi, "Neon", rot=(0, 0, 45 + rot_z + i * 7), tr=tr, **extra)


# ------------------------------------------------------------------ stations
def v_dummies():  # X2: training yard on the reference plinth (warm gold beam)
    z = base_v2((110, 200, 80), (255, 230, 120), (255, 236, 150), "Grass")
    wood, dark = (176, 122, 72), (120, 80, 48)
    for i, (x, y) in enumerate(((-3.4, 0.6), (0, 2.0), (3.4, 0.6))):
        blk((0.6, 0.6, 3.2), x, y, z, dark)
        blk((2.6, 1.8, 2.8), x, y, z + 2.4, (226, 200, 130))
        blk((4.6, 0.6, 0.6), x, y, z + 4.0, wood)
        blk((2.2, 2.2, 2.2), x, y, z + 5.2, (240, 226, 180))
        blk((0.9, 0.12, 0.9), x, y - 1.12, z + 3.6, (230, 50, 50))
        blk((1.7, 0.1, 1.7), x, y - 1.08, z + 3.6, WHITE)
        cyl(3.6, 0.3, (x, y, z + 7.55), (232, 196, 100))
        cyl(2.0, 1.1, (x, y, z + 8.2), (232, 196, 100))
        cyl(2.05, 0.35, (x, y, z + 7.85), (210, 50, 46))
    for s in (-1, 1):
        banner(s * 5.6, 4.6, z, (200, 50, 46), face=0 if s < 0 else 180)
    light_beam(z + 9, (255, 220, 110), h=26, d=1.1)
    swirl(z + 10, 3.2, (255, 230, 140))


def v_ring():  # X3: boxing ring with lantern corners + red/blue beam
    z = base_v2((60, 70, 110), (120, 170, 255), (255, 236, 150))
    blk((11.6, 11.6, 1.2), 0, 0, z, (245, 245, 252))
    blk((10, 10, 0.06), 0, 0, z + 1.2, (60, 120, 230))
    zz = z + 1.2
    for (x, y, c) in ((-5.4, -5.4, (230, 50, 50)), (5.4, 5.4, (230, 50, 50)), (-5.4, 5.4, (50, 100, 235)), (5.4, -5.4, (50, 100, 235))):
        blk((0.9, 0.9, 4.0), x, y, zz, c)
        box((1.0, 1.0, 1.0), (x, y, zz + 4.5), GOLD2, "Neon", rot=(0, 0, 45))
    for i, c in enumerate(((230, 50, 50), WHITE, (50, 100, 235))):
        h = zz + 1.2 + i * 1.0
        for s in (-1, 1):
            blk((10.4, 0.22, 0.22), 0, s * 5.4, h, c)
            blk((0.22, 10.4, 0.22), s * 5.4, 0, h, c)
    for s in (-1, 1):
        blk((0.7, 0.7, 9.5), s * 4, 6.2, z, INK)
    blk((8.7, 0.7, 0.7), 0, 6.2, z + 9.5, INK)
    for x in (-2.5, 2.5):
        cyl(1.6, 3.0, (x, 6.2, z + 6.2), (210, 40, 40))
        cyl(1.65, 0.3, (x, 6.2, z + 7.5), INK)
    ball(2.2, (0, 0, zz + 6), (255, 255, 255), "Neon", bob=1)
    light_beam(zz + 7, (255, 120, 120), h=26, d=1.1)
    swirl(zz + 6, 2.8, (120, 170, 255))


def v_well():  # X5 (ref 7): blue stone arch over a glowing chakra well, blue banners, cyan beam, floating cubes
    cyan = (90, 230, 255)
    z = base_v2((96, 104, 130), cyan, (150, 240, 255), lanterns=3)
    stone, stone2 = (130, 136, 156), (104, 110, 130)
    for s in (-1, 1):
        blk((2.0, 2.4, 9), s * 6.0, 3.0, z, stone, "Slate")
        blk((0.3, 0.3, 7.5), s * 6.0 - s * 1.05, 1.75, z + 0.8, cyan, "Neon")
    arch(0, 3.0, z + 8.6, 12, 4.2, 1.6, 2.4, stone2, n=10)
    for s in (-1, 1):
        banner(s * 4.6, 1.4, z + 2.0, (40, 70, 200), h=5.2, w=1.8, pole=GOLD, face=0 if s < 0 else 180)
    for i, (d, h) in enumerate(((8.4, 1.0), (7.0, 1.0), (5.8, 0.8))):  # stacked well rings
        cyl(d, h, (0, 0.5, z + 0.5 + i * 1.0 + h / 2 - 0.5), stone if i % 2 == 0 else stone2, "Slate")
    cyl(5.2, 0.2, (0, 0.5, z + 2.95), cyan, "Neon", tr=0.15, light=list(cyan) + [16])
    for k, r in enumerate((2.2, 1.4, 0.7)):
        ring(r, 18 - k * 4, (0.5, 0.15, 0.05), z + 3.08, (230, 255, 255), "Neon", cx=0, cy=0.5)
    blk((2.2, 0.4, 1.4), 0, -3.3, z + 1, stone)
    light_beam(z + 3, cyan, h=32, d=1.4, y=0.5)
    swirl(z + 6, 3.6, cyan, tilt=18)
    swirl(z + 9, 2.6, (200, 250, 255), tilt=-14)
    for i in range(8):
        a = i * math.pi / 4
        box((0.45, 0.45, 0.45), (math.cos(a) * 4.2, 3.0 + math.sin(a) * 0.6, z + 4 + (i % 4) * 1.3), cyan, "Neon", bob=1, fx="sparkle" if i == 0 else None)


def v_forge():  # X7 (ref 6): stone arch furnace with roaring fire, chimney smoke, red banners, fire beam
    orange = (255, 150, 40)
    z = base_v2((70, 64, 70), (255, 170, 40), (255, 200, 90), "Cobblestone", lanterns=3)
    st, st2 = (66, 62, 74), (52, 48, 60)
    blk((10, 4.5, 2.2), 0, 3.4, z, st2, "Slate")
    for s in (-1, 1):
        blk((2.4, 4.5, 6.2), s * 3.8, 3.4, z + 2.2, st, "Slate")
        blk((0.25, 0.3, 1.4), s * 3.8, 1.1, z + 3, orange, "Neon")
    arch(0, 1.6, z + 6.6, 7.6, 2.4, 1.4, 1.6, st, n=8)
    blk((5.4, 3.4, 4.6), 0, 3.6, z + 2.2, (30, 20, 20))
    blk((4.4, 0.4, 3.0), 0, 2.0, z + 2.3, (255, 120, 30), "Neon", fx="fire", light=[255, 140, 50, 18])
    blk((5.0, 1.0, 0.25), 0, 1.6, z + 2.2, (255, 200, 80), "Neon", fx="embers")
    blk((10, 4.5, 2.8), 0, 3.4, z + 8.4, st, "Slate")
    blk((2.4, 2.4, 6), 3.6, 4.0, z + 11.2, st2, "Slate")
    blk((2.6, 2.6, 0.4), 3.6, 4.0, z + 12.8, orange, "Neon")
    blk((2.8, 2.8, 0.6), 3.6, 4.0, z + 17.2, st, fx="smoke")
    for s in (-1, 1):
        banner(s * 6.4, 0.6, z, (200, 40, 40), face=0 if s < 0 else 180)
    light_beam(z + 11, (255, 190, 60), h=30, d=2.0, y=3.0)
    swirl(z + 18, 4.0, (255, 210, 60), tilt=8)


def v_pagoda(roof=(110, 40, 160), glow=(255, 110, 230), beam=(255, 120, 230)):  # X8 Golden Dojo R$ (ref 3)
    z = base_v2((150, 50, 140), glow, (255, 170, 240), "Slate")
    red = (200, 44, 40)
    blk((10, 8, 1.2), 0, 1.2, z, (120, 110, 130), "Slate")  # stone podium + steps
    for k in range(3):
        blk((3.4, 0.9, 0.4), 0, -3.2 - k * 0.8 + 0.4, z + 0.8 - k * 0.4, (150, 140, 160), "Slate")
    zz = z + 1.2
    for i, (w, h) in enumerate(((8.0, 3.4), (6.2, 2.8), (4.4, 2.4))):
        blk((w, w * 0.8, h), 0, 1.2, zz, red)
        for k in range(-1, 2):  # glowing windows
            blk((0.9, 0.12, h * 0.45), k * w / 3.2, 1.2 - w * 0.4 - 0.05, zz + h * 0.35, (255, 220, 140), "Neon")
        zz += h
        blk((w + 3.2, w * 0.8 + 3.2, 0.5), 0, 1.2, zz, GOLD)
        for s in (-1, 1):  # sloped purple roof skirts (wedges) + upturned gold corners
            wedge((w + 3, 1.8, 1.2), (0, 1.2 + s * (w * 0.4 + 0.9), zz + 1.1), roof, rot=(0, 0, 0 if s > 0 else 180))
            wedge((w * 0.8 + 3, 1.8, 1.2), (s * (w / 2 + 0.9), 1.2, zz + 1.1), roof, rot=(0, 0, -90 if s > 0 else 90))
        for sx in (-1, 1):
            for sy in (-1, 1):
                box((0.5, 0.5, 1.0), (sx * (w / 2 + 1.5), 1.2 + sy * (w * 0.4 + 1.5), zz + 0.9), GOLD, rot=(sy * 25, -sx * 25, 0))
        blk((w * 0.55, w * 0.45, 1.0), 0, 1.2, zz + 0.5, roof)
        zz += 1.7
    blk((0.6, 0.6, 2.2), 0, 1.2, zz, GOLD, "Metal")
    box((0.9, 0.9, 0.9), (0, 1.2, zz + 2.6), GOLD2, "Neon", rot=(45, 45, 0))
    blk((3.0, 0.15, 6.0), 0, 1.2 - 3.25, z + 3.6, (110, 30, 140))  # centre banner
    blk((3.2, 0.1, 0.3), 0, 1.2 - 3.3, z + 9.5, GOLD, "Neon")
    blk((2.4, 0.12, 2.8), 0, 1.2 - 3.3, z + 1.25, glow, "Neon", tr=0.1, fx="sparkle", light=list(glow) + [14])  # glowing doorway
    for s in (-1, 1):
        banner(s * 6.3, -1.0, z, (110, 30, 140), face=0 if s < 0 else 180)
    light_beam(zz + 3, beam, h=30, d=1.6, y=1.2)
    swirl(z + 9, 6.0, glow, tilt=10)
    swirl(z + 14, 4.6, glow, tilt=-12)


def v_sakura():  # X10 (ref 2): cherry-blossom shrine on a stepped platform with a floating purple orb
    pink, pink2, pink3 = (255, 170, 210), (255, 140, 195), (255, 200, 225)
    z = base_v2((150, 140, 170), (255, 130, 220), (255, 230, 170), "Slate")
    blk((12, 10, 1.0), 0, 1.0, z, (130, 124, 146), "Slate")
    for k in range(2):
        blk((3.6, 1.0, 0.5), 0, -4.4 - k * 0.9 + 0.5, z + 0.5 - k * 0.5, (150, 144, 166), "Slate")
    zz = z + 1.0
    trunk = (110, 70, 60)
    cyl(1.6, 6, (0, 3.2, zz + 3), trunk)
    for s in (-1, 1):
        box((0.9, 0.9, 4), (s * 1.5, 3.2, zz + 6.6), trunk, rot=(0, s * 35, 0))
    rng = [(-3, 3, 9.5, 4.6), (3, 3, 9.5, 4.6), (0, 3.5, 11.6, 5.2), (-5.4, 2.6, 8.2, 3.6), (5.4, 2.6, 8.2, 3.6), (-1.8, 1.4, 10.4, 4.0),
           (1.8, 4.8, 10.8, 4.0), (0, 2.0, 8.6, 3.8), (-3.8, 4.6, 11.0, 3.6), (3.8, 4.6, 11.0, 3.6), (-2.4, 3.6, 12.8, 3.4),
           (2.4, 2.4, 12.6, 3.4), (0, 4.8, 13.4, 3.0), (-6.2, 3.8, 9.8, 2.6), (6.2, 3.8, 9.8, 2.6), (-4.6, 1.6, 10.6, 2.8), (4.6, 1.6, 10.6, 2.8)]
    for i, (x, y, h, s) in enumerate(rng):
        blk((s, s * 0.9, s * 0.8), x, y, zz + h - s * 0.4, (pink, pink2, pink3)[i % 3], fx="petals" if i == 2 else None)
    for (x, y) in ((-4.4, -1.5), (4.4, -1.5), (-5.2, 4.8), (5.2, 4.8)):
        blk((2.2, 1.8, 1.6), x, y, zz, pink2)
    for s in (-1, 1):  # stone pagoda lanterns
        x = s * 3.3
        blk((1.2, 1.2, 0.5), x, -0.6, zz, (110, 106, 120))
        blk((0.5, 0.5, 1.6), x, -0.6, zz + 0.5, (110, 106, 120))
        blk((1.1, 1.1, 1.0), x, -0.6, zz + 2.1, (255, 220, 140), "Neon", light=[255, 220, 140, 8])
        wedge((1.8, 0.9, 0.7), (x, -0.6 - 0.45, zz + 3.45), (80, 76, 90), rot=(0, 0, 0))
        wedge((1.8, 0.9, 0.7), (x, -0.6 + 0.45, zz + 3.45), (80, 76, 90), rot=(0, 0, 180))
    for (x, y) in ((-1.6, 1.0), (1.4, 0.8), (0.2, 1.8)):  # rocks
        box((1.2, 1.0, 1.6), (x, y, zz + 0.8), (100, 96, 112), "Slate", rot=(10, 15, 30))
    ball(2.2, (0, 1.0, zz + 4.0), (190, 90, 255), "Neon", tr=0.05, bob=1, light=[200, 110, 255, 14])
    swirl(zz + 4.0, 2.0, (255, 160, 240), tilt=70)
    cyl(0.3, 12, (0, 1.0, zz + 10), (255, 150, 230), "Neon", tr=0.3)
    for s in (-1, 1):  # torii-style banner frames
        x = s * 6.3
        for dy in (-1.2, 1.2):
            blk((0.5, 0.5, 7), x, 0.8 + dy, z, (120, 50, 40))
        blk((0.6, 3.6, 0.5), x, 0.8, z + 7, GOLD)
        blk((0.15, 2.0, 4.6), x - s * 0.1, 0.8, z + 2.2, (220, 60, 160))
    swirl(zz + 14, 4.5, (255, 140, 230), tilt=8)


def v_storm():  # X12: blue-roofed storm pagoda variant on the reference plinth
    v_pagoda(roof=(40, 70, 150), glow=(110, 190, 255), beam=(140, 210, 255))


def v_crystal(col=(170, 90, 255), dark=(70, 60, 86), beam=(200, 120, 255)):  # X20 Gravity Seal (ref 5)
    z = base_v2((60, 30, 100), col, (255, 236, 150), "Slate", lanterns=3)
    for i, (w, h) in enumerate(((9.0, 1.2), (7.2, 1.2), (5.4, 1.0))):
        cyl(w, h, (0, 0.5, z + i * 1.2 + h / 2), dark, "Slate", verts=6)
        cyl(w + 0.2, 0.18, (0, 0.5, z + i * 1.2 + h - 0.05), GOLD, "Neon", verts=6)
    zz = z + 3.4
    for s in (-1, 1):
        box((0.7, 0.7, 1.6), (s * 2.0, 0.5, zz + 0.6), dark, "Slate", rot=(0, s * 20, 0))
    crystal(0, 0.5, zz + 0.2, 8.5, 3.6, col, tr=0.05, light=list(col) + [18], fx="sparkle")
    for i in range(5):
        a = i * 2 * math.pi / 5
        crystal(math.cos(a) * 4.0, 0.5 + math.sin(a) * 4.0, zz + 1.5 + (i % 3), 1.6, 0.6, col, tr=0.15, rot_z=i * 20, bob=1)
    light_beam(zz + 8.8, beam, h=30, d=1.8, y=0.5)
    swirl(zz + 4, 3.2, (230, 190, 255), tilt=16)


def v_torii(red=(220, 40, 40), top=(40, 32, 40), beam=(255, 150, 50), glow=(255, 190, 90), floor=(56, 50, 60), void=False):
    """X50 Dragon Gate R$ (ref 4: red torii, rope + paper, hanging lanterns, fire beam) / X40 Void (ref 8 when void)."""
    z = base_v2(floor, beam if not void else (200, 90, 255), glow, "Slate", lanterns=3)
    for s in (-1, 1):
        blk((1.5, 1.5, 11), s * 5.0, 1.5, z, red)
        blk((2.0, 2.0, 1.4), s * 5.0, 1.5, z, (30, 26, 32))
        if void:
            for k in range(3):
                blk((1.6, 1.6, 0.25), s * 5.0, 1.5, z + 2.5 + k * 3.2, (210, 100, 255), "Neon")
    blk((14, 1.8, 1.2), 0, 1.5, z + 11, top)
    for s in (-1, 1):
        wedge((1.6, 1.8, 0.9), (s * 7.6, 1.5, z + 11.85), top, rot=(0, 0, 90 * s))
    blk((12, 1.2, 0.9), 0, 1.5, z + 9.2, red)
    blk((2.6, 0.3, 1.6), 0, 0.85, z + 10.4, (150, 150, 160) if void else GOLD, "Metal")
    if void:
        for s in (-1, 1):
            blk((10.8 if s else 0, 0.1, 0.18), 0, 0.85, z + 11.6 + s * 0.3, (220, 120, 255), "Neon")
    if not void:  # shimenawa rope + paper zigzags + hanging lanterns
        for i in range(9):
            t = i / 8
            x = -4.2 + t * 8.4
            sag = math.sin(t * math.pi) * 0.9
            cyl(0.5, 1.2, (x, 1.0, z + 8.6 - sag), (220, 190, 120), rot=(0, 90, 0))
        for x in (-2.0, 2.0):
            for k in range(3):
                box((0.5, 0.06, 0.5), (x + (0.2 if k % 2 else -0.2), 0.95, z + 7.9 - sag - k * 0.45), WHITE, rot=(0, 0, 0))
        for s in (-1, 1):
            blk((0.1, 0.1, 1.0), s * 5.0, 0.5, z + 7.6, (60, 50, 50))
            blk((1.0, 1.0, 1.3), s * 5.0, 0.5, z + 6.3, (255, 210, 120), "Neon", light=[255, 200, 120, 10])
            blk((1.2, 1.2, 0.3), s * 5.0, 0.5, z + 7.6, (60, 50, 50))
    else:  # purple banners hanging from the beam
        for s in (-1, 1):
            blk((1.8, 0.12, 5.5), s * 3.4, 0.7, z + 3.6, (120, 40, 170))
            blk((1.9, 0.1, 0.2), s * 3.4, 0.65, z + 9.0, (230, 140, 255), "Neon")
    blk((3.2, 2.6, 1.6), 0, 1.5, z, (80, 76, 86), "Slate")  # altar
    blk((2.4, 2.0, 0.3), 0, 1.5, z + 1.6, beam, "Neon", fx="embers" if not void else "smoke", light=list(beam) + [16])
    light_beam(z + 1.9, beam, h=32, d=1.6, y=1.5)
    if void:  # vortex above the gate
        for k, (r, tilt) in enumerate(((5.0, 8), (3.8, -10), (2.6, 14))):
            swirl(z + 15 + k * 1.2, r, (150, 40, 220) if k % 2 == 0 else (230, 130, 255), tilt=tilt, n=24, gap=0.15)
        swirl(z + 6, 2.2, (230, 130, 255), tilt=60)
    else:
        swirl(z + 5, 1.8, (255, 200, 90), tilt=20)
        swirl(z + 9, 1.4, (255, 220, 120), tilt=-20)


def v_dome():  # X25 Thunder Dome R$: glass dome + lightning core on the reference plinth
    z = base_v2((40, 60, 90), (120, 200, 255), (160, 230, 255), "Slate")
    cyl(10.5, 0.6, (0, 0, z + 0.3), (80, 100, 140), "Metal")
    ball(10, (0, 0, z + 0.6), (160, 220, 255), "Glass", tr=0.6)
    ball(2.6, (0, 0, z + 3.4), (190, 235, 255), "Neon", light=[150, 220, 255, 18], bob=1, fx="sparkle")
    for i in range(6):
        a = i * math.pi / 3
        box((0.22, 0.22, 2.4), (math.cos(a) * 1.8, math.sin(a) * 1.8, z + 3.4), (230, 250, 255), "Neon", rot=(math.cos(a) * 60, math.sin(a) * 60, 0))
    light_beam(z + 5.6, (140, 210, 255), h=30, d=1.4)
    swirl(z + 7, 3.4, (170, 230, 255), tilt=12)


def v_crimson():  # X35: red crystal variant of the crystal altar
    v_crystal(col=(255, 50, 80), dark=(60, 30, 40), beam=(255, 80, 110))


def v_void():  # X40 (ref 8): dark torii with neon strips, purple banners and a vortex
    v_torii(red=(40, 30, 50), top=(30, 24, 36), beam=(200, 90, 255), glow=(255, 236, 150), floor=(36, 30, 48), void=True)


def v_throne():  # X250 Sage Throne R$ (ref 1): golden orb on a stepped dais, curved pillars, purple banners, halos
    z = base_v2((250, 244, 230), (255, 220, 100), (255, 236, 150), "Marble")
    for i, (d, h) in enumerate(((9.5, 1.0), (7.6, 1.0), (5.6, 1.0))):
        cyl(d, h, (0, 0.6, z + i * 1.0 + h / 2), (245, 240, 230) if i % 2 == 0 else GOLD, "Marble" if i % 2 == 0 else "SmoothPlastic")
        cyl(d + 0.15, 0.15, (0, 0.6, z + i * 1.0 + h), GOLD2, "Neon")
    blk((2.6, 0.4, 1.6), 0, -3.4, z + 0.8, GOLD, "Metal")
    zz = z + 3.0
    ball(5.2, (0, 0.6, zz + 3.2), (255, 200, 60), "Neon", tr=0.05, light=[255, 220, 120, 24], fx="sparkle")
    ball(5.8, (0, 0.6, zz + 3.2), (255, 236, 170), "Neon", tr=0.72)  # soft glow shell (Roblox Glass refracted the cliffs)
    swirl(zz + 3.2, 3.8, (255, 230, 140), tilt=65, n=26, gap=0.1)
    swirl(zz + 3.2, 4.4, (255, 210, 90), tilt=-55, n=26, gap=0.2)
    for s in (-1, 1):  # curved white pillars leaning in
        for k in range(6):
            t = k / 5
            x = s * (6.2 - t * t * 1.8)
            blk((1.6, 1.6, 2.0), x, 2.4, z + k * 1.9, (238, 236, 240), "Marble", rot=(0, s * -t * 18, 0))
            if k % 2 == 1:
                box((0.2, 1.62, 1.2), (x - s * 0.82, 2.4, z + k * 1.9 + 1.0), GOLD, "Neon", rot=(0, s * -t * 18, 0))
        banner(s * 7.0 - (0 if s < 0 else 0), -4.6, z, (110, 30, 150), h=6.5, w=1.6, pole=(90, 60, 40), face=0 if s < 0 else 180)
    ring(7.5, 40, (1.1, 0.4, 0.4), zz + 13, (255, 230, 130), "Neon", cy=0.6, spin=1)
    ring(6.6, 36, (0.9, 0.25, 0.25), zz + 13, (255, 250, 220), "Neon", cy=0.6, tr=0.3, spin=1)
    light_beam(zz + 6, (255, 225, 110), h=32, d=2.2, y=0.6)


STATIONS = [
    ("Dummy", v_dummies), ("Ring", v_ring), ("ChakraPool", v_well), ("Forge", v_forge), ("GoldenDojo", v_pagoda),
    ("ScrollTemple", v_sakura), ("StormPagoda", v_storm), ("GravitySeal", v_crystal), ("ThunderDome", v_dome),
    ("CrimsonAltar", v_crimson), ("VoidTotem", v_void), ("DragonGate", v_torii), ("SageThrone", v_throne),
]


def build_some(names, spacing=26):
    """rebuild only the named stations (faster than build_all)."""
    global _coll, _origin
    root = bpy.data.collections["Stations"]
    for i, (name, fn) in enumerate(STATIONS):
        if name not in names:
            continue
        old = bpy.data.collections.get("ST_" + name)
        if old:
            for o in list(old.objects):
                bpy.data.objects.remove(o, do_unlink=True)
            bpy.data.collections.remove(old)
        _coll = bpy.data.collections.new("ST_" + name)
        root.children.link(_coll)
        _origin = Vector(((i % 5) * spacing, -(i // 5) * spacing, 0))
        _coll["rbx_origin"] = list(_origin)
        fn()
    return True


def build_all(spacing=26):
    global _coll, _origin
    sc = scene()
    root = bpy.data.collections.get("Stations") or bpy.data.collections.new("Stations")
    if root.name not in sc.collection.children:
        sc.collection.children.link(root)
    for name, fn in STATIONS:
        old = bpy.data.collections.get("ST_" + name)
        if old:
            for o in list(old.objects):
                bpy.data.objects.remove(o, do_unlink=True)
            bpy.data.collections.remove(old)
    for i, (name, fn) in enumerate(STATIONS):
        _coll = bpy.data.collections.new("ST_" + name)
        root.children.link(_coll)
        _origin = Vector(((i % 5) * spacing, -(i // 5) * spacing, 0))
        _coll["rbx_origin"] = list(_origin)
        fn()
    return {name: len(bpy.data.collections["ST_" + name].objects) for name, _ in STATIONS}


def _to_rbx(v):
    return [round(v.x, 4), round(v.z, 4), round(-v.y, 4)]


def export_json(path):
    P = Matrix(((1, 0, 0), (0, 0, 1), (0, -1, 0)))
    out = {}
    for name, _ in STATIONS:
        col = bpy.data.collections["ST_" + name]
        origin = Vector(col["rbx_origin"])
        parts = []
        for o in col.objects:
            loc, rot, scl = o.matrix_world.decompose()
            R = P @ rot.to_matrix() @ P.transposed()
            d = o.scale
            parts.append({
                "k": o["rbx_kind"], "p": _to_rbx(loc - origin), "r": [round(R[i][j], 5) for i in range(3) for j in range(3)],
                "s": [round(abs(d.x), 4), round(abs(d.z), 4), round(abs(d.y), 4)], "c": list(o["rbx_col"]), "m": o["rbx_mat"],
                "t": o.get("rbx_tr", 0), "studs": o.get("rbx_studs", 0), "light": list(o["rbx_light"]) if "rbx_light" in o else None,
                "spin": o.get("rbx_spin", 0), "bob": o.get("rbx_bob", 0), "fx": o.get("rbx_fx"),
            })
        out[name] = parts
    with open(path, "w") as f:
        json.dump(out, f, separators=(",", ":"))
    return {k: len(v) for k, v in out.items()}
