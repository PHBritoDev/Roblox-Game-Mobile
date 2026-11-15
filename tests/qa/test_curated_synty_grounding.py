"""Curated Synty props must sit on Terrain rather than the Y=0 plane."""
from pathlib import Path

SOURCE = (Path(__file__).resolve().parents[2] / "src/server/DreamcoreWorld.server.luau").read_text(encoding="utf-8")


def test_curated_meshes_follow_terrain():
    assert "asset.CFrame=CFrame.new(entry[2],syntyGroundY(entry[2],entry[3])+asset.Size.Y/2-0.12,entry[3])" in SOURCE


def test_curated_models_follow_terrain():
    assert "asset:PivotTo(CFrame.new(entry[2],syntyGroundY(entry[2],entry[3])+desiredHeight/2-0.12,entry[3])" in SOURCE


def test_terrain_query_excludes_decorations():
    assert "syntyTerrainRayParams.FilterDescendantsInstances={terrain}" in SOURCE
