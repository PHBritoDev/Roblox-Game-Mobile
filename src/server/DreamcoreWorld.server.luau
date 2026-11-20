-- Mundo 1 | Floresta das Memorias: composicao cinematografica original.
-- Referencias de direcao de arte: fantasia anime e paisagens pintadas, sem copiar assets.
-- Construido no servidor; performance mobile: folhagem ancorada, poucos emissores/luzes.
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
ReplicatedStorage:SetAttribute("ForestState","Generating")
ReplicatedStorage:SetAttribute("ForestVersion",34)
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
local initialSpawn
local function generateWorld()
local generationStartedAt=os.clock()
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
terrain.WaterColor=Color3.fromRGB(53,100,93)
terrain.WaterTransparency=0.32
terrain.WaterReflectance=0.12
terrain.WaterWaveSize=0.18
terrain.WaterWaveSpeed=7
terrain:SetMaterialColor(Enum.Material.Grass,Color3.fromRGB(89,135,92))
terrain:SetMaterialColor(Enum.Material.LeafyGrass,Color3.fromRGB(72,118,82))
terrain:SetMaterialColor(Enum.Material.Ground,Color3.fromRGB(111,103,78))
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

-- Assets curados podem conter efeitos de particulas/luzes caros no Android.
-- Remover somente efeitos legados; preservar MeshParts e SurfaceAppearance.
local function stripImportedEffects(root)
 for _,descendant in root:GetDescendants() do
  if descendant:IsA("LuaSourceContainer") or descendant:IsA("ParticleEmitter")
   or descendant:IsA("Trail") or descendant:IsA("Beam")
   or descendant:IsA("Fire") or descendant:IsA("Smoke")
   or descendant:IsA("Sparkles") or descendant:IsA("Light") then
   descendant:Destroy()
  end
 end
end

local function solidMesh(item)
 item.CanCollide=true
 item.CanQuery=true
 item.CanTouch=false
 item:SetAttribute("CollisionRole","Trunk")
end
local function trunkProxy(x,z,height,diameter,parent,groundY)
 local proxy=part("Colisao de tronco",Vector3.new(diameter,height,diameter),
  CFrame.new(x,(groundY or 0)+height*0.5,z),P.bark,Enum.Material.Wood,parent)
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
-- Ampliacao incremental ~24% de area, alinhada a voxels de 4 studs.
terrain:FillBlock(CFrame.new(0,-28,-88),Vector3.new(760,24,880),Enum.Material.Ground)
local materials,occupancies={},{}
for ix=1,190 do
 materials[ix]={}; occupancies[ix]={}
 for iy=1,4 do materials[ix][iy]={}; occupancies[ix][iy]={} end
 -- Distribui trabalho volumetrico por frames, evitando timeout do script no servidor.
 if ix%4==0 then task.wait() end
 for iz=1,220 do
  local x,z=-380+(ix-0.5)*4,-528+(iz-0.5)*4
  local waterDistance=math.min(math.abs(x-riverX(z))-14,math.sqrt((x+84)^2+(z+151)^2)-11)
  local bed=-2-9*(1-math.clamp(waterDistance/9,0,1))
  local noise=math.noise(x/39,z/39,6.7)+0.32*math.noise(x/13,z/13,2)
  local trail=inWalkway(x,z,0.8*math.noise(x/11,z/11,4))
  -- Variacao de estrato no proprio Terrain: zero Parts/draw calls adicionais.
  -- Faixas umidas permanecem terrosas; manchas de xisto ficam longe da trilha.
  local macro=math.noise(x/87,z/87,11.3)
  local stonePatch=math.noise(x/22,z/22,19.1)
  local surface=if trail then Enum.Material.Ground
   else if waterDistance<13 then Enum.Material.Ground
   else if waterDistance>32 and noise < -0.48 and stonePatch>0.39 then Enum.Material.Rock
   else if noise+macro*0.28>0.09 then Enum.Material.LeafyGrass
   else Enum.Material.Grass
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
terrain:WriteVoxels(Region3.new(Vector3.new(-380,-16,-528),Vector3.new(380,0,352)),4,materials,occupancies)
world:SetAttribute("TerrainBounds","X -380..380 | Z -528..352")
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
  -- Silhueta afilada em cunha: substitui as placas retangulares do solo,
  -- sem aumentar a contagem de instancias nem exigir textura externa.
  local leaf=Instance.new("WedgePart")
  leaf.Name="Folha caida lanceolada"
  leaf.Size=Vector3.new(rng:NextNumber(0.35,0.75),0.10,rng:NextNumber(0.9,1.65))
  leaf.CFrame=CFrame.new(x,0.13,z)*CFrame.Angles(0,rng:NextNumber(0,2*PI),0)
  leaf.Color=if i%7==0 then P.flower else if i%3==0 then P.canopyGold else P.moss
  leaf.Material=Enum.Material.Grass
  optimizeDecorativeMesh(leaf,false)
  leaf.Parent=details
 end
end

-- Spawn discreto, integrado no caminho, sem plataforma brilhante artificial.
local spawn=initialSpawn
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

-- Geometria autoral incluida no gerador: nenhum download para a base visual.
-- Cylinder tem eixo X: a rotacao abaixo alinha o comprimento com o galho.
local function woodSegment(name,a,b,radius,parent,solid)
 local beam=part(name,Vector3.new((b-a).Magnitude,radius*2,radius*2),
  CFrame.lookAt((a+b)*0.5,b)*CFrame.Angles(0,PI/2,0),P.barkLight,Enum.Material.Wood,parent)
 beam.Shape=Enum.PartType.Cylinder
 if solid then solidMesh(beam) else optimizeDecorativeMesh(beam,false) end
 return beam
end
local function blade(name,cf,size,color,parent,shadow)
 local leaf=Instance.new("WedgePart")
 leaf.Name=name
 leaf.Size=size
 leaf.CFrame=cf
 leaf.Color=color
 leaf.Material=Enum.Material.SmoothPlastic
 optimizeDecorativeMesh(leaf,shadow)
 leaf.Parent=parent
 return leaf
end
-- Duas cunhas opostas formam uma massa foliar lenticular, sem bolas ou caixas.
local function leafSpray(cf,width,length,color,parent,shadow)
 for _,side in {-1,1} do
  blade("Folhagem autoral lanceolada",cf*CFrame.new(0,0,side*length/4)*CFrame.Angles(0,if side==1 then 0 else PI,0),
   Vector3.new(width,math.max(0.3,width*0.22),length/2),color,parent,shadow)
 end
end
local authoredTrees=0
local function branchTree(x,z,s,family,species)
 -- RNG local: variacao da copa nao desloca o layout nem os acessos.
 local random=Random.new(math.floor(x*71+z*133+s*997)%2147483647)
 species=species or (math.abs(math.floor(x+z))%3+1)
 local tree=Instance.new("Model")
 tree.Name="Arvore autoral — "..species
 tree:SetAttribute("AuthoredTree",true)
 tree.Parent=family
 -- LOD exclusivo da emergencia: silhueta preservada, menos pecas no bosque distante.
 -- Nao afetar a arvore heroica nem os exemplares que enquadram a trilha.
 local distant=math.abs(x-pathX(z))>105 and (x-pathX(-245))^2+(z+281)^2>110*110 and s<2.5
 local h=(if species==2 then 25 else 20)*s
 local base=Vector3.new(x,0,z)
 local bend=Vector3.new(random:NextNumber(-2,2)*s,0,random:NextNumber(-2,2)*s)
 local fork=base+Vector3.new(0,h*0.57,0)+bend
 local top=base+Vector3.new(0,h,0)+bend*1.8
 if distant then
  -- Uma unica haste no LOD de emergencia distante: menos Parts e colisores.
  -- O bosque proximo continua com tronco articulado e colisao integral.
  woodSegment("Tronco distante simplificado",base,top,0.95*s,tree,false)
 else
  woodSegment("Tronco autoral enraizado",base,fork,1.15*s,tree,true)
  woodSegment("Tronco autoral afilado",fork,top,0.66*s,tree,true)
 end
 for j=1,3 do
  local angle=j*PI*2/3+random:NextNumber(-0.3,0.3)
  local radial=Vector3.new(math.cos(angle),0,math.sin(angle))
  if not distant then
   woodSegment("Raiz autoral",base+radial*3*s+Vector3.new(0,0.18,0),base+Vector3.new(0,3*s,0),0.35*s,tree,false)
  end
  local reach=(if species==2 then 4.6 else 7.6)*s
  local tip=base+radial*reach+bend+Vector3.new(0,h*(0.65+j*0.08),0)
  if not distant then woodSegment("Braco autoral",fork,tip,0.42*s,tree,false) end
  for lobe=1,(if distant then 1 else 2) do
   local center=tip+radial*(lobe-1)*2*s+Vector3.new(0,(lobe-1)*1.5*s,0)
   local color=if species==3 and j==2 then P.canopyGold else if lobe==1 then P.canopy else P.canopyMid
   -- Fallback distante: tres massas radiais + cume (4 cunhas), nao seis + cume.
   -- Proximas: duas cunhas por lobo, preservando volume e silhueta.
   -- Somente fallback quando Forest Pack indisponivel, evitando bolas e
   -- evitando duplicar camadas e ultrapassar o orcamento Android.
   local radius=(if species==2 then 4 else 5.6)*s
   local drift=Vector3.new(random:NextNumber(-1.1,1.1)*s,1.1*s,random:NextNumber(-1.1,1.1)*s)
   local canopyCF=CFrame.new(center+drift)*CFrame.Angles(0,angle+random:NextNumber(-0.2,0.2),0)
   if distant then
    -- Um unico volume lanceolado por lobo distante; sem translucidez ou sombra.
    blade("Folhagem distante lanceolada",canopyCF,
     Vector3.new(radius*1.6,math.max(0.3,radius*0.22),radius*2.2),color,tree,false)
   else
    leafSpray(canopyCF,radius*1.6,radius*2.2,color,tree,false)
   end
  end
 end
 -- Cume proximo com duas cunhas; distante com apenas uma, sem sombra.
 -- A simplificacao atua exclusivamente no fallback e longe do corredor.
 local crownCF=CFrame.new(top)*CFrame.Angles(0,random:NextNumber(0,PI),0)
 if distant then
  blade("Cume distante lanceolado",crownCF,
   Vector3.new(5.5*s,math.max(0.3,1.21*s),7*s),P.canopyMid,tree,false)
 else
  leafSpray(crownCF,5.5*s,7*s,P.canopyMid,tree,false)
 end
 authoredTrees+=1
 if authoredTrees%8==0 then task.wait() end
 return tree
end

-- Reservar toda arvore visivel para MeshParts texturizadas Forest Pack.
-- A alternativa organica so aparece quando a Roblox recusa o asset.
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
 else
  -- Todas as arvores visiveis sao reservadas para MeshParts texturizadas.
  -- Nada de arvores low-poly no horizonte nem nas clareiras.
  -- Arvores detalhadas enquadram o corredor, mas troncos nao invadem a trilha.
  local path=pathX(z)
  local offset=x-path
  if z>-238 and z<32 and math.abs(offset)<32 then
   x=path+(if offset>=0 then 1 else -1)*(32+rng:NextNumber(0,14))
  end
  table.insert(forestTreeSites,{x=x,z=z,s=s})
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
-- Novas reservas premium distribuidas ate os limites expandidos; sem placeholder.
for i=1,92 do
 local x=rng:NextNumber(-330,330)
 local z=rng:NextNumber(-420,245)
 local nearPath=math.abs(x-pathX(z))<19 and z > -300 and z < 35
 local nearRiver=math.abs(x-125-math.sin((115-z)/23*0.32)*24)<23
 if not nearPath and not nearRiver and (x*x+(z+110)*(z+110))>900 then
  plantOrReserve(x,z,rng:NextNumber(0.75,1.38),i%3==0)
 end
end

-- Paisagem ribeirinha com modelos florestais premium, nada de galhos/placas low-poly.
-- As margens mantem espaco de seguranca junto a agua e a ponte.
local riverTrees={
 {84,64,1.4},{97,18,1.1},{78,-25,1.35},{90,-75,1.17},
 {83,-144,1.42},{103,-203,1.23},{148,-268,1.36},
}
for _,entry in riverTrees do
 table.insert(forestTreeSites,{x=entry[1],z=entry[2],s=entry[3],river=true})
end

-- Estrato autoral permanente: samambaias e capins agrupados nas bordas secas.
local understory=group("Sub-bosque autoral permanente")
local groundParams=RaycastParams.new()
groundParams.FilterType=Enum.RaycastFilterType.Include
groundParams.FilterDescendantsInstances={terrain}
groundParams.IgnoreWater=true
local plantRng=Random.new(330067)
local function groundPlant(x,z,fern)
 if inWalkway(x,z,-1) then return false end
 -- Amostrar acima de barrancos; rejeitar encostas ingremes e margens submersas.
 local hit=Workspace:Raycast(Vector3.new(x,80,z),Vector3.new(0,-120,0),groundParams)
 if not hit or hit.Position.Y < -0.5 or hit.Normal.Y < 0.78 then return false end
 -- Alinhar as touceiras ao solo sem inclinar excessivamente as laminas.
 local normal=hit.Normal
 local right=Vector3.new(0,0,1):Cross(normal).Unit
 local back=right:Cross(normal).Unit
 local base=CFrame.fromMatrix(hit.Position+normal*0.08,right,normal,back)
 local scale=plantRng:NextNumber(0.75,1.3)
 for j=1,(if fern then 5 else 3) do
  local a=j*2.4+plantRng:NextNumber(0,0.4)
  local pose=base*CFrame.Angles(0,a,0)*CFrame.new(0,0.65*scale,0.65*scale)*CFrame.Angles(-0.3,0,0)
  if fern then
   leafSpray(pose,0.65*scale,2.9*scale,if j%2==0 then P.mossLight else P.moss,understory,false)
  else
   blade("Lamina de capim",pose,Vector3.new(0.23*scale,1.8*scale,0.7*scale),P.mossLight,understory,false)
  end
 end
 return true
end
for i=1,84 do
 local z=22-i*3.2
 local side=if i%2==0 then 1 else -1
 local x=pathX(z)+side*plantRng:NextNumber(11,23)
 groundPlant(x,z,i%3==0)
 groundPlant(x+side*2.5,z+1.8,false)
end
-- Bosque exterior: clareiras com pequenas ilhas de gramineas, sem bloquear trilhas.
-- Instancias baratas e sem colisao; pequenos grupos visiveis, nao uma malha por folha.
for i=1,34 do
 local x=plantRng:NextNumber(-315,315)
 local z=plantRng:NextNumber(-408,235)
 if not reservedSite(x,z,6) and math.abs(x-riverX(z))>30 then
  groundPlant(x,z,i%4==0)
  groundPlant(x+2.2,z+1.7,false)
 end
 if i%8==0 then task.wait() end
end
-- Ilhas de sub-bosque nas bordas da expansao: composicao em tres alturas,
-- com pequenos intervalos para leitura do terreno e sem fechar corredores.
-- Semente independente para nao deslocar as arvores existentes.
local meadowRng=Random.new(20261116)
local meadowClusters=0
-- Limite conservador: cada touceira autoral cria varias Parts; manter ilhas
-- visiveis sem inflar a geometria mobile em mais de mil pecas.
for i=1,20 do
 local x=meadowRng:NextNumber(-338,338)
 local z=meadowRng:NextNumber(-442,265)
 if not reservedSite(x,z,12) and math.abs(x-riverX(z))>38 then
  local spread=meadowRng:NextNumber(2.6,5.4)
  -- Cada muda deve respeitar a reserva individualmente; checar so o
  -- centro deixava folhas invadirem trilhas, agua e espaco das arvores.
  local offsets={
   {x,z,true},
   {x+spread,z+spread*0.32,false},
   {x-spread*0.6,z-spread*0.55,i%3==0},
  }
  local planted=0
  for _,site in ipairs(offsets) do
   local px,pz=site[1],site[2]
   if not reservedSite(px,pz,7) and not inWalkway(px,pz,5)
    and math.abs(px-riverX(pz))>38 then
    if groundPlant(px,pz,site[3]) then planted+=1 end
   end
  end
  if planted>0 then meadowClusters+=1 end
 end
 if i%8==0 then task.wait() end
end
world:SetAttribute("MeadowEdgeClusters",meadowClusters)
-- Rochas baixas em grupos irregulares criam ritmo visual entre gramados externos.
-- Raycast apenas no Terrain; sem colisao, sombras, assets externos ou loops de animacao.
local stoneRng=Random.new(20261117)
local stoneGroups=0
local stonePieces=0
local stoneCast=RaycastParams.new()
stoneCast.FilterType=Enum.RaycastFilterType.Include
stoneCast.FilterDescendantsInstances={terrain}
for i=1,40 do
 local x=stoneRng:NextNumber(-342,342)
 local z=stoneRng:NextNumber(-465,295)
 if not reservedSite(x,z,13) and math.abs(x-riverX(z))>38 then
  local hit=Workspace:Raycast(Vector3.new(x,22,z),Vector3.new(0,-48,0),stoneCast)
  if hit and hit.Material~=Enum.Material.Water and hit.Normal.Y>0.82 and math.abs(hit.Position.Y)<4 then
   stoneGroups+=1
   local stones=Instance.new("Folder")
   stones.Name="Afloramento musgoso "..stoneGroups
   stones.Parent=world
   for j=1,3 do
    local angle=stoneRng:NextNumber(0,PI*2)
    local radius=stoneRng:NextNumber(0.4,2.1)
    local sx=x+math.cos(angle)*radius
    local sz=z+math.sin(angle)*radius
    local ground=Workspace:Raycast(Vector3.new(sx,22,sz),Vector3.new(0,-48,0),stoneCast)
    if ground and ground.Material~=Enum.Material.Water and ground.Normal.Y>0.82
     and not reservedSite(sx,sz,5) and not inWalkway(sx,sz,4)
     and math.abs(sx-riverX(sz))>34 and math.abs(ground.Position.Y)<4 then
     local width=stoneRng:NextNumber(0.8,2.2)
     local height=stoneRng:NextNumber(0.35,0.85)
     local rock=part("Pedra de xisto",Vector3.new(width,height,width*stoneRng:NextNumber(0.75,1.35)),
      CFrame.new(sx,ground.Position.Y+height*0.28,sz)*CFrame.Angles(0,angle,stoneRng:NextNumber(-0.15,0.15)),
      Color3.fromRGB(94+((i+j)%4)*7,105+((i+j)%3)*7,94+((i+j)%5)*4),Enum.Material.Slate,stones)
     optimizeDecorativeMesh(rock,false)
     stonePieces+=1
    end
   end
   -- Nao contabilizar nem manter grupos sem pedras validas apos os filtros.
   if #stones:GetChildren()==0 then
    stones:Destroy()
    stoneGroups-=1
   elseif i%2==0 then
    -- A muda auxiliar tambem deve respeitar as reservas individuais.
    local px,pz=x+3,z+2
    if not reservedSite(px,pz,7) and not inWalkway(px,pz,5)
     and math.abs(px-riverX(pz))>38 then
     groundPlant(px,pz,false)
    end
   end
  end
 end
 if i%9==0 then task.wait() end
end
world:SetAttribute("OuterStoneGroups",stoneGroups)
world:SetAttribute("OuterStonePieces",stonePieces)
world:SetAttribute("ForestExpansionPatch","Outer meadow vegetation + premium tree sites")
-- Bandos distantes: silhuetas autorais, sem assets externos, fisica ou emissores.
-- 21 pecas leves ao todo; altura e distancia preservam a leitura da trilha.
local skyBirds=group("Aves do horizonte — silhuetas")
local birdRng=Random.new(804271)
for i=1,7 do
 local z=-290+i*68
 local x=(if i%2==0 then -1 else 1)*birdRng:NextNumber(115,215)
 local y=birdRng:NextNumber(65,94)
 local center=Vector3.new(x,y,z)
 local facing=CFrame.new(center)*CFrame.Angles(0,birdRng:NextNumber(-PI,PI),0)
 local wingspan=birdRng:NextNumber(5.5,8.2)
 local shade=Color3.fromRGB(65,83,91)
 local body=part("Ave distante — corpo",Vector3.new(0.45,0.35,1.65),facing,shade,Enum.Material.SmoothPlastic,skyBirds)
 optimizeDecorativeMesh(body,false)
 for _,side in {-1,1} do
  local wing=part("Ave distante — asa",Vector3.new(wingspan*0.48,0.16,0.85),
   facing*CFrame.new(side*wingspan*0.24,0.08,0)*CFrame.Angles(0,side*0.15,side*0.13),
   shade,Enum.Material.SmoothPlastic,skyBirds)
  optimizeDecorativeMesh(wing,false)
 end
 if i%3==0 then task.wait() end
end
world:SetAttribute("SkyBirdCount",7)

-- Margens com juncos, musgo e seixos; preserva a travessia da ponte.
local riverbankStoneCount=0
for i=1,48 do
 local z=110-i*8
 local side=if i%2==0 then 1 else -1
 local x=riverX(z)+side*25
 if math.abs(z+89)>16 and not reservedSite(x,z,7)
  and not inWalkway(x,z,5) and math.abs(x-riverX(z))>22 then
  groundPlant(x,z,false)
  if i%3==0 then
   -- Preservar trilha, arvores e declives; pedras nao devem flutuar na margem.
   local hit=Workspace:Raycast(Vector3.new(x,20,z),Vector3.new(0,-45,0),groundParams)
   if hit and hit.Position.Y>=-0.5 and hit.Normal.Y>0.82
    and math.abs(hit.Position.Y)<4 then
    local rock=orb("Seixo de margem",hit.Position+Vector3.new(0,0.45,0),2.7,P.stone,Enum.Material.Slate,details)
    rock.Size=Vector3.new(3.4,1.3,2.3)
    rock.CFrame=rock.CFrame*CFrame.Angles(0,plantRng:NextNumber(-PI,PI),0)
    optimizeDecorativeMesh(rock,false)
    riverbankStoneCount+=1
   end
  end
 end
end
world:SetAttribute("RiverbankGroundedStones",riverbankStoneCount)
-- Horizonte em camadas com arvores premium, nunca placas quadradas.
local horizon=group("Bosque de horizonte")
for i=0,25 do
 local angle=i*2*PI/26
 local x=math.cos(angle)*322
 local z=-95+math.sin(angle)*384
 if math.abs(x-riverX(z))>32 then
  table.insert(forestTreeSites,{x=x,z=z,s=1.5+(i%4)*0.2,horizon=true})
 end
end
-- Limite fisico recuado da borda do Terrain, escondido pelo bosque distante.
for _,edge in {{0,-506,720,2},{0,328,720,2},{-358,-88,2,832},{358,-88,2,832}} do
 local barrier=part("Limite seguro do bosque",Vector3.new(edge[3],70,edge[4]),CFrame.new(edge[1],30,edge[2]),P.moss,Enum.Material.Grass,horizon)
 barrier.Transparency=1; barrier.CastShadow=false
 barrier:SetAttribute("CollisionRole","Boundary")
end

-- O bosque inteiro usa arvores de folhas com SurfaceAppearance do Forest Pack.
-- Synty fica apenas para pedras, grama e detalhes secundários.
for _,site in meshTreeSites do
 table.insert(forestTreeSites,site)
end
table.clear(meshTreeSites)

-- Asset curado: Synty Nature Pack, publicado por @Roblox (ID 6933438443).
-- Licenca oficial para qualquer jogo Roblox (DevForum Roblox 10/06/2021).
-- Inspecao isolada Open Cloud: 200 MeshParts, 11 Models, zero scripts.
-- Nunca parentear o pacote original nem ativar scripts de terceiros.
local curated=group("Vegetacao licenciada Roblox — Synty Nature")
local InsertService=game:GetService("InsertService")
local bundled=game:GetService("ServerStorage"):FindFirstChild("ForestLibrary")
world:SetAttribute("AssetSource",if bundled then "Bundled" else "InsertService")
stage("LoadingSynty")
-- Um asset externo nunca pode abortar o mundo inteiro, mesmo se carregar
-- com sucesso e uma malha/modelo especifico falhar durante a configuracao.
local sourcePack
local syntyIntegrated,syntyError=xpcall(function()
local okPack
okPack,sourcePack=pcall(function()
 if bundled and bundled:FindFirstChild("Synty") then return bundled.Synty:Clone() end
 return InsertService:LoadAsset(6933438443)
end)
world:SetAttribute("SyntyLoadSucceeded",okPack and sourcePack~=nil)
if okPack and sourcePack then
 for _,asset in sourcePack:GetDescendants() do
  if asset:IsA("LuaSourceContainer") then asset:Destroy() end
 end
 local syntyTerrainRayParams=RaycastParams.new()
 syntyTerrainRayParams.FilterType=Enum.RaycastFilterType.Include
 syntyTerrainRayParams.FilterDescendantsInstances={terrain}
 syntyTerrainRayParams.IgnoreWater=true
 local function syntyGroundY(x,z)
  local hit=Workspace:Raycast(Vector3.new(x,160,z),Vector3.new(0,-320,0),syntyTerrainRayParams)
  return if hit then hit.Position.Y else 0
 end
 -- Modelos escolhidos, posicionados para manter enquadramento da trilha.
 local selection={
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
   stripImportedEffects(asset)
   asset.Name="Synty — "..entry[1]
   local desiredHeight=entry[4]
   if asset:IsA("MeshPart") then
    local scale=desiredHeight/math.max(asset.Size.Y,0.1)
    asset.Size=asset.Size*scale
    asset.CFrame=CFrame.new(entry[2],syntyGroundY(entry[2],entry[3])+asset.Size.Y/2-0.12,entry[3])*CFrame.Angles(0,entry[5],0)
    optimizeDecorativeMesh(asset,math.abs(entry[2]-pathX(entry[3]))<76)
    asset.Parent=curated
   elseif asset:IsA("Model") then
    local extents=asset:GetExtentsSize()
    asset:ScaleTo(asset:GetScale()*desiredHeight/math.max(extents.Y,0.1))
    asset:PivotTo(CFrame.new(entry[2],syntyGroundY(entry[2],entry[3])+desiredHeight/2-0.12,entry[3])*CFrame.Angles(0,entry[5],0))
    for _,p in asset:GetDescendants() do
     if p:IsA("BasePart") then optimizeDecorativeMesh(p,math.abs(entry[2]-pathX(entry[3]))<76) end
    end
    asset.Parent=curated
   end
   if string.find(entry[1],"Tree",1,true) then
    trunkProxy(entry[2],entry[3],desiredHeight*0.55,desiredHeight*0.065,curated,syntyGroundY(entry[2],entry[3]))
   elseif string.find(entry[1],"Rock",1,true) then
    if asset:IsA("BasePart") then
     solidMesh(asset); asset:SetAttribute("CollisionRole","Rock")
    end
   end
   placed+=1
  end
 end
 -- Vegetacao profissional curada por planos: samambaias e tufos de grama
 -- próximos ao jogador (não espalhar 200 clones pela cena).
 -- Sondagem compartilhada: plantas pequenas nao devem flutuar em colinas.
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
   stripImportedEffects(leaf)
   leaf.Name="Synty — estrato de samambaias "..i
   local scale=2.3+rng:NextNumber(0.2,1.6)
   leaf.Size=leaf.Size*(scale/math.max(leaf.Size.Y,0.15))
   leaf.CFrame=CFrame.new(x,syntyGroundY(x,z)+leaf.Size.Y*0.49,z)*CFrame.Angles(0,i*1.81,0)
   optimizeDecorativeMesh(leaf,false)
   leaf.Parent=curated
  end
 end
 -- As copas facetadas Synty deixam de ocupar a cena principal.
 print("[Dreamcore] Sitios reservados para Forest Pack premium:",#forestTreeSites)
 print("[Dreamcore] Synty licenciado carregado:",placed,"instancias curadas")
 sourcePack:Destroy()
else
 -- Falha na rede/permissao: replanta todos os sitios reservados com vegetacao autoral.
 for _,site in meshTreeSites do
  site.completed=false
 end
 warn("[Dreamcore] Pacote Synty indisponivel; mantendo vegetacao autoral.")
end

end,debug.traceback)
if not syntyIntegrated then
 warn("[Dreamcore] Synty integracao falhou: "..tostring(syntyError))
 world:SetAttribute("SyntyIntegrationFailed",true)
 ReplicatedStorage:SetAttribute("ForestAssetWarning","Synty")
 curated:ClearAllChildren()
 for _,site in meshTreeSites do site.completed=false end
end

if typeof(sourcePack)=="Instance" then sourcePack:Destroy() end
world:SetAttribute("SyntyIntegrationSucceeded",syntyIntegrated)

-- Forest Pack @Roblox (6432306802): folhas reais em planos com SurfaceAppearance.
-- Baixa uma unica vez, remove todos os scripts, apenas clones curados de Models.
-- Se o pacote falhar, os sites recebem vegetacao original sem quebrar o jogo.
local naturalForest=group("Bosque premium — Forest Pack licenciado")
stage("LoadingForestPack")
local okForest,forestPack=pcall(function()
 if bundled and bundled:FindFirstChild("ForestPack") then return bundled.ForestPack:Clone() end
 return InsertService:LoadAsset(6432306802)
end)
local forestCount=0
local forestHeroBuilt=false
-- Publicar zero antes da tentativa: falha de carga nao pode parecer sucesso.
world:SetAttribute("ForestTreePlacementFailures",0)
world:SetAttribute("ForestTreeFirstPlacementError","")
-- Publicar diagnosticos do sub-bosque antes do LoadAsset e mesmo em fallback.
world:SetAttribute("ForestUndergrowthModels",0)
world:SetAttribute("ForestUndergrowthVariants",0)
world:SetAttribute("ForestUndergrowthPlacementFailures",0)
world:SetAttribute("ForestUndergrowthFirstPlacementError","")
world:SetAttribute("ForestUndergrowthLoadStatus","Pending")
local forestIntegrated,forestError=xpcall(function()
world:SetAttribute("ForestPackLoadSucceeded",okForest and forestPack~=nil)
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
 local placementFailures=0
 local firstPlacementError=nil
 local function plantForest(template,site,index)
  local tree=template:Clone()
  -- Falha durante ScaleTo/PivotTo nao pode deixar clone parcial no mundo.
  local okPlacement,placementError=pcall(function()
  tree.Name="Bosque de folhas texturizadas — "..index
  for _,item in tree:GetDescendants() do
   if item:IsA("LuaSourceContainer") or item:IsA("ParticleEmitter") or item:IsA("Trail") or item:IsA("Beam") or item:IsA("Fire") or item:IsA("Smoke") or item:IsA("Sparkles") or item:IsA("Light") then item:Destroy()
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
  end)
  if not okPlacement then
   tree:Destroy()
   error(placementError,0)
  end
 end
 for i,site in forestTreeSites do
  if i%6==0 then task.wait() end
  local preferred=names[(i-1)%#names+1]
  local template=candidates[preferred] or candidates["BeechwoodTree_Var03"]
  if template then
   local ok,err=pcall(plantForest,template,site,i)
   if ok then forestCount+=1; site.completed=true
   else
    site.completed=false
    placementFailures+=1
    if not firstPlacementError then firstPlacementError=tostring(err) end
   end
  else
   site.completed=false
   placementFailures+=1
   if not firstPlacementError then firstPlacementError="Modelo de arvore licenciado ausente" end
  end
 end
 world:SetAttribute("ForestTreePlacementFailures",placementFailures)
 world:SetAttribute("ForestTreeFirstPlacementError",string.sub(firstPlacementError or "",1,400))
 if placementFailures>0 then
  warn("[Dreamcore] Falhas no plantio Forest Pack:",placementFailures,"primeira causa:",firstPlacementError)
 end
 -- Arbustos e samambaias de folhas texturizadas organizados em camadas.
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
 local undergrowthFailures=0
 local firstUndergrowthError=nil
 if #undergrowthTemplates==0 then
  undergrowthFailures=84 -- 84 locais sem especie, nao confundir com zero erros.
  firstUndergrowthError="Nenhuma especie de estrato baixo encontrada no Forest Pack"
 end
 for i=1,84 do
  local template=if #undergrowthTemplates>0 then undergrowthTemplates[(i-1)%#undergrowthTemplates+1] else nil
  if template then
   -- Densidade lateral, evitando a faixa caminhavel da trilha em S.
   local z=22-i*3.35
   local side=if i%2==0 then 1 else -1
   local x=pathX(z)+side*(13+(i%7)*3.7)
   -- Isolar clonagem e saneamento de cada planta: assets externos podem falhar.
   local foliage=nil
   local okFoliage,foliageError=pcall(function()
    foliage=template:Clone()
    foliage.Name="Estrato baixo texturizado — "..i
    for _,item in foliage:GetDescendants() do
     if item:IsA("LuaSourceContainer") or item:IsA("ParticleEmitter") or item:IsA("Trail") or item:IsA("Beam") or item:IsA("Fire") or item:IsA("Smoke") or item:IsA("Sparkles") or item:IsA("Light") then
      item:Destroy()
     elseif item:IsA("BasePart") then
      optimizeDecorativeMesh(item,false)
     end
    end
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
   if okFoliage then
     undergrowthPlaced+=1
    else
     undergrowthFailures+=1
     if not firstUndergrowthError then firstUndergrowthError=tostring(foliageError) end
     if foliage then foliage:Destroy() end
    end
  end
 end
 world:SetAttribute("ForestUndergrowthPlacementFailures",undergrowthFailures)
  world:SetAttribute("ForestUndergrowthFirstPlacementError",string.sub(firstUndergrowthError or "",1,400))
  if undergrowthFailures>0 then
   warn("[Dreamcore] Falhas no plantio do estrato baixo:",undergrowthFailures,"primeira causa:",firstUndergrowthError)
  end
  world:SetAttribute("ForestUndergrowthModels",undergrowthPlaced)
 world:SetAttribute("ForestUndergrowthVariants",#undergrowthTemplates)
 world:SetAttribute("ForestUndergrowthLoadStatus",if #undergrowthTemplates==0 then "NoTemplates" else if undergrowthFailures>0 then "Partial" else "Placed")
 local heroTemplate=candidates["BeechwoodTreeLarge_Var01"]
 if heroTemplate then
  local okHero,heroError=pcall(plantForest,heroTemplate,{x=pathX(-245),z=-281,s=3.65},9001)
  if okHero then
   forestHeroBuilt=true
   forestCount+=1
  else
   placementFailures+=1
   world:SetAttribute("ForestTreePlacementFailures",placementFailures)
 world:SetAttribute("ForestTreeFirstPlacementError",string.sub(firstPlacementError or tostring(heroError),1,400))
   warn("[Dreamcore] Falha ao posicionar arvore principal Forest Pack; fallback ativado:",tostring(heroError))
  end
 else
  -- A arvore heroica tambem precisa de fallback quando a variante nao existe.
  placementFailures+=1
  world:SetAttribute("ForestTreePlacementFailures",placementFailures)
 world:SetAttribute("ForestTreeFirstPlacementError",string.sub(firstPlacementError or "Arvore principal Forest Pack ausente",1,400))
  warn("[Dreamcore] Arvore principal Forest Pack ausente; fallback ativado.")
 end
 forestPack:Destroy()
else
 for _,site in forestTreeSites do
  site.completed=false
 end
 world:SetAttribute("ForestTreePlacementFailures",#forestTreeSites+1)
 world:SetAttribute("ForestTreeFirstPlacementError","Forest Pack indisponivel")
 world:SetAttribute("ForestUndergrowthPlacementFailures",84)
 world:SetAttribute("ForestUndergrowthFirstPlacementError","Forest Pack indisponivel")
 world:SetAttribute("ForestUndergrowthLoadStatus","Unavailable")
 warn("[Dreamcore] Forest Pack indisponivel; fallback do bosque ativado.")
end
end,debug.traceback)
if not forestIntegrated then
 warn("[Dreamcore] Forest Pack integracao falhou: "..tostring(forestError))
 world:SetAttribute("ForestPackIntegrationFailed",true)
 world:SetAttribute("ForestTreePlacementFailures",#forestTreeSites+1)
 world:SetAttribute("ForestTreeFirstPlacementError",string.sub(tostring(forestError),1,400))
 world:SetAttribute("ForestUndergrowthModels",0)
 world:SetAttribute("ForestUndergrowthPlacementFailures",84)
 world:SetAttribute("ForestUndergrowthFirstPlacementError",string.sub(tostring(forestError),1,400))
 world:SetAttribute("ForestUndergrowthLoadStatus","IntegrationFailed")
 ReplicatedStorage:SetAttribute("ForestAssetWarning","ForestPack")
 naturalForest:ClearAllChildren()
 forestCount=0; forestHeroBuilt=false
 for _,site in forestTreeSites do site.completed=false end
end
if typeof(forestPack)=="Instance" then forestPack:Destroy() end
world:SetAttribute("ForestPackIntegrationSucceeded",forestIntegrated)
local reservedCount,fulfilledCount=0,0
for _,sites in {meshTreeSites,forestTreeSites} do
 for _,site in sites do
  reservedCount+=1
  if not site.completed then branchTree(site.x,site.z,site.s,props) end
  fulfilledCount+=1
 end
end
world:SetAttribute("ReservedTreeSites",reservedCount)
world:SetAttribute("FulfilledTreeSites",fulfilledCount)
world:SetAttribute("ForestMeshTrees",forestCount)
world:SetAttribute("VisualTreePolicy","Premium Forest Pack; organic fallback only if assets fail")
world:SetAttribute("PremiumTreeSites",#forestTreeSites)
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
 local hero=branchTree(center.X,center.Z,3.65,sacred,3)
 hero.Name="Cerne antigo autoral"
 hero:SetAttribute("Hero",true)
 -- Somente no modo emergencia: copa ancestral oval, sem placas quadradas.
 for j=1,5 do
  local angle=j*PI*2/5
  local tip=center+Vector3.new(math.cos(angle)*24,42+j*3,math.sin(angle)*24)
  woodSegment("Braco ancestral",center+Vector3.new(0,28,0),tip,1.7,sacred,false)
  -- Substituir as cinco esferas heroicas por folhagem lanceolada autoral.
  -- Duas cunhas por ramo, sem colisao e sem sombras caras no Android.
  local canopyCF=CFrame.new(tip)*CFrame.Angles(0,angle,math.rad(if j%2==0 then 9 else -9))
  leafSpray(canopyCF,18,24,P.canopyGold,sacred,false)
 end
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
-- Travessia artesanal: tabuas ritmadas e escoras diagonais dão escala humana
-- ao rio sem importar assets, criar luzes ou alterar a colisao do tabuleiro.
-- 15 tabuas rasas sem colisao; o tabuleiro unico continua sendo o piso seguro.
for i=0,14 do
 local x=103+i*4.15
 local board=part("Tabua envelhecida da ponte",Vector3.new(3.86,0.16,11.4),
  CFrame.new(x,0.34,-89),if i%4==0 then P.bark else P.barkLight,
  Enum.Material.WoodPlanks,landmarks)
 board.CanCollide=false
 board.CanQuery=false
 board.CastShadow=false
end
-- Escoras em V entre pilares: silhueta legivel da ponte vista de longe.
for _,side in ipairs({-1,1}) do
 for i=0,7 do
  local x=100+i*8
  local z=-89+side*5.8
  local brace=between("Escora diagonal da ponte",
   Vector3.new(x,0.4,z),Vector3.new(x+4,2.65,z),
   0.34,P.bark,Enum.Material.Wood,landmarks)
  brace.CanCollide=false
  brace.CanQuery=false
  brace.CastShadow=false
 end
end
world:SetAttribute("BridgeArtPass","15 deck boards + 16 diagonal braces; collision unchanged")

-- Somente alguns detalhes de brilho autorais: o sub-bosque principal é MeshPart.
for i=1,36 do
 local z=rng:NextNumber(-292,40)
 local side=if i%2==0 then 1 else -1
 local x=pathX(z)+side*rng:NextNumber(8,56)
 local kind=i%7
 if kind==0 then
  -- Flor radial de cinco petalas: silhueta legivel, sem bolhas gigantes.
  local size=rng:NextNumber(0.85,1.15)
  local stem=part("Haste de flor",Vector3.new(0.18,1.7,0.18),
   CFrame.new(x,0.85,z),P.mossLight,Enum.Material.Grass,details)
  optimizeDecorativeMesh(stem,false)
  for petalIndex=1,5 do
   local angle=(petalIndex-1)*2*PI/5
   local petal=part("Petala da memoria",Vector3.new(0.65*size,0.12,1.15*size),
    CFrame.new(x+math.sin(angle)*0.45*size,1.72,z+math.cos(angle)*0.45*size)
     *CFrame.Angles(0,angle,math.rad(16)),
    if petalIndex%2==0 then P.flower else P.canopyGold,Enum.Material.SmoothPlastic,details)
   optimizeDecorativeMesh(petal,false)
  end
  local heart=orb("Miolo da memoria",Vector3.new(x,1.78,z),0.38*size,P.firefly,
   Enum.Material.SmoothPlastic,details)
  optimizeDecorativeMesh(heart,false)
 elseif kind==1 then
  -- Cogumelo com pe e chapeu baixo: brilho so no miolo, sem luz dinamica.
  local stem=part("Pe do cogumelo",Vector3.new(0.32,0.75,0.32),
   CFrame.new(x,0.38,z),P.stone,Enum.Material.SmoothPlastic,details)
  optimizeDecorativeMesh(stem,false)
  local cap=orb("Chapeu do cogumelo",Vector3.new(x,0.82,z),1.35,P.blue,
   Enum.Material.SmoothPlastic,details)
  cap.Size=Vector3.new(1.35,0.34,1.35)
  optimizeDecorativeMesh(cap,false)
  local glow=orb("Nucleo bioluminescente",Vector3.new(x,0.77,z),0.26,P.blue,
   Enum.Material.Neon,details)
  optimizeDecorativeMesh(glow,false)
 else
  -- Flores baixas em pequenos tufos, sem esferas suspensas.
  local tint=if i%3==0 then P.flower else P.mossLight
  for petalIndex=1,3 do
   local angle=(petalIndex-1)*2*PI/3
   local petal=part("Flor silvestre discreta",Vector3.new(0.27,0.09,0.55),
    CFrame.new(x+math.sin(angle)*0.16,0.22,z+math.cos(angle)*0.16)
     *CFrame.Angles(0,angle,math.rad(9)),tint,Enum.Material.SmoothPlastic,details)
   optimizeDecorativeMesh(petal,false)
  end
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

-- Camada de ruinas cobertas por musgo: pedra e vegetacao contam a historia
-- do santuario sem luzes dinamicas, scripts externos ou custo de colisao.
-- RNG separado evita mudar a distribuicao das arvores existentes.
local ruinRng=Random.new(67173)
local ruinMoss=group("Musgo e fragmentos das ruinas")
local ruinGround=RaycastParams.new()
ruinGround.FilterType=Enum.RaycastFilterType.Include
ruinGround.FilterDescendantsInstances={terrain}
ruinGround.IgnoreWater=true
local ruinCenters={
 Vector2.new(pathX(-38)-16,-39),
 Vector2.new(pathX(-63)+18,-61),
 Vector2.new(pathX(-168)-17,-166),
 Vector2.new(center.X-26,center.Z+25),
 Vector2.new(center.X+28,center.Z+25),
}
local ruinFragments=0
local ruinMossPatches=0
for _,site in ipairs(ruinCenters) do
 for j=1,9 do
  local angle=(j/9)*PI*2+ruinRng:NextNumber(-0.16,0.16)
  local radius=ruinRng:NextNumber(5.8,12.5)
  local x=site.X+math.cos(angle)*radius
  local z=site.Y+math.sin(angle)*radius
  if not inWalkway(x,z,5) and math.abs(x-riverX(z))>29
   and ((x+84)^2+(z+151)^2)>27^2 then
   local hit=Workspace:Raycast(Vector3.new(x,16,z),Vector3.new(0,-34,0),ruinGround)
   if hit and hit.Normal.Y>0.8 and math.abs(hit.Position.Y)<2 then
    local ground=hit.Position.Y
    if j%3==0 then
     local slab=part("Fragmento de capitel coberto",Vector3.new(
      ruinRng:NextNumber(2.4,4.2),0.65,ruinRng:NextNumber(1.8,3.4)),
      CFrame.new(x,ground+0.24,z)*CFrame.Angles(0,angle,ruinRng:NextNumber(-0.12,0.12)),
      P.stone,Enum.Material.Slate,ruinMoss)
     optimizeDecorativeMesh(slab,false)
     ruinFragments+=1
    else
     -- Lajes achatadas de musgo, sem bolas ou cards transparentes.
     local patch=part("Musgo rasteiro das ruinas",Vector3.new(
      ruinRng:NextNumber(1.8,3.8),0.12,ruinRng:NextNumber(2.2,4.8)),
      CFrame.new(x,ground+0.08,z)*CFrame.Angles(0,angle,0),
      if j%2==0 then P.mossLight else P.moss,Enum.Material.Grass,ruinMoss)
     optimizeDecorativeMesh(patch,false)
     ruinMossPatches+=1
    end
   end
  end
 end
end
world:SetAttribute("RuinMossPatches",ruinMossPatches)
world:SetAttribute("RuinStoneFragments",ruinFragments)

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
 leaf.CastShadow=false
 leaf.CanQuery=false
 -- Flores de agua autorais: apenas quatro nenufares floridos para conter draw calls.
 -- Petalas fisicas pequenas, sem particulas ou luzes; leitura clara a curta distancia.
 if i%2==1 then
  local blossom=Vector3.new(leaf.Position.X,-1.52,leaf.Position.Z)
  local petals=4
  for petalIndex=1,petals do
   local angle=petalIndex*2*PI/petals+i*0.37
   local petal=part("Petala de nenufar",Vector3.new(0.62,0.14,1.12),
    CFrame.new(blossom+Vector3.new(math.cos(angle)*0.38,0,math.sin(angle)*0.38))
     *CFrame.Angles(0,-angle+PI/2,math.rad(9)),
    if i%4==1 then P.flower else Color3.fromRGB(240,229,197),
    Enum.Material.SmoothPlastic,reflection)
   petal.CanCollide=false
   petal.CanQuery=false
   petal.CastShadow=false
  end
  local heart=orb("Miolo dourado do nenufar",blossom+Vector3.new(0,0.08,0),
   0.34,P.rune,Enum.Material.SmoothPlastic,reflection)
  heart.CanCollide=false
  heart.CanQuery=false
  heart.CastShadow=false
 end
end
reflection:SetAttribute("AuthoredWaterLilyBlooms",4)
reflection:SetAttribute("WaterLilyDecorativeParts",20)

-- Faixa de juncos autorais na margem do lago: silhueta vertical, sem scripts/assets.
-- Distribuicao deterministica em pequenos tufos; sem colisao nem sombras mobile.
local lakeReedCount=0
for cluster=1,12 do
 local angle=(cluster/12)*PI*2+0.11
 local shoreRadius=19.2+(cluster%3)*0.85
 local bx=poolCenter.X+math.cos(angle)*shoreRadius
 local bz=poolCenter.Z+math.sin(angle)*shoreRadius
 if not inWalkway(bx,bz,3.5) then
  for blade=1,3 do
   local offset=(blade-2)*0.75
   local height=2.8+((cluster+blade)%4)*0.58
   local reed=part("Junco do Lago do Reflexo",Vector3.new(0.18,height,0.26),
    CFrame.new(bx+offset,0.35+height*0.5,bz+offset*0.45)
     *CFrame.Angles(math.rad((blade-2)*9),0,math.rad((cluster%2==0 and 1 or -1)*7)),
    if blade==2 then P.mossLight else P.moss,Enum.Material.Grass,reflection)
   reed.CanCollide=false
   reed.CanTouch=false
   reed.CanQuery=false
   reed.CastShadow=false
   lakeReedCount+=1
  end
 end
end
world:SetAttribute("LakeReedBlades",lakeReedCount)

-- Partículas leves confinadas à clareira, evitando dezenas de luzes dinâmicas.
local fireflies=part("Vagalumes na clareira",Vector3.new(1,1,1),
 CFrame.new(center+Vector3.new(0,7,34)),P.firefly,Enum.Material.SmoothPlastic,effects)
fireflies.Transparency=1
fireflies.CanCollide=false
fireflies.CanQuery=false
fireflies.CastShadow=false
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
-- Pontos de luz lentos e ascendentes: custo baixo de overdraw no Android.
-- Emissao luminosa sem luz dinamica extra por particula.
emitter.Rate=8
emitter.Lifetime=NumberRange.new(4,9)
emitter.Speed=NumberRange.new(0.3,1.1)
emitter.Acceleration=Vector3.new(0,0.22,0)
emitter.Drag=0.35
emitter.LightEmission=0.5
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
  ambient=Color3.fromRGB(54,75,87), outdoor=Color3.fromRGB(102,118,112),
  atm=Color3.fromRGB(235,212,178), decay=Color3.fromRGB(139,158,159),
  tint=Color3.fromRGB(255,248,235), exposure=-0.05,
   sunTint=Color3.fromRGB(59,39,17), shadeTint=Color3.fromRGB(9,23,28),
  cloud=Color3.fromRGB(245,214,192), cloudCover=0.32, cloudDensity=0.23, stars=0, rays=0.065, glow=0.72, fireflyRate=2,
 },
 {
  name="Cold Twilight", clock=19.0, brightness=1.55,
  ambient=Color3.fromRGB(62,75,121), outdoor=Color3.fromRGB(98,104,153),
  atm=Color3.fromRGB(155,154,207), decay=Color3.fromRGB(92,112,167),
  tint=Color3.fromRGB(208,211,255), exposure=-0.09,
   sunTint=Color3.fromRGB(24,14,31), shadeTint=Color3.fromRGB(8,16,30),
  cloud=Color3.fromRGB(175,166,219), cloudCover=0.24, cloudDensity=0.19, stars=1400, rays=0.05, glow=1.15, fireflyRate=6,
 },
 {
  name="Starry Dream Night", clock=23.6, brightness=1.1,
  ambient=Color3.fromRGB(38,49,98), outdoor=Color3.fromRGB(66,84,121),
  atm=Color3.fromRGB(88,117,175), decay=Color3.fromRGB(43,54,107),
  tint=Color3.fromRGB(185,201,255), exposure=-0.15,
   sunTint=Color3.fromRGB(12,20,36), shadeTint=Color3.fromRGB(5,10,23),
  cloud=Color3.fromRGB(105,130,183), cloudCover=0.12, cloudDensity=0.13, stars=3000, rays=0.0, glow=1.75, fireflyRate=8,
 },
 {
  -- Manha dourada/azul inspirada nas referencias enviadas, sem copiar assets.
  name="First Light Meadow", clock=6.35, brightness=2.05,
  ambient=Color3.fromRGB(67,84,104), outdoor=Color3.fromRGB(113,137,145),
  atm=Color3.fromRGB(246,208,172), decay=Color3.fromRGB(139,164,174),
  tint=Color3.fromRGB(255,241,220), exposure=-0.08,
  sunTint=Color3.fromRGB(52,32,16), shadeTint=Color3.fromRGB(7,25,35),
  cloud=Color3.fromRGB(255,211,185), cloudCover=0.29, cloudDensity=0.21, stars=0, rays=0.055, glow=0.65, fireflyRate=1,
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
-- Os valores definitivos sao aplicados pelo perfil de clima, inclusive apos reload.
clouds.Parent=terrain
Lighting.GlobalShadows=true
Lighting.ShadowSoftness=0.38
Lighting.GeographicLatitude=35
Lighting.EnvironmentDiffuseScale=0.35
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
 emitter.Rate=mood.fireflyRate
 sky.StarCount=mood.stars
 clouds.Color=mood.cloud
 clouds.Cover=mood.cloudCover
 clouds.Density=mood.cloudDensity
 world:SetAttribute("LightingMood",mood.name)
end
-- Por do sol para primeira impressao; transicoes suaves entre os tres climas.
applyMood(moods[1])
world:SetAttribute("ArtDirection","Floresta das Memorias | Original Anime Fantasy")
world:SetAttribute("WorldVersion",34)
world:SetAttribute("ForestTrunkCollision","Native Forest Pack trunks; anchored Synty proxies; foliage noncolliding")
task.wait() -- integrar as estruturas novas ao mundo fisico antes de liberar a chegada
stage("Finalizing")
world:SetAttribute("TerrainCollisionReadyAtBuild",floorReady)
world:SetAttribute("RobloxPlaceVersion",game.PlaceVersion)
-- O Terrain pode atrasar a colisao em servidores publicos. O spawn solido
-- continua valido; nao abortar toda a floresta apos o timeout tolerado acima.
local finalTerrainReady=true
for _,point in {Vector3.new(0,12,24),Vector3.new(0,12,-254),Vector3.new(90,12,-89),Vector3.new(-54,12,-151)} do
 local hit=Workspace:Raycast(point,Vector3.new(0,-24,0),readiness)
 if not hit or math.abs(hit.Position.Y)>0.45 then
  finalTerrainReady=false
  break
 end
end
world:SetAttribute("TerrainCollisionReadyAtBuild",finalTerrainReady)
if not finalTerrainReady then
 warn("[Dreamcore] Terrain sem colisao completa na finalizacao; spawn de apoio mantido")
end
world:SetAttribute("GenerationComplete",true)
ReplicatedStorage:SetAttribute("ForestState","Ready")
stage("Ready")
world:SetAttribute("LightingArtPass","Amber sunlight / teal shadow global color shift")
world:SetAttribute("TerrainProfile","Expanded woodland meadows | no mountains")
world:SetAttribute("AuthoredTreeCount",authoredTrees)
-- Telemetria de custo real da geracao (headless e servidor); nao e FPS Android.
local partCount,meshCount,nonCollidingCount=0,0,0
for _,descendant in world:GetDescendants() do
 if descendant:IsA("BasePart") then
  partCount+=1
  if descendant:IsA("MeshPart") then meshCount+=1 end
  if not descendant.CanCollide then nonCollidingCount+=1 end
 end
end
world:SetAttribute("GeneratedPartCount",partCount)
world:SetAttribute("GeneratedMeshPartCount",meshCount)
world:SetAttribute("GeneratedNonCollidingPartCount",nonCollidingCount)
world:SetAttribute("GenerationSeconds",math.floor((os.clock()-generationStartedAt)*100+0.5)/100)
world:SetAttribute("GeneratedObjectCount",#world:GetDescendants())
print("[Dreamcore] Floresta das Memorias v34:",#world:GetDescendants(),"instancias")

-- Ciclo com amanhecer, tarde dourada, crepusculo e noite; sem piscar no celular.
task.spawn(function()
 local hold=145
 local transition=48
 while world.Parent do
  local sequence={1,2,3,4}
  for index=1,#sequence do
   local start=moods[sequence[index]]
   local target=moods[sequence[(index%#sequence)+1]]
   applyMood(start)
   task.wait(hold)
   local begun=os.clock()
   while world.Parent do
    local t=math.clamp((os.clock()-begun)/transition,0,1)
    local smooth=t*t*(3-2*t)
    -- Interpolar pela meia-noite: 23.6 -> 6.35 deve atravessar 0h, nao meio-dia.
    local clockDelta=(target.clock-start.clock+12)%24-12
    Lighting.ClockTime=(start.clock+clockDelta*smooth)%24
    -- Contagem de estrelas evolui gradualmente, evitando o surgimento abrupto
    -- de milhares de pontos luminosos no meio do crepusculo.
    local starBlend=math.clamp((smooth-0.22)/0.62,0,1)
    -- Evitar replicar centenas de mudancas quase invisiveis de estrelas no Android.
    -- A ultima amostra sempre aplica o valor exato do proximo perfil.
    local stars=math.floor(start.stars+(target.stars-start.stars)*starBlend+0.5)
    if t>=1 or math.abs(stars-sky.StarCount)>=120 then
     sky.StarCount=stars
    end
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
    clouds.Cover=start.cloudCover+(target.cloudCover-start.cloudCover)*smooth
    clouds.Density=start.cloudDensity+(target.cloudDensity-start.cloudDensity)*smooth
    rays.Intensity=start.rays+(target.rays-start.rays)*smooth
    ancientGlow.Brightness=start.glow+(target.glow-start.glow)*smooth
    lakeGlow.Brightness=ancientGlow.Brightness*0.72
    -- Conduzir a presenca dos vagalumes entre o poente e a noite.
    emitter.Rate=start.fireflyRate+(target.fireflyRate-start.fireflyRate)*smooth
    if t>=1 then break end
    -- 2 atualizacoes/s: limita replicacao das propriedades de Lighting,
    -- sem saltos perceptiveis em transicoes de 48 segundos.
    task.wait(0.5)
   end
  end
 end
end)

end
-- Spawn disponivel antes de qualquer clonagem de biblioteca 3D ou Terrain.
-- O matchmaking nao deve depender da conclusao do gerador premium.
initialSpawn=Workspace:FindFirstChild("Nascimento Dreamcore")
if not initialSpawn then
 initialSpawn=Instance.new("SpawnLocation")
 initialSpawn.Name="Nascimento Dreamcore"
 initialSpawn.Size=Vector3.new(13,1,13)
 initialSpawn.CFrame=CFrame.new(0,-0.45,8)
 initialSpawn.Anchored=true
 initialSpawn.Neutral=true
 initialSpawn.Material=Enum.Material.Grass
 initialSpawn.Color=Color3.fromRGB(73,116,74)
 initialSpawn.Transparency=1
 initialSpawn.CanTouch=false
 initialSpawn.CanCollide=true
 initialSpawn.Duration=0
 initialSpawn.Parent=Workspace
end
-- Executar a criacao do mundo fora da inicializacao imediata do script.
-- Mantem todos os assets Codex/efeitos; caso falhe o spawn inicial permanece.
task.spawn(function()
local generated, generationError=xpcall(generateWorld,debug.traceback)
if not generated then
 ReplicatedStorage:SetAttribute("ForestState","Failed")
 local failedStage=tostring(ReplicatedStorage:GetAttribute("ForestStage") or "Unknown")
 ReplicatedStorage:SetAttribute("ForestErrorCode",failedStage)
 warn("[Dreamcore] V34 falha etapa "..failedStage..": "..tostring(generationError))
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
end)
