-- Mundo 1 | Floresta das Memorias: composicao cinematografica original.
-- Referencias de direcao de arte: fantasia anime e paisagens pintadas, sem copiar assets.
-- Construido no servidor; performance mobile: folhagem ancorada, poucos emissores/luzes.
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local terrain = Workspace.Terrain
local rng = Random.new(67001)
local PI = math.pi

local old = Workspace:FindFirstChild("DreamcoreGenerated")
if old then old:Destroy() end
local world = Instance.new("Folder")
world.Name = "DreamcoreGenerated"
world.Parent = Workspace
terrain:Clear()

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

-- Composicao central: trilha em S, rio lateral e horizonte enquadrado pelas copas.
terrain:FillBlock(CFrame.new(0,-19,-90),Vector3.new(680,38,790),Enum.Material.Grass)
terrain:FillBlock(CFrame.new(0,-25,-112),Vector3.new(24,9,380),Enum.Material.Ground)
for i=1,32 do
 local theta=(i/32)*PI*2
 local r=270+rng:NextNumber(-16,25)
 terrain:FillBall(Vector3.new(math.cos(theta)*r,-10,math.sin(theta)*r-90),
  rng:NextNumber(45,92),Enum.Material.Grass)
end
-- Rio e desfiladeiro a direita; agua real do Terrain, margens naturais.
for i=0,19 do
 local z=115-i*23
 local x=125+math.sin(i*0.32)*24
 terrain:FillBall(Vector3.new(x,-6,z),22,Enum.Material.Air)
 terrain:FillBlock(CFrame.new(x,-6,z),Vector3.new(31,10,30),Enum.Material.Water)
end
-- Caminho deliberado, nao dispersao aleatoria.
local function pathX(z)
 return math.sin((z+5)*0.027)*10 + math.sin(z*0.059)*2.5
end
for i=0,48 do
 local z=24-i*5.8
 local x=pathX(z)
 terrain:FillBlock(CFrame.new(x,0.12,z),Vector3.new(15,1.3,7.5),Enum.Material.Ground)
 if i%3 == 0 then
  local side=if i%2==0 then 1 else -1
  local stone=part("Pedra de trilha",Vector3.new(rng:NextNumber(2,4),0.5,rng:NextNumber(2,4)),
   CFrame.new(x+side*rng:NextNumber(4,6),0.6,z),P.stone,Enum.Material.Slate,details)
  stone.CFrame=stone.CFrame*CFrame.Angles(0,rng:NextNumber(0,PI),0)
 end
end

-- Spawn discreto, integrado no caminho, sem plataforma brilhante artificial.
local spawn=Instance.new("SpawnLocation")
spawn.Name="Nascimento Dreamcore"
spawn.Size=Vector3.new(13,1,13)
spawn.CFrame=CFrame.new(pathX(8),1.0,8)
spawn.Anchored=true
spawn.Neutral=true
spawn.Material=Enum.Material.Grass
spawn.Color=P.moss
spawn.Transparency=0.92
spawn.CanCollide=true
spawn.Parent=world

local function branchTree(x,z,s,family)
 local h=17*s
 local base=Vector3.new(x,0.5,z)
 local trunk=part("Tronco musgoso",Vector3.new(2.7*s,h,2.7*s),
  CFrame.new(x,h/2,z),P.bark,Enum.Material.Wood,family)
 trunk.CFrame=trunk.CFrame*CFrame.Angles(rng:NextNumber(-0.04,0.04),0,rng:NextNumber(-0.04,0.04))
 local count=if s>1.2 then 4 else 3
 local tint=if rng:NextNumber()<0.22 then P.canopyGold else
  if rng:NextNumber()<0.49 then P.canopyMid else P.canopy
 for j=1,count do
  local angle=j*PI*2/count + rng:NextNumber(-0.5,0.5)
  local reach=(4.2+rng:NextNumber(-1,2.5))*s
  local tip=Vector3.new(x+math.cos(angle)*reach, h*rng:NextNumber(0.76,1.02),z+math.sin(angle)*reach)
  between("Galho escultural",Vector3.new(x,h*0.68,z),tip,0.9*s,P.barkLight,Enum.Material.Wood,family)
  local leaf=orb("Copa em camadas",tip+Vector3.new(0,2.1*s,0),rng:NextNumber(8,11)*s,
   tint,Enum.Material.Grass,family)
  leaf.CanCollide=false
 end
 local upper=orb("Coroa alta",Vector3.new(x,h+2*s,z),rng:NextNumber(9,12)*s,
  tint,Enum.Material.Grass,family)
 upper.CanCollide=false
end

-- Corredor central com duas linhas de copas: profundidade, contraste e silhuetas.
for row=0,18 do
 local z=30-row*17
 for _,side in ipairs({-1,1}) do
  local width=rng:NextNumber(23,41)
  local x=pathX(z)+side*width
  branchTree(x,z+rng:NextNumber(-6,6),rng:NextNumber(1.12,1.8),props)
  if row%2==0 then
   branchTree(x+side*rng:NextNumber(12,25),z+rng:NextNumber(-11,11),
    rng:NextNumber(0.8,1.24),props)
  end
 end
end
-- Floresta exterior; mantém corredores de exploração amplos.
for i=1,68 do
 local x=rng:NextNumber(-275,275)
 local z=rng:NextNumber(-345,175)
 local nearPath=math.abs(x-pathX(z))<19 and z > -300 and z < 35
 local nearRiver=math.abs(x-125-math.sin((115-z)/23*0.32)*24)<23
 if not nearPath and not nearRiver and (x*x+(z+110)*(z+110))>900 then
  branchTree(x,z,rng:NextNumber(0.75,1.38),props)
 end
end

-- Landmark: a Arvore da Primeira Memoria, dominante na silhueta.
local sacred=Instance.new("Model")
sacred.Name="Arvore da Primeira Memoria"
sacred.Parent=landmarks
local center=Vector3.new(pathX(-245),0,-265)
local crownY=64
local core=part("Cerne antigo",Vector3.new(11,58,11),
 CFrame.new(center.X,29,center.Z),P.barkLight,Enum.Material.Wood,sacred)
for i=1,8 do
 local a=i*PI/4
 local low=center+Vector3.new(math.cos(a)*9,1,math.sin(a)*9)
 local high=center+Vector3.new(math.cos(a)*3,23,math.sin(a)*3)
 between("Raiz colossal",low,high,3.7,P.bark,Enum.Material.Wood,sacred)
end
for i=1,10 do
 local a=i*PI*2/10
 local start=Vector3.new(center.X,43,center.Z)
 local tip=center+Vector3.new(math.cos(a)*rng:NextNumber(19,34),rng:NextNumber(53,75),
  math.sin(a)*rng:NextNumber(19,34))
 between("Braco da arvore",start,tip,3.8,P.bark,Enum.Material.Wood,sacred)
 local leaves=orb("Dossel dourado",tip+Vector3.new(0,6,0),rng:NextNumber(24,36),
  if i%3==0 then P.canopyGold else P.canopyMid,Enum.Material.Grass,sacred)
 leaves.CanCollide=false
end
orb("Coroa do santuario",center+Vector3.new(0,crownY+17,0),42,
 P.canopy,Enum.Material.Grass,sacred).CanCollide=false

-- Círculo de pedras cerimoniais, inteligível na aproximação.
for i=1,12 do
 local a=(i/12)*2*PI
 local r=38
 local pos=center+Vector3.new(math.cos(a)*r,3.5,math.sin(a)*r)
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
 local x=pathX(-105)+rng:NextNumber(-14,14)
 local z=-100+rng:NextNumber(-18,18)
 local rock=orb("Pedra coberta de musgo",Vector3.new(x,0.8,z),
  rng:NextNumber(3,7),P.stone,Enum.Material.Slate,details)
 rock.Size=Vector3.new(rock.Size.X,2.2,rock.Size.Z)
end
-- Ponte decorativa sobre canal secundario.
local bridge=part("Ponte de madeira antiga",Vector3.new(19,1.2,34),
 CFrame.new(111,3,-89)*CFrame.Angles(0,-0.19,0),P.barkLight,Enum.Material.WoodPlanks,landmarks)
for i=1,6 do
 part("Viga da ponte",Vector3.new(1.2,2,19),
  CFrame.new(111+(i-3.5)*4,2.2,-89)*CFrame.Angles(0,-0.19,0),
  P.bark,Enum.Material.Wood,landmarks)
end
-- Gramíneas, flores e cogumelos: apenas elementos próximos a trilha e landmarks.
for i=1,155 do
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
  local bush=orb("Arbusto de sub-bosque",Vector3.new(x,1.15,z),
   rng:NextNumber(2.3,4.2),if i%3==0 then P.mossLight else P.moss,
   Enum.Material.Grass,details)
  bush.CanCollide=false
 end
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

-- Perfis calibrados para a direção de arte: quente, crepúsculo frio e noite azul.
local moods={
 {
  name="Golden Nostalgia", clock=17.35, brightness=2.6,
  ambient=Color3.fromRGB(81,91,116), outdoor=Color3.fromRGB(160,133,126),
  atm=Color3.fromRGB(246,196,148), decay=Color3.fromRGB(121,129,166),
  tint=Color3.fromRGB(255,230,203), exposure=0.02,
  cloud=Color3.fromRGB(255,208,172), stars=0, rays=0.13,
 },
 {
  name="Cold Twilight", clock=19.0, brightness=1.55,
  ambient=Color3.fromRGB(62,75,121), outdoor=Color3.fromRGB(98,104,153),
  atm=Color3.fromRGB(155,154,207), decay=Color3.fromRGB(92,112,167),
  tint=Color3.fromRGB(208,211,255), exposure=-0.09,
  cloud=Color3.fromRGB(175,166,219), stars=1400, rays=0.05,
 },
 {
  name="Starry Dream Night", clock=23.6, brightness=1.1,
  ambient=Color3.fromRGB(38,49,98), outdoor=Color3.fromRGB(66,84,121),
  atm=Color3.fromRGB(88,117,175), decay=Color3.fromRGB(43,54,107),
  tint=Color3.fromRGB(185,201,255), exposure=-0.15,
  cloud=Color3.fromRGB(105,130,183), stars=3000, rays=0.0,
 }
}

local atmosphere=Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
atmosphere.Name="DreamcoreAtmosphere"
atmosphere.Density=0.29
atmosphere.Offset=0.08
atmosphere.Haze=1.25
atmosphere.Glare=0.22
atmosphere.Parent=Lighting
local bloom=Lighting:FindFirstChild("DreamcoreBloom") or Instance.new("BloomEffect")
bloom.Name="DreamcoreBloom"
bloom.Intensity=0.22
bloom.Size=21
bloom.Threshold=1.8
bloom.Parent=Lighting
local grade=Lighting:FindFirstChild("DreamcoreColor") or Instance.new("ColorCorrectionEffect")
grade.Name="DreamcoreColor"
grade.Saturation=0.08
grade.Contrast=0.11
grade.Parent=Lighting
local rays=Lighting:FindFirstChild("DreamcoreSunRays") or Instance.new("SunRaysEffect")
rays.Name="DreamcoreSunRays"
rays.Spread=0.82
rays.Parent=Lighting
local depth=Lighting:FindFirstChild("DreamcoreDepth") or Instance.new("DepthOfFieldEffect")
depth.Name="DreamcoreDepth"
depth.FarIntensity=0.06
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
clouds.Cover=0.4
clouds.Density=0.35
clouds.Parent=terrain
Lighting.GlobalShadows=true
Lighting.GeographicLatitude=35
Lighting.EnvironmentDiffuseScale=0.45
Lighting.EnvironmentSpecularScale=0.55

local function applyMood(mood)
 Lighting.ClockTime=mood.clock
 Lighting.Brightness=mood.brightness
 Lighting.Ambient=mood.ambient
 Lighting.OutdoorAmbient=mood.outdoor
 Lighting.ExposureCompensation=mood.exposure
 Lighting.FogColor=mood.atm
 Lighting.FogStart=125
 Lighting.FogEnd=750
 atmosphere.Color=mood.atm
 atmosphere.Decay=mood.decay
 grade.TintColor=mood.tint
 rays.Intensity=mood.rays
 sky.StarCount=mood.stars
 clouds.Color=mood.cloud
 world:SetAttribute("LightingMood",mood.name)
end
-- Pôr do sol para primeira impressão; transições suaves entre os três climas.
applyMood(moods[1])
world:SetAttribute("ArtDirection","Floresta das Memorias | Original Anime Fantasy")
world:SetAttribute("WorldVersion",2)
world:SetAttribute("GeneratedObjectCount",#world:GetDescendants())
print("[Dreamcore] Floresta das Memorias v2:",#world:GetDescendants(),"instancias")

-- Um ciclo completo dura 12 minutos. Mistura cor e brilho sem piscar no celular.
task.spawn(function()
 local hold=145
 local transition=48
 while world.Parent do
  for index=1,#moods do
   local start=moods[index]
   local target=moods[(index%#moods)+1]
   applyMood(start)
   task.wait(hold)
   local begun=os.clock()
   while world.Parent do
    local t=math.clamp((os.clock()-begun)/transition,0,1)
    local smooth=t*t*(3-2*t)
    Lighting.ClockTime=start.clock+(target.clock-start.clock)*smooth
    Lighting.Brightness=start.brightness+(target.brightness-start.brightness)*smooth
    Lighting.Ambient=start.ambient:Lerp(target.ambient,smooth)
    Lighting.OutdoorAmbient=start.outdoor:Lerp(target.outdoor,smooth)
    Lighting.ExposureCompensation=start.exposure+(target.exposure-start.exposure)*smooth
    Lighting.FogColor=start.atm:Lerp(target.atm,smooth)
    atmosphere.Color=start.atm:Lerp(target.atm,smooth)
    atmosphere.Decay=start.decay:Lerp(target.decay,smooth)
    grade.TintColor=start.tint:Lerp(target.tint,smooth)
    clouds.Color=start.cloud:Lerp(target.cloud,smooth)
    rays.Intensity=start.rays+(target.rays-start.rays)*smooth
    if t>=1 then break end
    task.wait(0.18)
   end
  end
 end
end)
