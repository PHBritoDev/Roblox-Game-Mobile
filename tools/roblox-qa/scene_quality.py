#!/usr/bin/env python3
"""Engine navigation measurements plus proxy completeness; never visual approval."""
import argparse
import json
import math
from collections import Counter
from pathlib import Path


def navigation_failures(navigation):
    errors = []
    if not navigation:
        return ["Missing engine navigation measurements"]
    expected = {f"{name}:{offset}" for name, offsets in (
        ("main", (-4, 0, 4)), ("bridge", (-3, 0, 3)),
        ("lake", (-3, 0, 3)), ("river", (-3, 0, 3))) for offset in offsets}
    routes = navigation.get("routes", [])
    route_names = [route.get("name") for route in routes]
    if set(route_names) != expected:
        errors.append("Missing or unexpected navigation routes")
    if len(route_names) != len(set(route_names)):
        errors.append("Duplicate navigation routes; one route may hide an untested corridor")
    for route in routes:
        samples = route.get("samples", [])
        if len(samples) < (140 if route["name"].startswith("main:") else 10):
            errors.append(f"{route['name']}: incomplete samples")
        previous = None
        for index, sample in enumerate(samples):
            prefix = f"{route['name']}[{index}]"
            if not sample.get("supported"):
                errors.append(f"{prefix}: no solid support")
                previous = None
                continue
            if not all(isinstance(sample.get(key), (int, float)) and math.isfinite(sample[key])
                       for key in ("x", "y", "z", "normalY")):
                errors.append(f"{prefix}: invalid measurement")
                previous = None
                continue
            if not -1 <= sample["y"] <= 2:
                errors.append(f"{prefix}: support outside walkable ground height ({sample['y']:.2f})")
            if sample["normalY"] < math.cos(math.radians(20)):
                errors.append(f"{prefix}: support slope exceeds 20 degrees")
            if sample.get("blockers"):
                errors.append(f"{prefix}: solid obstacle {sample['blockers']}")
            if previous:
                distance = math.hypot(sample["x"]-previous["x"], sample["z"]-previous["z"])
                rise = abs(sample["y"]-previous["y"])
                if distance > 2.5:
                    errors.append(f"{prefix}: unsampled route gap ({distance:.2f})")
                if rise > 1.25 or (distance > 0 and rise/distance > math.tan(math.radians(20))):
                    errors.append(f"{prefix}: discontinuity/steep grade ({rise:.2f} in {distance:.2f})")
            previous = sample
    spawn = navigation.get("spawn", {})
    footing = spawn.get("footing", {})
    if not (spawn.get("present") and spawn.get("anchored") and spawn.get("collidable")
            and footing.get("supported") and not footing.get("blockers")
            and -1 <= footing.get("y", -99) <= 2):
        errors.append("Spawn missing, unsupported, obstructed, or not solid")
    if navigation.get("proxyCount", 0) < 1:
        errors.append("No physical tree/rock proxies measured")
    if navigation.get("invalidProxies"):
        errors.append(f"Invalid collision proxies: {navigation['invalidProxies']}")
    if navigation.get("activeScripts"):
        errors.append(f"Third-party scripts in generated world: {navigation['activeScripts']}")
    return errors


def evaluate(scene):
    parts = scene["parts"]
    counts = Counter(p["n"] for p in parts)
    origins = Counter(p.get("origin", "Authored") for p in parts)
    meta = scene["meta"]
    navigation = scene.get("navigation", {})
    errors = navigation_failures(navigation)
    if len(parts) != meta["partsExported"] or len(parts) > meta["partsTotal"]:
        errors.append("Exported geometry metadata inconsistent")
    if len(parts) < meta["partsTotal"] and not meta.get("geometrySampled", False):
        errors.append("Incomplete exported geometry without sampling declaration")
    if len(parts) != meta["partsTotal"]:
        errors.append("Incomplete exported geometry")
    assets = scene.get("assets", {})
    if meta.get("worldVersion",0)>=33:
        if not meta.get("generationComplete"):
            errors.append("World not ready")
        if not assets or assets.get("reserved",0)<1 or assets.get("fulfilled")!=assets.get("reserved"):
            errors.append("Reserved tree sites lost during asset integration")
        if assets.get("foliageBalls",0)>0 and not (
                meta.get("forcedAssetFailure") or meta.get("forcedIntegrationFailure")
        ):
            errors.append("Spherical placeholder foliage reintroduced outside isolated fault test")
        if assets.get("emptyMeshIds",0)>0:
            errors.append("Imported mesh has empty MeshId")
        if meta["partsTotal"]>6500:
            errors.append("Mobile part budget exceeded")
    if meta.get("forcedIntegrationFailure") and (assets.get("syntyIntegration") is not False or assets.get("forestIntegration") is not False):
        errors.append("Integration failure injection did not exercise both rollback paths")
    if meta.get("bakedEquivalentFixture") and assets.get("source")!="Bundled":
        errors.append("Bundled library was not used")
    asset_warnings = []
    if assets.get("foliageBalls",0)>0:
        asset_warnings.append(
            "Organic emergency tree crowns used in asset-failure simulation; "
            "appearance NOT validated and must not replace premium trees"
        )
    if meta.get("forestModels", 0) < 25:
        asset_warnings.append("Forest Pack degraded/unavailable; fallback needs visual review")
    if meta.get("forestUndergrowthModels", 0) < 12:
        asset_warnings.append("Textured undergrowth degraded/unavailable")
    return {
        "kind": "engine_geometry_and_navigation_qa",
        "robloxScreenshot": False,
        "runtimePlaytest": False,
        "engineSpatialQueries": True,
        "sampledParts": len(parts),
        "totalGeneratedParts": meta["partsTotal"],
        "geometrySampled": meta.get("geometrySampled", False),
        "treeTrunks": counts["Tronco musgoso"],
        "forestPackModels": meta.get("forestModels", 0),
        "forestUndergrowthModels": meta.get("forestUndergrowthModels", 0),
        "forestUndergrowthVariants": meta.get("forestUndergrowthVariants", 0),
        "forestPackParts": origins["ForestPack"],
        "syntyParts": origins["Synty"],
        "navigationSampleCount": sum(len(route.get("samples", [])) for route in navigation.get("routes", [])),
        "collisionProxyCount": navigation.get("proxyCount", 0),
        "navigationFailures": errors,
        "assetWarnings": asset_warnings,
        "assetDiagnostics": assets,
        "pass": not errors,
        "limitations": [
            "Engine support raycasts and standing-body collision geometry queries are not a Humanoid playtest",
            "Does not measure client streaming, Android FPS or appearance",
            "Roblox Terrain, water, alpha cards, PBR and lighting are not reconstructed faithfully by Blender",
            "Passing navigation and asset counts do not approve artistic quality",
            "Geometry preview may be sampled; navigation queries still inspect the full generated scene",
        ],
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--folder", type=Path, default=Path(__file__).resolve().parents[2] / "artifacts/visual-preview")
    folder = parser.parse_args().folder
    report = evaluate(json.loads((folder / "scene.json").read_text(encoding="utf-8")))
    (folder / "scene_qa.json").write_text(json.dumps(report, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False))
    if not report["pass"]:
        raise SystemExit("Falha QA de navegacao: verificar scene_qa.json")


if __name__ == "__main__":
    main()
