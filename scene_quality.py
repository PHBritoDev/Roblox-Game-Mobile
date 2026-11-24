#!/usr/bin/env python3
"""Engine navigation measurements plus proxy completeness; never visual approval."""
import argparse
import json
import math
from collections import Counter
from pathlib import Path


def finite_number(value):
    """Reject booleans, non-numbers and NaN/Infinity from engine measurements."""
    return type(value) in (int, float) and math.isfinite(value)


def valid_rotation(values):
    """CFrame rotation must be orthonormal and right-handed, not just finite."""
    if not isinstance(values, list) or len(values) != 9 or not all(finite_number(v) for v in values):
        return False
    rows = (values[0:3], values[3:6], values[6:9])
    dot = lambda a, b: sum(x * y for x, y in zip(a, b))
    if any(abs(dot(row, row) - 1) > 0.025 for row in rows):
        return False
    if any(abs(dot(rows[i], rows[j])) > 0.025 for i, j in ((0, 1), (0, 2), (1, 2))):
        return False
    cross = (
        rows[0][1] * rows[1][2] - rows[0][2] * rows[1][1],
        rows[0][2] * rows[1][0] - rows[0][0] * rows[1][2],
        rows[0][0] * rows[1][1] - rows[0][1] * rows[1][0],
    )
    return dot(cross, rows[2]) > 0.975


def navigation_failures(navigation):
    errors = []
    if not isinstance(navigation, dict) or not navigation:
        return ["Missing or malformed engine navigation measurements"]
    expected = {f"{name}:{offset}" for name, offsets in (
        ("main", (-4, 0, 4)), ("bridge", (-3, 0, 3)),
        ("lake", (-3, 0, 3)), ("river", (-3, 0, 3))) for offset in offsets}
    routes = navigation.get("routes", [])
    if not isinstance(routes, list) or not all(isinstance(route, dict) and isinstance(route.get("name"), str) for route in routes):
        return ["Malformed navigation routes: expected named route objects"]
    route_names = [route.get("name") for route in routes]
    if set(route_names) != expected:
        errors.append("Missing or unexpected navigation routes")
    if len(route_names) != len(set(route_names)):
        errors.append("Duplicate navigation routes; one route may hide an untested corridor")
    for route in routes:
        samples = route.get("samples", [])
        if not isinstance(samples, list) or not all(isinstance(sample, dict) for sample in samples):
            errors.append(f"{route['name']}: malformed samples")
            continue
        if len(samples) < (140 if route["name"].startswith("main:") else 10):
            errors.append(f"{route['name']}: incomplete samples")
        previous = None
        for index, sample in enumerate(samples):
            prefix = f"{route['name']}[{index}]"
            if sample.get("supported") is not True:
                errors.append(f"{prefix}: no solid support")
                previous = None
                continue
            if not isinstance(sample.get("blockers"), list) or not all(isinstance(b, str) for b in sample["blockers"]):
                errors.append(f"{prefix}: malformed collision blockers")
                previous = None
                continue
            if not all(finite_number(sample.get(key))
                       for key in ("x", "y", "z", "normalY")):
                errors.append(f"{prefix}: invalid measurement")
                previous = None
                continue
            if not -1 <= sample["y"] <= 2:
                errors.append(f"{prefix}: support outside walkable ground height ({sample['y']:.2f})")
            if not -1 <= sample["normalY"] <= 1:
                errors.append(f"{prefix}: surface normal outside [-1, 1]")
            elif sample["normalY"] < math.cos(math.radians(20)):
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
    if not isinstance(spawn, dict):
        return errors + ["Malformed spawn measurements"]
    footing = spawn.get("footing", {})
    if not isinstance(footing, dict):
        return errors + ["Malformed spawn footing"]
    if not (spawn.get("present") is True and spawn.get("anchored") is True
            and spawn.get("collidable") is True and footing.get("supported") is True
            and isinstance(footing.get("blockers"), list) and not footing["blockers"]
            and finite_number(footing.get("y"))
            and -1 <= footing["y"] <= 2):
        errors.append("Spawn missing, unsupported, obstructed, or not solid")
    proxy_count = navigation.get("proxyCount", 0)
    if not finite_number(proxy_count) or proxy_count < 1:
        errors.append("No physical tree/rock proxies measured")
    if not isinstance(navigation.get("invalidProxies"), list):
        errors.append("Malformed invalidProxies telemetry")
    if navigation.get("invalidProxies"):
        errors.append(f"Invalid collision proxies: {navigation['invalidProxies']}")
    if not isinstance(navigation.get("activeScripts"), list):
        errors.append("Malformed activeScripts telemetry")
    if navigation.get("activeScripts"):
        errors.append(f"Third-party scripts in generated world: {navigation['activeScripts']}")
    return errors


def evaluate(scene):
    if not isinstance(scene, dict):
        return {"pass": False, "navigationFailures": ["Scene snapshot must be a JSON object"]}
    parts = scene.get("parts")
    meta = scene.get("meta")
    if not isinstance(parts, list) or not all(isinstance(p, dict) and isinstance(p.get("n"), str) for p in parts):
        return {"pass": False, "navigationFailures": ["Malformed scene parts"]}
    if not isinstance(meta, dict) or not all(
            finite_number(meta.get(k)) and meta[k] >= 0 and int(meta[k]) == meta[k]
            for k in ("partsTotal", "partsExported")):
        return {"pass": False, "navigationFailures": ["Malformed scene geometry metadata"]}
    # Reject corrupt geometry even when navigation and total counts look valid.
    geometry_errors = []
    for index, part in enumerate(parts):
        if not isinstance(part.get("origin", "Authored"), str):
            geometry_errors.append(f"part[{index}]: invalid origin")
            continue
        for key, length in (("p", 3), ("s", 3), ("c", 3), ("rot", 9)):
            values = part.get(key)
            if not isinstance(values, list) or len(values) != length or not all(finite_number(v) for v in values):
                geometry_errors.append(f"part[{index}]: invalid {key} vector")
                break
            if key == "rot" and not valid_rotation(values):
                geometry_errors.append(f"part[{index}]: non-orthonormal or mirrored rotation")
                break
            if key == "s" and any(v <= 0 for v in values):
                geometry_errors.append(f"part[{index}]: non-positive size")
                break
            if key == "c" and any(not 0 <= v <= 1 for v in values):
                geometry_errors.append(f"part[{index}]: color outside [0, 1]")
                break
        if len(geometry_errors) >= 20:
            geometry_errors.append("Further invalid geometry omitted")
            break
    counts = Counter(p["n"] for p in parts)
    origins = Counter(p.get("origin", "Authored") for p in parts)
    navigation = scene.get("navigation", {})
    errors = geometry_errors + navigation_failures(navigation)
    if len(parts) != meta["partsExported"] or len(parts) > meta["partsTotal"]:
        errors.append("Exported geometry metadata inconsistent")
    if len(parts) < meta["partsTotal"] and not meta.get("geometrySampled", False):
        errors.append("Incomplete exported geometry without sampling declaration")
    if len(parts) != meta["partsTotal"]:
        errors.append("Incomplete exported geometry")
    assets = scene.get("assets", {})
    if not isinstance(assets, dict):
        errors.append("Malformed asset diagnostics")
        assets = {}
    version = meta.get("worldVersion", 0)
    if not finite_number(version) or version < 0 or int(version) != version:
        errors.append("Invalid worldVersion metadata")
        version = 0
    if version >= 33:
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
    # Telemetria do gerador deve bater com as instancias reais exportadas.
    # Isto nao mede FPS: detecta custo e inconsistencias antes do Android.
    if meta.get("generatedPartCount") is not None:
        total = meta["generatedPartCount"]
        meshes = meta.get("generatedMeshPartCount")
        noncolliding = meta.get("generatedNonCollidingPartCount")
        seconds = meta.get("generationSeconds")
        if (not finite_number(total) or int(total) != total or total != meta["partsTotal"]
                or not finite_number(meshes) or int(meshes) != meshes or not 0 <= meshes <= total
                or not finite_number(noncolliding) or int(noncolliding) != noncolliding
                or not 0 <= noncolliding <= total
                or not finite_number(seconds) or seconds < 0):
            errors.append("Invalid or inconsistent forest generation budget telemetry")
        elif meshes != sum(p.get("shape") == "MeshPart" for p in parts):
            errors.append("Generated MeshPart count disagrees with exported geometry")
        elif noncolliding != sum(p.get("collide") is False for p in parts):
            errors.append("Generated non-colliding count disagrees with exported geometry")
    elif meta.get("sourceSha256") and version >= 34:
        errors.append("Missing forest generation budget telemetry in headless snapshot")
    # A partir da V34, nao confundir telemetria ausente com ausencia de falhas.
    # O snapshot de fallback deve carregar um motivo explicito de degradacao.
    if version >= 34:
        status = assets.get("undergrowthStatus")
        failures = assets.get("undergrowthFailures")
        first_error = assets.get("undergrowthFirstError")
        valid = {"Placed", "Partial", "NoTemplates", "Unavailable", "IntegrationFailed"}
        if (status not in valid or not isinstance(failures, int)
                or isinstance(failures, bool) or failures < 0
                or not isinstance(first_error, str)):
            errors.append("Missing or malformed undergrowth rollback telemetry")
        elif status != "Placed" and (failures == 0 or not first_error):
            errors.append("Undergrowth degradation missing explicit cause and failure count")
        elif status == "Placed" and failures != 0:
            errors.append("Successful undergrowth placement reports failures")
        elif meta.get("forcedAssetFailure") and status != "Unavailable":
            errors.append("Forced asset failure failed to report undergrowth unavailability")
        elif meta.get("forcedIntegrationFailure") and status != "IntegrationFailed":
            errors.append("Forced integration failure failed to report undergrowth rollback")
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
