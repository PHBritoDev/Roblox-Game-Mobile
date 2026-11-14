-- Inspecao isolada do Forest Pack oficial do Roblox, sem executar scripts.
local InsertService=game:GetService("InsertService")
local assetId=6432306802
local ok,model=pcall(function() return InsertService:LoadAsset(assetId) end)
if not ok then
 return {kind="forest_asset_probe",success=false,error=tostring(model)}
end
local counts={MeshPart=0,Model=0,Script=0,LocalScript=0,ModuleScript=0,SurfaceAppearance=0,ParticleEmitter=0,Texture=0,Decal=0}
local list={}
for _,child in model:GetDescendants() do
 if counts[child.ClassName]~=nil then counts[child.ClassName]+=1 end
 if child:IsA("Model") then
  local size=child:GetExtentsSize()
  if #list<85 then table.insert(list,{name=child.Name,klass=child.ClassName,sz={math.round(size.X),math.round(size.Y),math.round(size.Z)},mesh= #child:GetDescendants()}) end
 elseif child:IsA("MeshPart") and child.Parent==model then
  if #list<85 then table.insert(list,{name=child.Name,klass="MeshPart",sz={math.round(child.Size.X),math.round(child.Size.Y),math.round(child.Size.Z)}}) end
 end
end
model:Destroy()
return {kind="forest_asset_probe",success=true,assetId=assetId,counts=counts,candidates=list}
