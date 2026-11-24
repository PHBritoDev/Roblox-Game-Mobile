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
-- V30: nao declarar falha apenas porque assets/terrain ainda estao gerando.
-- O cliente observa explicitamente Ready/Failed e apresenta estado de progresso.
hint.Text="Preparando a floresta…"
hint.TextTransparency=0
-- Mensagens de progresso reais, derivadas da etapa replicada pelo servidor.
-- Evita mostrar "gerando solo" durante downloads ou finalizacao no Android.
local stageHints={
 Starting="Iniciando a floresta…",
 ClearingTerrain="Preparando o terreno…",
 BuildingGround="Modelando o chão e as trilhas…",
 WritingTerrain="Aplicando materiais ao terreno…",
 PlantingForest="Plantando a floresta…",
 LoadingSynty="Posicionando detalhes da floresta…",
 LoadingForestPack="Preparando árvores e vegetação…",
 ConfiguringLighting="Ajustando a luz da floresta…",
 Finalizing="Finalizando caminhos e colisões…",
 Ready="Siga a trilha até a árvore ancestral",
}
local function progressHint()
 local stage=tostring(ReplicatedStorage:GetAttribute("ForestStage") or "Starting")
 return stageHints[stage] or "Preparando a floresta…"
end
local world=workspace:FindFirstChild("DreamcoreGenerated")
local deadline=time()+120
local state=ReplicatedStorage:GetAttribute("ForestState")
while state~="Ready" and state~="Failed" and time()<deadline do
 task.wait(0.35)
 state=ReplicatedStorage:GetAttribute("ForestState")
 world=workspace:FindFirstChild("DreamcoreGenerated")
 if state~="Failed" then
  hint.Text=if state=="Generating" then progressHint() else "Conectando ao mundo…"
 end
end
if state=="Ready" then
 hint.Text="Siga a trilha até a árvore ancestral"
 -- Streaming pode falhar por rede; nao transformar isto em erro de geracao.
 task.spawn(function()
  -- Streaming deve seguir a posicao atual do jogador, nao o spawn fixo:
  -- em Android o jogador pode ter caminhado enquanto o servidor gerava o mundo.
  local character=player.Character
  local root=character and character:FindFirstChild("HumanoidRootPart")
  local origin=root and root.Position or Vector3.new(0,4,8)
  pcall(function() player:RequestStreamAroundAsync(origin,10) end)
  -- Diagnostico local, separado do Ready do servidor e sem prometer renderizacao.
  -- Apenas IDs de meshes visiveis neste cliente; streaming posterior fica fora da amostra.
  -- Android: diagnosticar somente malhas proximas do jogador, sem forcar
  -- o download de toda a floresta antes de o jogador caminhar ate ela.
  local ids,seen={},{}
  local generated=workspace:FindFirstChild("DreamcoreGenerated")
  local maxSample=64
  if generated then
   -- Evitar pico em um unico frame Android ao inspecionar milhares de objetos.
   -- O diagnostico roda em task separada; ceder a cada lote preserva a UI.
   for index,item in generated:GetDescendants() do
    if #ids>=maxSample then break end
    if index%256==0 then task.wait() end
    if item:IsA("MeshPart") and item.MeshId~=""
      and (item.Position-origin).Magnitude<=160 and not seen[item.MeshId] then
     seen[item.MeshId]=true
     table.insert(ids,item.MeshId)
    end
   end
  end
  player:SetAttribute("ForestMeshPreloadComplete",false)
  local failures=0
  local ok=pcall(function()
   game:GetService("ContentProvider"):PreloadAsync(ids,function(_,status)
    if status~=Enum.AssetFetchStatus.Success then failures+=1 end
   end)
  end)
  player:SetAttribute("ForestMeshFetchFailures",failures)
  player:SetAttribute("ForestMeshFetchSample",#ids)
  player:SetAttribute("ForestMeshPreloadComplete",ok)
  if failures>0 or not ok then warn("[Dreamcore client] Falha de conteudo de malha; diagnostico local disponivel") end
 end)
elseif state=="Failed" then
 local code=tostring(ReplicatedStorage:GetAttribute("ForestErrorCode") or "Unknown")
 hint.Text="Erro ao criar floresta ("..code.."). Tente entrar em outro servidor."
else
 hint.Text="A floresta continua carregando. Você já pode explorar o caminho."
 -- Nao afirmar que a geracao falhou: pode apenas estar atrasada no servidor.
 task.spawn(function()
  while gui.Parent do
   local current=ReplicatedStorage:GetAttribute("ForestState")
   if current=="Ready" then hint.Text="Siga a trilha até a árvore ancestral"; break end
   if current=="Generating" then hint.Text=progressHint() end
   if current=="Failed" then hint.Text="Não foi possível criar a floresta. Tente outro servidor."; break end
   task.wait(2)
  end
 end)
end
subtitle.Text=string.format("Mundo I · V%s · Roblox %s",tostring(ReplicatedStorage:GetAttribute("ForestVersion") or "?"),tostring(game.PlaceVersion))
for _,t in ipairs({title,subtitle,hint}) do
 TweenService:Create(t,TweenInfo.new(1.6,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{TextTransparency=0}):Play()
end
task.spawn(function()
 while gui.Parent do
  local current=ReplicatedStorage:GetAttribute("ForestState")
  if current=="Ready" or current=="Failed" then break end
  task.wait(1)
 end
 -- Erros definitivos tambem liberam a tela; progresso lento continua visivel.
 task.wait(10)
 if not gui.Parent then return end
 for _,t in ipairs({title,subtitle,hint}) do
  TweenService:Create(t,TweenInfo.new(2,Enum.EasingStyle.Sine,Enum.EasingDirection.In),{TextTransparency=1}):Play()
 end
 task.wait(2.3)
 gui:Destroy()
end)
