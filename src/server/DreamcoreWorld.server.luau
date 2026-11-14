-- Mundo 1 | Floresta das Memorias: composicao cinematografica original.
-- Referencias de direcao de arte: fantasia anime e paisagens pintadas, sem copiar assets.
-- Construido no servidor; performance mobile: folhagem ancorada, poucos emissores/luzes.
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
ReplicatedStorage:SetAttribute("ForestState","Generating")
ReplicatedStorage:SetAttribute("ForestVersion",32)
ReplicatedStorage:SetAttribute("ForestStage","Starting")
ReplicatedStorage:SetAttribute("ForestErrorCode","")
local function stage(value)
 ReplicatedStorage:SetAttribute("ForestStage",value)
end
local terrain = Workspace.Terrain
local rng = Random.new(67001)
local PI = math.pi

local world
local pathX
local function generateWorld()
local old = Workspace:FindFirstChild("DreamcoreGenerated")
if old then old:Destroy() end
world = Instance.new("Folder")
world.Name = "DreamcoreGenerated"
world.Parent = Workspace
stage("ClearingTerrain")
terrain:Clear()
-- Materiais e vento fazem parte da qualidade: grama se move mesmo sem VFX extra.
-- Decoration e GrassLength sao propriedades NotScriptable na engine Roblox.
-- Nunca ajustar via script: isso abortava o gerador antes do Terrain e Spawn.
terrain.WaterColor=Color3.fromRGB(71,144,137)
terrain.WaterTransparency=0.32
terrain.WaterReflectance=0.2
terrain.WaterWaveSize=0.18
terrain.WaterWaveSpeed=7
terrain:SetMaterialColor(Enum.Material.Grass,Color3.fromRGB(89,135,92))
terrain:SetMaterialColor(Enum.Material.LeafyGrass,Color3.fromRGB(72,118,82))
terrain:SetMaterialColor(Enum.Material.Ground,Color3.fromRGB(125,108,84))
terrain:SetMaterialColor(Enum.Material.Rock,Color3.fromRGB(119,124,125))
Workspace.GlobalWind=Vector3.new(4.5,0,1.8)

local P = {
 earth = Color3.fromRGB(83, 94, 72),
 moss = Color3.fromRGB(73, 116, 74),
 mossLight = Color3.fromRGB(112, 154, 98),
 canopy = Color3.fromRGB(63, 113, 95),
 canopyMid = Color3.fromRGB(91, 148, 105),
 canopyGold = Color3.fromRGB(173, 174, 103),
 bark = Color3.fromRGB(80, 69, 82),
 barkLight = Color3.fromRGB(118, 99, 91),
 stone = Color3.fromRGB(143, 151, 140),
 rune = Color3.fromRGB(234, 213, 153),
 river = Color3.fromRGB(91, 149, 155),
 flower = Color3.fromRGB(245, 191, 198),
 blue = Color3.fromRGB(147, 191, 221),
 firefly = Color3.fromRGB(255, 229, 146),
}

local function part(name, size, cf, color, material, parent)
 local p = Instance.new("Part")
 p.Name = name
 p.CanTouch = false
 p.Anchored = true
 p.Size = size
 p.CFrame = cf
 p.Color = color
 p.Material = material or Enum.Material.SmoothPlastic
 p.TopSurface = Enum.SurfaceType.Smooth
 p.BottomSurface = Enum.SurfaceType.Smooth
 p.CastShadow = true
 p.Parent = parent or world
 return p
end
local function orb(name, pos, scale, color, material, parent)
 local p = part(name, Vector3.new(scale,scale,scale), CFrame.new(pos), color, material, parent)
 p.Shape = Enum.PartType.Ball
 return p
end
local function between(name, a, b, width, color, material, parent)
 local midpoint = (a+b)*0.5
 local segment = part(name, Vector3.new(width,(b-a).Magnitude,width),
  CFrame.lookAt(midpoint,b)*CFrame.Angles(PI/2,0,0), color, material, parent)
 return segment
end
-- Folhagem decorativa: sem física, eventos de toque ou raycasts.
-- RenderFidelity.Automatic permite LOD do motor sem destruir os detalhes próximos.
local function optimizeDecorativeMesh(item,shadow)
 if not item:IsA("BasePart") then return end
 item.Anchored=true
 item.CanCollide=false
 item.CanTouch=false
 item.CanQuery=false
 item.CastShadow=shadow
 if item:IsA("MeshPart") then
  item.RenderFidelity=Enum.RenderFidelity.Automatic
 end
end

local function solidMesh(item)
 item.CanCollide=true
 item.CanQuery=true
 item.CanTouch=false
 item:SetAttribute("CollisionRole","Trunk")
end
local function trunkProxy(x,z,height,diameter,parent)
 local proxy=part("Colisao de tronco",Vector3.new(diameter,height,diameter),
  CFrame.new(x,height*0.5,z),P.bark,Enum.Material.Wood,parent)
 proxy.Transparency=1
 proxy.CastShadow=false
 proxy:SetAttribute("CollisionRole","Trunk")
 return proxy
end

local function group(name)
 local folder = Instance.new("Folder")
 folder.Name = name
 folder.Parent = world
 return folder
end
local props=group("Bosque profundo — arvores")
local details=group("Vegetacao baixa e rochas")
local landmarks=group("Pontos de interesse")
local effects=group("Luzes e atmosfera diegetica")

-- Um unico campo de voxels: a troca de material nao altera a altura do piso.
-- Resolucao nativa 4 studs; camada superior meia ocupada fixa a isosuperficie em Y=0.
-- Medido na engine: ocupacao cheia nesta camada projetava o piso em Y=2.
pathX = function(z)
 return math.sin((z+5)*0.027)*10 + math.sin(z*0.059)*2.5
end
local function riverX(z)
 return 125+math.sin((115-z)/23*0.32)*24
end
local function inWalkway(x,z,margin)
 return (z>=-254 and z<=32 and math.abs(x-pathX(z))<10+margin)
  or (x>=pathX(-89) and x<=176 and math.abs(z+89)<8+margin)
  or (x>=-64 and x<=pathX(-151) and math.abs(z+151)<6+margin)
end
local function reservedSite(x,z,margin)
 return (math.abs(z+151)<27 and x>-90 and x<5)
  or (math.abs(z+89)<24 and x>5 and x<176)
  or inWalkway(x,z,margin) or math.abs(x-riverX(z))<25+margin
  or ((x+84)^2+(z+151)^2)<(22+margin)^2
end
stage("BuildingGround")
terrain:FillBlock(CFrame.new(0,-28,-92),Vector3.new(680,24,792),Enum.Material.Ground)
local materials,occupancies={},{}
for ix=1,170 do
 materials[ix]={}; occupancies[ix]={}
 for iy=1,4 do materials[ix][iy]={}; occupancies[ix][iy]={} end
 -- Distribui trabalho volumetrico por frames, evitando timeout do script no servidor.
 if ix%4==0 then task.wait() end
 for iz=1,198 do
  local x,z=-340+(ix-0.5)*4,-488+(iz-0.5)*4
  local waterDistance=math.min(math.abs(x-riverX(z))-14,math.sqrt((x+84)^2+(z+151)^2)-11)
  local bed=-2-9*(1-math.clamp(waterDistance/9,0,1))
  local noise=math.noise(x/39,z/39,6.7)+0.32*math.noise(x/13,z/13,2)
  local trail=inWalkway(x,z,0.8*math.noise(x/11,z/11,4))
  local surface=if trail then Enum.Material.Ground else
   if noise>0.12 then Enum.Material.LeafyGrass else
   if noise < -0.26 then Enum.Material.Ground else Enum.Material.Grass
  for iy=1,4 do
   local bottom=-16+(iy-1)*4
   local solid=math.clamp((bed-bottom)/4,0,1)
   local water=math.clamp((-4-bottom)/4,0,1)
   -- A camada mais alta de agua ocupa apenas meio voxel; margens continuam solidas.
   materials[ix][iy][iz]=if solid>0 then surface else if water>0 then Enum.Material.Water else Enum.Material.Air
   occupancies[ix][iy][iz]=if solid>0 then solid else water
  end
 end
end
stage("WritingTerrain")
terrain:WriteVoxels(Region3.new(Vector3.new(-340,-16,-488),Vector3.new(340,0,304)),4,materials,occupancies)
materials=nil; occupancies=nil
-- WriteVoxels atualiza colisao assincronamente. Nao depender do tempo de LoadAsset.
local readiness=RaycastParams.new()
readiness.FilterType=Enum.RaycastFilterType.Include
readiness.FilterDescendantsInstances={terrain}
readiness.IgnoreWater=true
-- V30: a colisao do Terrain e calculada de forma assincrona em servidores
-- publicos. O antigo assert apos 10s abortava o mundo inteiro no Android.
-- A espera e limitada; se a fisica demorar, o spawn solido garante apoio
-- enquanto a engine termina de atualizar o solo. Nao ocultar a falha.
local readyDeadline=time()+20
local floorReady=false
repeat
 task.wait(0.15)
 floorReady=true
 for _,point in {Vector3.new(0,12,24),Vector3.new(0,12,-254),Vector3.new(90,12,-89),Vector3.new(-54,12,-151)} do
  local hit=Workspace:Raycast(point,Vector3.new(0,-24,0),readiness)
  if not hit or math.abs(hit.Position.Y)>0.45 then floorReady=false break end
 end
until floorReady or time()>=readyDeadline
if not floorReady then
 warn("[Dreamcore] Colisao do terreno ainda pendente; continuando a gerar arvores e spawn.")
end

stage("PlantingForest")
-- Folhas originais achatadas nas bordas; sem colisao, sombras ou alpha cards extras.
for i=1,90 do
 local z=24-i*3.05
 local side=if i%2==0 then 1 else -1
 local x=pathX(z)+side*rng:NextNumber(8.5,16)
 if not inWalkway(x,z,-2) then
  local leaf=part("Folha caida original",Vector3.new(rng:NextNumber(0.4,0.9),0.07,rng:NextNumber(0.8,1.5)),
   CFrame.new(x,0.12,z)*CFrame.Angles(0,rng:NextNumber(0,2*PI),0),
   if i%3==0 then P.canopyGold else P.moss,Enum.Material.Grass,details)
  optimizeDecorativeMesh(leaf,false)
 end
end

-- Spawn discreto, integrado no caminho, sem plataforma brilhante artificial.
local spawn=Instance.new("SpawnLocation")
spawn.Name="Nascimento Dreamcore"
spawn.Size=Vector3.new(13,1,13)
spawn.CFrame=CFrame.new(pathX(8),-0.45,8)
spawn.Anchored=true
spawn.Neutral=true
spawn.Material=Enum.Material.Grass
spawn.Color=P.moss
spawn.Transparency=1
spawn.CanTouch=false
spawn.Duration=0
spawn.CanCollide=true
spawn.Parent=world

-- Fallback sem assets: copas em leques escalonados, nao esferas empilhadas.
-- Folhagem nao-colisiva, tronco solido; usa apenas primitivas nativas.
local function branchTree(x,z,s,family)
 local h=19*s
 local tilt=rng:NextNumber(-0.11,0.11)
 local tint=if rng:NextNumber()<0.18 then P.canopyGold else
  if rng:NextNumber()<0.52 then P.canopyMid else P.canopy
 local trunk=part("Tronco organico inclinado",Vector3.new(2.6*s,h,2.6*s),
  CFrame.new(x,h*0.5,z)*CFrame.Angles(tilt,0,tilt*0.6),
  P.bark,Enum.Material.Wood,family)
 trunk.Shape=Enum.PartType.Cylinder
 trunk:SetAttribute("CollisionRole","Trunk")
 -- Silhueta irregular: camadas afiladas de folhas elipticas em orientacoes distintas.
 -- 12 laminas por arvore, sombras somente nas mais altas para conter custo Android.
 for tier=1,3 do
  local height=h*(0.48+tier*0.155)
  local spread=(9.8-tier*1.75)*s
  for petal=1,4 do
   local angle=(petal-1)*PI*0.5+tier*0.43+rng:NextNumber(-0.17,0.17)
   local reach=spread*rng:NextNumber(0.82,1.12)
   local dx=math.cos(angle)*reach*0.53
   local dz=math.sin(angle)*reach*0.53
   local stem=Vector3.new(x+tilt*height*0.35,height-2*s,z)
   local tip=stem+Vector3.new(dx,height*0.075+2.2*s,dz)
   local twig=between("Galho ramificado",stem,tip,0.48*s,P.barkLight,Enum.Material.Wood,family)
   twig.CanCollide=false
   twig.CanQuery=false
   twig.CastShadow=false
   local blade=part("Leque de folhas afilado",
    Vector3.new(3.8*s,1.65*s,reach*1.42),
    CFrame.lookAt((stem+tip)*0.5,tip)*CFrame.Angles(0,angle*0.09,0),
    if petal==1 and tier==2 then P.canopyGold else tint,
    Enum.Material.Grass,family)
   blade.Shape=Enum.PartType.Wedge
   blade.CanCollide=false
   blade.CanQuery=false
   blade.CastShadow=tier==3
  end
 end
 -- Pequena ponta superior sem copa esferica.
 local apex=part("Coroa em ponta",Vector3.new(3.2*s,5*s,3.2*s),
  CFrame.new(x+tilt*h*0.3,h+0.4*s,z),tint,Enum.Material.Grass,family)
 apex.Shape=Enum.PartType.Wedge
 apex.CanCollide=false
 apex.CanQuery=false
end

-- Mistura de copas autorais com futuras arvores MeshPart oficiais.
-- Reserva sitios antes de carregar os modelos: se falhar, usa a arvore original.
local meshTreeSites={}
local forestTreeSites={}
local function plantOrReserve(x,z,s,useMesh)
 if reservedSite(x,z,5) then return end
 if useMesh then
  -- Mesmo afastamento das arvores Forest Pack: a copa nao deve fechar o corredor.
  -- Usa a coordenada real da trilha no Z do exemplar, inclusive nas curvas.
  local offset=x-pathX(z)
  if z>-238 and z<32 and math.abs(offset)<32 then
   x=pathX(z)+(if offset>=0 then 1 else -1)*32
  end
  table.insert(meshTreeSites,{x=x,z=z,s=s})
 elseif math.abs(x-pathX(z))<73 or rng:NextNumber()<0.56 then
  -- Arvores detalhadas enquadram o corredor, mas troncos nao invadem a trilha.
  local path=pathX(z)
  local offset=x-path
  if z>-238 and z<32 and math.abs(offset)<32 then
   x=path+(if offset>=0 then 1 else -1)*(32+rng:NextNumber(0,14))
  end
  table.insert(forestTreeSites,{x=x,z=z,s=s})
 else
  -- Poucas arvores de silhueta simples apenas no fundo.
  branchTree(x,z,s,props)
 end
end

-- Corredor principal: alternar silhuetas sem bloquear a trilha.
for row=0,18 do
 local z=30-row*17
 for _,side in ipairs({-1,1}) do
  local width=rng:NextNumber(23,41)
  local x=pathX(z)+side*width
  local treeZ=z+rng:NextNumber(-6,6)
  local scale=rng:NextNumber(1.12,1.8)
  plantOrReserve(x,treeZ,scale,row%2==0 and side==1)
  if row%2==0 then
   local outerX=x+side*rng:NextNumber(12,25)
   local outerZ=z+rng:NextNumber(-11,11)
   local outerScale=rng:NextNumber(0.8,1.24)
   plantOrReserve(outerX,outerZ,outerScale,row%4==0 and side==-1)
  end
 end
end

-- Floresta exterior: reservas intercaladas, mantendo sites de vegetacao coerentes.
for i=1,68 do
 local x=rng:NextNumber(-275,275)
 local z=rng:NextNumber(-345,175)
 local nearPath=math.abs(x-pathX(z))<19 and z > -300 and z < 35
 local nearRiver=math.abs(x-125-math.sin((115-z)/23*0.32)*24)<23
 if not nearPath and not nearRiver and (x*x+(z+110)*(z+110))>900 then
  plantOrReserve(x,z,rng:NextNumber(0.75,1.38),i%3==0)
 end
end

-- Arvores ribeirinhas: silhueta pendente, diferente das copas redondas do bosque.
-- Colocadas manualmente fora da trilha para criar contraste e enquadrar o rio.
local willow=group("Salgueiros da margem — copa pendente")
local function riverWillow(x,z,scale)
 local h=20*scale
 local bend=rng:NextNumber(-3,3)
 local start=Vector3.new(x,0.8,z)
 local trunkTop=Vector3.new(x+bend,h,z)
 between("Tronco curvo ribeirinho",start,trunkTop,2.7*scale,P.bark,Enum.Material.Wood,willow)
 local shade=if rng:NextNumber()<0.45 then P.canopyMid else P.canopy
 local crown=orb("Dossel de salgueiro",trunkTop+Vector3.new(0,1.8*scale,0),
  11*scale,shade,Enum.Material.Grass,willow)
 crown.Size=Vector3.new(19*scale,5.5*scale,15*scale)
 crown.CanCollide=false
 for j=1,8 do
  local angle=(j/8)*PI*2
  local reach=rng:NextNumber(6.5,10)*scale
  local top=trunkTop+Vector3.new(math.cos(angle)*reach,1.9*scale,math.sin(angle)*reach)
  between("Galho flexivel",trunkTop,top,0.68*scale,P.barkLight,Enum.Material.Wood,willow).CanCollide=false
  local drop=rng:NextNumber(7,12)*scale
  local veil=orb("Véu vegetal pendente",top+Vector3.new(0,-drop/2,0),
   4.2*scale,shade,Enum.Material.Grass,willow)
  veil.Size=Vector3.new(3.6*scale,drop,3.6*scale)
  veil.CanCollide=false
 end
end
riverWillow(84,64,1.4)
riverWillow(97,18,1.1)
riverWillow(78,-25,1.35)
riverWillow(90,-75,1.17)
riverWillow(83,-144,1.42)
riverWillow(103,-203,1.23)
riverWillow(148,-268,1.36)

-- Asset curado: Synty Nature Pack, publicado por @Roblox (ID 6933438443).
-- Licenca oficial para qualquer jogo Roblox (DevForum Roblox 10/06/2021).
-- Inspecao isolada Open Cloud: 200 MeshParts, 11 Models, zero scripts.
-- Nunca parentear o pacote original nem ativar scripts de terceiros.
local curated=group("Vegetacao licenciada Roblox — Synty Nature")
local InsertService=game:GetService("InsertService")
stage("LoadingSynty")
-- Um asset externo nunca pode abortar o mundo inteiro, mesmo se carregar
-- com sucesso e uma malha/modelo especifico falhar durante a configuracao.
local syntyIntegrated,syntyError=xpcall(function()
local okPack,sourcePack=pcall(function()
 return InsertService:LoadAsset(6933438443)
end)
if okPack and sourcePack then
 for _,asset in sourcePack:GetDescendants() do
  if asset:IsA("LuaSourceContainer") then asset:Destroy() end
 end
 -- Modelos escolhidos, posicionados para manter enquadramento da trilha.
 local selection={
  {"Meshes/Pine_Tree_Pine_Large_01",-70,36,31,0.2},
  {"Meshes/Pine_Tree_Pine_Large_02",65,-24,30,-0.1},
  {"Meshes/PolygonNature_Tree_Round_04",-75,-87,21,0.5},
  {"Meshes/Pine_Tree_Pine_02",68,-137,24,0.1},
  {"Meshes/PolygonNature_Tree_PolyPine_03",-82,-181,31,0.3},
  {"Meshes/Pine_Tree_Pine_01",78,-221,26,-0.4},
  {"Meshes/PolygonNature_Rock_Cluster_Large_05",44,-104,8,0.2},
  {"Meshes/PolygonNature_Rock_Pile_01",-53,-221,6,0.7},
  {"Meshes/PolygonNature_Plant_Grass_05",-18,-58,3,0.1},
  {"Meshes/Undergrowth",26,-139,4,0.3},
  {"Meshes/PolygonNature_Prop_Pillar_Arch_Moss_01",47,-290,17,0.2},
 }
 local lookup={}
 for _,obj in sourcePack:GetDescendants() do
  if obj:IsA("MeshPart") or obj:IsA("Model") then
   if not lookup[obj.Name] then lookup[obj.Name]=obj end
  end
 end
 local placed=0
 for _,entry in selection do
  local template=lookup[entry[1]]
  if template then
   local asset=template:Clone()
   asset.Name="Synty — "..entry[1]
   local desiredHeight=entry[4]
   if asset:IsA("MeshPart") then
    local scale=desiredHeight/math.max(asset.Size.Y,0.1)
    asset.Size=asset.Size*scale
    asset.CFrame=CFrame.new(entry[2],asset.Size.Y/2,entry[3])*CFrame.Angles(0,entry[5],0)
    optimizeDecorativeMesh(asset,math.abs(entry[2]-pathX(entry[3]))<76)
    asset.Parent=curated
   elseif asset:IsA("Model") then
    local extents=asset:GetExtentsSize()
    asset:ScaleTo(asset:GetScale()*desiredHeight/math.max(extents.Y,0.1))
    asset:PivotTo(CFrame.new(entry[2],desiredHeight/2,entry[3])*CFrame.Angles(0,entry[5],0))
    for _,p in asset:GetDescendants() do
     if p:IsA("BasePart") then optimizeDecorativeMesh(p,math.abs(entry[2]-pathX(entry[3]))<76) end
    end
    asset.Parent=curated
   end
   if string.find(entry[1],"Tree",1,true) then
    trunkProxy(entry[2],entry[3],desiredHeight*0.55,desiredHeight*0.065,curated)
   elseif string.find(entry[1],"Rock",1,true) then
    if asset:IsA("BasePart") then
     solidMesh(asset); asset:SetAttribute("CollisionRole","Rock")
    end
   end
   placed+=1
  end
 end
 -- Substituicoes avaliadas pelo agente: reduzir repeticao de copas esfericas.
 -- Tres arvores oficiais de silhuetas distintas, ancoradas e sem scripts.
 -- Vegetacao profissional curada por planos: samambaias e tufos de grama
 -- próximos ao jogador (não espalhar 200 clones pela cena).
 -- Sondagem compartilhada: plantas pequenas nao devem flutuar em colinas.
 local syntyTerrainRayParams=RaycastParams.new()
 syntyTerrainRayParams.FilterType=Enum.RaycastFilterType.Include
 syntyTerrainRayParams.FilterDescendantsInstances={terrain}
 syntyTerrainRayParams.IgnoreWater=true
 local function syntyGroundY(x,z)
  local hit=Workspace:Raycast(Vector3.new(x,160,z),Vector3.new(0,-320,0),syntyTerrainRayParams)
  return if hit then hit.Position.Y else 0
 end
 local fernNames={
  "Meshes/Fern_Plant_Fern_Leaves_01",
  "Meshes/PolygonNature_Plant_Grass_05",
  "Meshes/Undergrowth",
 }
 for i=1,34 do
  local z=25-i*8.1
  local edge=if i%2==0 then 1 else -1
  local x=pathX(z)+edge*(10+(i%4)*3)
  local template=lookup[fernNames[(i-1)%#fernNames+1]]
  if template and template:IsA("MeshPart") then
   local leaf=template:Clone()
   leaf.Name="Synty — estrato de samambaias "..i
   local scale=2.3+rng:NextNumber(0.2,1.6)
   leaf.Size=leaf.Size*(scale/math.max(leaf.Size.Y,0.15))
   leaf.CFrame=CFrame.new(x,syntyGroundY(x,z)+leaf.Size.Y*0.49,z)*CFrame.Angles(0,i*1.81,0)
   optimizeDecorativeMesh(leaf,false)
   leaf.Parent=curated
  end
 end
 local treeTypes={
  "Meshes/Pine_Tree_Pine_Large_01",
  "Meshes/PolygonNature_Tree_Round_04",
  "Meshes/PolygonNature_Tree_PolyPine_03",
 }
 local meshPlaced=0
 for i,site in meshTreeSites do
  local template=lookup[treeTypes[(i-1)%#treeTypes+1]]
  if template and template:IsA("MeshPart") then
   local tree=template:Clone()
   tree.Name="Synty — bosque alternado "..tostring(i)
   local height=site.s*22
   tree.Size=tree.Size*(height/math.max(tree.Size.Y,0.1))
   -- Synty tambem precisa acompanhar o Terrain; antes ficava em Y=0 nas colinas.
   local groundY=syntyGroundY(site.x,site.z)
   tree.CFrame=CFrame.new(site.x,groundY+tree.Size.Y*0.5-0.12,site.z)*CFrame.Angles(0,(i*1.73)%PI,0)
   optimizeDecorativeMesh(tree,math.abs(site.x-pathX(site.z))<76)
   tree.Parent=curated
   trunkProxy(site.x,site.z,height*0.58,math.clamp(height*0.065,1.2,3.5),curated)
   meshPlaced+=1
  else
   branchTree(site.x,site.z,site.s,props)
  end
 end
 print("[Dreamcore] Arvores com silhuetas oficiais:",meshPlaced)
 print("[Dreamcore] Synty licenciado carregado:",placed,"instancias curadas")
 sourcePack:Destroy()
else
 -- Falha na rede/permissao: replanta todos os sitios reservados com vegetacao autoral.
 for _,site in meshTreeSites do
  branchTree(site.x,site.z,site.s,props)
 end
 warn("[Dreamcore] Pacote Synty indisponivel; mantendo vegetacao autoral.")
end

end,debug.traceback)
if not syntyIntegrated then
 warn("[Dreamcore] Synty integracao falhou: "..tostring(syntyError))
 world:SetAttribute("SyntyIntegrationFailed",true)
 ReplicatedStorage:SetAttribute("ForestAssetWarning","Synty")
 -- A area principal, terreno, spawn e iluminacao continuam sendo gerados.
 -- Nao repetir clones no fallback: arvores autorais ja estao distribuidas.
end

-- Forest Pack @Roblox (6432306802): folhas reais em planos com SurfaceAppearance.
-- Baixa uma unica vez, remove todos os scripts, apenas clones curados de Models.
-- Se o pacote falhar, os sites recebem vegetacao original sem quebrar o jogo.
local naturalForest=group("Bosque premium — Forest Pack licenciado")
stage("LoadingForestPack")
local okForest,forestPack=pcall(function()
 return InsertService:LoadAsset(6432306802)
end)
local forestCount=0
local forestHeroBuilt=false
local forestIntegrated,forestError=xpcall(function()
if okForest and forestPack then
 for _,descendant in forestPack:GetDescendants() do
  if descendant:IsA("LuaSourceContainer") then descendant:Destroy() end
 end
 local candidates={}
 local names={
  "BeechwoodTreeLarge_Var01",
  "BeechwoodTree_Var01",
  "BeechwoodTree_Var02",
  "BeechwoodTree_Var03",
  "BroadLeafTree_Var01",
  "DogwoodTree_Var01",
  "MapleLeafTreeVar01",
  "RedwoodTree-Var01",
 }
 for _,obj in forestPack:GetDescendants() do
  if obj:IsA("Model") then
   for _,name in names do
    if obj.Name==name and not candidates[name] then
     candidates[name]=obj
    end
   end
  end
 end
 -- Sondagem unica de Terrain para arvores e plantas importadas.
 local terrainRayParams=RaycastParams.new()
 terrainRayParams.FilterType=Enum.RaycastFilterType.Include
 terrainRayParams.FilterDescendantsInstances={terrain}
 terrainRayParams.IgnoreWater=true
 local function terrainHeightAt(x,z)
  local hit=Workspace:Raycast(Vector3.new(x,160,z),Vector3.new(0,-320,0),terrainRayParams)
  return if hit then hit.Position.Y else 0
 end
 local function plantForest(template,site,index)
  local tree=template:Clone()
  tree.Name="Bosque de folhas texturizadas — "..index
  for _,item in tree:GetDescendants() do
   if item:IsA("LuaSourceContainer") or item:IsA("ParticleEmitter") then item:Destroy()
   elseif item:IsA("BasePart") then
    -- Sombras detalhadas apenas no corredor visível; árvores distantes
    -- preservam silhueta e textura sem gerar dezenas de shadow casters.
    local nearTrail=math.abs(site.x-pathX(site.z))<76
    local nearHero=(site.x-pathX(-245))^2+(site.z+265)^2<110*110
    local keepShadow=(nearTrail and site.z>-315 and site.z<55) or nearHero
    optimizeDecorativeMesh(item,keepShadow)
    if string.find(string.lower(item.Name),"trunk",1,true) then solidMesh(item) end
   end
  end
  local desiredHeight=site.s*(if template.Name=="RedwoodTree-Var01" then 29 else 23)
  local initialBounds=tree:GetExtentsSize()
  tree:ScaleTo(tree:GetScale()*desiredHeight/math.max(initialBounds.Y,0.1))
  local boundingCF,boundingSize=tree:GetBoundingBox()
  local groundY=terrainHeightAt(site.x,site.z)
  local target=CFrame.new(site.x,groundY+boundingSize.Y*0.5-0.12,site.z)*CFrame.Angles(0,index*1.78,0)
  local delta=target*boundingCF:Inverse()
  tree:PivotTo(delta*tree:GetPivot())
  tree.Parent=naturalForest
 end
 for i,site in forestTreeSites do
  local preferred=names[(i-1)%#names+1]
  local template=candidates[preferred] or candidates["BeechwoodTree_Var03"]
  if template then
   local ok=pcall(plantForest,template,site,i)
   if ok then forestCount+=1
   else branchTree(site.x,site.z,site.s,props) end
  else
   branchTree(site.x,site.z,site.s,props)
  end
 end
 -- Arbustos e samambaias com recortes de folhas reais nos primeiros planos.
 -- Mantemos a maioria fora da trilha e evitamos emissor externo dos templates.
 local undergrowthTemplates={}
 -- O pack muda nomes entre variantes; descobrir pela geometria, não por 4 strings rígidas.
 -- Evitar clones vazios e excluir árvores grandes, troncos e rochas.
 for _,item in forestPack:GetDescendants() do
  if item:IsA("Model") and not item:IsDescendantOf(naturalForest) then
   local lower=string.lower(item.Name)
   local isShrub=string.find(lower,"fern",1,true)
    or string.find(lower,"bush",1,true)
    or string.find(lower,"shrub",1,true)
    or string.find(lower,"laurel",1,true)
   if isShrub then
    local hasMesh=false
    for _,desc in item:GetDescendants() do
     if desc:IsA("MeshPart") then hasMesh=true break end
    end
    if hasMesh then
     local okSize,size=pcall(function() return item:GetExtentsSize() end)
     if okSize and size.Y>0.1 and size.Y<55 then
      table.insert(undergrowthTemplates,item)
     end
    end
   end
  end
 end
 -- Ordem estável: a distribuição de espécies não muda com a ordem interna
 -- dos descendentes do pack após uma atualização do asset.
 table.sort(undergrowthTemplates,function(a,b)
  return a:GetFullName()<b:GetFullName()
 end)
 -- Selecionar somente depois de ordenar: o limite anterior dependia da
 -- ordem arbitraria de GetDescendants e mudava as especies entre builds.
 while #undergrowthTemplates>16 do
  table.remove(undergrowthTemplates)
 end
 local undergrowthPlaced=0
 for i=1,58 do
  local template=if #undergrowthTemplates>0 then undergrowthTemplates[(i-1)%#undergrowthTemplates+1] else nil
  if template then
   local z=22-i*4.8
   local side=if i%2==0 then 1 else -1
   local x=pathX(z)+side*(12+(i%5)*4.1)
   local foliage=template:Clone()
   foliage.Name="Estrato baixo texturizado — "..i
   for _,item in foliage:GetDescendants() do
    if item:IsA("LuaSourceContainer") or item:IsA("ParticleEmitter") then
     item:Destroy()
    elseif item:IsA("BasePart") then
     optimizeDecorativeMesh(item,false)
    end
   end
   local okFoliage=pcall(function()
    local extent=foliage:GetExtentsSize()
    local sizeGoal=1.65+(i%5)*0.38
    foliage:ScaleTo(foliage:GetScale()*sizeGoal/math.max(extent.Y,0.1))
    local boundsCF,boundsSize=foliage:GetBoundingBox()
    -- Assentar cada planta no relevo real, sem flutuar nem atravessar
    -- o solo inclinado. Raycast inclui apenas Terrain (nao outros props).
    local groundY=terrainHeightAt(x,z)
    local desired=CFrame.new(x,groundY+boundsSize.Y*0.5-0.08,z)*CFrame.Angles(0,i*0.61,0)
    foliage:PivotTo(desired*boundsCF:Inverse()*foliage:GetPivot())
    foliage.Parent=naturalForest
   end)
   if okFoliage then undergrowthPlaced+=1 else foliage:Destroy() end
  end
 end
 world:SetAttribute("ForestUndergrowthModels",undergrowthPlaced)
 world:SetAttribute("ForestUndergrowthVariants",#undergrowthTemplates)
 local heroTemplate=candidates["BeechwoodTreeLarge_Var01"]
 if heroTemplate then
  local okHero=pcall(plantForest,heroTemplate,{x=pathX(-245),z=-281,s=3.65},9001)
  if okHero then
   forestHeroBuilt=true
   forestCount+=1
  end
 end
 forestPack:Destroy()
else
 for _,site in forestTreeSites do
  branchTree(site.x,site.z,site.s,props)
 end
 warn("[Dreamcore] Forest Pack indisponivel; fallback do bosque ativado.")
end
end,debug.traceback)
if not forestIntegrated then
 warn("[Dreamcore] Forest Pack integracao falhou: "..tostring(forestError))
 world:SetAttribute("ForestPackIntegrationFailed",true)
 ReplicatedStorage:SetAttribute("ForestAssetWarning","ForestPack")
 -- O monumento e a iluminacao seguem com o fallback integrado abaixo.
end
world:SetAttribute("ForestMeshTrees",forestCount)
print("[Dreamcore] Floresta com SurfaceAppearance:",forestCount,"modelos")

-- Landmark: a Arvore da Primeira Memoria, dominante na silhueta.
local sacred=Instance.new("Model")
sacred.Name="Arvore da Primeira Memoria"
sacred.Parent=landmarks
local center=Vector3.new(pathX(-245),0,-281)
local crownY=64
if forestHeroBuilt then
 -- Sem cilindros, raízes geométricas ou tronco invisível sobre a malha hero.
 -- O modelo licenciado é o único volume do marco central.
 world:SetAttribute("HeroUsesMeshOnly",true)
else
 world:SetAttribute("HeroUsesMeshOnly",false)
 local core=part("Cerne antigo",Vector3.new(11,58,11),
  CFrame.new(center.X,29,center.Z),P.barkLight,Enum.Material.Wood,sacred)
 for i=1,8 do
  local a=i*PI/4
  local low=center+Vector3.new(math.cos(a)*9,1,math.sin(a)*9)
  local high=center+Vector3.new(math.cos(a)*3,23,math.sin(a)*3)
  between("Raiz colossal",low,high,3.7,P.bark,Enum.Material.Wood,sacred)
 end
 -- Fallback do marco central somente se a malha licenciada estiver indisponivel.
 for i=1,10 do
  local a=i*PI*2/10
  local start=Vector3.new(center.X,43,center.Z)
  local tip=center+Vector3.new(math.cos(a)*rng:NextNumber(19,34),rng:NextNumber(53,75),
   math.sin(a)*rng:NextNumber(19,34))
  between("Braco da arvore",start,tip,3.8,P.bark,Enum.Material.Wood,sacred)
  local leaves=orb("Dossel dourado",tip+Vector3.new(0,6,0),rng:NextNumber(24,36),
   if i%3==0 then P.canopyGold else P.canopyMid,Enum.Material.Grass,sacred)
  leaves.Size=Vector3.new(leaves.Size.X*1.18,leaves.Size.Y*0.66,leaves.Size.Z*1.12)
  leaves.CanCollide=false
 end
 orb("Coroa do santuario",center+Vector3.new(0,crownY+17,0),42,
  P.canopy,Enum.Material.Grass,sacred).CanCollide=false
end

-- Círculo de pedras cerimoniais, inteligível na aproximação.
for i=1,12 do
 local a=(i/12)*2*PI
 local r=38
 local pos=center+Vector3.new(math.cos(a)*r,3.5,math.sin(a)*r)
 if inWalkway(pos.X,pos.Z,4) then continue end
 local stone=part("Pedra do circulo antigo",Vector3.new(4,7,5),
  CFrame.new(pos)*CFrame.Angles(0,a,rng:NextNumber(-0.08,0.08)),
  P.stone,Enum.Material.Slate,landmarks)
 if i%3==0 then
  local rune=part("Gravura iluminada",Vector3.new(0.4,3,3),
   stone.CFrame*CFrame.new(2.2,0,0),P.rune,Enum.Material.Neon,landmarks)
  rune.CanCollide=false
 end
end

-- Pequenos pontos de interesse: clareira de descanso, margem e ponte.
for i=1,8 do
 local x=pathX(-105)+(if i%2==0 then 1 else -1)*rng:NextNumber(16,24)
 local z=-100+rng:NextNumber(-18,18)
 if inWalkway(x,z,4) then continue end
 local rock=orb("Pedra coberta de musgo",Vector3.new(x,0.8,z),
  rng:NextNumber(3,7),P.stone,Enum.Material.Slate,details)
 rock.Size=Vector3.new(rock.Size.X,2.2,rock.Size.Z)
end
-- Travessia perpendicular ao rio: tabuleiro firme ate as duas margens planas.
local bridge=part("Ponte de madeira antiga",Vector3.new(12,1.2,64),
 CFrame.new(132,-0.35,-89)*CFrame.Angles(0,PI/2,0),P.barkLight,Enum.Material.WoodPlanks,landmarks)
bridge:SetAttribute("CollisionRole","Bridge")
for _,side in ipairs({-1,1}) do
 part("Corrimao da ponte",Vector3.new(64,0.65,0.65),
  CFrame.new(132,3,-89+side*5.8),P.bark,Enum.Material.Wood,landmarks)
 for i=0,8 do
  part("Pilar da ponte",Vector3.new(0.8,6,0.8),CFrame.new(100+i*8,0,-89+side*5.8),
   P.bark,Enum.Material.Wood,landmarks)
 end
end
-- Somente alguns detalhes de brilho autorais: o sub-bosque principal é MeshPart.
for i=1,36 do
 local z=rng:NextNumber(-292,40)
 local side=if i%2==0 then 1 else -1
 local x=pathX(z)+side*rng:NextNumber(8,56)
 local kind=i%7
 if kind==0 then
  local cap=orb("Flor de memoria",Vector3.new(x,1.65,z),rng:NextNumber(1,2.6),P.flower,
   Enum.Material.SmoothPlastic,details)
  cap.CanCollide=false
  part("Haste de flor",Vector3.new(0.22,1.7,0.22),
   CFrame.new(x,0.85,z),P.mossLight,Enum.Material.Grass,details).CanCollide=false
 elseif kind==1 then
  local fungi=orb("Cogumelo luminoso",Vector3.new(x,0.8,z),1.7,P.blue,
   Enum.Material.Neon,details)
  fungi.CanCollide=false
 else
  -- Retirar os arbustos-esfera que dominavam a silhueta do primeiro plano.
  -- As samambaias MeshPart do Forest Pack compõem o estrato baixo.
  local petal=orb("Flor silvestre discreta",Vector3.new(x,0.9,z),
   rng:NextNumber(0.35,0.65),if i%3==0 then P.flower else P.mossLight,
   Enum.Material.SmoothPlastic,details)
  petal.CanCollide=false
 end
end

-- Capitulo visual: vestigios de uma civilizacao que venerava a arvore ancestral.
-- Composicao deliberada: marcos em pontos fixos, nao props aleatorios no mapa.
local relics=group("Ruinas da antiga floresta")
local function stoneColumn(name,x,z,height,tilt)
 local col=part(name,Vector3.new(4.4,height,4.4),
  CFrame.new(x,height*0.5+0.6,z)*CFrame.Angles(tilt,0,tilt*0.44),
  P.stone,Enum.Material.Rock,relics)
 col.CanCollide=true
 local crest=part("Capitel esculpido",Vector3.new(6.5,1.25,6.5),
  col.CFrame*CFrame.new(0,height*0.5+0.4,0),
  P.stone,Enum.Material.Slate,relics)
 crest.CanCollide=false
end

-- Primeiro enquadramento: ruinas baixas conduzem o olhar para o corredor.
stoneColumn("Sentinela esquecida",pathX(-38)-16,-39,9,math.rad(-5))
stoneColumn("Sentinela esquecida",pathX(-63)+18,-61,11,math.rad(6))
stoneColumn("Sentinela quebrada",pathX(-168)-17,-166,6,math.rad(-13))
-- Um arco antigo quebrado junto da clareira, criando profundidade de silhueta.
stoneColumn("Pilar do santuario",center.X-26,center.Z+25,20,math.rad(2))
stoneColumn("Pilar do santuario",center.X+28,center.Z+25,16,math.rad(-4))
local fallen=between("Travessa tombada",
 Vector3.new(center.X-23,2,center.Z+17),Vector3.new(center.X+10,3,center.Z+13),
 2.8,P.stone,Enum.Material.Slate,relics)
fallen.CanCollide=false

-- Raizes mortas junto das trilhas, revelando a idade e o ciclo da floresta.
for i=1,12 do
 local z=-18-i*21
 local dir=if i%2==0 then 1 else -1
 local x=pathX(z)+dir*(17+rng:NextNumber(0,8))
 local a=Vector3.new(x,0.9,z-3)
 local b=Vector3.new(x+dir*7,1.6,z+3)
 local root=between("Raiz fossilizada",a,b,1.7,P.bark,Enum.Material.Wood,details)
 root.CanCollide=false
end

-- Santuario secundario: Lago do Reflexo. Composicao lateral à trilha, zona de descanso.
-- Um local intencional para explorar; nao espalhar decorações sem propósito.
local reflection=group("Lago do Reflexo — recanto nostalgico")
local poolCenter=Vector3.new(-84,0,-151)
for i=1,13 do
 local angle=i*2*PI/13
 local r=20+rng:NextNumber(-2.8,2.8)
 local x=poolCenter.X+math.cos(angle)*r
 local z=poolCenter.Z+math.sin(angle)*r
 if inWalkway(x,z,3) then continue end
 local boulder=orb("Pedra de margem antiga",Vector3.new(x,0.8,z),
  rng:NextNumber(3,6),P.stone,Enum.Material.Rock,reflection)
 boulder.Size=Vector3.new(boulder.Size.X,2.4,boulder.Size.Z)
 boulder.CanCollide=false
end
-- Obelisco partido: silhueta unica, sutil brilho interior.
local obelisk=part("Marco das aguas esquecidas",Vector3.new(4.8,16,4.5),
 CFrame.new(-101,8,-164)*CFrame.Angles(0,0.35,math.rad(-5)),
 P.stone,Enum.Material.Slate,reflection)
local sigil=part("Runa de agua silenciosa",Vector3.new(0.25,9.3,2.6),
 obelisk.CFrame*CFrame.new(2.5,0,0),
 P.blue,Enum.Material.Neon,reflection)
sigil.Transparency=0.38
sigil.CanCollide=false
sigil.CastShadow=false
-- Pequenos nenúfares na superficie d'agua, nao afetam movimento.
for i=1,7 do
 local ang=(i/7)*PI*2
 local radius=6+(i%3)*3
 local leaf=orb("Nenufar de memoria",Vector3.new(poolCenter.X+math.cos(ang)*radius,-1.8,poolCenter.Z+math.sin(ang)*radius),
  3.7,P.mossLight,Enum.Material.Grass,reflection)
 leaf.Size=Vector3.new(leaf.Size.X,0.2,leaf.Size.Z)
 leaf.CanCollide=false
end

-- Partículas leves confinadas à clareira, evitando dezenas de luzes dinâmicas.
local fireflies=part("Vagalumes na clareira",Vector3.new(1,1,1),
 CFrame.new(center+Vector3.new(0,7,34)),P.firefly,Enum.Material.SmoothPlastic,effects)
fireflies.Transparency=1
fireflies.CanCollide=false
local emitter=Instance.new("ParticleEmitter")
emitter.Name="Luzes suspensas"
emitter.Texture="rbxasset://textures/particles/sparkles_main.dds"
emitter.Color=ColorSequence.new(P.firefly)
emitter.Size=NumberSequence.new({
 NumberSequenceKeypoint.new(0,0.15),
 NumberSequenceKeypoint.new(0.5,0.36),
 NumberSequenceKeypoint.new(1,0),
})
emitter.Transparency=NumberSequence.new({
 NumberSequenceKeypoint.new(0,1),
 NumberSequenceKeypoint.new(0.25,0.3),
 NumberSequenceKeypoint.new(0.85,0.45),
 NumberSequenceKeypoint.new(1,1),
})
emitter.Rate=14
emitter.Lifetime=NumberRange.new(4,9)
emitter.Speed=NumberRange.new(0.3,1.5)
emitter.SpreadAngle=Vector2.new(180,180)
emitter.Parent=fireflies

-- Luz de destaque controlada nos dois marcos: 2 luzes, sem espalhar dezenas no mapa.
local function glow(name,pos,tint,range)
 local holder=part(name,Vector3.new(1,1,1),CFrame.new(pos),tint,Enum.Material.SmoothPlastic,effects)
 holder.Transparency=1
 holder.CanCollide=false
 holder.CastShadow=false
 local light=Instance.new("PointLight")
 light.Color=tint
 light.Range=range
 light.Brightness=0.7
 light.Shadows=false
 light.Parent=holder
 return light
end
local ancientGlow=glow("Luar sob a arvore",center+Vector3.new(0,6,11),
 Color3.fromRGB(255,206,142),30)
local lakeGlow=glow("Luz da runa no lago",Vector3.new(-101,7,-164),
 Color3.fromRGB(127,180,235),25)

for _,item in world:GetDescendants() do
 if item:IsA("BasePart") and not item.CanCollide then
  item.CanTouch=false
  item.CanQuery=false
 end
end

stage("ConfiguringLighting")
-- Perfis calibrados para a direção de arte: quente, crepúsculo frio e noite azul.
local moods={
 {
  name="Golden Nostalgia", clock=16.75, brightness=2.35,
  ambient=Color3.fromRGB(72,95,118), outdoor=Color3.fromRGB(148,147,133),
  atm=Color3.fromRGB(235,212,178), decay=Color3.fromRGB(139,158,159),
  tint=Color3.fromRGB(255,248,235), exposure=-0.05,
   sunTint=Color3.fromRGB(59,39,17), shadeTint=Color3.fromRGB(9,23,28),
  cloud=Color3.fromRGB(245,214,192), stars=0, rays=0.065, glow=0.72,
 },
 {
  name="Cold Twilight", clock=19.0, brightness=1.55,
  ambient=Color3.fromRGB(62,75,121), outdoor=Color3.fromRGB(98,104,153),
  atm=Color3.fromRGB(155,154,207), decay=Color3.fromRGB(92,112,167),
  tint=Color3.fromRGB(208,211,255), exposure=-0.09,
   sunTint=Color3.fromRGB(24,14,31), shadeTint=Color3.fromRGB(8,16,30),
  cloud=Color3.fromRGB(175,166,219), stars=1400, rays=0.05, glow=1.15,
 },
 {
  name="Starry Dream Night", clock=23.6, brightness=1.1,
  ambient=Color3.fromRGB(38,49,98), outdoor=Color3.fromRGB(66,84,121),
  atm=Color3.fromRGB(88,117,175), decay=Color3.fromRGB(43,54,107),
  tint=Color3.fromRGB(185,201,255), exposure=-0.15,
   sunTint=Color3.fromRGB(12,20,36), shadeTint=Color3.fromRGB(5,10,23),
  cloud=Color3.fromRGB(105,130,183), stars=3000, rays=0.0, glow=1.75,
 }
}

local atmosphere=Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
atmosphere.Name="DreamcoreAtmosphere"
atmosphere.Density=0.13
atmosphere.Offset=0.12
atmosphere.Haze=0.45
atmosphere.Glare=0.12
atmosphere.Parent=Lighting
local bloom=Lighting:FindFirstChild("DreamcoreBloom") or Instance.new("BloomEffect")
bloom.Name="DreamcoreBloom"
bloom.Intensity=0.14
bloom.Size=21
bloom.Threshold=1.8
bloom.Parent=Lighting
local grade=Lighting:FindFirstChild("DreamcoreColor") or Instance.new("ColorCorrectionEffect")
grade.Name="DreamcoreColor"
grade.Saturation=0.035
grade.Contrast=0.075
grade.Parent=Lighting
local rays=Lighting:FindFirstChild("DreamcoreSunRays") or Instance.new("SunRaysEffect")
rays.Name="DreamcoreSunRays"
rays.Spread=0.82
rays.Parent=Lighting
local depth=Lighting:FindFirstChild("DreamcoreDepth") or Instance.new("DepthOfFieldEffect")
depth.Name="DreamcoreDepth"
depth.FarIntensity=0.025
depth.NearIntensity=0
depth.FocusDistance=105
depth.InFocusRadius=85
depth.Parent=Lighting
local sky=Lighting:FindFirstChild("DreamcoreSky") or Instance.new("Sky")
sky.Name="DreamcoreSky"
sky.CelestialBodiesShown=true
sky.Parent=Lighting
local clouds=terrain:FindFirstChild("DreamcoreClouds") or Instance.new("Clouds")
clouds.Name="DreamcoreClouds"
clouds.Cover=0.31
clouds.Density=0.24
clouds.Parent=terrain
Lighting.GlobalShadows=true
Lighting.ShadowSoftness=0.38
Lighting.GeographicLatitude=35
Lighting.EnvironmentDiffuseScale=0.45
Lighting.EnvironmentSpecularScale=0.45
-- Direcao de arte V28: realces ambar e sombras verde-azul discretas.
-- ColorShift usa iluminacao global, sem criar PointLights por arvore.

local function applyMood(mood)
 Lighting.ClockTime=mood.clock
 Lighting.Brightness=mood.brightness
 Lighting.Ambient=mood.ambient
 Lighting.OutdoorAmbient=mood.outdoor
 Lighting.ColorShift_Top=mood.sunTint
 Lighting.ColorShift_Bottom=mood.shadeTint
 Lighting.ExposureCompensation=mood.exposure
 Lighting.FogColor=mood.atm
 Lighting.FogStart=225
 Lighting.FogEnd=1050
 atmosphere.Color=mood.atm
 atmosphere.Decay=mood.decay
 grade.TintColor=mood.tint
 rays.Intensity=mood.rays
 ancientGlow.Brightness=mood.glow
 lakeGlow.Brightness=mood.glow*0.72
 sky.StarCount=mood.stars
 clouds.Color=mood.cloud
 world:SetAttribute("LightingMood",mood.name)
end
-- Pôr do sol para primeira impressão; transições suaves entre os três climas.
applyMood(moods[1])
world:SetAttribute("ArtDirection","Floresta das Memorias | Original Anime Fantasy")
world:SetAttribute("WorldVersion",32)
world:SetAttribute("ForestTrunkCollision","Native Forest Pack trunks; anchored Synty proxies; foliage noncolliding")
task.wait() -- integrar as estruturas novas ao mundo fisico antes de liberar a chegada
stage("Finalizing")
world:SetAttribute("GenerationComplete",true)
world:SetAttribute("TerrainCollisionReadyAtBuild",floorReady)
world:SetAttribute("RobloxPlaceVersion",game.PlaceVersion)
ReplicatedStorage:SetAttribute("ForestState","Ready")
stage("Ready")
world:SetAttribute("LightingArtPass","Amber sunlight / teal shadow global color shift")
world:SetAttribute("TerrainProfile","Flat woodland meadow | no mountains")
world:SetAttribute("GeneratedObjectCount",#world:GetDescendants())
print("[Dreamcore] Floresta das Memorias v32:",#world:GetDescendants(),"instancias")

-- Um ciclo completo dura 772 segundos. Mistura cor e brilho sem piscar no celular.
task.spawn(function()
 local hold=145
 local transition=48
 while world.Parent do
  local sequence={1,2,3,2}
  for index=1,#sequence do
   local start=moods[sequence[index]]
   local target=moods[sequence[(index%#sequence)+1]]
   applyMood(start)
   task.wait(hold)
   local begun=os.clock()
   while world.Parent do
    local t=math.clamp((os.clock()-begun)/transition,0,1)
    local smooth=t*t*(3-2*t)
    Lighting.ClockTime=start.clock+(target.clock-start.clock)*smooth
    -- Contagem de estrelas evolui gradualmente, evitando o surgimento abrupto
    -- de milhares de pontos luminosos no meio do crepusculo.
    local starBlend=math.clamp((smooth-0.22)/0.62,0,1)
    sky.StarCount=math.floor(start.stars+(target.stars-start.stars)*starBlend+0.5)
    Lighting.Brightness=start.brightness+(target.brightness-start.brightness)*smooth
    Lighting.Ambient=start.ambient:Lerp(target.ambient,smooth)
    Lighting.OutdoorAmbient=start.outdoor:Lerp(target.outdoor,smooth)
    Lighting.ColorShift_Top=start.sunTint:Lerp(target.sunTint,smooth)
    Lighting.ColorShift_Bottom=start.shadeTint:Lerp(target.shadeTint,smooth)
    Lighting.ExposureCompensation=start.exposure+(target.exposure-start.exposure)*smooth
    Lighting.FogColor=start.atm:Lerp(target.atm,smooth)
    atmosphere.Color=start.atm:Lerp(target.atm,smooth)
    atmosphere.Decay=start.decay:Lerp(target.decay,smooth)
    grade.TintColor=start.tint:Lerp(target.tint,smooth)
    clouds.Color=start.cloud:Lerp(target.cloud,smooth)
    rays.Intensity=start.rays+(target.rays-start.rays)*smooth
    ancientGlow.Brightness=start.glow+(target.glow-start.glow)*smooth
    lakeGlow.Brightness=ancientGlow.Brightness*0.72
    if t>=1 then break end
    -- 2 atualizacoes/s: limita replicacao das propriedades de Lighting,
    -- sem saltos perceptiveis em transicoes de 48 segundos.
    task.wait(0.5)
   end
  end
 end
end)

end
local generated, generationError=xpcall(generateWorld,debug.traceback)
if not generated then
 ReplicatedStorage:SetAttribute("ForestState","Failed")
 local failedStage=tostring(ReplicatedStorage:GetAttribute("ForestStage") or "Unknown")
 ReplicatedStorage:SetAttribute("ForestErrorCode",failedStage)
 warn("[Dreamcore] V31 falha etapa "..failedStage..": "..tostring(generationError))
 -- Apoio emergencial mesmo quando o gerador falha antes de criar o spawn.
 local safeSpawn=Workspace:FindFirstChild("Nascimento Dreamcore",true)
 if not safeSpawn then
  safeSpawn=Instance.new("SpawnLocation")
  safeSpawn.Name="Nascimento Dreamcore"
  safeSpawn.Anchored=true
  safeSpawn.Size=Vector3.new(18,1,18)
  safeSpawn.CFrame=CFrame.new(0,0,8)
  safeSpawn.Neutral=true
  safeSpawn.Parent=Workspace
 end
 -- Um piso minimo navegavel torna o erro diagnosticavel sem cair no vazio.
 pcall(function()
  terrain:FillBlock(CFrame.new(0,-6,8),Vector3.new(72,12,72),Enum.Material.Grass)
 end)
 warn("[Dreamcore] Falha de geracao; apoio de emergencia ativo")
 error(generationError)
end
