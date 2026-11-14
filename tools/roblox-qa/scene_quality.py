#!/usr/bin/env python3
"""Measured geometric QA for the Blender proxy, not a Roblox gameplay/visual test."""
import json
import math
from collections import Counter
from pathlib import Path

root = Path(__file__).resolve().parents[2]
folder = root / "artifacts/visual-preview"
scene = json.loads((folder / "scene.json").read_text(encoding="utf-8"))
parts = scene["parts"]
counts = Counter(p["n"] for p in parts)
origins = Counter(p.get("origin", "Authored") for p in parts)
forest_models = scene["meta"].get("forestModels", 0)
undergrowth_models = scene["meta"].get("forestUndergrowthModels", 0)
undergrowth_variants = scene["meta"].get("forestUndergrowthVariants", 0)

def path_x(z):
    return math.sin((z+5)*0.027)*10 + math.sin(z*0.059)*2.5

# The central trail runs from z ~= 24 to -254. Only rigid trunks directly in this
# corridor are a potential physical obstruction; leaves are intentionally ignored.
trunks = [p for p in parts if p["n"] == "Tronco musgoso"]
trunk_obstructions = [
    {"position": p["p"], "size": p["s"]}
    for p in trunks
    if -250 <= p["p"][2] <= 24
    and abs(p["p"][0] - path_x(p["p"][2])) < (7.5 + p["s"][0]/2)
]
# Forest Pack parts use textured meshes; their bounding boxes are only a rough
# obstruction estimate (not equivalent to a collision test).
forest_trunk_obstructions = [
    {"name": p["n"], "position": p["p"], "size": p["s"]}
    for p in parts
    if p.get("origin") == "ForestPack"
    and "Trunk" in p["n"]
    and -232 <= p["p"][2] <= 24
    and abs(p["p"][0] - path_x(p["p"][2])) < (10 + min(p["s"][0] / 2, 24))
]
report = {
    "kind": "geometric_proxy_qa",
    "robloxScreenshot": False,
    "runtimePlaytest": False,
    "sampledParts": len(parts),
    "totalGeneratedParts": scene["meta"]["partsTotal"],
    "treeTrunks": counts["Tronco musgoso"],
    "forestPackModels": forest_models,
    "forestUndergrowthModels": undergrowth_models,
    "forestUndergrowthVariants": undergrowth_variants,
    "forestPackParts": origins["ForestPack"],
    "syntyParts": origins["Synty"],
    "treeCanopySections": counts["Copa em camadas"]+counts["Coroa alta"],
    "relicColumns": counts["Sentinela esquecida"]+counts["Sentinela quebrada"]+counts["Pilar do santuario"],
    "trunksIntersectingMainPath": trunk_obstructions[:20],
    "forestMeshTrunksCloseToPath": forest_trunk_obstructions[:20],
    "pass": len(parts) == scene["meta"]["partsTotal"]
       and forest_models >= 25
       and undergrowth_models >= 12
       and undergrowth_variants >= 1
       and origins["ForestPack"] >= 35
       and counts["Tronco musgoso"] <= 45
       and len(trunk_obstructions) == 0
       and len(forest_trunk_obstructions) == 0,
    "limitations": [
        "Does not test walkability, collision or FPS in an actual Roblox client",
        "Roblox terrain and actual lighting are not reconstructed faithfully",
        "The scenery quality and soundtrack require separate artistic review",
        "The Blender proxy does not reproduce texture/alpha cards of Forest Pack MeshParts"
    ],
}
(folder / "scene_qa.json").write_text(json.dumps(report, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
print(json.dumps({k:v for k,v in report.items() if k != "trunksIntersectingMainPath"},ensure_ascii=False))
if not report["pass"]:
    raise SystemExit("Falha QA geometrico: verificar scene_qa.json")
