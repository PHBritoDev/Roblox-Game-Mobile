"""Blender offline previsualizer.
IMPORTANT: this is NOT a Roblox screenshot, player footage, or exact lighting.
Uses geometry exported from the Roblox *headless* engine.
Run: blender -b -t 2 --python tools/roblox-qa/render_scene.py
"""
import bpy
import bmesh
import json
import math
import os
from mathutils import Vector, Matrix

# Roblox uses Y-up. Blender uses Z-up. Rotate the complete basis, including parts/cameras.
BASIS = Matrix(((1,0,0),(0,0,-1),(0,1,0)))
def rbpos(p):
    return (p[0], -p[2], p[1])
def rbscale(s):
    return (s[0], s[2], s[1])
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(os.environ.get("PREVIEW_FOLDER", ROOT / "artifacts/visual-preview"))
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

def mesh_object(name, vertices, faces, pos, mat=None):
    mesh=bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj=bpy.data.objects.new(name,mesh)
    bpy.context.collection.objects.link(obj)
    obj.location=pos
    if mat: mesh.materials.append(mat)
    return obj


def box(name, xyz, scale, mat):
    vertices=[(x*scale[0]/2,y*scale[1]/2,z*scale[2]/2)
              for x,y,z in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),
                            (-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
    return mesh_object(name,vertices,[(0,3,2,1),(4,5,6,7),(0,1,5,4),
                                     (1,2,6,5),(2,3,7,6),(3,0,4,7)],xyz,mat)


def cone_object(name, pos, radius1, radius2, depth):
    vertices=[]
    for z,radius in [(-depth/2,radius1),(depth/2,radius2)]:
        vertices.extend([(math.cos(i*math.tau/12)*radius,math.sin(i*math.tau/12)*radius,z) for i in range(12)])
    faces=[tuple(reversed(range(12))),tuple(range(12,24))]
    faces.extend([(i,(i+1)%12,(i+1)%12+12,i+12) for i in range(12)])
    return mesh_object(name,vertices,faces,pos)


for part in scene_data["parts"]:
    name=part["n"]
    if part.get("t",0)>0.7:
        continue
    pos=rbpos(part["p"])
    size=rbscale(part["s"])
    color=part["c"]
    is_forest = part.get("origin") == "ForestPack"
    leaf_card = is_forest and ("Leaf" in name or "leaves" in name.lower())
    trunk_mesh = is_forest and "Trunk" in name
    if part["shape"]=="Ball" or leaf_card:
        # ONLY A PROXY: leaf alpha cards are represented as coarse translucent-looking masses.
        mesh=bpy.data.meshes.new(name)
        bm=bmesh.new()
        bmesh.ops.create_uvsphere(bm,u_segments=12,v_segments=8,radius=1)
        bm.to_mesh(mesh);bm.free()
        obj=bpy.data.objects.new(name,mesh)
        bpy.context.collection.objects.link(obj)
        obj.location=pos
        obj.scale=tuple(v/2 for v in size)
    elif part["shape"] == "Wedge":
        # Roblox WedgePart: +Z face is high; -Z edge is low. Native geometry,
        # unlike the deliberately approximate MeshPart representation below.
        sx,sy,sz=part["s"]
        verts=[rbpos((x*sx/2,y*sy/2,z*sz/2)) for x,y,z in
               [(-1,-1,-1),(1,-1,-1),(-1,-1,1),(1,-1,1),(-1,1,1),(1,1,1)]]
        mesh=bpy.data.meshes.new(name)
        mesh.from_pydata(verts,[],[(0,2,3,1),(2,4,5,3),(0,1,5,4),(0,4,2),(1,3,5)])
        mesh.update()
        obj=bpy.data.objects.new(name,mesh)
        bpy.context.collection.objects.link(obj)
        obj.location=pos
    elif part["shape"] == "Cylinder":
        sx,sy,sz=part["s"]
        obj=cone_object(name,pos,1,1,2)
        # Apply native X-axis cylinder before the instance CFrame is applied.
        for v in obj.data.vertices:
            x,y,z=v.co
            v.co=Vector((z*sx/2,-y*sz/2,x*sy/2))
    elif trunk_mesh:
        # Source mesh branch bounding box is much wider than the physical trunk.
        # A cube of that size incorrectly blacks out cameras and blocks paths in previews.
        obj=cone_object(name,pos,max(0.75,min(size[0],size[1])*0.17),
                        max(0.25,min(size[0],size[1])*0.10),size[2])
    else:
        obj=box(name,pos,size,material(color))
    obj.name=name
    rot=part.get("rot")
    if rot and len(rot)==9:
        matrix=Matrix([rot[0:3],rot[3:6],rot[6:9]])
        obj.rotation_euler=(BASIS @ matrix @ BASIS.transposed()).to_euler()
    if len(obj.data.materials)==0:
        obj.data.materials.append(material(color))

# Terrain surface sampled from the engine at eight-stud spacing. This captures
# height/material layout, not Roblox voxels, textures, water shading or blending.
surface = scene_data.get("terrain")
if not surface:
    raise RuntimeError("Snapshot sem grade Terrain real; regenerar com export_scene.luau")
nx, nz = surface["nx"], surface["nz"]
samples = surface["samples"]
if len(samples) != nx*nz:
    raise RuntimeError("Grade Terrain incompleta; proxy recusado")
vertices = []
for index, (height, _) in enumerate(samples):
    ix, iz = index % nx, index // nx
    vertices.append(rbpos((surface["xMin"]+ix*surface["step"],
                           height if height is not False else 0,
                           surface["zMin"]+iz*surface["step"])))
faces, face_materials = [], []
for iz in range(nz-1):
    for ix in range(nx-1):
        # Clockwise in Roblox X/Z becomes upward-facing in Blender X/-Z.
        indices = (iz*nx+ix, (iz+1)*nx+ix, (iz+1)*nx+ix+1, iz*nx+ix+1)
        if any(samples[index][0] is False for index in indices):
            continue
        names = [samples[index][1] for index in indices]
        # Dominant material preserves the actual warm path and river locations.
        dominant = max(dict.fromkeys(names), key=names.count)
        faces.append(indices)
        face_materials.append(dominant)
mesh = bpy.data.meshes.new("Terrain sampled surface")
mesh.from_pydata(vertices, [], faces)
mesh.update()
ground = bpy.data.objects.new("Terrain RAYCAST PROXY — not Roblox rendering", mesh)
bpy.context.collection.objects.link(ground)
material_indices = {}
for name, rgb in surface["palette"].items():
    material_indices[name] = len(mesh.materials)
    mesh.materials.append(material(rgb, 0.18 if name == "Water" else 0.83))
for polygon, name in zip(mesh.polygons, face_materials):
    polygon.material_index = material_indices[name]

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
def camera_inside_proxy(camera_pos):
    x,y,z = camera_pos
    for item in scene_data["parts"]:
        if item.get("t",0)>0.7:
            continue
        if item.get("origin")=="ForestPack" and "Leaf" in item["n"]:
            # Transparent foliage card bounds are not reliable solid obstructions.
            continue
        px,py,pz=item["p"]
        sx,sy,sz=item["s"]
        if abs(x-px)<sx/2+1 and abs(y-py)<sy/2+1 and abs(z-pz)<sz/2+1:
            return True
    return False

def find_camera_position(initial):
    if not camera_inside_proxy(initial):
        return initial
    # Resolve an enclosed virtual camera deterministically, independent of playtesting.
    options=[]
    for dx in [0,-9,9,-18,18,-30,30,-48,48]:
        for dy in [0,8,16,27,38]:
            for dz in [0,13,-13,25,-25]:
                candidate=(initial[0]+dx,initial[1]+dy,initial[2]+dz)
                score=abs(dx)+0.6*dy+0.85*abs(dz)
                options.append((score,candidate))
    for _,pos in sorted(options,key=lambda item:item[0]):
        if not camera_inside_proxy(pos):
            return pos
    raise RuntimeError("Nenhuma camera livre encontrada no proxy; reposicionar visada")

camera_report=[]
for name, original, target in views:
    camera_pos=find_camera_position(original)
    camera_report.append({"view":name,"originalRobloxCoords":original,
                          "usedRobloxCoords":camera_pos,"adjusted":camera_pos!=original})
    point_camera(rbpos(camera_pos),rbpos(target))
    scn.render.filepath=str(OUT / ("preview_%s.png" % name))
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(scn.camera,do_unlink=True)
print("3 views: synthetic proxy previews; NEVER call these screenshots of Roblox.")

(OUT / "viewpoints.json").write_text(json.dumps(camera_report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
