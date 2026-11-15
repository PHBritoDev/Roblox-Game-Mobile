#!/usr/bin/env python3
"""Generate engine geometry and navigation evidence, optionally with failed asset loads."""
import argparse
import hashlib
import json
import os
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ENDPOINT = "https://apis.roblox.com/cloud/v2/"
PREAMBLE = """
local storedGenerator=game:GetService("ServerScriptService"):FindFirstChild("DreamcoreWorld",true)
local storedWorldVersion=nil
if storedGenerator then
 local readable,storedSource=pcall(function() return storedGenerator.Source end)
 if readable then storedWorldVersion=string.match(storedSource, 'WorldVersion",(%d+)') end
end
local storedPlaceVersion=game.PlaceVersion
"""


def source_without_assets(source):
    """Change only the two audited calls inside their existing pcall guards."""
    for asset_id in (6933438443, 6432306802):
        original = f"return InsertService:LoadAsset({asset_id})"
        if source.count(original) != 1:
            raise ValueError(f"Expected exactly one audited LoadAsset call for {asset_id}")
        source = source.replace(original, 'error("QA forced asset failure")', 1)
    source = source.replace('local bundled=game:GetService("ServerStorage"):FindFirstChild("ForestLibrary")', 'local bundled=nil')
    return source


def bundled_fixture():
    """Engine fixture from the same official meshes; NOT a deserialized build/playtest.

    Verify IDs and sizes against the committed XML before exercising bundled path.
    Roblox headless cannot open an arbitrary local rbxlx without saving a Place.
    """
    manifest = json.loads((ROOT / "assets/forest-manifest.json").read_text())
    encoded = json.dumps(manifest["packages"], ensure_ascii=False)
    return """
local fixtureManifest=game:GetService("HttpService"):JSONDecode([==[%s]==])
local storage=game:GetService("ServerStorage")
local existingLibrary=storage:FindFirstChild("ForestLibrary")
if existingLibrary then existingLibrary:Destroy() end
local fixture=Instance.new("Folder")
fixture.Name="ForestLibrary"
local allowed={Folder=true,Model=true,MeshPart=true,SurfaceAppearance=true}
for name,entry in fixtureManifest do
 local original=game:GetService("InsertService"):LoadAsset(entry.assetId)
 local package=Instance.new("Folder"); package.Name=name; package.Parent=fixture
 for _,template in entry.templates do
  local found=original:FindFirstChild(template.name,true)
  assert(found,"Bundled fixture template missing: "..template.name)
  local clone=found:Clone()
  for _,child in clone:GetDescendants() do
   if not allowed[child.ClassName] then child:Destroy() end
  end
  local meshes={}
  if clone:IsA("MeshPart") then table.insert(meshes,clone) end
  for _,child in clone:GetDescendants() do
   if child:IsA("MeshPart") then table.insert(meshes,child) end
  end
  table.sort(meshes,function(a,b) return a.MeshId<b.MeshId end)
  assert(#meshes==#template.meshes,"Bundled fixture mesh count changed")
  for index,mesh in meshes do
   local expected=template.meshes[index]
   assert(mesh.MeshId==expected.id,"Official asset changed since bake")
   assert((mesh.Size-Vector3.new(unpack(expected.size))).Magnitude<0.01,"Baked mesh size differs")
  end
  clone.Parent=package
 end
 original:Destroy()
end
fixture.Parent=storage
""" % encoded


def source_with_integration_failure(source):
    """Fail after a successful clone, not merely when the network is unavailable."""
    for marker in ("   site.completed=true", "   if ok then forestCount+=1; site.completed=true"):
        if source.count(marker) != 1:
            raise ValueError("Integration fault marker missing/duplicated")
        source = source.replace(marker, '   error("QA forced integration failure")\n'+marker, 1)
    return source


def request(path, key, payload=None):
    data = None if payload is None else json.dumps(payload).encode()
    req = urllib.request.Request(
        ENDPOINT + path, data=data,
        method="POST" if data is not None else "GET",
        headers={"x-api-key": key, "Content-Type": "application/json"},
    )
    # Retrying POST could execute the generator twice; only GET is retried.
    attempts = 3 if data is None else 1
    for attempt in range(attempts):
        try:
            with urllib.request.urlopen(req, timeout=50) as reply:
                return json.load(reply)
        except urllib.error.HTTPError as exc:
            message = exc.read().decode("utf-8", errors="replace").replace(key, "[REDACTED]")
            if exc.code in (429, 502, 503, 504) and attempt+1 < attempts:
                time.sleep(2**attempt)
                continue
            raise SystemExit(f"Erro API Roblox HTTP {exc.code}: {message[:450]}") from None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--without-assets", action="store_true",
                        help="Force both licensed asset loads to fail in memory and validate fallback")
    parser.add_argument("--integration-failure", action="store_true")
    args = parser.parse_args()
    out = ROOT / "artifacts" / "visual-preview"
    if args.without_assets:
        out /= "fallback"
    if args.integration_failure:
        out /= "integration-failure"
    out.mkdir(parents=True, exist_ok=True)
    key = os.environ.get("ROBLOX_API_KEY", "")
    universe = os.environ.get("ROBLOX_UNIVERSE_ID", "2660433574")
    place = os.environ.get("ROBLOX_PLACE_ID", "6947682498")
    if not key:
        raise SystemExit("Configure ROBLOX_API_KEY em GitHub Actions Secrets.")
    base = f"universes/{universe}/places/{place}"
    source = (ROOT / "src/server/DreamcoreWorld.server.luau").read_text(encoding="utf-8")
    probe = (ROOT / "tools/roblox-qa/export_scene.luau").read_text(encoding="utf-8")
    executed_source = source_without_assets(source) if args.without_assets else source
    if args.integration_failure:
        executed_source = source_with_integration_failure(executed_source)
    # Source and probe share one execution chunk; source file is never modified.
    fixture = "" if args.without_assets else bundled_fixture()
    # A V33 publica o spawn antes de iniciar a floresta completa numa task.
    # O probe headless precisa aguardar Ready/Failed, sem aceitar cena parcial.
    await_generation = """
local snapshotReplicated=game:GetService("ReplicatedStorage")
local snapshotDeadline=os.clock()+180
while snapshotReplicated:GetAttribute("ForestState")=="Generating"
    and os.clock()<snapshotDeadline do
 task.wait(0.5)
end
local snapshotStatus=snapshotReplicated:GetAttribute("ForestState")
assert(snapshotStatus=="Ready",
    "Headless V33 not ready: "..tostring(snapshotStatus)..", stage="..
    tostring(snapshotReplicated:GetAttribute("ForestStage")))
"""
    code = PREAMBLE + fixture + executed_source + "\n" + await_generation + "\n" + probe
    task = request(base + "/luau-execution-session-tasks", key, {"script": code})
    path = task.get("path", "")
    if not path.startswith(base + "/"):
        raise SystemExit("API Roblox nao retornou um identificador de tarefa valido.")
    end = time.monotonic() + 240
    while time.monotonic() < end:
        task = request(path, key)
        if task.get("state") != "PROCESSING":
            break
        time.sleep(5)
    if task.get("state") != "COMPLETE":
        raise SystemExit(f"Auditoria headless incompleta: {task.get('state')}; {str(task.get('error'))[:300]}")
    results = task.get("output", {}).get("results", [])
    scene = next((item for item in results if isinstance(item, dict) and item.get("kind") == "roblox_headless_geometry_snapshot"), None)
    if not scene:
        raise SystemExit("Tarefa executou mas nao retornou geometria; verificar output Luau.")
    if len(scene.get("parts", [])) < 30:
        raise SystemExit("Amostra inesperadamente pequena, previsualizacao recusada.")
    scene["meta"]["sourceCommit"] = os.environ.get("GITHUB_SHA", "local")
    scene["meta"]["sourceSha256"] = hashlib.sha256(source.encode()).hexdigest()
    scene["meta"]["executedSourceSha256"] = hashlib.sha256(executed_source.encode()).hexdigest()
    scene["meta"]["executedScriptSha256"] = hashlib.sha256(code.encode()).hexdigest()
    scene["meta"]["forcedAssetFailure"] = args.without_assets
    scene["meta"]["forcedIntegrationFailure"] = args.integration_failure
    scene["meta"]["bakedEquivalentFixture"] = not args.without_assets
    scene["meta"]["taskPath"] = path
    scene["meta"]["source"] = "Luau Execution Roblox; geometria da engine, sem viewport renderizado"
    scene["meta"]["renderWarning"] = "Blender aproxima geometria/material/sol; nao reproduz shaders nem terrain Roblox"
    (out / "scene.json").write_text(json.dumps(scene, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Snapshot: {scene['meta']['partsExported']}/{scene['meta']['partsTotal']} partes; fallback={args.without_assets}; nao e screenshot real.")


if __name__ == "__main__":
    main()
