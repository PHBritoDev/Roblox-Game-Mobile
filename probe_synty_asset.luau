-- Testa um pacote publicado por @Roblox em sessao isolada da engine.
-- Nao publica, NAO faz parent no Workspace, NAO executa Scripts de terceiros.
local InsertService=game:GetService("InsertService")
local assetId=6933438443 -- Synty Nature Pack by @Roblox (licenca anunciada no Developer Forum)
local ok,model=pcall(function() return InsertService:LoadAsset(assetId) end)
if not ok then
 return {kind="asset_probe",assetId=assetId,success=false,error=tostring(model)}
end
local stats={Model=0,MeshPart=0,Part=0,Script=0,LocalScript=0,ModuleScript=0}
local roots={}
for _,item in model:GetDescendants() do
 if stats[item.ClassName]~=nil then stats[item.ClassName]+=1 end
end
for _,child in model:GetChildren() do
 table.insert(roots,{name=child.Name,class=child.ClassName})
end
model:Destroy()
return {kind="asset_probe",assetId=assetId,success=true,stats=stats,roots=roots}
