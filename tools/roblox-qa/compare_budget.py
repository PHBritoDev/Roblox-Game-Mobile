#!/usr/bin/env python3
"""Compare equivalent Roblox headless snapshots; never claim client FPS."""
import argparse
import json
import math
from pathlib import Path


def metrics(scene):
    meta = scene["meta"]
    nav = scene["navigation"]
    parts = scene["parts"]
    if not isinstance(parts, list) or not parts:
        raise ValueError("Empty geometry")
    if type(meta.get("partsTotal")) is not int or meta["partsTotal"] <= 0:
        raise ValueError("Invalid partsTotal")
    if len(parts) != meta["partsTotal"] or meta.get("generationComplete") is not True:
        raise ValueError("Incomplete or sampled snapshot")
    if not isinstance(nav.get("routes"), list) or not nav["routes"]:
        raise ValueError("Missing navigation routes")
    if type(nav.get("proxyCount")) is not int or nav["proxyCount"] < 0:
        raise ValueError("Invalid navigation proxyCount")
    if any(not isinstance(route, dict) or not isinstance(route.get("samples"), list)
           or not route["samples"] for route in nav["routes"]):
        raise ValueError("Invalid navigation route samples")
    if any(not isinstance(part, dict) for part in parts):
        raise ValueError("Invalid geometry part")
    if any(type(part.get("collide")) is not bool for part in parts):
        raise ValueError("Invalid geometry collision flag")
    if any(not isinstance(part.get("shape"), str) or not part["shape"] for part in parts):
        raise ValueError("Invalid geometry shape")
    seconds = meta.get("generationSeconds")
    if type(seconds) not in (int, float) or not math.isfinite(seconds) or seconds < 0:
        raise ValueError("Missing or invalid generationSeconds")
    return {
        "parts": len(parts),
        "collidable_parts": sum(part.get("collide") is True for part in parts),
        "mesh_parts": sum(part.get("shape") == "MeshPart" for part in parts),
        "collidable_mesh_parts": sum(part.get("shape") == "MeshPart" and part.get("collide") is True for part in parts),
        "collision_proxies": nav["proxyCount"],
        "generation_seconds": seconds,
        "navigation_samples": sum(len(route["samples"]) for route in nav["routes"]),
    }


def compare(base, head):
    a, b = metrics(base), metrics(head)
    for key in ("forcedAssetFailure", "forcedIntegrationFailure", "testedLiveInsertService", "bakedEquivalentFixture"):
        if base["meta"].get(key) != head["meta"].get(key):
            raise ValueError(f"Incompatible snapshot modes: {key}")
    if not isinstance(base.get("assets"), dict) or not isinstance(head.get("assets"), dict):
        raise ValueError("Missing asset metadata")
    if base["assets"].get("source") != head["assets"].get("source"):
        raise ValueError("Incompatible asset sources")
    # Reject corrupt coordinate pairs; legacy coordinate-free fixtures remain supported.
    for scene in (base, head):
        for route in scene["navigation"]["routes"]:
            for sample in route["samples"]:
                if not isinstance(sample, dict):
                    raise ValueError("Invalid navigation sample")
                x, z = sample.get("x"), sample.get("z")
                if (x is None) != (z is None):
                    raise ValueError("Incomplete navigation coordinates")
                if x is not None and (type(x) not in (int, float) or type(z) not in (int, float)
                                      or not math.isfinite(x) or not math.isfinite(z)):
                    raise ValueError("Invalid navigation coordinates")
    # Route geometry alone is insufficient: a candidate can retain coordinates
    # while losing ground support or introducing a blocking trunk.
    for scene in (base, head):
        for route in scene["navigation"]["routes"]:
            for sample in route["samples"]:
                if "supported" in sample and sample["supported"] is not True:
                    raise ValueError("Navigation footing lost")
                if "blockers" in sample and (not isinstance(sample["blockers"], list)
                                             or sample["blockers"]):
                    raise ValueError("Navigation clearance blocked or invalid")
        spawn = scene["navigation"].get("spawn", {})
        if spawn and (spawn.get("present") is not True or spawn.get("anchored") is not True
                      or spawn.get("collidable") is not True):
            raise ValueError("Invalid spawn integrity")
        if spawn and isinstance(spawn.get("footing"), dict):
            foot = spawn["footing"]
            if foot.get("supported") is not True or foot.get("blockers"):
                raise ValueError("Spawn footing or clearance invalid")
        if scene["navigation"].get("invalidProxies"):
            raise ValueError("Invalid collision proxies")
    # Prevent a candidate snapshot from passing by omitting safety evidence.
    # Older fixtures without these optional fields remain comparable when both omit them.
    for old_route, new_route in zip(base["navigation"]["routes"], head["navigation"]["routes"]):
        for old_sample, new_sample in zip(old_route["samples"], new_route["samples"]):
            for field in ("supported", "blockers"):
                if field in old_sample and field not in new_sample:
                    raise ValueError(f"Candidate navigation evidence missing: {field}")
    old_nav, new_nav = base["navigation"], head["navigation"]
    for field in ("spawn", "invalidProxies"):
        if field in old_nav and field not in new_nav:
            raise ValueError(f"Candidate navigation evidence missing: {field}")
    if isinstance(old_nav.get("spawn"), dict) and isinstance(new_nav.get("spawn"), dict):
        for field in ("present", "anchored", "collidable", "footing"):
            if field in old_nav["spawn"] and field not in new_nav["spawn"]:
                raise ValueError(f"Candidate spawn evidence missing: {field}")
    if isinstance(old_nav.get("spawn", {}).get("footing"), dict):
        old_foot = old_nav["spawn"]["footing"]
        new_foot = new_nav["spawn"].get("footing")
        if not isinstance(new_foot, dict):
            raise ValueError("Candidate spawn footing missing")
        for field in ("supported", "blockers"):
            if field in old_foot and field not in new_foot:
                raise ValueError(f"Candidate spawn footing evidence missing: {field}")
    base_routes = [len(route["samples"]) for route in base["navigation"]["routes"]]
    head_routes = [len(route["samples"]) for route in head["navigation"]["routes"]]
    if base_routes != head_routes:
        raise ValueError("Navigation coverage differs")
    # Equal sample counts alone do not guarantee identical paths or bridge positions.
    for old_route, new_route in zip(base["navigation"]["routes"], head["navigation"]["routes"]):
        if old_route.get("name") != new_route.get("name"):
            raise ValueError("Navigation route names differ")
        for old_sample, new_sample in zip(old_route["samples"], new_route["samples"]):
            for axis in ("x", "z"):
                old_coord, new_coord = old_sample.get(axis), new_sample.get(axis)
                if old_coord is None and new_coord is None:
                    continue  # Legacy synthetic test fixtures without coordinates.
                if (type(old_coord) not in (int, float) or type(new_coord) not in (int, float)
                        or not math.isfinite(old_coord) or not math.isfinite(new_coord)
                        or abs(old_coord - new_coord) > 0.01):
                    raise ValueError("Navigation route coordinates differ")
    return {
        "baseline": a,
        "candidate": b,
        "delta": {key: round(b[key] - a[key], 4) for key in a},
        "percent_change": {key: (round((b[key] - a[key]) * 100 / a[key], 2)
                                if a[key] else None) for key in a},
        "limitations": "Headless geometry and generation time only; not Android FPS or Roblox visual approval",
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("baseline", type=Path, help="main scene.json")
    parser.add_argument("candidate", type=Path, help="PR scene.json")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    report = compare(json.loads(args.baseline.read_text()), json.loads(args.candidate.read_text()))
    result = json.dumps(report, indent=2) + "\n"
    if args.output:
        args.output.write_text(result)
    print(result, end="")


if __name__ == "__main__":
    main()
