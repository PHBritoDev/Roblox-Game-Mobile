-- ANEXAR apos o codigo do gerador do mundo (na mesma sessao de Luau).
-- Execucao headless em memoria: NAO salva Place nem captura viewport real.
local snapshot = {
 kind = "roblox_headless_geometry_snapshot",
 visualCapture = false,
 saved = false,
 generated = world ~= nil,
 parts = {},
 meta = {
  storedPlaceVersion = storedPlaceVersion,
  storedWorldVersion = storedWorldVersion,
  generationComplete = world:GetAttribute("GenerationComplete") == true,
  clock = Lighting.ClockTime,
  brightness = Lighting.Brightness,
  ambient = { Lighting.Ambient.R, Lighting.Ambient.G, Lighting.Ambient.B },
  descendantCount = #world:GetDescendants(),
  generatedPartCount = world:GetAttribute("GeneratedPartCount"),
  generatedMeshPartCount = world:GetAttribute("GeneratedMeshPartCount"),
  generatedNonCollidingPartCount = world:GetAttribute("GeneratedNonCollidingPartCount"),
  generationSeconds = world:GetAttribute("GenerationSeconds"),
  forestModels = world:GetAttribute("ForestMeshTrees") or 0,
  forestUndergrowthModels = world:GetAttribute("ForestUndergrowthModels") or 0,
  forestUndergrowthVariants = world:GetAttribute("ForestUndergrowthVariants") or 0,
  worldVersion = world:GetAttribute("WorldVersion") or 0,
 }
}
snapshot.assets = {
 source=world:GetAttribute("AssetSource"),
 syntyLoad=world:GetAttribute("SyntyLoadSucceeded"),
 forestLoad=world:GetAttribute("ForestPackLoadSucceeded"),
 syntyIntegration=world:GetAttribute("SyntyIntegrationSucceeded"),
 forestIntegration=world:GetAttribute("ForestPackIntegrationSucceeded"),
 undergrowthStatus=world:GetAttribute("ForestUndergrowthLoadStatus"),
 undergrowthFailures=world:GetAttribute("ForestUndergrowthPlacementFailures"),
 undergrowthFirstError=world:GetAttribute("ForestUndergrowthFirstPlacementError"),
 reserved=world:GetAttribute("ReservedTreeSites"), fulfilled=world:GetAttribute("FulfilledTreeSites"),
 authoredTrees=world:GetAttribute("AuthoredTreeCount"),
 foliageBalls=0, meshes=0, emptyMeshIds=0, surfaces=0,
}
for _,item in world:GetDescendants() do
 if item:IsA("SurfaceAppearance") then snapshot.assets.surfaces+=1 end
 if item:IsA("MeshPart") then
  snapshot.assets.meshes+=1
  if item.MeshId=="" then snapshot.assets.emptyMeshIds+=1 end
 end
 if item:IsA("Part") and item.Shape==Enum.PartType.Ball
  and (item:FindFirstAncestor("Bosque profundo — arvores") or item:FindFirstAncestor("Arvore da Primeira Memoria") or item:FindFirstAncestor("Salgueiros da margem — copa pendente")) then
  snapshot.assets.foliageBalls+=1
 end
end
local all = {}
for _, instance in world:GetDescendants() do
 if instance:IsA("BasePart") then
  table.insert(all, instance)
 end
end
-- Exportar todas as partes para que galhos e copas nao aparecam soltos na previsualizacao.
-- Caso o mundo cresca muito, pode ser necessario dividir snapshots em blocos.
assert(#all<=6500,"Orcamento de 6500 partes excedido; revisar densidade antes de exportar")
local stride = 1
for index, item in all do
 local important = item:IsA("SpawnLocation") or item:FindFirstAncestor("Arvore da Primeira Memoria") ~= nil
 if index % stride == 0 or important then
  local cf = item.CFrame
  local x,y,z,r00,r01,r02,r10,r11,r12,r20,r21,r22 = cf:GetComponents()
  table.insert(snapshot.parts, {
   n = item.Name,
   origin = if item:FindFirstAncestor("Bosque premium — Forest Pack licenciado") then "ForestPack" else if item:FindFirstAncestor("Vegetacao licenciada Roblox — Synty Nature") then "Synty" else "Authored",
   shape = if item:IsA("WedgePart") then "Wedge" else if item:IsA("Part") then item.Shape.Name else "MeshPart",
   meshId = if item:IsA("MeshPart") then item.MeshId else nil,
   textureId = if item:IsA("MeshPart") then item.TextureID else nil,
   p = {math.round(x*100)/100,math.round(y*100)/100,math.round(z*100)/100},
   s = {math.round(item.Size.X*100)/100,math.round(item.Size.Y*100)/100,math.round(item.Size.Z*100)/100},
   c = {math.round(item.Color.R*1000)/1000,math.round(item.Color.G*1000)/1000,math.round(item.Color.B*1000)/1000},
   rot = {r00,r01,r02,r10,r11,r12,r20,r21,r22},
   t = item.Transparency,
   collide = item.CanCollide,
   query = item.CanQuery,
   touch = item.CanTouch,
   collisionRole = item:GetAttribute("CollisionRole"),
  })
 end
end
snapshot.meta.partsTotal = #all
snapshot.meta.partsExported = #snapshot.parts
snapshot.meta.geometrySampled = #snapshot.parts < #all
-- Physical checks run against the actual generated scene, never Blender bounds.
-- RespectCanCollide includes collision proxies even when visual meshes are query-disabled.
local supportParams = RaycastParams.new()
supportParams.FilterType = Enum.RaycastFilterType.Include
supportParams.FilterDescendantsInstances = {terrain, world}
supportParams.RespectCanCollide = true
supportParams.IgnoreWater = true
local clearanceParams = OverlapParams.new()
clearanceParams.FilterType = Enum.RaycastFilterType.Include
clearanceParams.FilterDescendantsInstances = {world}
clearanceParams.RespectCanCollide = true
-- Temporary query volume outside the generated world: never exported or published.
local clearanceProbe = Instance.new("Part")
clearanceProbe.Name = "QA standing clearance probe"
clearanceProbe.Anchored = true
clearanceProbe.CanCollide = false
clearanceProbe.CanTouch = false
clearanceProbe.CanQuery = false
clearanceProbe.Transparency = 1
clearanceProbe.Size = Vector3.new(2,4.8,2)
clearanceProbe.Parent = Workspace
local navigation = {routes = {}, spawn = {}, proxyCount = 0, invalidProxies = {}, activeScripts = {}}
local function sampleFooting(position)
 local hit = Workspace:Raycast(Vector3.new(position.X,12,position.Z),Vector3.new(0,-24,0),supportParams)
 local sample = {x = position.X, z = position.Z, supported = hit ~= nil, blockers = {}}
 if hit then
  sample.y = hit.Position.Y
  sample.normalY = hit.Normal.Y
  sample.support = hit.Instance.Name
  -- Standing body, feet +0.35 through +5.15. Broad-phase bounds only find
  -- candidates; narrow phase tests actual collision geometry, including trunks.
  clearanceProbe.CFrame = CFrame.new(position.X,hit.Position.Y+2.75,position.Z)
  local candidates = Workspace:GetPartBoundsInBox(clearanceProbe.CFrame,clearanceProbe.Size,clearanceParams)
  if #candidates > 0 then
   for _,blocker in Workspace:GetPartsInPart(clearanceProbe,clearanceParams) do
    if blocker ~= hit.Instance then table.insert(sample.blockers,blocker.Name) end
   end
  end
 end
 return sample
end
local function addRoute(name, positions)
 local route = {name = name, samples = {}}
 for _,position in positions do table.insert(route.samples,sampleFooting(position)) end
 table.insert(navigation.routes,route)
end
for _,offset in {-4,0,4} do
 local positions = {}
 for index=0,139 do
  local z=24-index*2
  table.insert(positions,Vector3.new(pathX(z)+offset,0,z))
 end
 addRoute("main:"..offset,positions)
end
local actualBridge = world:FindFirstChild("Ponte de madeira antiga",true)
if actualBridge and actualBridge:IsA("BasePart") then
 local alongX = actualBridge.Size.X > actualBridge.Size.Z
 local halfLength = (if alongX then actualBridge.Size.X else actualBridge.Size.Z)*0.5
 for _,offset in {-3,0,3} do
  local positions = {}
  local steps = math.ceil((halfLength+10)*2/2)
  for index=0,steps do
   local distance = -(halfLength+10)+(halfLength+10)*2*index/steps
   local localPosition = if alongX then Vector3.new(distance,0,offset) else Vector3.new(offset,0,distance)
   table.insert(positions,actualBridge.CFrame:PointToWorldSpace(localPosition))
  end
  addRoute("bridge:"..offset,positions)
 end
end
for _,destination in {{name="lake",x=-62,z=-151},{name="river",x=105,z=-89}} do
 for _,offset in {-3,0,3} do
  local positions = {}
  local startX = pathX(destination.z)
  local steps = math.ceil(math.abs(destination.x-startX)/2)
  for index=0,steps do
   table.insert(positions,Vector3.new(startX+(destination.x-startX)*index/steps,0,destination.z+offset))
  end
  addRoute(destination.name..":"..offset,positions)
 end
end
local actualSpawn = world:FindFirstChildWhichIsA("SpawnLocation",true)
if actualSpawn then
 navigation.spawn = {
  present=true, anchored=actualSpawn.Anchored, collidable=actualSpawn.CanCollide,
  footing=sampleFooting(actualSpawn.Position),
 }
else
 navigation.spawn = {present=false}
end
for _,item in world:GetDescendants() do
 if item:IsA("LuaSourceContainer") then table.insert(navigation.activeScripts,item:GetFullName()) end
 if item:IsA("BasePart") and item:GetAttribute("CollisionRole") then
  navigation.proxyCount += 1
  if not item.Anchored or not item.CanCollide or not item.CanQuery or item.CanTouch then
   table.insert(navigation.invalidProxies,item:GetFullName())
  end
 end
end
clearanceProbe:Destroy()
snapshot.navigation = navigation
-- Surface grid from actual Terrain raycasts: coarse geometry/material evidence,
-- not engine rendering. Water is included rather than replaced with a fake ribbon.
local terrainParams = RaycastParams.new()
terrainParams.FilterType = Enum.RaycastFilterType.Include
terrainParams.FilterDescendantsInstances = {terrain}
terrainParams.IgnoreWater = false
local surface = {xMin=-300,zMin=-400,step=8,nx=76,nz=76,samples={},palette={}}
for iz=0,surface.nz-1 do
 for ix=0,surface.nx-1 do
  local x=surface.xMin+ix*surface.step
  local z=surface.zMin+iz*surface.step
  local hit=Workspace:Raycast(Vector3.new(x,128,z),Vector3.new(0,-256,0),terrainParams)
  if hit then
   local name=hit.Material.Name
   if not surface.palette[name] then
    local color=if hit.Material==Enum.Material.Water then terrain.WaterColor else terrain:GetMaterialColor(hit.Material)
    surface.palette[name]={color.R,color.G,color.B}
   end
   table.insert(surface.samples,{math.round(hit.Position.Y*100)/100,name})
  else
   table.insert(surface.samples,{false,"Air"})
  end
 end
end
snapshot.terrain = surface
return snapshot
