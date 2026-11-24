#!/usr/bin/env python3
"""Validate the compact ForestLibrary actually shipped in the premium Roblox place.

The existing default.project.json remains lightweight for emergency rollback.
"""
import argparse
import json
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ASSET = ROOT / "assets/ForestLibraryMobile.rbxmx"
PREMIUM = ROOT / "mobile-premium.project.json"
DEFAULT = ROOT / "default.project.json"
BUNDLED = ROOT / "bundled.project.json"
ALLOWED = {"Folder", "Model", "MeshPart", "SurfaceAppearance"}
EXPECTED = {
    "ForestPack": {
        "BeechwoodTreeLarge_Var01", "BeechwoodTree_Var03", "DogwoodTree_Var01",
        "MapleLeafTreeVar01", "RedwoodTree-Var01",
        "FernTallVar01", "MountainLaurelBush_Var01",
    },
    "Synty": {
        "Meshes/Fern_Plant_Fern_Leaves_01", "Meshes/Undergrowth",
        "Meshes/PolygonNature_Plant_Grass_05",
        "Meshes/PolygonNature_Rock_Cluster_Large_05",
    },
}

def instance_name(item):
    element = item.find("./Properties/string[@name='Name']")
    return element.text if element is not None else None

def validate():
    lite = json.loads(DEFAULT.read_text())
    full = json.loads(BUNDLED.read_text())
    mobile = json.loads(PREMIUM.read_text())
    assert "ServerStorage" not in lite["tree"], "Emergency startup build must remain lightweight"
    assert full["tree"]["ServerStorage"]["ForestLibrary"]["$path"] == "assets/ForestLibrary.rbxmx"
    assert mobile["tree"]["ServerStorage"]["ForestLibrary"]["$path"] == "assets/ForestLibraryMobile.rbxmx"
    for project in (full, mobile):
        del project["tree"]["ServerStorage"]
        assert project == lite, "Project variants differ beyond library injection"
    assert ASSET.stat().st_size < 1_200_000, "Mobile library exceeds startup budget"
    root = ET.parse(ASSET).getroot()
    library = root.find("Item")
    assert library is not None and instance_name(library) == "ForestLibrary"
    folders = {instance_name(folder): folder for folder in library.findall("Item")}
    assert set(folders) == set(EXPECTED)
    count = 0
    manifest = json.loads((ROOT / "assets/forest-manifest.json").read_text())
    for package, folder in folders.items():
        templates = {instance_name(item): item for item in folder.findall("Item")}
        assert set(templates) == EXPECTED[package], f"Missing or unexpected {package} template"
        originals = {item["name"]: item for item in manifest["packages"][package]["templates"]}
        for name, template in templates.items():
            meshes = [m for m in template.iter("Item") if m.get("class") == "MeshPart"]
            assert meshes, f"Template without mesh: {name}"
            actual_mesh_ids = sorted((m.find("./Properties/Content[@name='MeshId']/url").text or "")
                                     for m in meshes)
            expected_ids = sorted(x["id"] for x in originals[name]["meshes"])
            assert actual_mesh_ids == expected_ids, f"Mesh changed from reviewed asset: {name}"
            count += len(meshes)
    assert count == 20, f"Unexpected premium mesh budget: {count}"
    assert all(item.get("class") in ALLOWED for item in root.iter("Item")), "Unexpected script or external instance"
    ids = {x.get("md5") for x in root.findall("./SharedStrings/SharedString")}
    for node in root.iter("SharedString"):
        if node.get("name") is not None and node.text:
            assert node.text in ids, "Unresolved shared mesh data"
    print(f"Premium asset verified: {ASSET.stat().st_size} bytes, {count} meshes, 11 approved templates.")

def validate_built_premium(path):
    tree = ET.parse(path).getroot()
    server = next((e for e in tree.iter("Item")
                   if e.get("class") == "ServerStorage" or
                   (e.get("class") == "Service" and instance_name(e) == "ServerStorage")), None)
    # Rojo may serialize services as their class names or as unparented root items.
    assert server is not None, "ServerStorage absent from premium place"
    library = next((n for n in server.iter("Item")
                    if instance_name(n) == "ForestLibrary"), None)
    assert library is not None, "Premium library absent from published place"
    actual = [x for x in library.iter("Item") if x.get("class") == "MeshPart"]
    assert len(actual) == 20, f"Premium place lost curated meshes ({len(actual)})"
    assert all(x.get("class") not in {"Script", "LocalScript", "ModuleScript"}
               for x in library.iter("Item")), "Bundled third-party script!"
    print(f"Published premium place contains {len(actual)} curated MeshParts in ServerStorage.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("place", type=Path, nargs="?")
    args = parser.parse_args()
    validate()
    if args.place:
        validate_built_premium(args.place)
