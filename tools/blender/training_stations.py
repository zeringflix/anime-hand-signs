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


# ------------------------------------------------------------------ shared pieces
def plinth(floor_col, floor_mat="SmoothPlastic", rail=True, h=1.2):
    """dark studded base slab, inset themed floor, gold rail with glowing corner caps. Returns the floor top Z."""
    blk((16, 16, h), 0, 0, 0, STONE, "Plastic", studs=True)
    blk((13.6, 13.6, 0.25), 0, 0, h, floor_col, floor_mat, studs=floor_mat == "Plastic")
    top = h + 0.25
    if rail:
        for s in (-1, 1):
            blk((15.6, 0.7, 0.35), 0, s * 7.6, h - 0.05, GOLD, "Neon")
            blk((0.7, 15.6, 0.35), s * 7.6, 0, h - 0.05, GOLD, "Neon")
        for sx in (-1, 1):
            for sy in (-1, 1):
                blk((1.4, 1.4, 2.6), sx * 7.2, sy * 7.2, h, GOLD, "SmoothPlastic")
                box((1.2, 1.2, 1.2), (sx * 7.2, sy * 7.2, h + 3.3), GOLD2, "Neon", rot=(0, 0, 45))
    return top


def lantern(x, y, z, glow=(255, 236, 140)):
    blk((1.4, 1.4, 0.5), x, y, z, (170, 170, 178))
    blk((0.6, 0.6, 1.8), x, y, z + 0.5, (170, 170, 178))
    blk((1.3, 1.3, 1.1), x, y, z + 2.3, glow, "Neon", light=list(glow) + [10])
    blk((1.9, 1.9, 0.45), x, y, z + 3.4, (130, 130, 140))


# ------------------------------------------------------------------ the 13 stations (original designs)
def s_dummies():  # X2 Training Dummies: grassy yard, fence, three straw dummies, bamboo target poles
    z = plinth((110, 200, 80), "Grass", rail=False)
    wood, dark = (176, 122, 72), (120, 80, 48)
    for s in (-1, 1):
        for k in range(-3, 4):
            blk((0.6, 0.6, 2.2), k * 2.2, s * 6.8, z, dark)
            blk((0.6, 0.6, 2.2), s * 6.8, k * 2.2, z, dark)
        blk((14, 0.35, 0.4), 0, s * 6.8, z + 1.2, wood)
        blk((0.35, 14, 0.4), s * 6.8, 0, z + 1.2, wood)
    for i, (x, y) in enumerate(((-3.6, -1.5), (0, 1.2), (3.6, -1.5))):
        blk((0.6, 0.6, 3.2), x, y, z, dark)
        blk((2.6, 1.8, 2.8), x, y, z + 2.4, (226, 200, 130), "SmoothPlastic")       # straw body
        blk((4.6, 0.6, 0.6), x, y, z + 4.0, wood)                                   # arms
        blk((2.2, 2.2, 2.2), x, y, z + 5.2, (240, 226, 180))                        # head
        blk((0.9, 0.12, 0.9), x, y - 1.12, z + 3.6, (230, 50, 50))                  # target dot
        blk((1.7, 0.1, 1.7), x, y - 1.08, z + 3.6, WHITE)
        cyl(3.6, 0.3, (x, y, z + 7.55), (232, 196, 100))                            # straw hat brim
        cyl(2.0, 1.1, (x, y, z + 8.2), (232, 196, 100))
        cyl(2.05, 0.35, (x, y, z + 7.85), (210, 50, 46))
    for x in (-5.5, 5.5):
        cyl(0.7, 6, (x, 4.6, z + 3), (130, 190, 80))                                # bamboo
        for k in range(3):
            cyl(0.8, 0.2, (x, 4.6, z + 1.2 + k * 1.9), (90, 150, 60))
    blk((1.4, 1.4, 1.4), 4.5, -5, z, (255, 220, 70), "Neon", light=[255, 220, 70, 9])


def s_ring():  # X3 Boxing Ring: raised ring, glowing corner posts, ropes, gantry with punching bags
    z = plinth((240, 240, 246), rail=False)
    blk((13, 13, 1.2), 0, 0, z, (245, 245, 252), "SmoothPlastic")
    blk((11, 11, 0.06), 0, 0, z + 1.2, (60, 120, 230))
    blk((6, 6, 0.08), 0, 0, z + 1.24, (240, 240, 250))
    zz = z + 1.2
    for (x, y, c) in ((-6, -6, (230, 50, 50)), (6, 6, (230, 50, 50)), (-6, 6, (50, 100, 235)), (6, -6, (50, 100, 235))):
        blk((1.1, 1.1, 4.4), x, y, zz, c)
        box((1.2, 1.2, 1.2), (x, y, zz + 5.0), GOLD2, "Neon", rot=(0, 0, 45))
    for i, c in enumerate(((230, 50, 50), WHITE, (50, 100, 235))):
        h = zz + 1.3 + i * 1.1
        for s in (-1, 1):
            blk((11.6, 0.25, 0.25), 0, s * 6, h, c)
            blk((0.25, 11.6, 0.25), s * 6, 0, h, c)
    for s in (-1, 1):  # gantry
        blk((0.8, 0.8, 10), s * 7.3, 7.3, 0, INK)
    blk((15.4, 0.8, 0.8), 0, 7.3, 10, INK)
    for x in (-4, 0, 4):
        blk((0.15, 0.15, 1.8), x, 7.3, 8.2, (120, 120, 130))
        cyl(1.8, 3.4, (x, 7.3, 6.5), (210, 40, 40))
        cyl(1.85, 0.35, (x, 7.3, 7.9), INK)
    blk((0.6, 0.6, 0.6), 0, 7.3, 10.8, (255, 240, 180), "Neon", light=[255, 240, 200, 16])


def s_pool():  # X5 Chakra Pool: round basin of glowing chakra, crystal spikes, floating orbs
    z = plinth((60, 70, 110), "Slate")
    cyl(12, 1.4, (0, 0, z + 0.7), STONE2, "Cobblestone")
    cyl(10.4, 0.25, (0, 0, z + 1.35), (70, 200, 255), "Neon", tr=0.15, light=[90, 210, 255, 16])
    cyl(4, 0.4, (0, 0, z + 1.5), (200, 245, 255), "Neon", tr=0.3)
    for i in range(6):
        a = i * math.pi / 3
        x, y = math.cos(a) * 6.2, math.sin(a) * 6.2
        box((1.1, 1.1, 3.6 + (i % 3)), (x, y, z + 2.2 + (i % 3) * 0.5), (120, 220, 255), "Neon", rot=(math.cos(a) * 12, math.sin(a) * 12, math.degrees(a)), tr=0.1)
    for i, (x, y, h) in enumerate(((-2, 1.5, 5), (2.5, -1, 6.5), (0, 0, 8.5))):
        ball(1.2 + i * 0.5, (x, y, z + h), (150, 230, 255), "Neon", bob=1)
    box((1, 1, 1), (0, 0, z + 10.5), WHITE, "Neon", rot=(45, 45, 0), spin=1)


def s_forge():  # X7 Fire Forge: stone furnace with lava mouth, chimney, anvil, lava channels
    z = plinth((70, 60, 60), "Cobblestone")
    blk((7, 5.5, 6), 0, 2, z, (48, 44, 52), "Slate")
    blk((7.6, 6.1, 0.8), 0, 2, z + 6, (70, 66, 76), "Slate")
    blk((3.6, 0.3, 2.6), 0, -0.8, z + 1.2, (255, 110, 30), "Neon", light=[255, 120, 40, 16])
    blk((2.4, 2.4, 7), 2, 3, z + 6.8, (70, 66, 76), "Slate")
    blk((3, 3, 0.8), 2, 3, z + 13.8, (40, 38, 44))
    ball(1.8, (2, 3, z + 15.4), (255, 140, 40), "Neon", tr=0.2, bob=1)
    blk((14, 1.2, 0.12), 0, -4.5, z, (255, 120, 30), "Neon")                         # lava channel
    blk((1.2, 6, 0.12), -5.5, -2, z, (255, 120, 30), "Neon")
    blk((2, 1.4, 1.4), -3.8, -4.4, z + 0.12, (90, 90, 100))                         # anvil
    blk((3.4, 1.6, 0.9), -3.8, -4.4, z + 1.5, (120, 120, 132), "Metal")
    wedge((1.2, 1.6, 0.9), (-6.0, -4.4, z + 1.95), (120, 120, 132), "Metal", rot=(0, 0, -90))
    blk((0.35, 0.35, 2.6), -3.2, -4.4, z + 2.4, (150, 110, 70), rot=(0, 30, 0))       # hammer
    blk((1.1, 0.8, 0.8), -2.6, -4.4, z + 4.6, (120, 120, 132), "Metal")
    for x in (4.5, 5.6):
        blk((0.9, 0.9, 0.9), x, -4.6, z + 0.12, (255, 200, 60), "Neon")


def s_golden_dojo():  # X8 Golden Dojo (Robux): gold pagoda pavilion, tatami, red lanterns
    z = plinth((236, 214, 150), "WoodPlanks")
    red = (200, 44, 40)
    for x in (-5.5, 5.5):
        for y in (-5.5, 5.5):
            blk((1.1, 1.1, 7), x, y, z, red)
    for i, (w, h) in enumerate(((15, 1.0), (11, 0.9))):
        zz = z + 7 + i * 3.2
        blk((w, w, h), 0, 0, zz, GOLD, "SmoothPlastic")
        for s in (-1, 1):  # sloped roof skirts (wedges) on all four sides
            wedge((w, 2.4, 1.6), (0, s * (w / 2 + 0.9), zz + h + 0.8), GOLD2, rot=(0, 0, 0 if s > 0 else 180))
            wedge((w, 2.4, 1.6), (s * (w / 2 + 0.9), 0, zz + h + 0.8), GOLD2, rot=(0, 0, -90 if s > 0 else 90))
        blk((w - 4, w - 4, 1.4), 0, 0, zz + h, red)
    blk((1.2, 1.2, 3.4), 0, 0, z + 14.6, GOLD, "Metal")
    ball(1.8, (0, 0, z + 18.6), GOLD2, "Neon", light=[255, 220, 120, 18])
    for x in (-3, 3):
        cyl(1.4, 1.8, (x, -5.5, z + 5.2), (230, 50, 50), "Neon", light=[255, 90, 70, 8])
    blk((8, 6, 0.1), 0, 0, z, (214, 200, 120))                                      # tatami


def s_scroll():  # X10 Scroll Temple: giant unrolled scroll on an altar, stacked scroll rolls, incense
    z = plinth((214, 196, 160), "Sand")
    blk((9, 4, 2.2), 0, 2.5, z, (120, 70, 50), "Wood")
    blk((9.6, 4.6, 0.5), 0, 2.5, z + 2.2, (90, 50, 36), "Wood")
    blk((7, 0.15, 7), 0, 3.2, z + 3.4, (250, 240, 214), rot=(-10, 0, 0))             # hanging paper
    for zz in (z + 3.0, z + 10.4):
        cyl(1.0, 8.4, (0, 3.6, zz), (180, 60, 40), rot=(0, 90, 0))
    for k, c in enumerate(((40, 40, 50), (200, 40, 40), (40, 40, 50))):
        blk((0.5, 0.05, 1.2), -2 + k * 2, 3.05, z + 6.8 - k * 0.4, c)
    for i, (x, y) in enumerate(((-5, -3), (-3.2, -4.6), (4.6, -3.8))):  # stacked rolls
        for j in range(2 + i % 2):
            cyl(1.6, 3.2, (x + j * 0.2, y, z + 0.8 + j * 1.6), (245, 232, 200), rot=(0, 90, 20 * j))
            cyl(1.7, 0.3, (x + j * 0.2 - 1.6, y, z + 0.8 + j * 1.6), (190, 60, 40), rot=(0, 90, 20 * j))
    cyl(1.2, 0.8, (0, -2, z + 0.4), (90, 80, 70))
    for k in range(3):
        blk((0.1, 0.1, 2), -0.3 + k * 0.3, -2, z + 0.8, (200, 120, 60))
    ball(0.4, (0, -2, z + 3.2), (255, 160, 80), "Neon", light=[255, 170, 90, 8])
    for x in (-6.6, 6.6):  # paper banners
        blk((0.3, 0.3, 9), x, 6.6, z, INK)
        blk((1.8, 0.1, 5), x, 6.4, z + 3.5, (240, 230, 210))


def s_pagoda():  # X12 Storm Pagoda: 4-tier tower, lightning rod, storm cloud, bolts
    z = plinth((232, 222, 196), "Sand")
    zz = z
    for k in range(4):
        w = 8 - k * 1.5
        blk((w, w, 2.6), 0, 0, zz, (244, 238, 226))
        for sx in (-1, 1):
            for sy in (-1, 1):
                blk((0.5, 0.5, 2.6), sx * (w / 2 - 0.2), sy * (w / 2 - 0.2), zz, (200, 56, 50))
        blk((w + 2.8, w + 2.8, 0.6), 0, 0, zz + 2.6, (52, 84, 140))
        blk((w + 1.4, w + 1.4, 0.5), 0, 0, zz + 3.2, (40, 64, 110))
        zz += 3.7
    blk((0.4, 0.4, 4), 0, 0, zz, GOLD, "Metal")
    for i, (x, y, w) in enumerate(((-1.5, 0, 4), (1.6, 0.8, 3.4), (0, -1.2, 3.6), (0.3, 1.4, 2.6))):
        blk((w, w * 0.8, 1.6), x, y, zz + 5 + (i % 2) * 0.6, (90, 96, 130), bob=1)
    pts = [(0, 0, zz + 4), (0.8, 0, zz + 2.6), (-0.4, 0.3, zz + 1.4), (0.5, 0, zz)]
    for a, b in zip(pts, pts[1:]):
        va, vb = Vector(a), Vector(b)
        mid, d = (va + vb) / 2, (vb - va)
        ang = math.degrees(math.atan2(d.x, d.z))
        box((0.3, 0.3, d.length), mid, (150, 220, 255), "Neon", rot=(0, ang, 0), light=[150, 220, 255, 14] if a == pts[0] else None)


def s_gravity():  # X20 Gravity Seal: obsidian seal circle, neon rune rings, orbiting floating rocks
    z = plinth((30, 26, 40), "Slate", rail=False)
    cyl(13, 0.3, (0, 0, z + 0.15), (24, 20, 32), "Slate")
    ring(5.8, 28, (0.9, 0.35, 0.12), z + 0.35, (190, 110, 255))
    ring(3.4, 18, (0.8, 0.3, 0.12), z + 0.35, (190, 110, 255))
    for i in range(4):
        a = i * math.pi / 2 + math.pi / 4
        x, y = math.cos(a) * 6.6, math.sin(a) * 6.6
        blk((1.8, 1.8, 6 + i), x, y, z, (28, 24, 36), "Slate")
        blk((0.3, 0.5, 4 + i), x * 0.9, y * 0.9, z + 1, (190, 110, 255), "Neon")
    ball(2.6, (0, 0, z + 5), (120, 60, 200), "Neon", tr=0.1, light=[190, 110, 255, 18], bob=1)
    ring(2.6, 16, (0.4, 0.4, 0.4), z + 5, (230, 200, 255), tilt=70, spin=1)
    for i in range(6):
        a = i * math.pi / 3
        box((1.4, 1.2, 1.1), (math.cos(a) * 4.4, math.sin(a) * 4.4, z + 3.5 + (i % 3)), (48, 40, 60), "Slate", rot=(i * 20, i * 33, 0), bob=1)


def s_thunder_dome():  # X25 Thunder Dome (Robux): glass dome, tesla coils, lightning core
    z = plinth((40, 60, 90), "Slate")
    cyl(11, 0.6, (0, 0, z + 0.3), (70, 100, 140), "Metal")
    ball(10.4, (0, 0, z + 0.6), (160, 220, 255), "Glass", tr=0.6)
    ball(2.6, (0, 0, z + 3.2), (180, 230, 255), "Neon", light=[150, 220, 255, 18], bob=1)
    for i in range(6):
        a = i * math.pi / 3
        box((0.25, 0.25, 2.4), (math.cos(a) * 1.8, math.sin(a) * 1.8, z + 3.2), (220, 245, 255), "Neon", rot=(math.cos(a) * 60, math.sin(a) * 60, 0))
    for x, y in ((-6.4, -6.4), (6.4, 6.4), (-6.4, 6.4), (6.4, -6.4)):
        cyl(1.4, 5, (x, y, z + 2.5), (90, 90, 104), "Metal")
        for k in range(3):
            cyl(2.0 - k * 0.3, 0.4, (x, y, z + 1.4 + k * 1.3), (200, 130, 60), "Metal")
        ball(1.6, (x, y, z + 5.8), (190, 235, 255), "Neon")


def s_crimson():  # X35 Crimson Altar: black altar, giant red crystal heart, chains, spikes
    z = plinth((60, 20, 30), "Slate")
    for i, w in enumerate((9, 7, 5)):
        blk((w, w, 1), 0, 0, z + i, (30 + i * 10, 18, 26), "Slate")
    box((3.6, 3.6, 3.6), (0, 0, z + 8.2), (230, 30, 60), "Neon", rot=(45, 35.26, 0), tr=0.05, light=[255, 50, 80, 18], spin=1)  # gem on its tip
    box((1.4, 1.4, 1.4), (0, 0, z + 8.2), (255, 200, 210), "Neon", rot=(45, 35.26, 0))
    for i in range(8):
        a = i * math.pi / 4
        box((0.9, 0.9, 2.6 + (i % 2) * 1.6), (math.cos(a) * 5.6, math.sin(a) * 5.6, z + 1.4), (20, 16, 24), "Slate", rot=(math.cos(a) * 18, math.sin(a) * 18, 45))
    for s in (-1, 1):
        for k in range(6):
            box((0.5, 0.25, 0.9), (s * (1.6 + k * 0.85), 0, z + 9 - k * 1.2), (150, 150, 160), "Metal", rot=(0, s * 50, 90 * (k % 2)))


def s_void():  # X40 Void Totem: tall obsidian obelisk with a neon eye, floating void cubes
    z = plinth((26, 18, 40), "Slate")
    blk((3.6, 3.6, 13), 0, 0, z, (20, 14, 30), "Slate")
    wedge((3.6, 1.8, 2.2), (0, 0.9, z + 14.1), (20, 14, 30), "Slate", rot=(0, 0, 180))
    wedge((3.6, 1.8, 2.2), (0, -0.9, z + 14.1), (20, 14, 30), "Slate")
    blk((2.4, 0.2, 1.2), 0, -1.85, z + 9, (230, 210, 255), "Neon")
    blk((0.9, 0.22, 0.9), 0, -1.88, z + 9.15, (150, 60, 255), "Neon", light=[170, 90, 255, 18])
    for k in range(3):
        blk((3.9, 3.9, 0.3), 0, 0, z + 2 + k * 3.5, (150, 60, 255), "Neon")
    for i in range(5):
        a = i * 2 * math.pi / 5
        box((1.3, 1.3, 1.3), (math.cos(a) * 5, math.sin(a) * 5, z + 4 + i), (40, 26, 60), "Slate", rot=(i * 30, i * 20, i * 40), bob=1)
        box((0.5, 0.5, 0.5), (math.cos(a) * 5, math.sin(a) * 5 - 0.7, z + 4 + i), (190, 110, 255), "Neon", bob=1)


def s_dragon_gate():  # X50 Dragon Gate (Robux): huge red torii with a coiling block dragon and a pearl
    z = plinth((40, 30, 36), "Slate")
    red = (210, 40, 40)
    for x in (-5.5, 5.5):
        blk((1.6, 1.6, 13), x, 0, z, red)
        blk((2.4, 2.4, 1), x, 0, z, INK)
    blk((16, 2, 1.4), 0, 0, z + 13, INK)
    blk((14.4, 1.6, 1), 0, 0, z + 11.4, red)
    for s in (-1, 1):
        wedge((1.8, 2, 1.2), (s * 8.6, 0, z + 14.0), INK, rot=(0, 0, 90 * s))
    blk((2, 0.4, 2.2), 0, -0.9, z + 11.2, GOLD)
    jade, jade2 = (60, 200, 120), (230, 220, 90)
    for i in range(16):  # dragon body spiralling around the left pillar and across the beam
        t = i / 15
        a = t * math.pi * 3
        x = -5.5 + math.cos(a) * 1.8 + t * 9
        y = math.sin(a) * 1.8
        zz = z + 1.5 + t * 11
        box((1.6, 1.6, 1.6), (x, y, zz), jade if i % 3 else jade2, rot=(0, 0, math.degrees(a)))
    box((2.4, 2.0, 1.8), (4.2, 0, z + 13.6), jade, rot=(0, 0, 20))                    # head
    box((0.4, 0.4, 0.4), (5.0, -0.9, z + 14.2), (255, 230, 60), "Neon")
    box((0.4, 0.4, 0.4), (5.0, 0.9, z + 14.2), (255, 230, 60), "Neon")
    ball(2.2, (0, 0, z + 6), (255, 240, 200), "Neon", light=[255, 220, 150, 18], bob=1)


def s_sage_throne():  # X250 Sage Throne (Robux): stepped gold pyramid, throne, halo ring, rainbow orbs
    z = plinth((90, 40, 140), "Marble")
    for i, w in enumerate((12, 9.6, 7.2)):
        blk((w, w, 1), 0, 1, z + i, (250, 246, 255) if i % 2 == 0 else GOLD, "Marble" if i % 2 == 0 else "SmoothPlastic")
    zz = z + 3
    blk((3.6, 3, 1), 0, 1.6, zz, (160, 90, 240))
    blk((3.8, 0.9, 6), 0, 3.0, zz, GOLD)
    for s in (-1, 1):
        blk((0.7, 3, 2.2), s * 2.1, 1.6, zz, GOLD)
        blk((0.6, 0.6, 7), s * 3.2, 3.2, zz, GOLD)
        box((1.1, 1.1, 1.1), (s * 3.2, 3.2, zz + 7.6), GOLD2, "Neon", rot=(0, 0, 45))
    ring(5.2, 32, (1.0, 0.5, 0.5), zz + 9, GOLD2, tilt=90, cy=4.2, spin=1)            # halo behind the throne
    cols = ((255, 90, 90), (255, 200, 60), (110, 240, 110), (90, 170, 255), (200, 110, 255))
    for i, c in enumerate(cols):
        a = i * 2 * math.pi / 5
        ball(1.2, (math.cos(a) * 6, math.sin(a) * 6, zz + 2 + (i % 2) * 1.5), c, "Neon", bob=1)
    for x, y in ((-6, -6), (6, -6)):
        blk((3, 2.4, 1.2), x, y, z + 0.2, WHITE, bob=1)                               # little clouds
    ball(1.6, (0, 4.2, zz + 9), (255, 255, 255), "Neon", light=[255, 236, 180, 22])


STATIONS = [
    ("Dummy", s_dummies), ("Ring", s_ring), ("ChakraPool", s_pool), ("Forge", s_forge), ("GoldenDojo", s_golden_dojo),
    ("ScrollTemple", s_scroll), ("StormPagoda", s_pagoda), ("GravitySeal", s_gravity), ("ThunderDome", s_thunder_dome),
    ("CrimsonAltar", s_crimson), ("VoidTotem", s_void), ("DragonGate", s_dragon_gate), ("SageThrone", s_sage_throne),
]


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


# ------------------------------------------------------------------ export to Roblox space (Y up)
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
            mw = o.matrix_world
            loc, rot, scl = mw.decompose()
            R = P @ rot.to_matrix() @ P.transposed()
            d = o.scale if o.get("rbx_kind") != "Wedge" else o.scale
            size = [abs(d.x), abs(d.z), abs(d.y)]  # Roblox local (x, y, z) = Blender local (x, z, y)
            parts.append({
                "k": o["rbx_kind"], "p": _to_rbx(loc - origin), "r": [round(R[i][j], 5) for i in range(3) for j in range(3)],
                "s": [round(v, 4) for v in size], "c": list(o["rbx_col"]), "m": o["rbx_mat"], "t": o.get("rbx_tr", 0),
                "studs": o.get("rbx_studs", 0), "light": list(o["rbx_light"]) if "rbx_light" in o else None,
                "spin": o.get("rbx_spin", 0), "bob": o.get("rbx_bob", 0),
            })
        out[name] = parts
    with open(path, "w") as f:
        json.dump(out, f, separators=(",", ":"))
    return {k: len(v) for k, v in out.items()}
