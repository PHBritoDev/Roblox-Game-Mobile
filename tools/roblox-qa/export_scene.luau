-- ANEXAR apos o codigo do gerador do mundo (na mesma sessao de Luau).
-- Execucao headless em memoria: NAO salva Place nem captura viewport real.
local snapshot = {
 kind = "roblox_headless_geometry_snapshot",
 visualCapture = false,
 saved = false,
 generated = world ~= nil,
 parts = {},
 meta = {
  clock = Lighting.ClockTime,
  brightness = Lighting.Brightness,
  ambient = { Lighting.Ambient.R, Lighting.Ambient.G, Lighting.Ambient.B },
  descendantCount = #world:GetDescendants(),
  forestModels = world:GetAttribute("ForestMeshTrees") or 0,
  forestUndergrowthModels = world:GetAttribute("ForestUndergrowthModels") or 0,
  forestUndergrowthVariants = world:GetAttribute("ForestUndergrowthVariants") or 0,
  worldVersion = world:GetAttribute("WorldVersion") or 0,
 }
}
local all = {}
for _, instance in world:GetDescendants() do
 if instance:IsA("BasePart") then
  table.insert(all, instance)
 end
end
-- Exportar todas as partes para que galhos e copas nao aparecam soltos na previsualizacao.
-- Caso o mundo cresca muito, pode ser necessario dividir snapshots em blocos.
local stride = math.max(1, math.ceil(#all / 1600))
for index, item in all do
 local important = item:IsA("SpawnLocation") or item:FindFirstAncestor("Arvore da Primeira Memoria") ~= nil
 if index % stride == 0 or important then
  local cf = item.CFrame
  local x,y,z,r00,r01,r02,r10,r11,r12,r20,r21,r22 = cf:GetComponents()
  table.insert(snapshot.parts, {
   n = item.Name,
   origin = if item:FindFirstAncestor("Bosque premium — Forest Pack licenciado") then "ForestPack" else if item:FindFirstAncestor("Vegetacao licenciada Roblox — Synty Nature") then "Synty" else "Authored",
   shape = if item:IsA("Part") then item.Shape.Name else "MeshPart",
   p = {math.round(x*100)/100,math.round(y*100)/100,math.round(z*100)/100},
   s = {math.round(item.Size.X*100)/100,math.round(item.Size.Y*100)/100,math.round(item.Size.Z*100)/100},
   c = {math.round(item.Color.R*1000)/1000,math.round(item.Color.G*1000)/1000,math.round(item.Color.B*1000)/1000},
   rot = {r00,r01,r02,r10,r11,r12,r20,r21,r22},
   t = item.Transparency,
  })
 end
end
snapshot.meta.partsTotal = #all
snapshot.meta.partsExported = #snapshot.parts
return snapshot
