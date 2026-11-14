#!/usr/bin/env python3
"""Generate JSON geometry via Roblox Luau Execution (NOT a native screenshot)."""
import hashlib
import json
import os
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "artifacts" / "visual-preview"
OUT.mkdir(parents=True, exist_ok=True)
KEY = os.environ.get("ROBLOX_API_KEY", "")
UNIVERSE = os.environ.get("ROBLOX_UNIVERSE_ID", "2660433574")
PLACE = os.environ.get("ROBLOX_PLACE_ID", "6947682498")
if not KEY:
    raise SystemExit("Configure ROBLOX_API_KEY em GitHub Actions Secrets.")

base = f"universes/{UNIVERSE}/places/{PLACE}"
endpoint = "https://apis.roblox.com/cloud/v2/"
source = (ROOT / "src/server/DreamcoreWorld.server.luau").read_text(encoding="utf-8")
probe = (ROOT / "tools/roblox-qa/export_scene.luau").read_text(encoding="utf-8")
# Source+probe in ONE execution chunk: the probe reads local 'world' from generator.
# Read stored-place provenance before executing branch source in memory.
preamble = """
local storedGenerator=game:GetService("ServerScriptService"):FindFirstChild("DreamcoreWorld",true)
local storedWorldVersion=nil
if storedGenerator then
 local readable,storedSource=pcall(function() return storedGenerator.Source end)
 if readable then storedWorldVersion=string.match(storedSource, 'WorldVersion",(%d+)') end
end
local storedPlaceVersion=game.PlaceVersion
"""
code = preamble + source + "\n" + probe

def request(path, payload=None):
    data = None if payload is None else json.dumps(payload).encode()
    req = urllib.request.Request(
        endpoint + path,
        data=data,
        method="POST" if data is not None else "GET",
        headers={"x-api-key": KEY, "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=50) as reply:
            return json.load(reply)
    except urllib.error.HTTPError as exc:
        message = exc.read().decode("utf-8", errors="replace").replace(KEY, "[REDACTED]")
        raise SystemExit(f"Erro API Roblox HTTP {exc.code}: {message[:450]}") from None

task = request(base + "/luau-execution-session-tasks", {"script": code})
path = task.get("path", "")
if not path.startswith(base + "/"):
    raise SystemExit("API Roblox nao retornou um identificador de tarefa valido.")
end = time.monotonic() + 240
while time.monotonic() < end:
    task = request(path)
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
scene["meta"]["taskPath"] = path
scene["meta"]["source"] = "Luau Execution Roblox; geometria da engine, sem viewport renderizado"
scene["meta"]["renderWarning"] = "Blender aproxima geometria/material/sol; nao reproduz shaders nem terrain Roblox"
(OUT / "scene.json").write_text(json.dumps(scene, ensure_ascii=False) + "\n", encoding="utf-8")
print(f"Snapshot: {scene['meta']['partsExported']}/{scene['meta']['partsTotal']} partes; nao e screenshot real.")
