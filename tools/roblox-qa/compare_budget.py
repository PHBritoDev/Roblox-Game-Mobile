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
    seconds = meta.get("generationSeconds")
    if type(seconds) not in (int, float) or not math.isfinite(seconds) or seconds < 0:
        raise ValueError("Missing or invalid generationSeconds")
    return {
        "parts": len(parts),
        "collidable_parts": sum(part.get("collide") is True for part in parts),
        "mesh_parts": sum(part.get("shape") == "MeshPart" for part in parts),
        "collision_proxies": nav["proxyCount"],
        "generation_seconds": seconds,
        "navigation_samples": sum(len(route["samples"]) for route in nav["routes"]),
    }


def compare(base, head):
    a, b = metrics(base), metrics(head)
    for key in ("forcedAssetFailure", "forcedIntegrationFailure", "testedLiveInsertService"):
        if base["meta"].get(key) != head["meta"].get(key):
            raise ValueError(f"Incompatible snapshot modes: {key}")
    if base["assets"].get("source") != head["assets"].get("source"):
        raise ValueError("Incompatible asset sources")
    base_routes = [len(route["samples"]) for route in base["navigation"]["routes"]]
    head_routes = [len(route["samples"]) for route in head["navigation"]["routes"]]
    if base_routes != head_routes or a["collision_proxies"] != b["collision_proxies"]:
        raise ValueError("Navigation coverage differs")
    return {
        "baseline": a,
        "candidate": b,
        "delta": {key: round(b[key] - a[key], 4) for key in a},
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
