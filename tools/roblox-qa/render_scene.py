"""Blender offline previsualizer.
IMPORTANT: this is NOT a Roblox screenshot, player footage, or exact lighting.
Uses geometry exported from the Roblox *headless* engine.
Run: blender -b -t 2 --python tools/roblox-qa/render_scene.py
"""
import bpy
import json
import math
from mathutils import Vector, Matrix

# Roblox uses Y-up. Blender uses Z-up. Rotate the complete basis, including parts/cameras.
BASIS = Matrix(((1,0,0),(0,0,-1),(0,1,0)))
def rbpos(p):
    return (p[0], -p[2], p[1])
def rbscale(s):
    return (s[0], s[2], s[1])
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "artifacts/visual-preview"
scene_data = json.loads((OUT / "scene.json").read_text(encoding="utf-8"))
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
scn = bpy.context.scene
scn.render.engine = "CYCLES"
scn.cycles.samples = 8
# Ubuntu distribution Blender is built without Intel OpenImageDenoise.
scn.cycles.use_denoising = False
bpy.context.view_layer.cycles.use_denoising = False
scn.render.resolution_x = 768
scn.render.resolution_y = 432
scn.render.resolution_percentage = 100
scn.render.image_settings.file_format = "PNG"
scn.world.color = (0.32, 0.32, 0.32)
scn.view_settings.view_transform = "Standard"
scn.view_settings.look = "Medium High Contrast"
scn.view_settings.exposure = 0
scn.view_settings.gamma = 1

materials = {}
def material(rgb, roughness=0.83):
    key = tuple(round(float(x), 2) for x in rgb)
    if key in materials:
        return materials[key]
    mat = bpy.data.materials.new(name="Mat_%s" % (len(materials)))
    mat.diffuse_color = (*key, 1.0)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*key, 1)
    shader.inputs["Roughness"].default_value = roughness
    materials[key] = mat
    return mat

def box(name, xyz, scale, mat):
    bpy.ops.mesh.primitive_cube_add(size=1, location=xyz)
    obj=bpy.context.object
    obj.name=name
    obj.dimensions=scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    return obj

for part in scene_data["parts"]:
    name=part["n"]
    if part.get("t",0)>0.7:
        continue
    pos=rbpos(part["p"])
    size=rbscale(part["s"])
    color=part["c"]
    if part["shape"]=="Ball":
        bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=8,radius=1,location=pos)
        obj=bpy.context.object
        obj.scale=tuple(v/2 for v in size)
    else:
        obj=box(name,pos,size,material(color))
    obj.name=name
    rot=part.get("rot")
    if rot and len(rot)==9:
        matrix=Matrix([rot[0:3],rot[3:6],rot[6:9]])
        obj.rotation_euler=(BASIS @ matrix @ BASIS.transposed()).to_euler()
    if len(obj.data.materials)==0:
        obj.data.materials.append(material(color))

# Landscape approximation: Roblox Terrain is not included in the geometry export.
ground=box("Terrain PROXY — not official Roblox", rbpos((0,-1,-95)),rbscale((650,2,780)),material((0.25,0.37,0.25)))
# A secondary ribbon hints at the watercourse; not original terrain geometry.
water=box("Rio PROXY", rbpos((129,0,-91)),rbscale((32,0.35,385)),material((0.20,0.38,0.46),0.15))
sun_data=bpy.data.lights.new(name="Sun proxy",type="SUN")
sun_data.energy=2.35
sun_data.angle=math.radians(9)
sun=bpy.data.objects.new("Golden sun — approximate",sun_data)
bpy.context.collection.objects.link(sun)
sun.rotation_euler=(math.radians(55),math.radians(-22),math.radians(-30))
world=bpy.data.worlds.new("Warm nostalgic sky")
scn.world=world
world.use_nodes=True
world.node_tree.nodes["Background"].inputs["Color"].default_value=(0.43,0.50,0.72,1)
world.node_tree.nodes["Background"].inputs["Strength"].default_value=0.7

def point_camera(location,look_at):
    bpy.ops.object.camera_add(location=location)
    cam=bpy.context.object
    direction=Vector(look_at)-cam.location
    cam.rotation_euler=direction.to_track_quat('-Z','Y').to_euler()
    cam.data.lens=29
    scn.camera=cam

views=[
    ("spawn", (2,13,38), (0,26,-225)),
    ("approach", (-18,18,-155), (0,35,-266)),
    ("canopy", (76,64,-175), (0,34,-265)),
]
for name, camera_pos, target in views:
    point_camera(rbpos(camera_pos),rbpos(target))
    scn.render.filepath=str(OUT / ("preview_%s.png" % name))
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(scn.camera,do_unlink=True)
print("3 views: synthetic proxy previews; NEVER call these screenshots of Roblox.")
