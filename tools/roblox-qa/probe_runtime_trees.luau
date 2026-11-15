-- Probe de leitura em sessao isolada da engine; sem publicar/parentear no Workspace.
-- Testa exatamente o metodo InsertService usado pelo Place V14.
local InsertService = game:GetService("InsertService")
local packs = {
 {name="Synty", id=6933438443,
  required={"Meshes/Pine_Tree_Pine_Large_01","Meshes/PolygonNature_Tree_Round_04",
   "Meshes/PolygonNature_Tree_PolyPine_03","Meshes/Fern_Plant_Fern_Leaves_01"}},
 {name="ForestPack", id=6432306802,
  required={"BeechwoodTreeLarge_Var01","BeechwoodTree_Var01","MapleLeafTreeVar01",
   "RedwoodTree-Var01"}},
}
local results = {}
for _,pack in packs do
 local ok,asset=pcall(function() return InsertService:LoadAsset(pack.id) end)
 local row={name=pack.name,assetId=pack.id,loadSucceeded=ok and asset~=nil,
  meshParts=0,surfaceAppearance=0,activeScripts=0,missingNames={},error=nil}
 if not ok or asset==nil then
  row.error=string.sub(tostring(asset),1,250)
 else
  local available={}
  for _,item in asset:GetDescendants() do
   if item:IsA("MeshPart") then row.meshParts+=1 end
   if item:IsA("SurfaceAppearance") then row.surfaceAppearance+=1 end
   if item:IsA("LuaSourceContainer") then row.activeScripts+=1 end
   available[item.Name]=true
  end
  for _,name in pack.required do
   if not available[name] then table.insert(row.missingNames,name) end
  end
  asset:Destroy()
 end
 table.insert(results,row)
end
return {kind="dreamcore_runtime_tree_asset_probe",placeVersion=game.PlaceVersion,
 results=results,mutatedPlace=false,robloxScreenshot=false}
