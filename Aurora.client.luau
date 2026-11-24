-- Cortinas de aurora originais para noites da Floresta das Memorias.
-- Beam leve, sem texturas/sons de terceiros, sem fisica ou replicaçao por frame.
-- A aparencia final precisa de captura REAL em cliente Roblox; proxy Blender nao cobre Beams.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Lighting=game:GetService("Lighting")
local Workspace=game:GetService("Workspace")
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local localPlayer=Players.LocalPlayer
local existing=Workspace:FindFirstChild("DreamcoreLocalAurora")
if existing then existing:Destroy() end
local folder=Instance.new("Folder")
folder.Name="DreamcoreLocalAurora"
folder.Parent=Workspace

local UPDATE_INTERVAL=0.15 -- maximo 7 Hz, so para VFX
local MAX_BANDS=4
local elapsed=0
local clock=0
local anchorCenter=nil

local palette={
 Color3.fromRGB(84,182,181),
 Color3.fromRGB(122,137,214),
 Color3.fromRGB(165,99,215),
 Color3.fromRGB(98,175,162),
}

local function anchor(name)
 local p=Instance.new("Part")
 p.Name=name
 p.Anchored=true
 p.Transparency=1
 p.Size=Vector3.new(0.5,0.5,0.5)
 p.CanCollide=false
 p.CanTouch=false
 p.CanQuery=false
 p.CastShadow=false
 p.Parent=folder
 local attachment=Instance.new("Attachment")
 attachment.Parent=p
 return p,attachment
end

local function createBand(index)
 local left,leftAttach=anchor("Aurora esquerda "..index)
 local right,rightAttach=anchor("Aurora direita "..index)
 local beam=Instance.new("Beam")
 beam.Name="Cortina boreal "..index
 beam.Attachment0=leftAttach
 beam.Attachment1=rightAttach
 beam.FaceCamera=true
 beam.Segments=28
 beam.Width0=26+index*6
 beam.Width1=23+index*5
 beam.LightEmission=0.48
 beam.LightInfluence=0
 beam.CurveSize0=48
 beam.CurveSize1=-46
 beam.Enabled=false
 local color=palette[index]
 local blend=palette[(index%#palette)+1]
 beam.Color=ColorSequence.new({
  ColorSequenceKeypoint.new(0,color),
  ColorSequenceKeypoint.new(0.5,blend),
  ColorSequenceKeypoint.new(1,color)
 })
 beam.Parent=left
 return {left=left,right=right,beam=beam,index=index,phase=index*1.84}
end

local bands={}
for index=1,MAX_BANDS do
 bands[index]=createBand(index)
end

local function nightVisibility()
 local hour=Lighting.ClockTime
 if hour>=20.5 then return math.clamp((hour-20.5)/2.1,0,1) end
 if hour<5.4 then return math.clamp((5.4-hour)/1.3,0,1) end
 return 0
end

local function updateAurora(dt)
 clock+=dt
 local character=localPlayer.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 local factor=nightVisibility()
 if ReplicatedStorage:GetAttribute("ForestState")~="Ready" or not root or factor<0.02 then
  for _,band in bands do band.beam.Enabled=false end
  return
 end
 if not anchorCenter or (anchorCenter-root.Position).Magnitude>175 then
  anchorCenter=root.Position
 end
 for _,band in bands do
  local i=band.index
  local drift=math.sin(clock*0.10+band.phase)*18
  local wave=math.sin(clock*0.14+band.phase)*11
  local z=-165-i*26
  local height=218+i*18
  band.left.CFrame=CFrame.new(anchorCenter+Vector3.new(-300+drift,height+wave,z))
  band.right.CFrame=CFrame.new(anchorCenter+Vector3.new(300+drift,height-wave,z))
  band.beam.CurveSize0=36+math.sin(clock*0.08+band.phase)*23
  band.beam.CurveSize1=-40+math.cos(clock*0.09+band.phase)*19
  local strength=(0.14+math.sin(clock*0.11+band.phase)*0.025)*factor
  -- Bordas invisiveis e miolo suave evitam uma faixa neon opaca.
  local middle=1-strength
  band.beam.Transparency=NumberSequence.new({
   NumberSequenceKeypoint.new(0,1),
   NumberSequenceKeypoint.new(0.13,1-strength*0.54),
   NumberSequenceKeypoint.new(0.38,middle),
   NumberSequenceKeypoint.new(0.65,1-strength*0.83),
   NumberSequenceKeypoint.new(0.86,1-strength*0.42),
   NumberSequenceKeypoint.new(1,1)
  })
  band.beam.Width0=25+i*6+math.sin(clock*0.17+band.phase)*4
  band.beam.Width1=22+i*5+math.cos(clock*0.16+band.phase)*4
  band.beam.Enabled=true
 end
end

local connection=RunService.Heartbeat:Connect(function(dt)
 elapsed+=math.min(dt,0.1)
 if elapsed<UPDATE_INTERVAL then return end
 local interval=elapsed
 elapsed=0
 updateAurora(interval)
end)

script.Destroying:Connect(function()
 connection:Disconnect()
 folder:Destroy()
end)
