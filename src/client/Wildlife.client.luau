-- Fauna ambiente original, somente no cliente: preserva rede e fisica no Android.
-- Silhuetas pequenas em segundo plano, nao substituem modelos premium do mapa.
-- Nenhum asset externo, audio sem licenca ou script de terceiros.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Workspace=game:GetService("Workspace")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Lighting=game:GetService("Lighting")

local player=Players.LocalPlayer
local old=Workspace:FindFirstChild("DreamcoreLocalWildlife")
if old then old:Destroy() end
local folder=Instance.new("Folder")
folder.Name="DreamcoreLocalWildlife"
folder.Parent=Workspace

local UPDATE_INTERVAL=0.05 -- 20 Hz, evitando custo por frame no Android
local MAX_RABBITS=3
local MAX_BIRDS=3
local MAX_VIEW_DISTANCE=185
-- Habitats devem permanecer longe de passagens, lago, rio e limites da floresta.
-- Predicados replicam somente a geometria do corredor; nenhuma instancia de terreno e gerada aqui.
local function pathX(z)
 return math.sin((z+5)*0.027)*10+math.sin(z*0.059)*2.5
end
local function riverX(z)
 return 125+math.sin((115-z)/23*0.32)*24
end
local function safeRabbitHabitat(x,y,z)
 if x< -345 or x>345 or z< -485 or z>307 or y< -0.35 or y>3 then return false end
 if z>=-261 and z<=39 and math.abs(x-pathX(z))<18 then return false end
 if x>=pathX(-89)-7 and x<=184 and math.abs(z+89)<18 then return false end
 if x>=-74 and x<=pathX(-151)+8 and math.abs(z+151)<16 then return false end
 if math.abs(x-riverX(z))<34 then return false end
 if (x+84)^2+(z+151)^2<31*31 then return false end
 return true
end
local function birdsActive(hour)
 return hour>=5.9 and hour<19.15
end
local clock=0
local elapsed=0
local ready=false

local function part(name,size,color,shape,parent)
 local p=Instance.new("Part")
 p.Name=name
 p.Size=size
 p.Color=color
 p.Material=Enum.Material.SmoothPlastic
 p.Shape=shape or Enum.PartType.Block
 p.Anchored=true
 p.CanCollide=false
 p.CanTouch=false
 p.CanQuery=false
 p.CastShadow=false
 p.TopSurface=Enum.SurfaceType.Smooth
 p.BottomSurface=Enum.SurfaceType.Smooth
 p.Parent=parent
 return p
end

local function makeRabbit(index)
 local rabbit=Instance.new("Model")
 rabbit.Name="Coelho do bosque "..index
 local fur=({Color3.fromRGB(175,158,139),Color3.fromRGB(204,190,158),Color3.fromRGB(137,145,133)})[index]
 local pale=Color3.fromRGB(232,213,189)
 local dark=Color3.fromRGB(45,53,58)
 local torso=part("Corpo",Vector3.new(1.1,0.85,1.6),fur,Enum.PartType.Ball,rabbit)
 torso.CFrame=CFrame.new(0,0,0)
 rabbit.PrimaryPart=torso
 local function feature(name,sz,color,offset,shape,roll)
  local p=part(name,sz,color,shape,rabbit)
  p.CFrame=CFrame.new(offset)*CFrame.Angles(0,0,roll or 0)
 end
 feature("Peito",Vector3.new(0.7,0.62,0.9),pale,Vector3.new(0,0.01,-0.48),Enum.PartType.Ball)
 feature("Cabeca",Vector3.new(0.8,0.74,0.79),fur,Vector3.new(0,0.47,-0.75),Enum.PartType.Ball)
 feature("Orelha esquerda",Vector3.new(0.23,0.88,0.35),fur,Vector3.new(-0.22,1.16,-0.81),Enum.PartType.Ball,-0.17)
 feature("Orelha direita",Vector3.new(0.23,0.96,0.35),fur,Vector3.new(0.21,1.19,-0.79),Enum.PartType.Ball,0.19)
 feature("Ponta da cauda",Vector3.new(0.45,0.47,0.47),pale,Vector3.new(0,0.18,0.87),Enum.PartType.Ball)
 feature("Pata esquerda",Vector3.new(0.38,0.32,0.57),fur,Vector3.new(-0.40,-0.34,0.40),Enum.PartType.Ball)
 feature("Pata direita",Vector3.new(0.38,0.32,0.57),fur,Vector3.new(0.40,-0.34,0.40),Enum.PartType.Ball)
 feature("Olho esquerdo",Vector3.new(0.12,0.15,0.12),dark,Vector3.new(-0.35,0.53,-1.02),Enum.PartType.Ball)
 feature("Olho direito",Vector3.new(0.12,0.15,0.12),dark,Vector3.new(0.35,0.53,-1.02),Enum.PartType.Ball)
 rabbit.Parent=nil -- esconder ate haver terreno pronto
 return {model=rabbit,phase=index*1.74,angle=index*2.399,dist=57+index*16,groundY=nil,groundX=nil,groundZ=nil}
end

local function makeBird(index)
 local bird=Instance.new("Model")
 bird.Name="Passaro distante "..index
 local dark=Color3.fromRGB(48+index*6,61+index*4,73+index*5)
 local body=part("Silhueta",Vector3.new(0.30,0.24,0.80),dark,Enum.PartType.Ball,bird)
 body.CFrame=CFrame.new(0,0,0)
 bird.PrimaryPart=body
 local left=part("Asa esquerda",Vector3.new(1.0,0.085,0.34),dark,Enum.PartType.Block,bird)
 local right=part("Asa direita",Vector3.new(1.0,0.085,0.34),dark,Enum.PartType.Block,bird)
 local tail=part("Cauda",Vector3.new(0.28,0.06,0.42),dark,Enum.PartType.Block,bird)
 bird.Parent=nil -- esconder ate haver terreno pronto
 return {model=bird,body=body,left=left,right=right,tail=tail,phase=index*2.1,angle=index*2.09,radius=58+index*12}
end

local rabbits={}
for i=1,MAX_RABBITS do rabbits[i]=makeRabbit(i) end
local birds={}
for i=1,MAX_BIRDS do birds[i]=makeBird(i) end

local params=RaycastParams.new()
params.FilterType=Enum.RaycastFilterType.Include
params.FilterDescendantsInstances={Workspace.Terrain}
params.IgnoreWater=true

local function groundAt(x,z)
 local hit=Workspace:Raycast(Vector3.new(x,110,z),Vector3.new(0,-240,0),params)
 if hit and hit.Normal.Y>0.83 then return hit.Position.Y end
 return nil
end

local function hideGroup(group)
 if group.model.Parent then group.model.Parent=nil end
end
local function showGroup(group)
 if not group.model.Parent then group.model.Parent=folder end
end

local lastGroundSample=-100
local habitatCenter=nil
local function step(dt)
 clock+=dt
 local character=player.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 local isReady=ReplicatedStorage:GetAttribute("ForestState")=="Ready"
 if not root or not isReady then
  -- Limpar referencias ao terreno e habitat antigo depois de streaming/respawn.
  habitatCenter=nil
  lastGroundSample=-100
  for _,r in rabbits do
   r.groundY=nil; r.groundX=nil; r.groundZ=nil
   hideGroup(r)
  end
  for _,b in birds do hideGroup(b) end
  return
 end
 local focus=root.Position
 if not habitatCenter or (focus-habitatCenter).Magnitude>140 then
  habitatCenter=focus
  lastGroundSample=-100
  for _,r in rabbits do r.groundY=nil; r.groundX=nil; r.groundZ=nil end
 end
 local updateGround=clock-lastGroundSample>0.8
 if updateGround then lastGroundSample=clock end
 for _,r in rabbits do
  -- Clareiras em arco afastadas do jogador, sem atravessar trilhas na sua frente.
  local theta=r.angle+clock*0.025
  local x=habitatCenter.X+math.cos(theta)*r.dist
  local z=habitatCenter.Z+math.sin(theta)*r.dist
  -- Altura em cache so e valida perto do ponto de amostragem.
  local moved=r.groundX==nil or (x-r.groundX)^2+(z-r.groundZ)^2>9
  if updateGround or moved or r.groundY==nil then
   r.groundY=groundAt(x,z)
   r.groundX=x; r.groundZ=z
  end
  if not r.groundY or not safeRabbitHabitat(x,r.groundY,z)
   or (Vector3.new(x,r.groundY,z)-focus).Magnitude>MAX_VIEW_DISTANCE then
   hideGroup(r)
  else
   showGroup(r)
   local hop=math.pow(math.max(0,math.sin(clock*2.2+r.phase)),2)*0.62
   local facing=theta+math.pi*0.5
   r.model:PivotTo(CFrame.new(x,r.groundY+0.52+hop,z)*CFrame.Angles(0,facing,0))
  end
 end
 -- Durante a noite os passaros descansam; a aurora e os grilos ganham destaque.
 if not birdsActive(Lighting.ClockTime) then
  for _,b in birds do hideGroup(b) end
  return
 end
 for _,b in birds do
  local theta=b.angle+clock*(0.09+b.phase*0.004)
  local p=focus+Vector3.new(math.cos(theta)*b.radius,44+math.sin(clock*0.42+b.phase)*4,math.sin(theta)*b.radius)
  if (p-focus).Magnitude>MAX_VIEW_DISTANCE then
   hideGroup(b)
  else
   showGroup(b)
   local tangent=Vector3.new(-math.sin(theta),0,math.cos(theta))
   local facing=CFrame.lookAt(p,p+tangent)
   b.model:PivotTo(facing)
   local flap=math.sin(clock*5.2+b.phase)*0.47
   b.left.CFrame=facing*CFrame.new(-0.62,0,0)*CFrame.Angles(0,0,-flap)
   b.right.CFrame=facing*CFrame.new(0.62,0,0)*CFrame.Angles(0,0,flap)
   b.tail.CFrame=facing*CFrame.new(0,0,0.49)
  end
 end
end

local connection=RunService.Heartbeat:Connect(function(dt)
 elapsed+=math.min(dt,0.1)
 if elapsed<UPDATE_INTERVAL then return end
 local frameDt=elapsed
 elapsed=0
 step(frameDt)
end)

script.Destroying:Connect(function()
 connection:Disconnect()
 folder:Destroy()
end)
