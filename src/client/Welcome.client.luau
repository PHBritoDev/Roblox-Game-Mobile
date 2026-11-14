-- Mundo 1: vinheta de chegada sutil, legivel no celular.
local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local gui=Instance.new("ScreenGui")
gui.Name="ForestArrival"
gui.ResetOnSpawn=false
gui.IgnoreGuiInset=true
gui.DisplayOrder=10
gui.Parent=player:WaitForChild("PlayerGui")
local function label(name,y,height,size,content)
 local t=Instance.new("TextLabel")
 t.Name=name
 t.AnchorPoint=Vector2.new(0.5,0)
 t.Position=UDim2.fromScale(0.5,y)
 t.Size=UDim2.fromScale(0.91,height)
 t.BackgroundTransparency=1
 t.Text=content
 t.Font=Enum.Font.Gotham
 t.TextSize=size
 t.TextScaled=false
 t.TextWrapped=true
 t.TextColor3=Color3.fromRGB(255,234,209)
 t.TextStrokeColor3=Color3.fromRGB(36,42,58)
 t.TextStrokeTransparency=0.25
 t.TextTransparency=1
 t.Parent=gui
 return t
end
local title=label("WorldTitle",0.095,0.07,28,"FLORESTA DAS MEMÓRIAS")
title.Font=Enum.Font.GothamBold
local subtitle=label("WorldSubtitle",0.167,0.06,15,"Mundo I  ·  Onde a luz recorda")
local hint=label("WorldHint",0.835,0.05,14,"Siga a trilha até a árvore ancestral")
-- A chegada acompanha o servidor e pede streaming na area inicial antes da vinheta.
hint.Text="Carregando a floresta…"
hint.TextTransparency=0
local deadline=os.clock()+45
while ReplicatedStorage:GetAttribute("ForestState")~="Ready"
 and ReplicatedStorage:GetAttribute("ForestState")~="Failed" and os.clock()<deadline do
 task.wait(0.25)
end
if ReplicatedStorage:GetAttribute("ForestState")=="Ready" then
 pcall(function() player:RequestStreamAroundAsync(Vector3.new(0,4,8),8) end)
 hint.Text="Siga a trilha até a árvore ancestral"
else
 hint.Text="A floresta demorou a carregar. Tente entrar novamente."
end
subtitle.Text=string.format("Mundo I · V%s · Roblox %s",tostring(ReplicatedStorage:GetAttribute("ForestVersion") or "?"),tostring(game.PlaceVersion))
for _,t in ipairs({title,subtitle,hint}) do
 TweenService:Create(t,TweenInfo.new(1.6,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{TextTransparency=0}):Play()
end
task.delay(10,function()
 if not gui.Parent then return end
 for _,t in ipairs({title,subtitle,hint}) do
  TweenService:Create(t,TweenInfo.new(2,Enum.EasingStyle.Sine,Enum.EasingDirection.In),{TextTransparency=1}):Play()
 end
 task.wait(2.3)
 gui:Destroy()
end)
