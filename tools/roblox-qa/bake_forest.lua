-- Run with rbxmk run --desc-latest tools/roblox-qa/bake_forest.lua CACHE_DIRECTORY
local cache=assert(..., 'Provide directory containing the two original .rbxm files')
local library=Instance.new('Folder'); library.Name='ForestLibrary'
local allowed={Folder=true,Model=true,MeshPart=true,SurfaceAppearance=true}
local forestNames={BeechwoodTreeLarge_Var01=true,BeechwoodTree_Var01=true,BeechwoodTree_Var02=true,BeechwoodTree_Var03=true,BroadLeafTree_Var01=true,DogwoodTree_Var01=true,MapleLeafTreeVar01=true,['RedwoodTree-Var01']=true}
local syntyNames={}
local source=fs.read('src/server/DreamcoreWorld.server.luau','txt')
for name in source:gmatch('"(Meshes/[^"\n]+)"') do syntyNames[name]=true end
for _,entry in ipairs({{6432306802,'ForestPack'},{6933438443,'Synty'}}) do
 local root=fs.read(cache..'/'..entry[1]..'.rbxm')
 local folder=Instance.new('Folder'); folder.Name=entry[2]; folder.Parent=library
 local seen={}
 for _,obj in ipairs(root:GetDescendants()) do
  local low=obj.Name:lower()
  local shrub=obj.ClassName=='Model' and (low:find('fern',1,true) or low:find('bush',1,true) or low:find('shrub',1,true) or low:find('laurel',1,true))
  local selected=entry[2]=='ForestPack' and (forestNames[obj.Name] or shrub) or entry[2]=='Synty' and syntyNames[obj.Name]
  if selected and not seen[obj.Name] then
   local clone=obj:Clone()
   for _,child in ipairs(clone:GetDescendants()) do
    if not allowed[child.ClassName] then child:Destroy() end
   end
   clone.Parent=folder; seen[obj.Name]=true
  end
 end
 print(entry[2],#folder:GetChildren(),#folder:GetDescendants())
end
fs.write('assets/ForestLibrary.rbxmx',library)
