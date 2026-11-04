"""Visual Lock pilot (issue #14): the Forge training station as REAL Blender meshes for the Roblox 3D Importer.

Builds on the v2 Forge layout (training_stations_v2.py) but:
  * floor rings are true torus meshes, not rings of blocks; the stray gold swirl above the chimney is gone
  * every solid gets a real bevel (toy-plastic edge highlight) and the parts are merged into a handful of meshes,
    one per colour/material, so Roblox gets ~25 MeshParts instead of ~140 Parts
  * new modelled props: anvil + hammer at the front-left, a coal heap with glowing coals at the front-right
Object names carry the Roblox look, applied after import by ServerStorage.Tools.MeshStationKit:
    M_<r>_<g>_<b>_<Material>_<transparency%>[_SPIN|_BOB]   merged visual mesh
    FX_<tag>_<r>_<g>_<b>_<Material>_<tr%>_<i>               effect anchor (beam / fire / smoke / embers / sparkle)
    L_<r>_<g>_<b>_<range>_<i>                               invisible PointLight host
Front faces Blender -Y (Roblox +Z after import), floor at Z = 0, centred on the origin, 1 Blender unit = 1 stud.

Run inside Blender:
    exec(open(r"<repo>/tools/blender/pilot_forge_mesh.py").read()); run(r"<repo>", r"<out>.fbx")
"""
import bpy, bmesh, math, os
from mathutils import Vector, Euler, Matrix


def _torus(ns, radius, thick, height, z, col, mat, tr=0.0, tilt=0, cx=0, cy=0, gap=0.0, **kw):
    bpy.ops.mesh.primitive_torus_add(major_radius=radius, minor_radius=0.5, major_segments=56, minor_segments=8)
    o = bpy.context.active_object
    # squash the tube to thick x height
    me = o.data
    for v in me.vertices:
        p = v.co
        r = math.hypot(p.x, p.y)
        k = (r - radius)
        nr = radius + k * thick
        a = math.atan2(p.y, p.x)
        v.co = Vector((math.cos(a) * nr, math.sin(a) * nr, p.z * height))
    if gap > 0:  # open swirl: drop the last `gap` of the circle
        bm = bmesh.new(); bm.from_mesh(me)
        dead = [v for v in bm.verts if ((math.atan2(v.co.y, v.co.x) + math.pi) / (2 * math.pi)) > 1 - gap]
        bmesh.ops.delete(bm, geom=dead, context="VERTS")
        bm.to_mesh(me); bm.free()
    o.location = ns["_origin"] + Vector((cx, cy, z))
    o.rotation_euler = Euler((math.radians(tilt), 0, 0))
    o["rbx_kind"] = "Mesh"
    return ns["_finish"](o, col, mat, tr, False, **kw)


def run(repo, out_fbx):
    ns = {"__name__": "training_stations_v2"}
    exec(open(os.path.join(repo, "tools", "blender", "training_stations_v2.py")).read(), ns)

    sc = bpy.data.scenes.get("PilotForge") or bpy.data.scenes.new("PilotForge")
    bpy.context.window.scene = sc
    for o in list(sc.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    coll = bpy.data.collections.get("PF_Forge") or bpy.data.collections.new("PF_Forge")
    if coll.name not in sc.collection.children:
        sc.collection.children.link(coll)
    ns["_coll"] = coll
    ns["_origin"] = Vector((0, 0, 0))

    # real torus rings instead of block rings; drop the stray swirl
    def ring(radius, n, part, z, col, mat="Neon", tilt=0, tr=0.0, cx=0, cy=0, **kw):
        kw.pop("fx", None)
        return [_torus(ns, radius, part[1], part[2], z, col, mat, tr=tr, tilt=tilt, cx=cx, cy=cy, **kw)]
    ns["ring"] = ring
    ns["swirl"] = lambda *a, **k: None
    orig_beam = ns["light_beam"]

    def light_beam(z0, col, h=34, d=1.6, x=0, y=0):  # beam anchor only (the client draws the textured beam)
        h *= ns["BEAM_SCALE"]
        ns["cyl"](d, h, (x, y, z0 + h / 2), col, "Neon", tr=0.45, fx="beam")
    ns["light_beam"] = light_beam

    ns["v_forge"]()
    box, blk, cyl, ball, wedge = ns["box"], ns["blk"], ns["cyl"], ns["ball"], ns["wedge"]
    z = 1.25
    # anvil (front-left) + hammer
    metal, metal2, wood = (78, 82, 96), (110, 116, 132), (128, 84, 50)
    ax, ay = -3.6, -4.2
    blk((2.0, 1.4, 0.6), ax, ay, z, metal, "Metal")
    blk((1.0, 0.8, 0.9), ax, ay, z + 0.6, metal, "Metal")
    blk((2.6, 1.2, 0.7), ax, ay, z + 1.5, metal2, "Metal")
    wedge((1.2, 0.7, 0.7), (ax + 1.9, ay, z + 1.85), metal2, "Metal", rot=(0, 0, 90))
    cyl(0.28, 2.6, (ax - 0.2, ay - 0.1, z + 2.45), wood, "Wood", rot=(0, 72, 20))
    blk((0.6, 0.6, 1.1), ax - 1.35, ay - 0.55, z + 2.0, metal, "Metal")
    # coal heap (front-right) with glowing coals
    hx, hy = 3.6, -4.0
    for i, (dx, dy, s) in enumerate([(0, 0, 1.5), (0.8, 0.3, 1.1), (-0.7, 0.4, 1.0), (0.2, -0.6, 1.0), (-0.3, -0.2, 0.9), (0.5, 0.8, 0.8)]):
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=s / 2)
        o = bpy.context.active_object
        o.location = Vector((hx + dx, hy + dy, z + s * 0.32 + (0.45 if i == 4 else 0)))
        o.rotation_euler = Euler((i * 0.7, i * 1.1, i * 0.5))
        o["rbx_kind"] = "Mesh"
        ns["_finish"](o, (44, 38, 42), "Slate", 0.0, False)
    for (dx, dy) in [(0.3, -0.5), (-0.5, 0.0), (0.7, 0.4)]:
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.28)
        o = bpy.context.active_object
        o.location = Vector((hx + dx, hy + dy, z + 0.9))
        o["rbx_kind"] = "Mesh"
        ns["_finish"](o, (255, 130, 40), "Neon", 0.0, False)

    # ---------------------------------------------------------------- bevel solids, then merge by look
    dg = bpy.context.evaluated_depsgraph_get()
    objs = list(coll.objects)
    for o in objs:  # bake scale into the mesh so bevels stay even
        o.data = o.data.copy()
        o.data.transform(Matrix.Diagonal(tuple(o.scale) + (1,)))
        o.scale = (1, 1, 1)
    for o in objs:
        if o.get("rbx_kind") not in ("Block", "Wedge", "Cylinder") or o.get("rbx_mat") == "Neon" or o.get("rbx_fx"):
            continue
        dims = o.dimensions
        m = min(dims)
        if m < 0.35:
            continue
        b = o.modifiers.new("Bevel", "BEVEL")
        b.width = min(0.16, m * 0.12); b.segments = 2; b.limit_method = "ANGLE"; b.angle_limit = math.radians(40)
    dg = bpy.context.evaluated_depsgraph_get()
    for o in objs:
        if o.modifiers:
            me = bpy.data.meshes.new_from_object(o.evaluated_get(dg))
            o.modifiers.clear()
            o.data = me

    groups, fx, lights = {}, [], []
    for o in objs:
        col, mat, tr = tuple(o["rbx_col"]), o["rbx_mat"], int(round(o.get("rbx_tr", 0) * 100))
        if "rbx_light" in o:
            lights.append((o.matrix_world.translation.copy(), list(o["rbx_light"])))
        if o.get("rbx_fx"):
            fx.append((o, o["rbx_fx"], col, mat, tr))
            continue
        suf = "_SPIN" if o.get("rbx_spin") else ("_BOB" if o.get("rbx_bob") else "")
        groups.setdefault(f"M_{col[0]}_{col[1]}_{col[2]}_{mat}_{tr}{suf}", []).append(o)

    for name, members in groups.items():
        bpy.ops.object.select_all(action="DESELECT")
        for o in members:
            o.select_set(True)
        bpy.context.view_layer.objects.active = members[0]
        if len(members) > 1:
            bpy.ops.object.join()
        o = bpy.context.view_layer.objects.active
        o.name = name; o.data.name = name
    for i, (o, tag, col, mat, tr) in enumerate(fx):
        o.name = f"FX_{tag}_{col[0]}_{col[1]}_{col[2]}_{mat}_{tr}_{i}"
    for i, (p, l) in enumerate(lights):
        bpy.ops.mesh.primitive_cube_add(size=0.4, location=p)
        o = bpy.context.active_object
        o.name = f"L_{l[0]}_{l[1]}_{l[2]}_{int(l[3])}_{i}"
        for c in o.users_collection:
            c.objects.unlink(o)
        coll.objects.link(o)

    bpy.ops.object.select_all(action="DESELECT")
    for o in coll.objects:
        o.select_set(True)
        bpy.context.view_layer.objects.active = o
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    os.makedirs(os.path.dirname(out_fbx), exist_ok=True)
    bpy.ops.export_scene.fbx(filepath=out_fbx, use_selection=True, object_types={"MESH"}, apply_unit_scale=True,
                             apply_scale_options="FBX_SCALE_ALL", axis_forward="-Z", axis_up="Y", mesh_smooth_type="FACE",
                             use_mesh_modifiers=True, add_leaf_bones=False, bake_anim=False)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.splitext(out_fbx)[0] + ".blend", copy=True)
    tris = sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in coll.objects)
    return {"objects": len(coll.objects), "tris": tris, "names": sorted(o.name for o in coll.objects)}
