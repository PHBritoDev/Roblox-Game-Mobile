#!/usr/bin/env python3
"""Read-only Luau Execution API task for an existing Roblox Place."""
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "artifacts" / "engine"
OUT.mkdir(parents=True, exist_ok=True)
KEY = os.environ.get("ROBLOX_API_KEY", "")
UNIVERSE = os.environ.get("ROBLOX_UNIVERSE_ID", "")
PLACE = os.environ.get("ROBLOX_PLACE_ID", "")
if not (KEY and UNIVERSE.isdecimal() and PLACE.isdecimal()):
    raise SystemExit("Faltam API key/Universe ID/Place ID. Nenhum teste executado.")
API = "https://apis.roblox.com/cloud/v2/"
BASE = f"universes/{UNIVERSE}/places/{PLACE}"

def request(path, payload=None):
    data = None if payload is None else json.dumps(payload).encode()
    req = urllib.request.Request(
        API + path,
        data=data,
        headers={"x-api-key": KEY, "Content-Type": "application/json"},
        method="POST" if data is not None else "GET",
    )
    try:
        with urllib.request.urlopen(req, timeout=40) as response:
            return json.loads(response.read())
    except urllib.error.HTTPError as e:
        raw = e.read().decode("utf-8", "replace")
        # Avoid leaking any credentials in errors.
        raw = raw.replace(KEY, "[REDACTED]")
        raise SystemExit(f"Roblox HTTP {e.code}: {raw[:400]}") from None

script = (ROOT / "tools" / "roblox-qa" / "engine_probe.luau").read_text()
task = request(BASE + "/luau-execution-session-tasks", {"script": script})
path = task.get("path")
if not path or not path.startswith(f"{BASE}/"):
    raise SystemExit("API retornou task path inesperado.")
state = "PROCESSING"
end = time.monotonic() + 180
while time.monotonic() < end:
    task = request(path)
    state = task.get("state", "UNKNOWN")
    if state != "PROCESSING":
        break
    time.sleep(4)
else:
    raise SystemExit("Task sem resposta após 180s.")

result = {
    "taskState": state,
    "headless": True,
    "screenCapture": False,
    "playtest": False,
    "output": task.get("output", {}).get("results", []),
    "error": task.get("error"),
}
(OUT / "resultado.json").write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n")
print("Estado:", state)
print("Resultado:", json.dumps(result["output"], ensure_ascii=False)[:2500])
if state != "COMPLETE":
    raise SystemExit(f"Task Roblox terminou com estado {state}.")
