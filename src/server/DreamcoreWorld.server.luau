-- Roblox Game-Mobile | Primeiro protótipo Dreamcore
-- Mundo de demonstração, sem espécie ou planeta definitivo.
-- Gera uma paisagem no servidor no início da sessão.
-- IMPORTANTE: Terrain:Clear() apaga o terreno existente deste Place.
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local SEED = 67000
local rng = Random.new(SEED)
local terrain = Workspace.Terrain

local previous = Workspace:FindFirstChild("DreamcoreGenerated")
if previous then previous:Destroy() end
local world = Instance.new("Folder")
world.Name = "DreamcoreGenerated"
world.Parent = Workspace
terrain:Clear()

local PALETTE = {
 grass = Color3.fromRGB(147, 207, 167),
 blossom = Color3.fromRGB(241, 168, 209),
 blossom2 = Color3.fromRGB(195, 170, 252),
 pale = Color3.fromRGB(230, 224, 255),
 stone = Color3.fromRGB(188, 176, 210),
 gold = Color3.fromRGB(255, 225, 162),
 water = Color3.fromRGB(136, 217, 233),
 dark = Color3.fromRGB(92, 80, 135),
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
 p.Parent = parent or world
 return p
end

local function ball(name, position, diameter, color, material)
 local p = part(name, Vector3.new(diameter,diameter,diameter), CFrame.new(position), color, material)
 p.Shape = Enum.PartType.Ball
 return p
end

local function foliageTree(x,z,scale)
 local rootY = 1
 local height = 13*scale
 part("Tronco perolado",Vector3.new(2.5*scale,height,2.5*scale),
  CFrame.new(x,rootY+height/2,z),PALETTE.pale,Enum.Material.Wood)
 local tint = if rng:NextNumber()<0.5 then PALETTE.blossom else PALETTE.blossom2
 ball("Copa principal",Vector3.new(x,rootY+height+2*scale,z),13*scale,tint)
 ball("Copa lateral",Vector3.new(x-4*scale,rootY+height-1*scale,z),8*scale,tint)
 ball("Copa lateral",Vector3.new(x+4*scale,rootY+height-1*scale,z),8*scale,tint)
end

-- Planície central, bordas onduladas e montes afastados: área jogável plana para prototipagem.
terrain:FillBlock(CFrame.new(0,-13,0),Vector3.new(700,26,700),Enum.Material.Grass)
for i=1,24 do
 local angle=(i/24)*math.pi*2
 local radius=rng:NextNumber(220,330)
 local x,z=math.cos(angle)*radius,math.sin(angle)*radius
 terrain:FillBall(Vector3.new(x,-9,z),rng:NextNumber(48,93),Enum.Material.Grass)
end

-- Lago circular estático no setor leste, com borda levemente elevada.
terrain:FillBall(Vector3.new(170,-13,60),46,Enum.Material.Air)
terrain:FillBlock(CFrame.new(170,-10,60),Vector3.new(76,12,76),Enum.Material.Water)

-- Área de chegada e plataforma segura.
local platform=part("Praça de chegada",Vector3.new(32,2,32),CFrame.new(0,2,0),
 PALETTE.stone,Enum.Material.Marble)
local spawn=Instance.new("SpawnLocation")
spawn.Name="Nascimento Dreamcore"
spawn.Size=Vector3.new(12,1,12)
spawn.CFrame=CFrame.new(0,3.5,0)
spawn.Anchored=true
spawn.Neutral=true
spawn.Material=Enum.Material.Neon
spawn.Color=PALETTE.pale
spawn.Transparency=0.25
spawn.Parent=world

-- Um corredor que orienta o jogador para o monumento principal.
for i=1,19 do
 local z=-20-i*7
 local slab=part("Trilha de memórias",Vector3.new(6,0.35,5),
  CFrame.new(math.sin(i*0.24)*4,0.27,z),PALETTE.pale,Enum.Material.Marble)
 slab.Transparency=0.08
end

-- PORTA IMPOSSÍVEL: visual marcante visto desde o spawn.
local portalZ=-195
part("Arco esquerdo",Vector3.new(9,67,12),CFrame.new(-21,34,portalZ),
 PALETTE.pale,Enum.Material.Marble)
part("Arco direito",Vector3.new(9,67,12),CFrame.new(21,34,portalZ),
 PALETTE.pale,Enum.Material.Marble)
part("Lintel suspenso",Vector3.new(53,10,14),CFrame.new(0,69,portalZ),
 PALETTE.pale,Enum.Material.Marble)
local gate=part("Núcleo da porta",Vector3.new(29,48,2),CFrame.new(0,30,portalZ),
 PALETTE.blossom2,Enum.Material.Neon)
gate.Transparency=0.3
gate.CanCollide=false

-- Esculturas monolíticas e arquipélago impossível acima da paisagem.
for i=1,9 do
 local a=(i/9)*math.pi*2
 local r=100 + ((i%3)*25)
 local h=19+(i%4)*9
 local monolith=part("Monólito dos sonhos",Vector3.new(8,h,8),
  CFrame.new(math.cos(a)*r,h/2+1,math.sin(a)*r),PALETTE.stone,Enum.Material.Marble)
 monolith.CFrame=monolith.CFrame*CFrame.Angles(0,a,math.rad(if i%2==0 then 4 else -4))
end
for i=1,5 do
 local x=-220+(i*73)
 local z=-165-(i%2)*60
 local y=85+(i%3)*18
 local island=part("Ilha flutuante",Vector3.new(35,8,24),CFrame.new(x,y,z),
  PALETTE.grass,Enum.Material.Grass)
 island.Shape=Enum.PartType.Block
 ball("Nuvem luminosa",Vector3.new(x,y+14,z),19,
  if i%2==0 then PALETTE.blossom else PALETTE.pale,Enum.Material.Neon).Transparency=0.45
end

-- Árvores distribuídas por anéis: evita bloquear o spawn e o corredor principal.
for i=1,65 do
 local a=rng:NextNumber(0,2*math.pi)
 local distance=rng:NextNumber(65,285)
 local x,z=math.cos(a)*distance,math.sin(a)*distance
 if not (z < -25 and z > -230 and math.abs(x)<30) then
  foliageTree(x,z,rng:NextNumber(0.7,1.8))
 end
end

-- Orbes estranhos, sem colisão, como detalhe de atmosfera.
for i=1,22 do
 local a=rng:NextNumber(0,2*math.pi)
 local r=rng:NextNumber(40,280)
 local orb=ball("Vagalume monumental",Vector3.new(math.cos(a)*r,rng:NextNumber(20,55),math.sin(a)*r),
  rng:NextNumber(3,8),PALETTE.gold,Enum.Material.Neon)
 orb.CanCollide=false
 orb.Transparency=0.22
end

-- Lua impossível no horizonte: efeito cênico, não corpo celeste físico.
local moon=ball("Lua do sonho",Vector3.new(10,180,-580),115,PALETTE.pale,Enum.Material.Neon)
moon.CanCollide=false
moon.Transparency=0.08

-- Atmosfera calibrada como ponto inicial; ajustar após testes em aparelhos reais.
Lighting.ClockTime=17.3
Lighting.Brightness=2
Lighting.Ambient=Color3.fromRGB(137,118,166)
Lighting.OutdoorAmbient=Color3.fromRGB(179,162,199)
Lighting.FogColor=Color3.fromRGB(208,184,229)
Lighting.FogStart=160
Lighting.FogEnd=660
Lighting.GlobalShadows=true
local atmosphere=Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
atmosphere.Name="DreamcoreAtmosphere"
atmosphere.Density=0.32
atmosphere.Offset=0.06
atmosphere.Color=Color3.fromRGB(239,204,239)
atmosphere.Decay=Color3.fromRGB(171,181,232)
atmosphere.Glare=0.22
atmosphere.Haze=1.3
atmosphere.Parent=Lighting
local bloom=Lighting:FindFirstChild("DreamcoreBloom") or Instance.new("BloomEffect")
bloom.Name="DreamcoreBloom"
bloom.Intensity=0.3
bloom.Size=17
bloom.Threshold=1.7
bloom.Parent=Lighting
local grade=Lighting:FindFirstChild("DreamcoreColor") or Instance.new("ColorCorrectionEffect")
grade.Name="DreamcoreColor"
grade.Saturation=0.11
grade.Contrast=0.05
grade.TintColor=Color3.fromRGB(255,239,253)
grade.Parent=Lighting

print("[Dreamcore] protótipo gerado:", #world:GetChildren(), "objetos (sem contar terreno)")
