#!/usr/bin/env python3
"""Inspect Roblox-owned official pack safely in headless session. Never publishes."""
import json,os,time,urllib.request,urllib.error
from pathlib import Path
root=Path(__file__).resolve().parents[2]
key=os.environ.get("ROBLOX_API_KEY","")
if not key: raise SystemExit("ROBLOX_API_KEY ausente")
base="https://apis.roblox.com/cloud/v2/"
resource="universes/2660433574/places/6947682498"
def request(path,data=None):
 req=urllib.request.Request(base+path,data=None if data is None else json.dumps(data).encode(),headers={"x-api-key":key,"Content-Type":"application/json"},method="POST" if data is not None else "GET")
 try:
  with urllib.request.urlopen(req,timeout=45) as response: return json.load(response)
 except urllib.error.HTTPError as e:
  detail=e.read().decode(errors="replace").replace(key,"[REDACTED]")
  raise SystemExit(f"HTTP {e.code}: {detail[:400]}") from None
script=(root/"tools/roblox-qa/probe_forest_asset.luau").read_text()
task=request(resource+"/luau-execution-session-tasks",{"script":script})
path=task.get("path","")
if not path.startswith(resource+"/"):raise SystemExit("Task identificador inesperado")
for attempt in range(36):
 task=request(path)
 if task.get("state")!="PROCESSING":break
 time.sleep(5)
else: raise SystemExit("Timeout")
out={"state":task.get("state"),"results":task.get("output",{}).get("results",[]),"error":task.get("error")}
f=root/"artifacts/assets/forest_probe.json"
f.parent.mkdir(parents=True,exist_ok=True)
f.write_text(json.dumps(out,ensure_ascii=False,indent=2))
print(json.dumps(out,ensure_ascii=False)[:3500])
if out["state"]!="COMPLETE":raise SystemExit("Engine probe failed")
if not any(isinstance(x,dict) and x.get("kind")=="forest_asset_probe" and x.get("success") for x in out["results"]):raise SystemExit("Asset inaccessible; review report")
