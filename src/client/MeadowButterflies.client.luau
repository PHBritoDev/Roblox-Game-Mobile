-- Borboletas autorais nos prados, somente no cliente: 4 modelos, 20 partes.
-- Sem audios/meshes externos, colisoes ou replicacao de animacao pela rede.
local Players=game:GetService("Players")
local Lighting=game:GetService("Lighting")
local Workspace=game:GetService("Workspace")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")

local localPlayer=Players.LocalPlayer
local previous=Workspace:FindFirstChild("DreamcoreLocalButterflies")
if previous then previous:Destroy() end
local folder=Instance.new("Folder")
folder.Name="DreamcoreLocalButterflies"
folder.Parent=Workspace

local COUNT=4
local UPDATE_INTERVAL=0.09 -- ate ~11 atualizacoes/s, nunca todo Heartbeat
local MAX_DISTANCE=105
local MAX_ALTITUDE=3.5
local GROUND_REFRESH=0.55 -- evita voo sobre altura antiga durante deslocamento
local elapsed=0
local clock=0
local center=nil
local lastGround=-100

local ray=RaycastParams.new()
ray.FilterType=Enum.RaycastFilterType.Include
ray.FilterDescendantsInstances={Workspace.Terrain}
ray.IgnoreWater=true

local palette={
 Color3.fromRGB(241,205,144),
 Color3.fromRGB(204,167,222),
 Color3.fromRGB(165,204,191),
 Color3.fromRGB(243,182,174),
}
local function createPart(name,size,color,parent)
 local p=Instance.new("Part")
 p.Name=name
 p.Anchored=true
 p.CanCollide=false
 p.CanTouch=false
 p.CanQuery=false
 p.CastShadow=false
 p.Material=Enum.Material.SmoothPlastic
 p.Size=size
 p.Color=color
 p.Parent=parent
 return p
end

local butterflies={}
for i=1,COUNT do
 local model=Instance.new("Model")
 model.Name="Borboleta do prado "..i
 local color=palette[i]
 local body=createPart("Corpo",Vector3.new(0.12,0.13,0.44),Color3.fromRGB(69,61,66),model)
 body.Shape=Enum.PartType.Ball
 local left=createPart("Asa anterior esquerda",Vector3.new(0.58,0.035,0.78),color,model)
 local right=createPart("Asa anterior direita",Vector3.new(0.58,0.035,0.78),color,model)
 local lowerLeft=createPart("Asa posterior esquerda",Vector3.new(0.43,0.028,0.49),color:Lerp(Color3.fromRGB(255,239,209),0.23),model)
 local lowerRight=createPart("Asa posterior direita",Vector3.new(0.43,0.028,0.49),color:Lerp(Color3.fromRGB(255,239,209),0.23),model)
 -- Ovais de volumes delicados, evitando asas em placas retangulares genericas.
 for _,wing in {left,right,lowerLeft,lowerRight} do wing.Shape=Enum.PartType.Ball end
 model.PrimaryPart=body
 model.Parent=nil -- nao empilhar modelos em (0,0,0) antes do mundo ficar pronto
 butterflies[i]={
  model=model,body=body,left=left,right=right,
  lowerLeft=lowerLeft,lowerRight=lowerRight,
  angle=i*2.39996,radius=21+i*11,phase=i*1.7,ground=nil
 }
end

local function show(b,visible)
 if visible then
  if b.model.Parent~=folder then b.model.Parent=folder end
 elseif b.model.Parent then
  b.model.Parent=nil
 end
end
local function daylight(hour)
 -- Sem fauna colorida competindo com o por do sol ou o ceu de aurora.
 return hour>=6.3 and hour<=17.7
end
local function pathX(z)
 return math.sin((z+5)*0.027)*10+math.sin(z*0.059)*2.5
end
local function validGround(x,y,z)
 if x< -340 or x>340 or z< -480 or z>300 or y< -0.3 or y>MAX_ALTITUDE then return false end
 if z>=-258 and z<=36 and math.abs(x-pathX(z))<13 then return false end
 if x>=pathX(-89)-7 and x<=184 and math.abs(z+89)<18 then return false end
 if x>=-74 and x<=pathX(-151)+8 and math.abs(z+151)<16 then return false end
 if math.abs(x-(125+math.sin((115-z)/23*0.32)*24))<32 then return false end
 if (x+84)^2+(z+151)^2<30^2 then return false end
 return true
end
local function sampleGround(x,z)
 local hit=Workspace:Raycast(Vector3.new(x,100,z),Vector3.new(0,-200,0),ray)
 if hit and hit.Normal.Y>0.85 and validGround(x,hit.Position.Y,z) then
  return hit.Position.Y
 end
 return nil
end
local function tickWildlife(dt)
 clock+=dt
 local character=localPlayer.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 if ReplicatedStorage:GetAttribute("ForestState")~="Ready" or not root or not daylight(Lighting.ClockTime) then
  for _,b in butterflies do show(b,false) end
  return
 end
 if not center or (root.Position-center).Magnitude>85 then
  center=root.Position
  lastGround=-100
  for _,b in butterflies do b.ground=nil end
 end
 local refresh=clock-lastGround>GROUND_REFRESH
 if refresh then lastGround=clock end
 for i,b in butterflies do
  -- Trajetoria circular lenta com ondulacao organica: movimento real, nao apenas asas batendo.
  local angle=b.angle+clock*0.065*(i%2==0 and -1 or 1)+math.sin(clock*0.18+b.phase)*0.18
  local radius=b.radius+math.sin(clock*0.31+b.phase)*2.5
  local x=center.X+math.cos(angle)*radius
  local z=center.Z+math.sin(angle)*radius
  if refresh or b.ground==nil then
   b.ground=sampleGround(x,z)
  end
  local visible=b.ground~=nil and (Vector3.new(x,b.ground or 0,z)-root.Position).Magnitude<=MAX_DISTANCE
  show(b,visible)
  if visible then
   local y=b.ground+1.6+math.sin(clock*1.2+b.phase)*0.42
   local origin=CFrame.new(x,y,z)*CFrame.Angles(0,angle+math.pi/2,0)
   b.body.CFrame=origin
   local flap=math.sin(clock*7.5+b.phase)*0.56
   b.left.CFrame=origin*CFrame.new(-0.33,0,0)*CFrame.Angles(0,0,-flap)
   b.right.CFrame=origin*CFrame.new(0.33,0,0)*CFrame.Angles(0,0,flap)
   b.lowerLeft.CFrame=origin*CFrame.new(-0.27,-0.01,0.32)*CFrame.Angles(0,0,-flap*0.84)
   b.lowerRight.CFrame=origin*CFrame.new(0.27,-0.01,0.32)*CFrame.Angles(0,0,flap*0.84)
  end
 end
end

local conn=RunService.Heartbeat:Connect(function(dt)
 elapsed+=math.min(dt,0.1)
 if elapsed<UPDATE_INTERVAL then return end
 local delta=elapsed
 elapsed=0
 tickWildlife(delta)
end)
script.Destroying:Connect(function()
 conn:Disconnect()
 folder:Destroy()
end)
