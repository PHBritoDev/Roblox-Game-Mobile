-- Roblox Open Cloud Luau Execution: auditoria headless, apenas leitura.
-- IMPORTANTE: scripts do Place NAO iniciam automaticamente neste tipo de tarefa.
-- Não salvar alterações, alterar DataStores, publicar ou executar código de jogo.
local workspace = game:GetService("Workspace")
local lighting = game:GetService("Lighting")
local scripts = game:GetService("ServerScriptService")
local starterPlayer = game:GetService("StarterPlayer")
local serverScript = scripts:FindFirstChild("DreamcoreWorld", true)
local clientScript = starterPlayer:FindFirstChild("Welcome", true)
local generated = workspace:FindFirstChild("DreamcoreGenerated")
local spawn = workspace:FindFirstChild("Nascimento Dreamcore", true)
local effects = {}
for _, child in lighting:GetChildren() do
    if child:IsA("PostEffect") or child:IsA("Atmosphere") then
        table.insert(effects, { name = child.Name, class = child.ClassName })
    end
end
local report = {
    kind = "roblox_engine_headless",
    placeId = game.PlaceId,
    universeId = game.GameId,
    serverGeneratorPresent = serverScript ~= nil,
    clientWelcomePresent = clientScript ~= nil,
    generatedWorldLoaded = generated ~= nil,
    spawnPresentInStoredPlace = spawn ~= nil,
    lightingClockTime = lighting.ClockTime,
    lightingEffects = effects,
    workspaceChildCount = #workspace:GetChildren(),
    explanation = "Task headless: scripts nao rodam automaticamente; nao testa o mundo gerado em Play nem captura frames.",
    actualVisualCapture = false,
    playtestPerformed = false,
}
assert(serverScript ~= nil, "Script gerador ausente na versao do Place")
return report
