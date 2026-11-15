#!/usr/bin/env python3
"""Check that the startup Place is light while an identical full-library build remains."""
from pathlib import Path
import argparse
import json
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]


def count_meshes(path):
    root = ET.parse(path).getroot()
    return sum(1 for node in root.iter("Item") if node.get("class") == "MeshPart")


def validate(light_file, full_file):
    light = json.loads((ROOT / "default.project.json").read_text(encoding="utf-8"))
    full = json.loads((ROOT / "bundled.project.json").read_text(encoding="utf-8"))
    assert full["tree"]["ServerStorage"]["ForestLibrary"]["$path"] == "assets/ForestLibrary.rbxmx"
    del full["tree"]["ServerStorage"]
    assert light == full, "Build variants differ beyond the deferred library"
    lightweight_count = count_meshes(light_file)
    full_count = count_meshes(full_file)
    assert lightweight_count == 0, f"Unexpected {lightweight_count} MeshParts in bootstrap"
    assert full_count >= 37, f"Bundled Place lost curated meshes: {full_count}"
    print(f"Bootstrap verified: {lightweight_count} meshes; full library preserved: {full_count} meshes")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("light_file", type=Path)
    parser.add_argument("full_file", type=Path)
    args = parser.parse_args()
    validate(args.light_file, args.full_file)
