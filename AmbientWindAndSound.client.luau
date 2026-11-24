-- Movimentacao ambiental suave da vegetacao rasteira e estado sonoro dia/noite (Android).
-- Opera apenas no cliente, em raio curto (70 studs) e a 8 Hz, sem fisica nem rede.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Lighting=game:GetService("Lighting")
local Workspace=game:GetService("Workspace")
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local localPlayer=Players.LocalPlayer
local UPDATE_INTERVAL=0.125 -- 8 Hz para economizar CPU/bateria no Android
local SWAY_RADIUS=70
local MAX_SWAY_PARTS=28
local RESCAN_INTERVAL=2.5

local elapsed=0
local clock=0
local lastScan=-100
local trackedParts={}

local function isNight(hour)
 return hour>=19.5 or hour<=5.6
end

local function rescanNearbyFoliage(origin)
 table.clear(trackedParts)
 local generated=Workspace:FindFirstChild("DreamcoreGenerated")
 if not generated then return end
 for _,folderName in ipairs({"Lago do Reflexo — recanto nostalgico","Sub-bosque autoral permanente"}) do
  local folder=generated:FindFirstChild(folderName)
  if folder then
   for _,item in ipairs(folder:GetChildren()) do
    if #trackedParts>=MAX_SWAY_PARTS then break end
    if item:IsA("BasePart") and not item.CanCollide then
     local dist=(item.Position-origin).Magnitude
     if dist<=SWAY_RADIUS then
      local baseCF=item:GetAttribute("BaseCFrame")
      if not baseCF then
       baseCF=item.CFrame
       item:SetAttribute("BaseCFrame",baseCF)
      end
      table.insert(trackedParts,{part=item,base=baseCF,phase=(item.Position.X*0.37+item.Position.Z*0.53)})
     end
    end
   end
  end
 end
end

local function stepAmbient(dt)
 clock+=dt
 if ReplicatedStorage:GetAttribute("ForestState")~="Ready" then return end
 local character=localPlayer.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 if not root then return end

 -- Atualiza estado ambiental de audio/atmosfera local conforme o horario
 local hour=Lighting.ClockTime
 local night=isNight(hour)
 localPlayer:SetAttribute("AmbientSoundProfile",if night then "NightCricketsAndBreeze" else "DaylightMeadowBreeze")
 localPlayer:SetAttribute("NightCricketsActive",night)

 if clock-lastScan>=RESCAN_INTERVAL then
  lastScan=clock
  rescanNearbyFoliage(root.Position)
 end

 for i,entry in ipairs(trackedParts) do
  local p=entry.part
  if p and p.Parent then
   local sway=math.sin(clock*1.85+entry.phase)*0.045
   local roll=math.cos(clock*1.35+entry.phase)*0.032
   p.CFrame=entry.base*CFrame.Angles(sway,0,roll)
  end
 end
end

local conn=RunService.Heartbeat:Connect(function(dt)
 elapsed+=math.min(dt,0.1)
 if elapsed<UPDATE_INTERVAL then return end
 local delta=elapsed
 elapsed=0
 stepAmbient(delta)
end)

script.Destroying:Connect(function()
 conn:Disconnect()
 table.clear(trackedParts)
end)
