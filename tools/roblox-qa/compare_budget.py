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
    if len(parts) != meta["partsTotal"] or not meta.get("generationComplete"):
        raise ValueError("Incomplete or sampled snapshot")
    if not isinstance(parts, list) or not parts:
        raise ValueError("Empty geometry")
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
    if a["navigation_samples"] != b["navigation_samples"]:
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
