#!/usr/bin/env python3
"""Safely query Roblox's runtime InsertService access; never publish a Place."""
from __future__ import annotations
import json
import os
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
URL="https://apis.roblox.com/cloud/v2/"
RESOURCE="universes/2660433574/places/6947682498"
OUT=ROOT/"artifacts/assets/runtime_tree_probe.json"

def request(path,key,payload=None):
    data=None if payload is None else json.dumps(payload).encode()
    req=urllib.request.Request(URL+path,data=data,
        method="POST" if data is not None else "GET",
        headers={"x-api-key":key,"Content-Type":"application/json"})
    try:
        with urllib.request.urlopen(req,timeout=50) as response:
            return json.load(response)
    except urllib.error.HTTPError as err:
        detail=err.read().decode(errors="replace").replace(key,"[REDACTED]")
        raise RuntimeError(f"HTTP {err.code}: {detail[:350]}") from None

def interpret(task):
    outputs=task.get("output",{}).get("results",[])
    report=next((x for x in outputs if isinstance(x,dict)
        and x.get("kind")=="dreamcore_runtime_tree_asset_probe"),None)
    result={"taskState":task.get("state"),"result":report,
        "error":str(task.get("error"))[:350],"actualRobloxScreenshot":False,
        "scope":"headless InsertService diagnostic; not a live Android playtest"}
    return result

def success(result):
    rows=(result.get("result") or {}).get("results",[])
    return (result["taskState"]=="COMPLETE" and len(rows)==2
        and all(x.get("loadSucceeded") and x.get("meshParts",0)>0
                and not x.get("missingNames") for x in rows))

def main():
    key=os.getenv("ROBLOX_API_KEY","")
    if not key:
        raise SystemExit("ROBLOX_API_KEY unavailable")
    code=(ROOT/"tools/roblox-qa/probe_runtime_trees.luau").read_text(encoding="utf-8")
    OUT.parent.mkdir(parents=True,exist_ok=True)
    result={"taskState":"NOT_STARTED","actualRobloxScreenshot":False}
    try:
        task=request(RESOURCE+"/luau-execution-session-tasks",key,{"script":code})
        path=task.get("path","")
        if not path.startswith(RESOURCE+"/"):
            raise RuntimeError("Invalid task path returned by Roblox")
        deadline=time.monotonic()+330
        while time.monotonic()<deadline:
            task=request(path,key)
            if task.get("state")!="PROCESSING":
                break
            time.sleep(min(5,max(0,deadline-time.monotonic())))
        result=interpret(task)
        result["taskPath"]=path
    except (RuntimeError,TimeoutError,urllib.error.URLError) as exc:
        result={"taskState":"REQUEST_FAILED","error":str(exc)[:350],
            "actualRobloxScreenshot":False}
    OUT.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(result,ensure_ascii=False)[:2500])
    if not success(result):
        raise SystemExit("Runtime tree access not confirmed; see artifact")

if __name__=="__main__":
    main()
